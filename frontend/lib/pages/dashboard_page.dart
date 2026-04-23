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

  @override
  Widget build(BuildContext context) {
    if (data == null) {
      return const Scaffold(
        backgroundColor: AppColors.bg,
        body: Center(child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2)),
      );
    }

    // PENCEGAHAN ERROR: Pastikan variabel tidak null
    final user    = data!['user'] ?? {};
    final summary = data!['today_summary'] ?? {};

    return Scaffold(
      backgroundColor: AppColors.bg,
      body: CustomScrollView(
        slivers: [
          // ── Hero Header ──────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 32),
              decoration: const BoxDecoration(
                gradient: AppColors.heroBg,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Halo, ${user['name'] ?? 'Pengguna'} 👋", // Fallback jika nama kosong
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                user['status'] ?? 'Menunggu Data', // Fallback status
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.notifications_outlined, color: Colors.white, size: 22),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Quick Calorie Summary ────────────
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white.withOpacity(0.2)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text("Kalori Hari Ini",
                                  style: TextStyle(color: Colors.white70, fontSize: 12)),
                              const SizedBox(height: 4),
                              Text(
                                "${summary['calories_consumed'] ?? 0}", // Fallback 0
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  height: 1,
                                ),
                              ),
                              Text(
                                "dari ${summary['calories_target'] ?? 0} kcal",
                                style: const TextStyle(color: Colors.white60, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        _CircleProgress(
                          // PENCEGAHAN ERROR: Safe casting (int/double) & Mencegah NaN
                          consumed: (summary['calories_consumed'] as num?)?.toDouble() ?? 0.0,
                          target: (summary['calories_target'] as num?)?.toDouble() ?? 1.0,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ── Section Label ────────────────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 28, 24, 14),
              child: Text(
                "RINGKASAN HARI INI",
                style: TextStyle(
                  color: AppColors.textSub,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),

          // ── Stat Cards ───────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                _StatCard(
                  label: "Kalori Dikonsumsi",
                  consumed: summary['calories_consumed'] ?? 0,
                  target: summary['calories_target'] ?? 1, // Cegah bagi 0
                  unit: "kcal",
                  icon: Icons.local_fire_department_rounded,
                  color: AppColors.accent,
                ),
                const SizedBox(height: 14),
                _StatCard(
                  label: "Karbo / Gula",
                  consumed: summary['sugar_consumed'] ?? 0,
                  target: summary['sugar_target'] ?? 150,
                  unit: "gram",
                  icon: Icons.water_drop_rounded,
                  color: const Color(0xFFF57C00),
                ),
              ]),
            ),
          ),

          // ── Section Label (Meal Plan) ────────────────
          const SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 28, 24, 14),
              child: Text(
                "REKOMENDASI JADWAL MAKAN",
                style: TextStyle(
                  color: AppColors.textSub,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ),
          ),

          // ── Meal Plan ────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            sliver: _buildMealPlanSection(),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

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
        (context, index) {
          final plan = mealPlan![index] ?? {}; // Pencegahan list item null
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.border),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 12,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.accentLight,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.restaurant_rounded,
                              color: AppColors.accent, size: 16),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          plan['waktu'] ?? '-',
                          style: const TextStyle(
                            color: AppColors.textPri,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: AppColors.accentLight,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        plan['jam'] ?? '-',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  "Target: ${plan['target_kalori'] ?? 0} kcal",
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  plan['menu_rekomendasi'] ?? '',
                  style: const TextStyle(
                    color: AppColors.textPri,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "Fokus: ${plan['catatan_klinis'] ?? ''}",
                  style: const TextStyle(
                    color: AppColors.textSub,
                    fontSize: 12,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          );
        },
        childCount: mealPlan!.length,
      ),
    );
  }
}

// ── Circle Progress ────────────────────────────────────────────────────────────
class _CircleProgress extends StatelessWidget {
  final double consumed;
  final double target;
  const _CircleProgress({required this.consumed, required this.target});

  @override
  Widget build(BuildContext context) {
    // PENCEGAHAN ERROR: Pembagian dengan 0 
    final double safeTarget = target > 0 ? target : 1.0;
    final progress = (consumed / safeTarget).clamp(0.0, 1.0);
    final pct = (progress * 100).toInt();

    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: progress,
            strokeWidth: 6,
            backgroundColor: Colors.white.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            strokeCap: StrokeCap.round,
          ),
          Text(
            "$pct%",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Stat Card ──────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  final String label;
  final dynamic consumed; // Menggunakan dynamic, ditangani di dalam fungsi
  final dynamic target;
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
    // PENCEGAHAN ERROR: Casting num yang aman untuk tipe data API JSON
    final double consumedVal = (consumed is num) ? consumed.toDouble() : 0.0;
    final double targetVal   = (target is num && target > 0) ? target.toDouble() : 1.0;
    
    final double progress = (consumedVal / targetVal).clamp(0.0, 1.0);
    final bool isOver = consumedVal >= targetVal;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isOver ? AppColors.danger.withOpacity(0.3) : AppColors.border),
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
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 12),
              Text(
                label,
                style: const TextStyle(
                  color: AppColors.textPri,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (isOver)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.danger.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Melebihi batas",
                    style: TextStyle(
                      color: AppColors.danger,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                "$consumedVal", // Menggunakan nilai yang sudah aman
                style: TextStyle(
                  color: isOver ? AppColors.danger : color,
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
              const SizedBox(width: 4),
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(unit, style: const TextStyle(color: AppColors.textSub, fontSize: 12)),
              ),
              const Spacer(),
              Text(
                "dari $targetVal $unit",
                style: const TextStyle(color: AppColors.textSub, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: AppColors.bg,
              valueColor: AlwaysStoppedAnimation<Color>(isOver ? AppColors.danger : color),
            ),
          ),
        ],
      ),
    );
  }
}