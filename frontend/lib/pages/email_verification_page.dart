import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/primary_button.dart';
import '../widgets/main_shell.dart';
import 'onboarding_page.dart';

/// Halaman input kode OTP 6 digit yang dikirim ke email user setelah registrasi.
class EmailVerificationPage extends StatefulWidget {
  final String email;

  /// Lama hitung mundur tombol "Kirim Ulang" (detik).
  final int resendCooldown;

  const EmailVerificationPage({
    super.key,
    required this.email,
    this.resendCooldown = 60,
  });

  @override
  State<EmailVerificationPage> createState() => _EmailVerificationPageState();
}

class _EmailVerificationPageState extends State<EmailVerificationPage> {
  static const int _codeLength = 6;

  final List<TextEditingController> _controllers =
      List.generate(_codeLength, (_) => TextEditingController());
  final List<FocusNode> _focusNodes = List.generate(_codeLength, (_) => FocusNode());

  Timer? _timer;
  int _secondsLeft = 0;
  bool _isLoading = false;
  bool _isResending = false;

  String get _code => _controllers.map((c) => c.text).join();

  @override
  void initState() {
    super.initState();
    _startCountdown(widget.resendCooldown);
    // Border kotak ikut berubah saat fokus berpindah
    for (final node in _focusNodes) {
      node.addListener(() {
        if (mounted) setState(() {});
      });
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _focusNodes.first.requestFocus();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _controllers) {
      c.dispose();
    }
    for (final f in _focusNodes) {
      f.dispose();
    }
    super.dispose();
  }

