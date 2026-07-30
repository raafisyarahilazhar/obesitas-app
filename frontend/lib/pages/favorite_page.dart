import 'package:flutter/material.dart';

import '../services/api_service.dart';
import '../theme/app_colors.dart';
import '../widgets/empty_state_box.dart';
import 'scanner_page.dart';

/// Daftar makanan yang paling sering discan user (minimal 5x scan).
/// Favorit tidak diinput manual — dihitung otomatis dari riwayat makan.
class FavoritePage extends StatefulWidget {
  final int userId;
  const FavoritePage({super.key, required this.userId});

  @override
  State<FavoritePage> createState() => _FavoritePageState();
}

class _FavoritePageState extends State<FavoritePage> {
  final TextEditingController _searchController = TextEditingController();

  List<dynamic> _favorites = [];
  int _minScan = 5;
  bool _isLoading = true;
  String _keyword = "";
  String? _selectedFood;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService.getFavorites(widget.userId);
      if (!mounted) return;
      setState(() {
        _favorites = res['favorites'] ?? [];
        _minScan = res['min_scan'] ?? 5;
        _isLoading = false;
        // Pilihan sebelumnya dibuang kalau makanannya sudah tidak ada
        if (!_favorites.any((f) => f['food_name'] == _selectedFood)) {
          _selectedFood = null;
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      _showMessage(e.toString().replaceAll("Exception: ", ""), isError: true);
    }
  }

  List<dynamic> get _filtered {
    if (_keyword.isEmpty) return _favorites;
    return _favorites
        .where((f) => (f['food_name'] ?? '')
            .toString()
            .toLowerCase()
            .contains(_keyword.toLowerCase()))
        .toList();
  }

  Map<String, dynamic>? get _selected {
    if (_selectedFood == null) return null;
    for (final f in _favorites) {
      if (f['food_name'] == _selectedFood) return Map<String, dynamic>.from(f);
    }
    return null;
  }

  // ── Aksi cepat ──────────────────────────────────────────────────
  void _showNutritionDetail(Map<String, dynamic> food) {
    final per100 = food['per_100g'] ?? {};

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => Container(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        decoration: const BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              food['food_name'] ?? '-',
              style: const TextStyle(
                color: AppColors.textPri,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              "${food['category'] ?? '-'}  ·  discan ${food['scan_count'] ?? 0}x",
              style: const TextStyle(color: AppColors.textSub, fontSize: 12),
            ),
            const SizedBox(height: 20),
            const Text(
              "Kandungan per 100 gram",
              style: TextStyle(
                color: AppColors.textPri,
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _NutrientBox(
                    label: "Kalori",
                    value: _fmt(per100['calories']),
                    unit: "kcal",
                    color: AppColors.accent),
                const SizedBox(width: 10),
                _NutrientBox(
                    label: "Karbo",
                    value: _fmt(per100['carbs']),
                    unit: "g",
                    color: AppColors.warning),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _NutrientBox(
                    label: "Protein",
                    value: _fmt(per100['protein']),
                    unit: "g",
                    color: AppColors.info),
                const SizedBox(width: 10),
                _NutrientBox(
                    label: "Lemak",
                    value: _fmt(per100['fat']),
                    unit: "g",
                    color: AppColors.success),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.medical_information_outlined,
                      color: AppColors.accent, size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      food['medical_status'] ?? '-',
                      style: const TextStyle(
                        color: AppColors.textPri,
                        fontSize: 12,
                        height: 1.5,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Text(
              "Porsi rata-rata kamu: ${food['avg_weight_grams'] ?? 0} g "
              "(${food['avg_calories'] ?? 0} kcal)",
              style: const TextStyle(color: AppColors.textSub, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  void _addToTodayHistory(Map<String, dynamic> food) async {
    try {
      await ApiService.logMeal({
        "user_id": widget.userId,
        "food_name": food['food_name'],
        "weight_grams": (food['avg_weight_grams'] ?? 100).toDouble(),
        "calories": (food['avg_calories'] ?? 0).toDouble(),
        "carbs": (food['avg_carbs'] ?? 0).toDouble(),
      });
      if (!mounted) return;
      _showMessage("${food['food_name']} ditambahkan ke riwayat hari ini");
      _fetch();
    } catch (e) {
      _showMessage("Gagal menambahkan ke riwayat", isError: true);
    }
  }

  void _removeFromFavorites(Map<String, dynamic> food) async {
    final String nama = food['food_name'];
    try {
      await ApiService.setFavoriteHidden(widget.userId, nama, true);
      if (!mounted) return;
      setState(() {
        _favorites.removeWhere((f) => f['food_name'] == nama);
        _selectedFood = null;
      });
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text("$nama dihapus dari favorit"),
        backgroundColor: AppColors.textPri,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        action: SnackBarAction(
          label: "Urungkan",
          textColor: Colors.white,
          onPressed: () async {
            try {
              await ApiService.setFavoriteHidden(widget.userId, nama, false);
              _fetch();
            } catch (_) {}
          },
        ),
      ));
    } catch (e) {
      _showMessage("Gagal menghapus dari favorit", isError: true);
    }
  }

  void _openScanner() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => ScannerPage(userId: widget.userId)),
    ).then((_) => _fetch());
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
      backgroundColor: AppColors.bg,
      body: RefreshIndicator(
        onRefresh: _fetch,
        color: AppColors.accent,
        backgroundColor: AppColors.card,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(child: _buildHeader()),
            SliverToBoxAdapter(child: _buildSearchField()),

            if (_isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 60),
                  child: Center(
                    child: CircularProgressIndicator(
                        color: AppColors.accent, strokeWidth: 2),
                  ),
                ),
              )
            else if (_favorites.isEmpty)
              SliverToBoxAdapter(child: _buildEmptyState())
            else ...[
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 22, 24, 14),
                  child: Text(
                    "Makanan Favorit",
                    style: TextStyle(
                      color: AppColors.textPri,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.2,
                    ),
                  ),
                ),
              ),

              if (_filtered.isEmpty)
                const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                    child: Text(
                      "Tidak ada makanan favorit yang cocok dengan pencarianmu.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.textSub, fontSize: 13),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, i) {
                        final food = Map<String, dynamic>.from(_filtered[i]);
                        return _FavoriteCard(
                          food: food,
                          isSelected: food['food_name'] == _selectedFood,
                          onTap: () => setState(() {
                            _selectedFood = food['food_name'] == _selectedFood
                                ? null
                                : food['food_name'];
                          }),
                        );
                      },
                      childCount: _filtered.length,
                    ),
                  ),
                ),

              SliverToBoxAdapter(child: _buildQuickActions()),
            ],

            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

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
                  "Favorit",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  "Daftar makanan favoritmu",
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ),
          ),
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (v) => setState(() => _keyword = v.trim()),
          style: const TextStyle(color: AppColors.textPri, fontSize: 14),
          decoration: InputDecoration(
            hintText: "Cari makanan favorit...",
            hintStyle: const TextStyle(color: AppColors.textSub, fontSize: 14),
            prefixIcon: const Icon(Icons.search_rounded,
                color: AppColors.textSub, size: 20),
            suffixIcon: _keyword.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.close_rounded,
                        color: AppColors.textSub, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _keyword = "");
                    },
                  ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 14),
          ),
        ),
      ),
    );
  }

  // ── Panel "Detail Cepat" ────────────────────────────────────────
  Widget _buildQuickActions() {
    final food = _selected;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      child: Column(
        children: [
          const Row(
            children: [
              Expanded(child: Divider(color: AppColors.border, height: 1)),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  "DETAIL CEPAT",
                  style: TextStyle(
                    color: AppColors.textSub,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              Expanded(child: Divider(color: AppColors.border, height: 1)),
            ],
          ),
          const SizedBox(height: 14),

          if (food == null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
              ),
              child: const Text(
                "Pilih salah satu makanan di atas untuk melihat aksi cepat.",
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSub, fontSize: 12),
              ),
            )
          else
            Container(
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: AppColors.border),
                boxShadow: const [
                  BoxShadow(
                      color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 2)),
                ],
              ),
              child: Column(
                children: [
                  _QuickAction(
                    icon: Icons.info_outline_rounded,
                    label: "Lihat Detail Nutrisi",
                    onTap: () => _showNutritionDetail(food),
                  ),
                  const Divider(color: AppColors.border, height: 1, indent: 16, endIndent: 16),
                  _QuickAction(
                    icon: Icons.add_circle_outline_rounded,
                    label: "Tambahkan ke Riwayat Hari Ini",
                    onTap: () => _addToTodayHistory(food),
                  ),
                  const Divider(color: AppColors.border, height: 1, indent: 16, endIndent: 16),
                  _QuickAction(
                    icon: Icons.delete_outline_rounded,
                    label: "Hapus dari Favorit",
                    isDanger: true,
                    onTap: () => _removeFromFavorites(food),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  // ── Kondisi kosong ──────────────────────────────────────────────
  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: EmptyStateBox(
        icon: Icons.favorite_border_rounded,
        title: "Belum ada hasil dari scan",
        message: "Scan makanan yang sama minimal $_minScan kali, "
            "nanti otomatis muncul di sini agar lebih mudah ditemukan.",
        buttonLabel: "Mulai Scan Makanan",
        onButtonTap: _openScanner,
      ),
    );
  }
}

