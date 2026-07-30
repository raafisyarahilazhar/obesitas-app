import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';
import 'onboarding_page.dart';

class DashboardPage extends StatefulWidget {
  final int userId;
  const DashboardPage({super.key, required this.userId});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  Map<String, dynamic>? data;
  List<dynamic>? mealPlan;
  bool _isLoadingPlan = false;
  bool _bmiExpanded = false;

  @override
  void initState() {
    super.initState();
    _fetch();
    _fetchMealPlan();
  }

  void _fetch() async {
    try {
      final res = await ApiService.getDashboard(widget.userId);
      if (mounted) setState(() => data = res);
    } catch (e) {
      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => OnboardingPage(userId: widget.userId)),
        );
      }
    }
  }

  void _fetchMealPlan() async {
    setState(() => _isLoadingPlan = true);
    try {
      final res = await ApiService.getMealSchedule(widget.userId);
      if (mounted) {
        setState(() {
          mealPlan = res['meal_plan'];
          _isLoadingPlan = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoadingPlan = false);
    }
  }

  double _num(dynamic v, [double fallback = 0]) =>
      (v is num) ? v.toDouble() : fallback;

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)),
      );
    }

    final user = data!['user'] ?? {};
    final summary = data!['today_summary'] ?? {};

    final double kaloriTarget = _num(summary['calories_target'], 0);
    final double kaloriMasuk = _num(summary['calories_consumed']);

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: () async {
          _fetch();
          _fetchMealPlan();
        },
        color: AppColors.accent,
        backgroundColor: AppColors.card,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            // ── Header: sapaan + notifikasi ──────────────
            SliverToBoxAdapter(child: _buildHeader(user)),

            // ── Chip Status BMI ──────────────────────────
            SliverToBoxAdapter(child: _buildBmiChip(user)),

            // ── Kartu Kalori Hari Ini ────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                child: _buildCalorieCard(kaloriMasuk, kaloriTarget),
              ),
            ),

            // ── Ringkasan Hari Ini ───────────────────────
            const SliverToBoxAdapter(child: _SectionTitle("Ringkasan Hari Ini")),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 14,
                  crossAxisSpacing: 14,
                  mainAxisExtent: 162,
                ),
                delegate: SliverChildListDelegate([
                  _StatCard(
                    label: "Kalori Dikonsumsi",
                    consumed: kaloriMasuk,
                    target: kaloriTarget,
                    unit: "kcal",
                    icon: Icons.local_fire_department_rounded,
                    color: AppColors.accent,
                  ),
                  _StatCard(
                    label: "Karbohidrat / Gula",
                    consumed: _num(summary['carbs_consumed']),
                    target: _num(summary['carbs_target']),
                    unit: "g",
                    icon: Icons.water_drop_rounded,
                    color: AppColors.warning,
                  ),
                  _StatCard(
                    label: "Protein",
                    consumed: _num(summary['protein_consumed']),
                    target: _num(summary['protein_target']),
                    unit: "g",
                    icon: Icons.egg_alt_outlined,
                    color: AppColors.info,
                  ),
                  _StatCard(
                    label: "Lemak",
                    consumed: _num(summary['fat_consumed']),
                    target: _num(summary['fat_target']),
                    unit: "g",
                    icon: Icons.opacity_rounded,
                    color: AppColors.success,
                  ),
                ]),
              ),
            ),

            // ── Rekomendasi Jadwal Makan ─────────────────
            const SliverToBoxAdapter(child: _SectionTitle("Rekomendasi Jadwal Makan")),

            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: _buildMealPlanSection(),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────
  Widget _buildHeader(Map user) {
    final String nama = (user['name'] ?? 'Pengguna').toString();
    final String inisial = nama.trim().isEmpty ? "?" : nama.trim()[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 28),
      decoration: const BoxDecoration(
        gradient: AppColors.heroBg,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(36),
          bottomRight: Radius.circular(36),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Avatar inisial
          Container(
            width: 46,
            height: 46,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.5),
            ),
            child: Text(
              inisial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Halo, $nama",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Tetap semangat capai target kalori harianmu!",
                  style: TextStyle(color: Colors.white70, fontSize: 12, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),

          // Tombol notifikasi
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.notifications_outlined,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(height: 4),
              const Text(
                "Notifikasi",
                style: TextStyle(color: Colors.white70, fontSize: 9),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Chip Status BMI (bisa dibuka) ───────────────────────────────
  Widget _buildBmiChip(Map user) {
    final String status = (user['status'] ?? 'Menunggu Data').toString();

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => setState(() => _bmiExpanded = !_bmiExpanded),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border, width: 1.5),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Status BMI",
                    style: TextStyle(
                      color: AppColors.textSub,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    status,
                    style: const TextStyle(
                      color: AppColors.textPri,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 6),
                  AnimatedRotation(
                    turns: _bmiExpanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: AppColors.textSub, size: 20),
                  ),
                ],
              ),
            ),
          ),

          // Detail BMI muncul saat chip ditekan
          if (_bmiExpanded)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _MiniStat(label: "BMI", value: "${user['bmi'] ?? '-'}"),
                  _MiniStat(label: "Tinggi", value: "${user['height_cm'] ?? '-'} cm"),
                  _MiniStat(label: "Berat", value: "${user['weight_kg'] ?? '-'} kg"),
                  _MiniStat(label: "Umur", value: "${user['age'] ?? '-'} th"),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Kartu Kalori Hari Ini ───────────────────────────────────────
  Widget _buildCalorieCard(double masuk, double target) {
    final double aman = target > 0 ? target : 1;
    final double progress = (masuk / aman).clamp(0.0, 1.0);
    final int persen = (progress * 100).round();
    final bool lebih = target > 0 && masuk > target;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 16, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Kalori Hari Ini",
                  style: TextStyle(
                    color: AppColors.textPri,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        _fmt(masuk),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: lebih ? AppColors.danger : AppColors.textPri,
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 5),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 3),
                      child: Text("kcal",
                          style: TextStyle(color: AppColors.textSub, fontSize: 13)),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "dari ${_fmt(target)} kcal",
                  style: const TextStyle(color: AppColors.textSub, fontSize: 13),
                ),
                const SizedBox(height: 2),
                const Text(
                  "Target harian",
                  style: TextStyle(color: AppColors.textSub, fontSize: 11),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          _CircleProgress(progress: progress, percent: persen, isOver: lebih),
        ],
      ),
    );
  }

  // ── Jadwal makan ────────────────────────────────────────────────
  Widget _buildMealPlanSection() {
    if (_isLoadingPlan) {
      return const SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
          ),
        ),
      );
    }

    if (mealPlan == null || mealPlan!.isEmpty) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Text(
            "Jadwal makan tidak tersedia.",
            style: TextStyle(color: AppColors.textSub, fontSize: 13),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) => _MealCard(plan: mealPlan![index] ?? {}),
        childCount: mealPlan!.length,
      ),
    );
  }
}

