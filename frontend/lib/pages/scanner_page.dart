import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import '../services/api_service.dart';
import '../widgets/primary_button.dart';
import '../widgets/picker_button.dart';
import '../theme/app_colors.dart';

class ScannerPage extends StatefulWidget {
  final int userId;
  const ScannerPage({super.key, required this.userId});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> with SingleTickerProviderStateMixin {
  XFile? imageFile;
  Map<String, dynamic>? result;
  bool isLoading     = false;
  bool isSavingBulk  = false;

  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  final picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim =
        CurvedAnimation(parent: _animController, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image =
        await picker.pickImage(source: source, imageQuality: 80);
    if (image != null) {
      setState(() {
        imageFile = image;
        result    = null;
      });
      _animController.reset();
    }
  }

  Future<void> _analyzeFood() async {
    if (imageFile == null) return;
    setState(() => isLoading = true);
    try {
      final res =
          await ApiService.scanFood(imageFile!, 0.0, widget.userId);
      setState(() => result = res);
      _animController.forward();
    } catch (e) {
      _showSnack("Gagal menganalisis: $e", isError: true);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _saveAllToLog(List items) async {
    setState(() => isSavingBulk = true);
    try {
      String lastAdvice = "";
      for (var item in items) {
        final mealData = {
          "user_id":      widget.userId,
          "food_name":    item['food_name'],
          "weight_grams": item['estimated_weight_grams'],
          "calories":     item['nutrition_facts']['calories'],
          "carbs":        item['nutrition_facts']['carbohydrates'] ?? 0.0,
        };
        final res = await ApiService.logMeal(mealData);
        lastAdvice = res['smart_recommendation_next_meal'] ?? "Berhasil disimpan.";
      }
      _showSnack("Semua porsi berhasil disimpan. $lastAdvice", isLong: true);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnack("Gagal menyimpan jurnal", isError: true);
    } finally {
      if (mounted) setState(() => isSavingBulk = false);
    }
  }

  void _showSnack(String msg, {bool isError = false, bool isLong = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(fontSize: 13)),
        backgroundColor: isError ? AppColors.danger : const Color(0xFF2E7D32),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        duration: Duration(seconds: isLong ? 6 : 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
              decoration: const BoxDecoration(
                gradient: AppColors.heroBg,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "AI Calorie Scanner",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        "Foto makananmu, deteksi otomatis",
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                const Text(
                  "FOTO MAKANAN",
                  style: TextStyle(
                    color: AppColors.textSub,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                  ),
                ),
                const SizedBox(height: 12),

                _buildImageArea(),
                const SizedBox(height: 16),

                if (imageFile == null)
                  Row(
                    children: [
                      Expanded(
                        child: PickerButton(
                          icon: Icons.camera_alt_rounded,
                          label: "Kamera",
                          onTap: () => _pickImage(ImageSource.camera),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: PickerButton(
                          icon: Icons.photo_library_rounded,
                          label: "Galeri",
                          onTap: () => _pickImage(ImageSource.gallery),
                        ),
                      ),
                    ],
                  ),

                if (imageFile != null && result == null)
                  TextButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.refresh_rounded, size: 16, color: AppColors.textSub),
                    label: const Text("Ganti foto",
                        style: TextStyle(color: AppColors.textSub, fontSize: 13)),
                  ),

                const SizedBox(height: 8),

                if (imageFile != null && result == null)
                  PrimaryButton(
                    label: "Mulai Analisis",
                    onTap: _analyzeFood,
                    isLoading: isLoading,
                  ),

                if (result != null)
                  FadeTransition(opacity: _fadeAnim, child: _buildResultList()),
              ]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageArea() {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      height: 240,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: imageFile != null ? AppColors.accent.withOpacity(0.5) : AppColors.border,
          width: imageFile != null ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: imageFile == null
          ? Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.add_a_photo_rounded, color: AppColors.accent, size: 32),
                ),
                const SizedBox(height: 14),
                const Text(
                  "Tap untuk ambil foto",
                  style: TextStyle(color: AppColors.textSub, fontSize: 13),
                ),
              ],
            )
          : ClipRRect(
              borderRadius: BorderRadius.circular(22),
              child: kIsWeb
                  ? Image.network(imageFile!.path, fit: BoxFit.cover, width: double.infinity)
                  : Image.file(File(imageFile!.path), fit: BoxFit.cover, width: double.infinity),
            ),
    );
  }

  Widget _buildResultList() {
    final List items = result!['detailed_data'] ?? [];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),

        Row(
          children: [
            const Text(
              "Hasil Deteksi",
              style: TextStyle(
                color: AppColors.textPri,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                "${items.length} item",
                style: const TextStyle(
                  color: AppColors.accent,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        ...items.map((item) => _buildFoodItemCard(item as Map<String, dynamic>)),

        const SizedBox(height: 8),

        if (items.isNotEmpty)
          GestureDetector(
            onTap: isSavingBulk ? null : () => _saveAllToLog(items),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.accent.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Center(
                child: isSavingBulk
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.save_rounded, color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            "Simpan Semua ke Jurnal",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFoodItemCard(Map<String, dynamic> item) {
    // ---------------------------------------------------------
    // PERUBAHAN LOGIKA PENCOCOKAN STRING CSV DI SINI
    // ---------------------------------------------------------
    final String medicalStatus = item['medical_status']?.toString() ?? "Aman";
    final String statusLower = medicalStatus.toLowerCase();

    bool isSafe = true;
    Color statusColor = AppColors.success;
    Color statusBg = const Color(0xFFE8F5E9);
    String shortBadge = "Aman";

    // Cek isi kalimat dari CSV
    if (statusLower.contains("hati-hati") || statusLower.contains("batasi")) {
      isSafe = false;
      statusColor = AppColors.warning;
      statusBg = const Color(0xFFFFF3E0);
      shortBadge = "Batasi Porsi";
    } else if (statusLower.contains("bahaya")) {
      isSafe = false;
      statusColor = AppColors.danger;
      statusBg = AppColors.danger.withOpacity(0.1);
      shortBadge = "Tinggi Kalori";
    }

    final nutrition = item['nutrition_facts'] as Map<String, dynamic>;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isSafe ? AppColors.border : statusColor.withOpacity(0.3),
        ),
        boxShadow: [
          BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          // ── Card Header ──────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item['food_name'],
                    style: const TextStyle(
                      color: AppColors.textPri,
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSafe ? Icons.check_circle_rounded : Icons.local_fire_department_rounded,
                        color: statusColor,
                        size: 13,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        shortBadge, // <-- Sekarang mengikuti badge dinamis
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Nutrition Row ────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _nutriStat("Kalori", "${nutrition['calories']}", "kcal"),
                _divider(),
                _nutriStat("Karbo", "${nutrition['carbohydrates'] ?? 0}", "gram"),
                _divider(),
                _nutriStat("Porsi", "${item['estimated_weight_grams']}", "gram"),
              ],
            ),
          ),

          // ── Advice Box ───────────────────────────
          _buildRecommendationBox(item, isSafe, statusColor, statusBg),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // Parameter fungsi ini ditambah sedikit untuk mengirim style warna
  Widget _buildRecommendationBox(Map<String, dynamic> item, bool isSafe, Color color, Color bgColor) {
    // ---------------------------------------------------------
    // MENGGUNAKAN TEKS LANGSUNG DARI CSV (MEDICAL STATUS)
    // ---------------------------------------------------------
    final String advice = item['medical_status'] ?? "Tidak ada catatan klinis.";

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 10, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            isSafe ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
            color: color,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Saran Medis AI",
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  advice, // <-- Pesan dari backend ditampilkan apa adanya
                  style: const TextStyle(
                    color: AppColors.textPri,
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutriStat(String label, String val, String unit) {
    return Expanded(
      child: Column(
        children: [
          Text(
            val,
            style: const TextStyle(
              color: AppColors.textPri,
              fontWeight: FontWeight.w800,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 2),
          Text(unit, style: const TextStyle(color: AppColors.textSub, fontSize: 10)),
          const SizedBox(height: 2),
          Text(label,
              style: const TextStyle(
                  color: AppColors.textSub, fontSize: 11, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _divider() =>
      Container(width: 1, height: 36, color: AppColors.border);
}