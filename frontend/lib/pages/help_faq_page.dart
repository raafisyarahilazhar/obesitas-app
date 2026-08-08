import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class HelpFaqPage extends StatelessWidget {
  const HelpFaqPage({super.key});

  final List<Map<String, String>> _faqs = const [
    {
      'question': 'Bagaimana cara kerja scan makanan?',
      'answer':
          'FoodScan AI menggunakan model AI vision untuk mengenali jenis makanan dari foto yang kamu ambil, kemudian mengestimasi porsi dan kandungan gizinya secara otomatis.'
    },
    {
      'question': 'Bagaimana target kalori harian dihitung?',
      'answer':
          'Target kalori dihitung berdasarkan tinggi badan, berat badan, usia, dan kategori BMI kamu. Sistem akan menyesuaikan batas kalori agar mendukung program kesehatanmu.'
    },
    {
      'question': 'Apakah saya bisa mengubah data berat/tinggi badan?',
      'answer':
          'Bisa. Kamu dapat memperbarui data fisik kapan saja melalui menu "Edit Profil". Target kalori dan BMI akan dihitung ulang secara otomatis.'
    },
    {
      'question': 'Bagaimana jika makanan tidak terdeteksi dengan pas?',
      'answer':
          'Kamu bisa mengambil ulang foto dengan pencahayaan yang lebih terang, atau pastikan seluruh piring/makanan terlihat jelas di dalam bingkai kamera.'
    },
    {
      'question': 'Apakah data profil saya aman?',
      'answer':
          'Data pribadi dan riwayat kesehatanmu tersimpan secara aman dan hanya digunakan untuk memberikan rekomendasi nutrisi secara personal.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        backgroundColor: AppColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.textPri,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Bantuan & FAQ',
          style: TextStyle(
            color: AppColors.textPri,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header Banner ───────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.heroBg,
                  borderRadius: BorderRadius.circular(22),
                ),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.support_agent_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                    SizedBox(height: 12),
                    Text(
                      'Pusat Bantuan',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Temukan jawaban atas pertanyaan yang sering diajukan mengenai penggunaan FoodScan AI.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              const Text(
                'PERTANYAAN POPULER',
                style: TextStyle(
                  color: AppColors.textSub,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.3,
                ),
              ),

              const SizedBox(height: 12),

              // ── Item FAQ Accordion ─────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: AppColors.card,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _faqs.length,
                  separatorBuilder: (_, __) => const Divider(
                    height: 1,
                    indent: 16,
                    endIndent: 16,
                    color: AppColors.border,
                  ),
                  itemBuilder: (context, index) {
                    final item = _faqs[index];
                    return Theme(
                      data: Theme.of(context).copyWith(
                        dividerColor: Colors.transparent,
                      ),
                      child: ExpansionTile(
                        tilePadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 4,
                        ),
                        iconColor: AppColors.accent,
                        collapsedIconColor: AppColors.textSub,
                        title: Text(
                          item['question']!,
                          style: const TextStyle(
                            color: AppColors.textPri,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                item['answer']!,
                                style: const TextStyle(
                                  color: AppColors.textSub,
                                  fontSize: 13,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 28),

              // ── Contact Info Card ──────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColors.accent.withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.accent.withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.mark_email_read_outlined,
                        color: AppColors.accent,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Masih butuh bantuan?',
                            style: TextStyle(
                              color: AppColors.textPri,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'Hubungi tim dukungan di support@foodscan.ai',
                            style: TextStyle(
                              color: AppColors.textSub,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}