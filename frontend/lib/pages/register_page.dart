import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/primary_button.dart';
import '../theme/app_colors.dart';
import 'email_verification_page.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final TextEditingController _userController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  bool _isLoading = false;
  bool _obscurePass = true;

  static final RegExp _emailRegex = RegExp(r'^[\w.+-]+@[\w-]+\.[\w.-]+$');

  @override
  void dispose() {
    _userController.dispose();
    _emailController.dispose();
    _passController.dispose();
    super.dispose();
  }

  void _register() async {
    final username = _userController.text.trim();
    final email = _emailController.text.trim().toLowerCase();

    if (username.isEmpty || email.isEmpty || _passController.text.isEmpty) {
      _showError("Lengkapi username, email, dan kata sandi");
      return;
    }
    if (!_emailRegex.hasMatch(email)) {
      _showError("Format email tidak valid");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result = await ApiService.register(username, email, _passController.text);
      if (!mounted) return;

      if (result['email_sent'] == false) {
        _showError("Akun dibuat, tapi email gagal dikirim. Coba tombol Kirim Ulang.");
      }

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => EmailVerificationPage(
            email: result['email'] ?? email,
            resendCooldown: result['resend_cooldown'] ?? 60,
          ),
        ),
      );
    } catch (e) {
      _showError(e.toString().replaceAll("Exception: ", ""));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: AppColors.danger,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
    ));
  }

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
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
                  onPressed: () => Navigator.pop(context),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(28, 0, 28, 40),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header text on red ──────────
                        const Padding(
                          padding: EdgeInsets.only(left: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Buat Akun",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              SizedBox(height: 6),
                              Text(
                                "Mulai perjalanan defisit kalori Anda hari ini.",
                                style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                              ),
                            ],
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
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildField("Username", "Buat username",
                                  Icons.person_add_outlined, _userController, false),
                              const SizedBox(height: 16),
                              _buildField("Email", "contoh@email.com",
                                  Icons.email_outlined, _emailController, false,
                                  keyboardType: TextInputType.emailAddress),
                              const SizedBox(height: 16),
                              _buildField("Password", "Buat kata sandi",
                                  Icons.lock_outline_rounded, _passController, true),

                              const SizedBox(height: 14),

                              const Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.info_outline_rounded,
                                      color: AppColors.textSub, size: 15),
                                  SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      "Kami akan mengirim kode verifikasi 6 digit ke email Anda.",
                                      style: TextStyle(
                                        color: AppColors.textSub,
                                        fontSize: 12,
                                        height: 1.5,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 28),

                              PrimaryButton(
                                label: "Daftar",
                                onTap: _register,
                                isLoading: _isLoading,
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

  Widget _buildField(String label, String hint, IconData icon,
      TextEditingController ctrl, bool isPass,
      {TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppColors.textPri,
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border, width: 1.5),
          ),
          child: TextField(
            controller: ctrl,
            obscureText: isPass && _obscurePass,
            keyboardType: keyboardType,
            style: const TextStyle(color: AppColors.textPri, fontSize: 15),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: AppColors.textSub, fontSize: 14),
              prefixIcon: Icon(icon, color: AppColors.accent, size: 20),
              suffixIcon: isPass
                  ? IconButton(
                      icon: Icon(
                        _obscurePass ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: AppColors.textSub,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscurePass = !_obscurePass),
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ],
    );
  }
}