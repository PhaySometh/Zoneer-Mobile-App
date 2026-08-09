import 'package:flutter/material.dart';
import 'package:zoneer_mobile/core/utils/app_colors.dart';
import 'package:zoneer_mobile/data/models/property/property_model.dart';

/// Price-pill marker shown on the map when zoomed out (zoom < 12).
///
/// Layout (all measurements in logical pixels):
///
///   ┌──────────────────────────────────────┐  y = 0
///   │              pill (36 px)            │
///   └──────────────┬───────────────────────┘  y = 36
///                  │  tail (8 px)
///                  ▼                          y = 44  ← coordinate anchor
///
/// [markerWidth] × [markerHeight] must match the Marker(width:, height:)
/// declared in property_map_page.dart.  Alignment.bottomCenter places the
/// tip of the tail (the very bottom of this widget) on the map coordinate.
class PropertyPricePin extends StatelessWidget {
  final PropertyModel property;
  final bool isSelected;
  final VoidCallback onTap;

  /// Must match Marker(width:, height:) in the map page.
  static const double markerWidth = 80.0;
  static const double markerHeight = 44.0;
  static const double _tailHeight = 8.0;
  static const double _pillHeight = markerHeight - _tailHeight; // 36.0

  const PropertyPricePin({
    super.key,
    required this.property,
    this.isSelected = false,
    required this.onTap,
  });

  String _formatPrice(double price) {
    if (price >= 1000) {
      return '\$${(price / 1000).toStringAsFixed(1)}k';
    }
    return '\$${price.toInt()}';
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = isSelected ? AppColors.primary : Colors.white;
    final textColor = isSelected ? Colors.white : Colors.black87;
    final borderColor =
        isSelected ? AppColors.primary : Colors.grey.shade300;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: markerWidth,
        height: markerHeight,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            // ── Teardrop shape (pill + tail) ───────────────────────────
            // CustomPaint with no child uses the explicit `size` parameter,
            // so the canvas is exactly markerWidth × markerHeight.
            CustomPaint(
              size: const Size(markerWidth, markerHeight),
              painter: _TearDropPainter(
                bgColor: bgColor,
                borderColor: borderColor,
                isSelected: isSelected,
                pillHeight: _pillHeight,
              ),
            ),
            // ── Price label — sits inside the pill area only ───────────
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: _pillHeight,
              child: Center(
                child: Text(
                  _formatPrice(property.price),
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TearDropPainter extends CustomPainter {
  final Color bgColor;
  final Color borderColor;
  final bool isSelected;
  final double pillHeight;

  const _TearDropPainter({
    required this.bgColor,
    required this.borderColor,
    required this.isSelected,
    required this.pillHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = _buildPath(size);

    // Shadow
    canvas.drawShadow(
      path,
      Colors.black,
      isSelected ? 4.0 : 2.0,
      false,
    );

    // Fill
    canvas.drawPath(
      path,
      Paint()
        ..color = bgColor
        ..style = PaintingStyle.fill,
    );

    // Stroke
    canvas.drawPath(
      path,
      Paint()
        ..color = borderColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );
  }

  /// Builds the combined teardrop path using actual canvas [size].
  ///
  /// Pill: rounded rect from (0,0) → (size.width, pillHeight).
  /// Tail: smooth bezier triangle, base centred on pill bottom,
  ///       tip at (size.width/2, size.height) — the coordinate anchor.
  Path _buildPath(Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Rounded pill
    final pill = Path()
      ..addRRect(RRect.fromLTRBR(
          0, 0, w, pillHeight, const Radius.circular(10)));

    // Downward-pointing bezier tail.
    // Base spans [cx-7 … cx+7] at y=pillHeight; tip at (cx, h).
    final tail = Path()
      ..moveTo(cx - 7, pillHeight)
      ..lineTo(cx + 7, pillHeight)
      ..quadraticBezierTo(cx + 7, pillHeight + 2, cx, h)
      ..quadraticBezierTo(cx - 7, pillHeight + 2, cx - 7, pillHeight)
      ..close();

    return Path.combine(PathOperation.union, pill, tail);
  }

  @override
  bool shouldRepaint(covariant _TearDropPainter old) =>
      old.bgColor != bgColor ||
      old.borderColor != borderColor ||
      old.isSelected != isSelected ||
      old.pillHeight != pillHeight;
}