  // ── Hitung mundur "Kirim Ulang" ────────────────────────────────
  void _startCountdown(int seconds) {
    _timer?.cancel();
    setState(() => _secondsLeft = seconds);
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return t.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) t.cancel();
    });
  }

  String get _countdownText {
    final m = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final s = (_secondsLeft % 60).toString().padLeft(2, '0');
    return "$m:$s";
  }

  // ── Input OTP ───────────────────────────────────────────────────
  void _onDigitChanged(int index, String value) {
    // Dukungan tempel (paste) kode langsung dari email
    if (value.length > 1) {
      final digits = value.replaceAll(RegExp(r'\D'), '');
      for (int i = 0; i < _codeLength; i++) {
        _controllers[i].text = i < digits.length ? digits[i] : '';
      }
      final next = digits.length.clamp(0, _codeLength - 1);
      _focusNodes[next].requestFocus();
      setState(() {});
      if (digits.length >= _codeLength) _verify();
      return;
    }

    if (value.isNotEmpty && index < _codeLength - 1) {
      _focusNodes[index + 1].requestFocus();
    } else if (value.isEmpty && index > 0) {
      _focusNodes[index - 1].requestFocus();
    }

    setState(() {});

    if (_code.length == _codeLength) {
      FocusScope.of(context).unfocus();
      _verify();
    }
  }

  /// Backspace pada kotak kosong -> mundur ke kotak sebelumnya.
  KeyEventResult _onKey(int index, KeyEvent event) {
    if (event is KeyDownEvent &&
        event.logicalKey == LogicalKeyboardKey.backspace &&
        _controllers[index].text.isEmpty &&
        index > 0) {
      _controllers[index - 1].clear();
      _focusNodes[index - 1].requestFocus();
      setState(() {});
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  void _clearCode() {
    for (final c in _controllers) {
      c.clear();
    }
    _focusNodes.first.requestFocus();
    setState(() {});
  }

  // ── Aksi ────────────────────────────────────────────────────────
  void _verify() async {
    if (_isLoading) return;
    if (_code.length != _codeLength) {
      _showMessage("Masukkan $_codeLength digit kode verifikasi", isError: true);
      return;
    }
    setState(() => _isLoading = true);
    try {
      final int userId = await ApiService.verifyEmail(widget.email, _code);
      if (!mounted) return;

      // Cek apakah user sudah punya profil kesehatan
      bool hasProfile = true;
      try {
        await ApiService.getDashboard(userId);
      } catch (_) {
        hasProfile = false;
      }
      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => hasProfile ? MainShell(userId: userId) : OnboardingPage(userId: userId),
        ),
        (route) => false,
      );
    } catch (e) {
      _showMessage(e.toString().replaceAll("Exception: ", ""), isError: true);
      _clearCode();
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _resend() async {
    if (_secondsLeft > 0 || _isResending) return;
    setState(() => _isResending = true);
    try {
      await ApiService.resendVerificationCode(widget.email);
      if (!mounted) return;
      _clearCode();
      _startCountdown(widget.resendCooldown);
      _showMessage("Kode baru telah dikirim ke ${widget.email}");
    } catch (e) {
      _showMessage(e.toString().replaceAll("Exception: ", ""), isError: true);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(text),
      backgroundColor: isError ? AppColors.danger : AppColors.success,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ));
  }

  // ── UI ──────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.card,
      body: Stack(
        children: [
          // ── Red curve header ─────────────────────────
          Container(
            height: 220,
            decoration: const BoxDecoration(
              gradient: AppColors.heroBg,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(48),
                bottomRight: Radius.circular(48),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back button in red area
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded,
                      color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),

                const SizedBox(height: 8),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Ikon amplop di area merah ──────
                        Center(
                          child: Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.3), width: 1.5),
                            ),
                            child: const Icon(Icons.mark_email_unread_outlined,
                                size: 38, color: Colors.white),
                          ),
                        ),

                        const SizedBox(height: 28),

                        // ── White form card ─────────────
                        Container(
                          padding: const EdgeInsets.all(28),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 32,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                "Verifikasi Email",
                                style: TextStyle(
                                  color: AppColors.textPri,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              const SizedBox(height: 6),
                              const Text(
                                "Kode verifikasi telah dikirim ke email Anda",
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    color: AppColors.textSub, fontSize: 13, height: 1.5),
                              ),

                              const SizedBox(height: 20),

                              // ── Email chip ─────────────
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.bg,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                      color: AppColors.border, width: 1.5),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.email_outlined,
                                        color: AppColors.accent, size: 18),
                                    const SizedBox(width: 10),
                                    Flexible(
                                      child: Text(
                                        widget.email,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          color: AppColors.textPri,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),

                              // ── 6 kotak OTP ────────────
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: List.generate(
                                    _codeLength, (i) => _buildCodeBox(i)),
                              ),

                              const SizedBox(height: 28),

                              PrimaryButton(
                                label: "Verifikasi",
                                onTap: _verify,
                                isLoading: _isLoading,
                              ),

                              const SizedBox(height: 22),

                              // ── Kirim ulang ────────────
                              const Text(
                                "Tidak menerima kode?",
                                style: TextStyle(
                                    color: AppColors.textSub, fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              GestureDetector(
                                onTap: _resend,
                                child: Text(
                                  "Kirim Ulang",
                                  style: TextStyle(
                                    color: _secondsLeft > 0
                                        ? AppColors.textSub
                                        : AppColors.accent,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    decoration: TextDecoration.underline,
                                    decorationColor: _secondsLeft > 0
                                        ? AppColors.textSub
                                        : AppColors.accent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _secondsLeft > 0
                                    ? "Kirim ulang dalam $_countdownText"
                                    : "Anda bisa meminta kode baru sekarang",
                                style: const TextStyle(
                                    color: AppColors.textSub, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeBox(int index) {
    final bool filled = _controllers[index].text.isNotEmpty;
    final bool focused = _focusNodes[index].hasFocus;

    return Flexible(
      child: Padding(
        padding: EdgeInsets.only(right: index == _codeLength - 1 ? 0 : 8),
        child: Focus(
          canRequestFocus: false,
          skipTraversal: true,
          onKeyEvent: (_, event) => _onKey(index, event),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            height: 56,
            decoration: BoxDecoration(
              color: filled ? AppColors.accentLight : AppColors.bg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: focused || filled ? AppColors.accent : AppColors.border,
                width: 1.5,
              ),
            ),
            child: TextField(
              controller: _controllers[index],
              focusNode: _focusNodes[index],
              onChanged: (v) => _onDigitChanged(index, v),
              onTap: () => _controllers[index].selection = TextSelection.collapsed(
                  offset: _controllers[index].text.length),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              textInputAction: index == _codeLength - 1
                  ? TextInputAction.done
                  : TextInputAction.next,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: index == 0 ? _codeLength : 1, // kotak pertama menerima paste
              showCursor: false,
              style: const TextStyle(
                color: AppColors.textPri,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
              decoration: const InputDecoration(
                counterText: "",
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
