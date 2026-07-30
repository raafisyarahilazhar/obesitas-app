import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state_box.dart';
import 'scanner_page.dart';

class HistoryPage extends StatefulWidget {
  final int userId;
  const HistoryPage({super.key, required this.userId});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  List<dynamic> _items = [];
  Map<String, dynamic> _summary = {};
  bool _isLoading = true;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = _dateOnly(DateTime.now());
    _fetch();
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  bool get _isToday => _selectedDate == _dateOnly(DateTime.now());
  bool get _isYesterday =>
      _selectedDate ==
      _dateOnly(DateTime.now().subtract(const Duration(days: 1)));

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getMealHistory(widget.userId, date: _selectedDate);
      if (!mounted) return;
      setState(() {
        _items = res['items'] ?? [];
        _summary = Map<String, dynamic>.from(res['summary'] ?? {});
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _items = [];
        _isLoading = false;
      });
    }
  }

  void _pilihTanggal(DateTime date) {
    setState(() => _selectedDate = _dateOnly(date));
    _fetch();
  }

  Future<void> _bukaKalender() async {
    final DateTime? dipilih = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      helpText: "Pilih tanggal riwayat",
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.accent,
            onPrimary: Colors.white,
            surface: AppColors.card,
            onSurface: AppColors.textPri,
          ),
        ),
        child: child!,
      ),
    );
    if (dipilih != null) _pilihTanggal(dipilih);
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ScannerPage(userId: widget.userId)),
    ).then((_) => _fetch());
  }

  double _num(dynamic v) => (v is num) ? v.toDouble() : 0.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: AppColors.accent,
        backgroundColor: AppColors.card,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),

            // ── Ringkasan Harian ─────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
                child: _buildSummaryCard(),
              ),
            ),

            // ── Filter Tanggal ───────────────────────────
            const SliverToBoxAdapter(child: _SectionTitle("Filter Tanggal")),
            SliverToBoxAdapter(child: _buildDateFilter()),

            // ── Daftar riwayat ───────────────────────────
            SliverToBoxAdapter(child: _SectionTitle(_judulRiwayat())),

            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 50),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.accent, strokeWidth: 2),
                  ),
                ),
              )
            else if (_items.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                  child: EmptyStateBox(
                    icon: Icons.history_toggle_off_rounded,
                    title: _isToday
                        ? "Belum ada riwayat hari ini"
                        : "Tidak ada riwayat di tanggal ini",
                    message: _isToday
                        ? "Scan makananmu untuk mulai mencatat konsumsi harian."
                        : "Coba pilih tanggal lain, atau scan makanan untuk mencatat hari ini.",
                    buttonLabel: "Scan Makanan",
                    onButtonTap: _openScanner,
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) => _HistoryCard(
                        item: Map<String, dynamic>.from(_items[i])),
                    childCount: _items.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  String _judulRiwayat() {
    if (_isToday) return "Riwayat Hari Ini";
    if (_isYesterday) return "Riwayat Kemarin";
    return "Riwayat ${_tanggalPanjang(_selectedDate)}";
  }

  // ── Header ──────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 56, 24, 26),
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
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
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

          // Tombol Filter / Kalender
          GestureDetector(
            onTap: _bukaKalender,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.calendar_month_rounded,
                      color: Colors.white, size: 20),
                ),
                const SizedBox(height: 4),
                const Text(
                  "Filter / Kalender",
                  style: TextStyle(color: Colors.white70, fontSize: 9),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Kartu Ringkasan Harian ──────────────────────────────────────
  Widget _buildSummaryCard() {
    final double target = _num(_summary['calories_target']);
    final double masuk = _num(_summary['calories_consumed']);
    final double aman = target > 0 ? target : 1;
    final double progress = (masuk / aman).clamp(0.0, 1.0);
    final int persen = (progress * 100).round();
    final bool lebih = target > 0 && masuk > target;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 14, offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Ringkasan Harian",
            style: TextStyle(
              color: AppColors.textPri,
              fontSize: 14,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 16),

          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kiri: kalori
                Expanded(
                  flex: 5,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Kalori Hari Ini",
                          style: TextStyle(color: AppColors.textSub, fontSize: 11)),
                      const SizedBox(height: 8),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Flexible(
                            child: Text(
                              _ribuan(masuk),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: lebih ? AppColors.danger : AppColors.textPri,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                height: 1,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Padding(
                            padding: EdgeInsets.only(bottom: 2),
                            child: Text("kcal",
                                style: TextStyle(
                                    color: AppColors.textSub, fontSize: 12)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "dari ${_ribuan(target)} kcal",
                        style: const TextStyle(
                            color: AppColors.textSub, fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 7,
                          backgroundColor: AppColors.bg,
                          valueColor: AlwaysStoppedAnimation<Color>(
                              lebih ? AppColors.danger : AppColors.accent),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "$persen% target tercapai",
                        style: TextStyle(
                          color: lebih ? AppColors.danger : AppColors.textSub,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 16),
                const VerticalDivider(color: AppColors.border, width: 1),
                const SizedBox(width: 16),

                // Kanan: makronutrien
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Nutrisi Hari Ini",
                          style: TextStyle(color: AppColors.textSub, fontSize: 11)),
                      const SizedBox(height: 10),
                      _NutrientRow(
                        label: "Protein",
                        consumed: _num(_summary['protein_consumed']),
                        target: _num(_summary['protein_target']),
                        color: AppColors.info,
                      ),
                      const SizedBox(height: 10),
                      _NutrientRow(
                        label: "Karbohidrat / Gula",
                        consumed: _num(_summary['carbs_consumed']),
                        target: _num(_summary['carbs_target']),
                        color: AppColors.warning,
                      ),
                      const SizedBox(height: 10),
                      _NutrientRow(
                        label: "Lemak",
                        consumed: _num(_summary['fat_consumed']),
                        target: _num(_summary['fat_target']),
                        color: AppColors.success,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Filter tanggal ──────────────────────────────────────────────
  Widget _buildDateFilter() {
    final DateTime hariIni = _dateOnly(DateTime.now());
    final DateTime kemarin = hariIni.subtract(const Duration(days: 1));
    final bool tanggalLain = !_isToday && !_isYesterday;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          Expanded(
            child: _FilterChip(
              icon: Icons.today_rounded,
              label: "Hari Ini",
              isActive: _isToday,
              onTap: () => _pilihTanggal(hariIni),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _FilterChip(
              icon: Icons.history_rounded,
              label: "Kemarin",
              isActive: _isYesterday,
              onTap: () => _pilihTanggal(kemarin),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: _FilterChip(
              icon: Icons.calendar_month_rounded,
              label: tanggalLain ? _tanggalPendek(_selectedDate) : "Pilih Tanggal",
              isActive: tanggalLain,
              onTap: _bukaKalender,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Format angka & tanggal ─────────────────────────────────────────────────────
/// 1250 -> "1.250" (pemisah ribuan gaya Indonesia)
String _ribuan(double v) {
  final String angka =
      v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
  final List<String> bagian = angka.split('.');
  final String bulat = bagian[0];

  final buffer = StringBuffer();
  for (int i = 0; i < bulat.length; i++) {
    if (i > 0 && (bulat.length - i) % 3 == 0) buffer.write('.');
    buffer.write(bulat[i]);
  }
  return bagian.length > 1 ? "${buffer.toString()},${bagian[1]}" : buffer.toString();
}

String _angka(double v) =>
    v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);

const List<String> _namaBulan = [
  "Jan", "Feb", "Mar", "Apr", "Mei", "Jun",
  "Jul", "Agu", "Sep", "Okt", "Nov", "Des"
];

String _tanggalPendek(DateTime d) => "${d.day} ${_namaBulan[d.month - 1]}";
String _tanggalPanjang(DateTime d) =>
    "${d.day} ${_namaBulan[d.month - 1]} ${d.year}";

// ── Judul section ──────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
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

// ── Baris makronutrien di kartu ringkasan ──────────────────────────────────────
class _NutrientRow extends StatelessWidget {
  final String label;
  final double consumed;
  final double target;
  final Color color;

  const _NutrientRow({
    required this.label,
    required this.consumed,
    required this.target,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final double aman = target > 0 ? target : 1;
    final double progress = (consumed / aman).clamp(0.0, 1.0);
    final int persen = (progress * 100).round();
    final bool lebih = target > 0 && consumed > target;
    final Color warna = lebih ? AppColors.danger : color;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColors.textPri,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text(
              "${_angka(consumed)} g",
              style: TextStyle(
                color: warna,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(3),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 5,
            backgroundColor: AppColors.bg,
            valueColor: AlwaysStoppedAnimation<Color>(warna),
          ),
        ),
        const SizedBox(height: 4),
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            "$persen% / ${_angka(target)} g",
            style: const TextStyle(color: AppColors.textSub, fontSize: 9),
          ),
        ),
      ],
    );
  }
}

// ── Chip filter tanggal ────────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback onTap;

  const _FilterChip({
    required this.icon,
    required this.label,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: isActive ? AppColors.accentLight : AppColors.card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isActive ? AppColors.accent : AppColors.border,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 15, color: isActive ? AppColors.accent : AppColors.textSub),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: isActive ? AppColors.accent : AppColors.textSub,
                  fontSize: 12,
                  fontWeight: isActive ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Kartu satu catatan makan ───────────────────────────────────────────────────
class _HistoryCard extends StatelessWidget {
  final Map<String, dynamic> item;
  const _HistoryCard({required this.item});

  double _n(dynamic v) => (v is num) ? v.toDouble() : 0.0;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: const [
          BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Thumbnail
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.accentLight,
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(Icons.restaurant_rounded,
                color: AppColors.accent, size: 24),
          ),
          const SizedBox(width: 12),

          // Nama, jam, berat
          Expanded(
            flex: 5,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (item['food_name'] ?? '-').toString(),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.textPri,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.schedule_rounded,
                        size: 12, color: AppColors.textSub),
                    const SizedBox(width: 4),
                    Text(
                      "${item['time'] ?? '-'} WIB",
                      style: const TextStyle(
                          color: AppColors.textSub, fontSize: 11),
                    ),
                  ],
                ),
                const SizedBox(height: 3),
                Row(
                  children: [
                    const Icon(Icons.scale_outlined,
                        size: 12, color: AppColors.textSub),
                    const SizedBox(width: 4),
                    Text(
                      "${_angka(_n(item['weight_grams']))} gram",
                      style: const TextStyle(
                          color: AppColors.textSub, fontSize: 11),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Kalori + rincian gizi
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Flexible(
                      child: Text(
                        _ribuan(_n(item['calories'])),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 3),
                    const Text("kcal",
                        style: TextStyle(color: AppColors.textSub, fontSize: 10)),
                  ],
                ),
                const SizedBox(height: 8),
                _MacroLine(label: "Protein", value: _n(item['protein'])),
                _MacroLine(label: "Karbohidrat", value: _n(item['carbs'])),
                _MacroLine(label: "Lemak", value: _n(item['fat'])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MacroLine extends StatelessWidget {
  final String label;
  final double value;
  const _MacroLine({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: AppColors.textSub, fontSize: 10),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            "${_angka(value)} g",
            style: const TextStyle(
              color: AppColors.textPri,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