/// Angka tanpa ".0" yang mengganggu (2300.0 -> 2300).
String _fmt(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

// ── Judul Section ──────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 26, 24, 14),
      child: Text(
        text,
        style: const TextStyle(
          color: AppColors.textPri,
          fontSize: 16,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.2,
        ),
      ),
    );
  }
}

// ── Statistik kecil di panel BMI ───────────────────────────────────────────────
class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: AppColors.textPri,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(color: AppColors.textSub, fontSize: 11)),
      ],
    );
  }
}

// ── Cincin progres kalori ──────────────────────────────────────────────────────
class _CircleProgress extends StatelessWidget {
  final double progress;
  final int percent;
  final bool isOver;

  const _CircleProgress({
    required this.progress,
    required this.percent,
    required this.isOver,
  });

  @override
  Widget build(BuildContext context) {
    final Color warna = isOver ? AppColors.danger : AppColors.accent;

    return SizedBox(
      width: 104,
      height: 104,
      child: Stack(
        alignment: Alignment.center,
        children: [
          SizedBox(
            width: 104,
            height: 104,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => CircularProgressIndicator(
                value: value,
                strokeWidth: 10,
                backgroundColor: AppColors.bg,
                valueColor: AlwaysStoppedAnimation<Color>(warna),
                strokeCap: StrokeCap.round,
              ),
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "$percent%",
                style: TextStyle(
                  color: warna,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  height: 1.1,
                ),
              ),
              const Text(
                "dari target",
                style: TextStyle(color: AppColors.textSub, fontSize: 10),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Kartu ringkasan gizi (grid 2 kolom) ────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final double consumed;
  final double target;
  final String unit;
  final IconData icon;
  final Color color;

  const _StatCard({
    required this.label,
    required this.consumed,
    required this.target,
    required this.unit,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double safeTarget = target > 0 ? target : 1;
    final double progress = (consumed / safeTarget).clamp(0.0, 1.0);
    final bool isOver = target > 0 && consumed > target;
    final Color warna = isOver ? AppColors.danger : color;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isOver ? AppColors.danger.withOpacity(0.35) : AppColors.border),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textSub,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),

          const Spacer(),

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Flexible(
                child: Text(
                  _fmt(consumed),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: warna,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 2),
                child: Text(unit,
                    style: const TextStyle(color: AppColors.textSub, fontSize: 11)),
              ),
            ],
          ),

          const SizedBox(height: 10),

          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: const Duration(milliseconds: 600),
              curve: Curves.easeOutCubic,
              builder: (_, value, __) => LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: AppColors.bg,
                valueColor: AlwaysStoppedAnimation<Color>(warna),
              ),
            ),
          ),

          const SizedBox(height: 6),

          Align(
            alignment: Alignment.centerRight,
            child: Text(
              "${_fmt(consumed)} / ${_fmt(target)} $unit",
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSub, fontSize: 10),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Kartu jadwal makan ─────────────────────────────────────────────────────────
class _MealCard extends StatelessWidget {
  final Map plan;
  const _MealCard({required this.plan});

  static IconData _iconFor(String waktu) {
    final w = waktu.toLowerCase();
    if (w.contains("sarapan")) return Icons.free_breakfast_rounded;
    if (w.contains("siang")) return Icons.lunch_dining_rounded;
    if (w.contains("selingan")) return Icons.cookie_rounded;
    if (w.contains("malam")) return Icons.dinner_dining_rounded;
    return Icons.restaurant_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final String waktu = (plan['waktu'] ?? '-').toString();

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(_iconFor(waktu), color: AppColors.accent, size: 16),
              ),
              const SizedBox(width: 10),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      waktu,
                      style: const TextStyle(
                        color: AppColors.textPri,
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      "Target: ${plan['target_kalori'] ?? 0} kcal",
                      style: const TextStyle(
                        color: AppColors.textSub,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    Text(
                      "Rekomendasi: ${plan['menu_rekomendasi'] ?? '-'}",
                      style: const TextStyle(
                        color: AppColors.textSub,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                    Text(
                      "Fokus: ${plan['catatan_klinis'] ?? '-'}",
                      style: const TextStyle(
                        color: AppColors.textSub,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Badge jam makan
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule_rounded,
                        color: AppColors.accent, size: 12),
                    const SizedBox(width: 4),
                    Text(
                      (plan['jam'] ?? '-').toString(),
                      style: const TextStyle(
                        color: AppColors.accent,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
