import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Kotak bergaris putus-putus untuk kondisi "belum ada data",
/// dipakai di halaman Favorit dan Riwayat.
class EmptyStateBox extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String buttonLabel;
  final IconData buttonIcon;
  final VoidCallback onButtonTap;

  const EmptyStateBox({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.buttonLabel,
    required this.onButtonTap,
    this.buttonIcon = Icons.document_scanner_rounded,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBorderPainter(),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
        child: Column(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(
                color: AppColors.accentLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.accent, size: 28),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColors.textPri,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: AppColors.textSub, fontSize: 12, height: 1.6),
            ),
            const SizedBox(height: 22),
            GestureDetector(
              onTap: onButtonTap,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.accent.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(buttonIcon, color: Colors.white, size: 18),
                    const SizedBox(width: 10),
                    Text(
                      buttonLabel,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Garis putus-putus ──────────────────────────────────────────────────────────
class _DashedBorderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(20),
    );

    // Path dipotong jadi garis-garis pendek
    const double dash = 7;
    const double gap = 5;
    final Path path = Path()..addRRect(rrect);
    for (final metric in path.computeMetrics()) {
      double jarak = 0;
      while (jarak < metric.length) {
        final double akhir = (jarak + dash).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(jarak, akhir), paint);
        jarak = akhir + gap;
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
