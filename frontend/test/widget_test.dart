// Smoke test dasar untuk FoodScan AI.
//
// Menguji halaman awal (Login) dan halaman Verifikasi Email dapat dirender.
// Tidak ada pemanggilan API di sini, hanya pengecekan tampilan.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:frontend/main.dart';
import 'package:frontend/pages/email_verification_page.dart';

void main() {
  testWidgets('Aplikasi terbuka di halaman Login', (WidgetTester tester) async {
    await tester.pumpWidget(const FoodScanApp());

    expect(find.text('FoodScan AI'), findsOneWidget);
    expect(find.text('Masuk'), findsWidgets);
    expect(find.text('Selamat datang kembali!'), findsOneWidget);
    expect(find.text('Username'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });

  testWidgets('Halaman Verifikasi Email menampilkan 6 kotak kode',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: EmailVerificationPage(email: 'user@example.com'),
    ));

    expect(find.text('Verifikasi Email'), findsOneWidget);
    expect(find.text('Kode verifikasi telah dikirim ke email Anda'), findsOneWidget);
    expect(find.text('user@example.com'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(6));
    expect(find.text('Verifikasi'), findsOneWidget);
    expect(find.text('Kirim Ulang'), findsOneWidget);

    // Hitung mundur dimulai dari 60 detik
    expect(find.text('Kirim ulang dalam 01:00'), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Kirim ulang dalam 00:59'), findsOneWidget);

    // Lepas halaman agar Timer periodik ikut dibatalkan
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('Mengetik kode memindahkan fokus antar kotak',
      (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: EmailVerificationPage(email: 'user@example.com'),
    ));

    await tester.enterText(find.byType(TextField).at(0), '1');
    await tester.pump();
    await tester.enterText(find.byType(TextField).at(1), '2');
    await tester.pump();

    expect(find.text('1'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);

    await tester.pumpWidget(const SizedBox());
  });
}