String _fmt(dynamic v) {
  if (v is! num) return "-";
  return v == v.roundToDouble() ? v.round().toString() : v.toStringAsFixed(1);
}

// ── Kartu makanan favorit ──────────────────────────────────────────────────────
class _FavoriteCard extends StatelessWidget {
  final Map<String, dynamic> food;
  final bool isSelected;
  final VoidCallback onTap;

  const _FavoriteCard({
    required this.food,
    required this.isSelected,
    required this.onTap,
  });

  static IconData _iconFor(String kategori) {
    switch (kategori) {
      case "Makanan Utama":
        return Icons.rice_bowl_rounded;
      case "Lauk Protein":
        return Icons.set_meal_rounded;
      case "Sayuran":
        return Icons.eco_rounded;
      case "Buah":
        return Icons.apple_rounded;
      case "Camilan":
        return Icons.cookie_rounded;
      default:
        return Icons.restaurant_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final String kategori = (food['category'] ?? '-').toString();

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? AppColors.accent : AppColors.border,
            width: isSelected ? 1.5 : 1,
          ),
          boxShadow: const [
            BoxShadow(color: AppColors.shadow, blurRadius: 12, offset: Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            // Thumbnail
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.accentLight,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(_iconFor(kategori), color: AppColors.accent, size: 24),
            ),
            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (food['food_name'] ?? '-').toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: AppColors.textPri,
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    kategori,
                    style: const TextStyle(color: AppColors.textSub, fontSize: 12),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    "${food['avg_calories'] ?? 0} kcal",
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),

            // Jumlah scan
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.accentLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    "${food['scan_count'] ?? 0}x",
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Icon(
                  isSelected
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: AppColors.textSub,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── Baris aksi cepat ───────────────────────────────────────────────────────────
class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDanger;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDanger = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color warna = isDanger ? AppColors.danger : AppColors.textPri;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        child: Row(
          children: [
            Icon(icon, color: isDanger ? AppColors.danger : AppColors.accent, size: 19),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: warna,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textSub, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Kotak nutrisi di bottom sheet ──────────────────────────────────────────────
class _NutrientBox extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;

  const _NutrientBox({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.bg,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(color: AppColors.textSub, fontSize: 11)),
            const SizedBox(height: 6),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(width: 3),
                Text(unit,
                    style: const TextStyle(color: AppColors.textSub, fontSize: 11)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
