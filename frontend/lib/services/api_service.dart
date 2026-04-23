import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform, TargetPlatform;
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class ApiService {
  static String get baseUrl {
    if (kIsWeb) return "http://127.0.0.1:8000";
    if (defaultTargetPlatform == TargetPlatform.android) return "http://192.168.68.205:8000";
    return "http://127.0.0.1:8000";
  }

  // ── Auth & Profile ──────────────────────────────────────────────
  static Future<int> login(String username, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/login"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body)['user_id'];
    throw Exception("Username atau password salah");
  }

  static Future<int> register(String username, String password) async {
    final res = await http.post(
      Uri.parse("$baseUrl/auth/register"),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"username": username, "password": password}),
    );
    if (res.statusCode == 200) return jsonDecode(res.body)['user_id'];
    throw Exception("Gagal mendaftar. Username mungkin sudah dipakai.");
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