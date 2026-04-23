import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../theme/app_colors.dart';

class HistoryPage extends StatefulWidget {
  final int userId;
  const HistoryPage({super.key, required this.userId});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> history = [];
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    try {
      final data = await ApiService.getDashboard(widget.userId);
      setState(() {
        history   = data['meals_history_today'] ?? [];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupHistoryByMealTime() {
    Map<String, List<Map<String, dynamic>>> grouped = {
      "Sarapan (06:00 - 10:30)": [],
      "Makan Siang (11:00 - 15:00)": [],
      "Selingan Sore (15:00 - 18:00)": [],
      "Makan Malam (18:00 - 22:00)": [],
      "Lainnya": [],
    };

    for (var item in history) {
      final timeString = item['time'] as String;
      try {
        final parts = timeString.split(':');
        final hour  = int.parse(parts[0]);
        if      (hour >= 6  && hour < 11) grouped["Sarapan (06:00 - 10:30)"]!.add(item);
        else if (hour >= 11 && hour < 15) grouped["Makan Siang (11:00 - 15:00)"]!.add(item);
        else if (hour >= 15 && hour < 18) grouped["Selingan Sore (15:00 - 18:00)"]!.add(item);
        else if (hour >= 18 && hour < 22) grouped["Makan Malam (18:00 - 22:00)"]!.add(item);
        else                              grouped["Lainnya"]!.add(item);
      } catch (_) {
        grouped["Lainnya"]!.add(item);
      }
    }

    grouped.removeWhere((key, value) => value.isEmpty);
    return grouped;
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
              padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
              decoration: const BoxDecoration(
                gradient: AppColors.heroBg,
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(36),
                  bottomRight: Radius.circular(36),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Riwayat Makan",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "Semua catatan makanan hari ini",
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  if (!isLoading && history.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "${history.length} item",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Body ─────────────────────────────────────
          if (isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: AppColors.accent, strokeWidth: 2),
              ),
            )
          else if (history.isEmpty)
            SliverFillRemaining(child: _buildEmptyState())
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 100),
              sliver: SliverList(
                delegate: SliverChildListDelegate(_buildGroupedItems()),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history_toggle_off_rounded, size: 44, color: AppColors.accent),
          ),
          const SizedBox(height: 20),
          const Text(
            "Belum ada riwayat hari ini",
            style: TextStyle(color: AppColors.textPri, fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          const Text(
            "Scan makananmu untuk mulai mencatat",
            style: TextStyle(color: AppColors.textSub, fontSize: 13),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildGroupedItems() {
    final groupedData = _groupHistoryByMealTime();
    List<Widget> items = [];

    groupedData.forEach((categoryName, entries) {
      // ── Group Header ────────────────────────────
      items.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 20, 0, 12),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 16,
                decoration: BoxDecoration(
                  color: AppColors.accent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                categoryName.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textSub,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ),
      );

      int totalCaloriesPerSession = 0;
      for (var item in entries) {
        items.add(_buildHistoryCard(item));
        totalCaloriesPerSession += (int.tryParse("${item['calories']}") ?? 0);
      }

      items.add(
        Padding(
          padding: const EdgeInsets.only(bottom: 8, top: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.accentLight,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "Total sesi: $totalCaloriesPerSession kcal",
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });

    return items;
  }

  Widget _buildHistoryCard(Map<String, dynamic> item) {
    final int calories   = int.tryParse("${item['calories']}") ?? 0;
    final bool isHigh    = calories > 400;
    final Color calColor = isHigh
        ? AppColors.danger
        : calories > 200
            ? AppColors.warning
            : AppColors.success;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isHigh ? AppColors.danger.withOpacity(0.3) : AppColors.border),
        boxShadow: [
          BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.restaurant_rounded, color: AppColors.accent, size: 22),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['food_name'].toString().toUpperCase(),
                        style: const TextStyle(
                          color: AppColors.textPri,
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          const Icon(Icons.access_time_rounded, size: 11, color: AppColors.textSub),
                          const SizedBox(width: 4),
                          Text(
                            "${item['time']}  •  ${item['weight_grams']}g",
                            style: const TextStyle(color: AppColors.textSub, fontSize: 12),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              children: [
                _nutriStat("Kalori", "${item['calories']}", "kcal", calColor),
                _divider(),
                _nutriStat("Karbo", "${item['carbs'] ?? 0}", "gram", AppColors.warning),
                _divider(),
                _nutriStat("Status", "Tercatat", "", AppColors.success),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _nutriStat(String label, String value, String unit, Color color) {
    return Expanded(
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              text: value,
              style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 16),
              children: unit.isNotEmpty
                  ? [
                      TextSpan(
                        text: " $unit",
                        style: const TextStyle(
                          color: AppColors.textSub,
                          fontSize: 10,
                          fontWeight: FontWeight.normal,
                        ),
                      )
                    ]
                  : null,
            ),
          ),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(color: AppColors.textSub, fontSize: 11)),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 32,
        color: AppColors.border,
      );
}