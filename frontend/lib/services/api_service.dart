import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

/// Dilempar saat login memakai akun yang emailnya belum diverifikasi,
/// supaya UI bisa langsung mengarahkan ke halaman Verifikasi Email.
class EmailNotVerifiedException implements Exception {
  final String email;
  final String message;
  EmailNotVerifiedException(this.email, this.message);

  @override
  String toString() => message;
}

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return "http://127.0.0.1:8000";
    if (defaultTargetPlatform == TargetPlatform.android) return "http://10.210.112.44:8000";
    return "http://127.0.0.1:8000";
  }

  /// Ambil pesan error dari body FastAPI ({"detail": ...}).
  static String _detailOf(http.Response res, String fallback) {
    try {
      final detail = jsonDecode(utf8.decode(res.bodyBytes))['detail'];
      if (detail is String) return detail;
      if (detail is Map && detail['message'] is String) return detail['message'];
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] is String) return first['msg'];
      }
    } catch (_) {}
    return fallback;
  }

  // ── Auth & Profile ──────────────────────────────────────────────
  static Future<int> login(String username, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body)['user_id'];

    if (res.statusCode == 403) {
      final detail = jsonDecode(utf8.decode(res.bodyBytes))['detail'];
      if (detail is Map && detail['code'] == "EMAIL_NOT_VERIFIED") {
        throw EmailNotVerifiedException(
          detail['email'] ?? "",
          detail['message'] ?? "Email belum diverifikasi",
        );
      }
    }
    throw Exception(_detailOf(res, "Username atau password salah"));
  }

  /// Mendaftarkan user baru. Akun dibuat dalam status belum terverifikasi
  /// dan kode OTP dikirim ke [email].
  static Future<Map<String, dynamic>> register(
      String username, String email, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "email": email, "password": password}),
    );
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception(_detailOf(res, "Gagal mendaftar. Username atau email mungkin sudah dipakai."));
  }

  /// Kirim kode OTP yang diinput user. Mengembalikan user_id kalau berhasil.
  static Future<int> verifyEmail(String email, String code) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/verify-email"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email, "code": code}),
    );
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes))['user_id'];
    }
    throw Exception(_detailOf(res, "Kode verifikasi salah"));
  }

  /// Minta kode OTP baru (tombol "Kirim Ulang").
  static Future<void> resendVerificationCode(String email) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/resend-code"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"email": email}),
    );
    if (res.statusCode != 200) {
      throw Exception(_detailOf(res, "Gagal mengirim ulang kode"));
    }
  }

  static Future<bool> createProfile(int userId, Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/profile/$userId"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    return res.statusCode == 200;
  }

  // ── Dashboard & Meals ───────────────────────────────────────────
  static Future<Map<String, dynamic>> getDashboard(int userId) async {
    final res = await http.get(Uri.parse("$baseUrl/dashboard/$userId"));
    if (res.statusCode == 200) return jsonDecode(res.body);
    throw Exception("PROFILE_NOT_FOUND");
  }

  static Future<Map<String, dynamic>> scanFood(XFile image, double glucose, int userId) async {
    var req = http.MultipartRequest('POST', Uri.parse("$baseUrl/scan/"));
    req.files.add(http.MultipartFile.fromBytes('file', await image.readAsBytes(), filename: image.name));
    req.fields['user_id'] = userId.toString();
    var res = await req.send();
    if (res.statusCode != 200) throw Exception("Gagal scan makanan");
    return jsonDecode(await res.stream.bytesToString());
  }

  static Future<Map<String, dynamic>> logMeal(Map<String, dynamic> data) async {
    final res = await http.post(
      Uri.parse("$baseUrl/meals/log"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );
    return jsonDecode(res.body);
  }

  /// Riwayat makan pada satu tanggal (null = hari ini) + ringkasan gizinya.
  static Future<Map<String, dynamic>> getMealHistory(int userId, {DateTime? date}) async {
    final query = date == null
        ? ""
        : "?tanggal=${date.year.toString().padLeft(4, '0')}-"
            "${date.month.toString().padLeft(2, '0')}-"
            "${date.day.toString().padLeft(2, '0')}";
    final res = await http.get(Uri.parse("$baseUrl/meals/history/$userId$query"));
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception(_detailOf(res, "Gagal memuat riwayat makan"));
  }

  // ── Favorit ─────────────────────────────────────────────────────
  /// Makanan yang sudah discan minimal 5x oleh user.
  static Future<Map<String, dynamic>> getFavorites(int userId) async {
    final res = await http.get(Uri.parse("$baseUrl/meals/favorites/$userId"));
    if (res.statusCode == 200) {
      return jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    }
    throw Exception(_detailOf(res, "Gagal memuat makanan favorit"));
  }

  /// Sembunyikan / kembalikan makanan dari daftar favorit.
  static Future<void> setFavoriteHidden(
      int userId, String foodName, bool hidden) async {
    final aksi = hidden ? "hide" : "unhide";
    final res = await http.post(
      Uri.parse("$baseUrl/meals/favorites/$userId/$aksi"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"food_name": foodName}),
    );
    if (res.statusCode != 200) {
      throw Exception(_detailOf(res, "Gagal memperbarui favorit"));
    }
  }

  static Future<Map<String, dynamic>> getMealSchedule(int userId) async {
    final response = await http.get(Uri.parse('$baseUrl/meals/schedule/$userId'));
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Gagal memuat jadwal makan');
    }
  }

  static Future<Map<String, dynamic>> getProfile(int userId) async {
  final res = await http.get(Uri.parse("$baseUrl/auth/profile/$userId"));
  if (res.statusCode == 200) return jsonDecode(res.body);
  throw Exception("Gagal memuat profil");
}
}