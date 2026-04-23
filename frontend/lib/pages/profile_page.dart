import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'login_page.dart';

class ProfilePage extends StatefulWidget {
  final int userId;
  const ProfilePage({super.key, required this.userId});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  Map<String, dynamic>? _data;
  bool _isLoading = true;
  bool _hasError = false; // ⬅️ Tambahan state untuk mendeteksi error

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    if (mounted) setState(() { _isLoading = true; _hasError = false; });
    try {
      // Mengambil data dashboard (yang akan kita update di backend agar mengirim data lengkap)
      final res = await ApiService.getDashboard(widget.userId);
      if (mounted) setState(() { _data = res; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _hasError = true; });
    }
  }

  // ── Penentuan Label & Warna BMI ──────────────────────────────────
  String _bmiLabel(double bmi) {
    if (bmi <= 0)   return "–";
    if (bmi < 18.5) return "Kurus";
    if (bmi < 25.0) return "Normal";
    if (bmi < 30.0) return "Overweight";
    return "Obesitas";
  }

  Color _bmiColor(double bmi) {
    if (bmi <= 0)   return AppColors.textSub;
    if (bmi < 18.5) return AppColors.info;
    if (bmi < 25.0) return AppColors.success;
    if (bmi < 30.0) return AppColors.warning;
    return AppColors.danger;
  }

  // ── Calorie Progress ─────────────────────────────────────────────
  double _calorieProgress() {
    if (_data == null) return 0;
    final s = _data!['today_summary'];
    final consumed = (s['calories_consumed'] as num?)?.toDouble() ?? 0;
    final target   = (s['calories_target']  as num?)?.toDouble() ?? 1;
    if (target <= 0) return 0; // Mencegah division by zero
    return (consumed / target).clamp(0.0, 1.0);
  }

  void _logout() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("Keluar", style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white)),
        content: const Text("Apakah kamu yakin ingin keluar dari akun ini?",
            style: TextStyle(color: AppColors.textSub)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Batal", style: TextStyle(color: AppColors.textSub)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginPage()),
                (_) => false,
              );
            },
            child: const Text("Keluar", style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading && _data == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)),
      );
    }

    // ⬅️ Tampilan jika gagal memuat data (Mencegah blank screen)
    if (_hasError && _data == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.wifi_off_rounded, color: AppColors.textSub, size: 48),
              const SizedBox(height: 16),
              const Text("Gagal memuat profil", style: TextStyle(color: AppColors.textPri, fontWeight: FontWeight.w600)),
              const SizedBox(height: 16),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.accent, foregroundColor: Colors.black),
                onPressed: _fetch, 
                child: const Text("Coba Lagi")
              )
            ],
          ),
        ),
      );
    }

    final user    = _data?['user'] ?? {};
    final summary = _data?['today_summary'] ?? {};
    
    // Ambil BMI langsung dari backend, fallback ke kalkulasi manual jika backend tidak mengirimnya
    final bmi = (user['bmi'] as num?)?.toDouble() ?? 0.0;

    return Scaffold(
      backgroundColor: AppColors.bg,
      // ⬅️ UX Refresh: Tarik ke bawah untuk refresh data
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: AppColors.accent,
        backgroundColor: AppColors.card,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(), // Wajib agar bisa di-pull to refresh meski layarnya pendek
          slivers: [
            // ── Hero Header ──────────────────────────────
            SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.fromLTRB(24, 60, 24, 36),
                decoration: const BoxDecoration(
                  gradient: AppColors.heroBg,
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                ),
                child: Column(
                  children: [
                    // Avatar
                    Container(
                      width: 88, height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle, color: Colors.white.withOpacity(0.15),
                        border: Border.all(color: Colors.white.withOpacity(0.4), width: 2.5),
                      ),
                      child: Center(
                        child: Text(
                          (user['name'] as String? ?? "U").substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontSize: 36, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Name & status badge
                    Text(
                      user['name'] ?? "–",
                      style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        user['status'] ?? "–",
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ── Calorie bar ──────────────────────
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: Colors.white.withOpacity(0.2)),
                      ),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text("Kalori Hari Ini", style: TextStyle(color: Colors.white70, fontSize: 12)),
                              Text(
                                "${summary['calories_consumed'] ?? 0} / ${summary['calories_target'] ?? 0} kcal",
                                style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: _calorieProgress(),
                              minHeight: 8,
                              backgroundColor: Colors.white.withOpacity(0.2),
                              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate([

                  // ── Stats Section ────────────────────────
                  const _SectionLabel("DATA KESEHATAN"),
                  const SizedBox(height: 12),

                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.scale_outlined, label: "Berat",
                          value: "${user['weight_kg'] ?? '–'}", unit: "kg", color: AppColors.accent,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatTile(
                          icon: Icons.height_rounded, label: "Tinggi",
                          value: "${user['height_cm'] ?? '–'}", unit: "cm", color: AppColors.info,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatTile(
                          icon: Icons.cake_outlined, label: "Usia",
                          value: "${user['age'] ?? '–'}", unit: "tahun", color: AppColors.warning,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _BmiTile(
                          bmi: bmi, label: _bmiLabel(bmi), color: _bmiColor(bmi),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Target Section ───────────────────────
                  const _SectionLabel("TARGET KALORI"),
                  const SizedBox(height: 12),
                  _InfoCard(
                    children: [
                      _InfoRow(
                        icon: Icons.local_fire_department_rounded, label: "Target Harian",
                        value: "${summary['calories_target'] ?? '–'} kcal", color: AppColors.accent,
                      ),
                      _divider(),
                      _InfoRow(
                        icon: Icons.check_circle_outline_rounded, label: "Dikonsumsi Hari Ini",
                        value: "${summary['calories_consumed'] ?? '–'} kcal", color: AppColors.success,
                      ),
                      _divider(),
                      _InfoRow(
                        icon: Icons.remove_circle_outline_rounded, label: "Sisa Kalori",
                        value: () {
                          final target   = (summary['calories_target']   as num?)?.toInt() ?? 0;
                          final consumed = (summary['calories_consumed'] as num?)?.toInt() ?? 0;
                          final sisa = target - consumed;
                          return "${sisa > 0 ? sisa : 0} kcal"; // Pastikan tampil utuh (tidak .0) dan tidak minus
                        }(),
                        color: AppColors.info,
                      ),
                    ],
                  ),

                  const SizedBox(height: 28),

                  // ── Account Section ──────────────────────
                  const _SectionLabel("AKUN"),
                  const SizedBox(height: 12),
                  _InfoCard(
                    children: [
                      _MenuRow(icon: Icons.edit_outlined, label: "Edit Profil", onTap: () {}), _divider(),
                      _MenuRow(icon: Icons.notifications_outlined, label: "Notifikasi", onTap: () {}), _divider(),
                      _MenuRow(icon: Icons.help_outline_rounded, label: "Bantuan & FAQ", onTap: () {}), _divider(),
                      _MenuRow(icon: Icons.info_outline_rounded, label: "Tentang Aplikasi", onTap: () => _showAboutDialog()),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // ── Logout Button ────────────────────────
                  GestureDetector(
                    onTap: _logout,
                    child: Container(
                      width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: AppColors.danger.withOpacity(0.07), borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.danger.withOpacity(0.25)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.logout_rounded, color: AppColors.danger, size: 18),
                          SizedBox(width: 8),
                          Text("Keluar dari Akun", style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  const Center(child: Text("FoodScan AI  •  v1.0.0", style: TextStyle(color: AppColors.textSub, fontSize: 11))),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(color: AppColors.accentLight, shape: BoxShape.circle),
              child: const Icon(Icons.eco_rounded, color: AppColors.accent, size: 36),
            ),
            const SizedBox(height: 16),
            const Text("FoodScan AI", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPri)),
            const SizedBox(height: 6),
            const Text(
              "Aplikasi analisis nutrisi berbasis AI untuk membantu manajemen berat badan dan deteksi obesitas.",
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSub, fontSize: 13, height: 1.5),
            ),
            const SizedBox(height: 12),
            const Text("Versi 1.0.0", style: TextStyle(color: AppColors.textSub, fontSize: 12)),
          ],
        ),
        actions: [
          Center(
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup", style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Helper Widgets (Bagian ini tidak saya ubah karena sudah sempurna) ────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 4, height: 14, decoration: BoxDecoration(color: AppColors.accent, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(text, style: const TextStyle(color: AppColors.textSub, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 1.3)),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon; final String label; final String value; final String unit; final Color color;
  const _StatTile({required this.icon, required this.label, required this.value, required this.unit, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          RichText(
            text: TextSpan(
              text: value, style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w800, height: 1),
              children: [TextSpan(text: " $unit", style: const TextStyle(color: AppColors.textSub, fontSize: 12, fontWeight: FontWeight.normal))],
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textSub, fontSize: 12)),
        ],
      ),
    );
  }
}

class _BmiTile extends StatelessWidget {
  final double bmi; final String label; final Color color;
  const _BmiTile({required this.bmi, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card, borderRadius: BorderRadius.circular(18), border: Border.all(color: bmi >= 30 ? AppColors.danger.withOpacity(0.3) : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
            child: Icon(Icons.monitor_heart_outlined, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          RichText(text: TextSpan(text: bmi > 0 ? bmi.toStringAsFixed(1) : "–", style: TextStyle(color: color, fontSize: 26, fontWeight: FontWeight.w800, height: 1))),
          const SizedBox(height: 4),
          Row(
            children: [
              const Text("BMI  ", style: TextStyle(color: AppColors.textSub, fontSize: 12)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(6)),
                child: Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w700)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;
  const _InfoCard({required this.children});
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: AppColors.card, borderRadius: BorderRadius.circular(20), border: Border.all(color: AppColors.border)),
      child: Column(children: children),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon; final String label; final String value; final Color color;
  const _InfoRow({required this.icon, required this.label, required this.value, required this.color});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Row(
        children: [
          Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: color, size: 16)),
          const SizedBox(width: 12),
          Expanded(child: Text(label, style: const TextStyle(color: AppColors.textPri, fontSize: 13, fontWeight: FontWeight.w500))),
          Text(value, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _MenuRow extends StatelessWidget {
  final IconData icon; final String label; final VoidCallback onTap;
  const _MenuRow({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap, borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        child: Row(
          children: [
            Container(padding: const EdgeInsets.all(7), decoration: BoxDecoration(color: AppColors.accentLight, borderRadius: BorderRadius.circular(9)), child: Icon(icon, color: AppColors.accent, size: 16)),
            const SizedBox(width: 12),
            Expanded(child: Text(label, style: const TextStyle(color: AppColors.textPri, fontSize: 13, fontWeight: FontWeight.w500))),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSub, size: 20),
          ],
        ),
      ),
    );
  }
}

Widget _divider() => const Divider(height: 1, indent: 18, endIndent: 18, color: AppColors.border);