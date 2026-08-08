import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/main_shell.dart';
import '../theme/app_colors.dart';

class OnboardingPage extends StatefulWidget {
  final int userId;
  const OnboardingPage({super.key, required this.userId});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _nameController   = TextEditingController();
  final _ageController    = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _ageController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  // Batas wajar untuk perhitungan kalori (Mifflin-St Jeor).
  static const _minAge = 1, _maxAge = 120;
  static const _minHeight = 50.0, _maxHeight = 250.0;
  static const _minWeight = 10.0, _maxWeight = 300.0;

  static double? _toNum(String raw) =>
      double.tryParse(raw.trim().replaceAll(',', '.'));

  /// Mengembalikan pesan error pertama yang ditemukan, atau null jika valid.
  String? _validateInputs() {
    if (_nameController.text.trim().isEmpty) {
      return "Nama panggilan tidak boleh kosong";
    }

    final age = int.tryParse(_ageController.text.trim());
    if (age == null) return "Umur harus berupa angka";
    if (age < _minAge || age > _maxAge) {
      return "Umur harus antara $_minAge sampai $_maxAge tahun";
    }

    final height = _toNum(_heightController.text);
    if (height == null) return "Tinggi badan harus berupa angka";
    if (height < _minHeight || height > _maxHeight) {
      return "Tinggi badan harus antara ${_minHeight.toInt()} sampai ${_maxHeight.toInt()} cm";
    }

    final weight = _toNum(_weightController.text);
    if (weight == null) return "Berat badan harus berupa angka";
    if (weight < _minWeight || weight > _maxWeight) {
      return "Berat badan harus antara ${_minWeight.toInt()} sampai ${_maxWeight.toInt()} kg";
    }

    return null;
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

  void _submit() async {
    // Hentikan sebelum request: tidak menghitung BMR, tidak menyimpan ke database.
    final validationError = _validateInputs();
    if (validationError != null) {
      _showError(validationError);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final data = {
        "name":      _nameController.text.trim(),
        "age":       int.parse(_ageController.text.trim()),
        "height_cm": _toNum(_heightController.text)!,
        "weight_kg": _toNum(_weightController.text)!,
      };
      final bool success = await ApiService.createProfile(widget.userId, data);
      if (success && mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainShell(userId: widget.userId)),
        );
      }
    } catch (e) {
      _showError("Gagal menyimpan profil");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ──────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 60, 24, 32),
              decoration: const BoxDecoration(
                gradient: AppColors.heroBg,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Buat Profil",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    "Lengkapi data dirimu agar AI dapat menghitung kalori yang tepat.",
                    style: TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                  ),
                ],
              ),
            ),
          ),

          // ── Form ─────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([

                // ── Identitas Section ──────────────────
                _sectionCard(
                  title: "Identitas",
                  icon: Icons.badge_outlined,
                  children: [
                    _buildField(_nameController, "Nama Panggilan", Icons.person_outline_rounded),
                    const SizedBox(height: 14),
                    _buildField(_ageController, "Umur (Tahun)", Icons.cake_outlined, isNum: true),
                  ],
                ),

                const SizedBox(height: 16),

                // ── Data Fisik Section ─────────────────
                _sectionCard(
                  title: "Data Fisik",
                  icon: Icons.monitor_weight_outlined,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _buildField(
                            _heightController, "Tinggi (cm)", Icons.height_rounded, isNum: true),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildField(
                            _weightController, "Berat (kg)", Icons.scale_outlined, isNum: true),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                PrimaryButton(
                  label: "Simpan & Mulai",
                  onTap: _submit,
                  isLoading: _isLoading,
                ),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.accent, size: 16),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: AppColors.textPri,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: AppColors.border, height: 1),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(TextEditingController ctrl, String hint, IconData icon,
      {bool isNum = false}) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border, width: 1.5),
      ),
      child: TextField(
        controller: ctrl,
        keyboardType: isNum ? TextInputType.number : TextInputType.text,
        style: const TextStyle(color: AppColors.textPri, fontSize: 15),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textSub, fontSize: 14),
          prefixIcon: Icon(icon, color: AppColors.accent, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 16),
        ),
      ),
    );
  }
}