import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:pp_tracker/theme/app_theme.dart';

/// A soft, decorative floral motif that bleeds in from the top-right corner as
/// a background watermark. Purely ornamental: it sits *behind* content, ignores
/// pointer events, and is drawn at a low opacity so it never competes with the
/// UI (it reads as a gentle brand flourish, on-theme for "Petal").
///
/// Tuned to be tasteful and easy to dial in — adjust [opacity] / [size] or drop
/// it entirely by flipping `AppBackground(showFlower: false)`.
class CornerFlower extends StatelessWidget {
  final double size;
  final double opacity;

  const CornerFlower({super.key, this.size = 260, this.opacity = 0.12});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Opacity(
        opacity: opacity,
        child: SizedBox(
          width: size,
          height: size,
          child: CustomPaint(painter: _FlowerPainter()),
        ),
      ),
    );
  }
}

class _FlowerPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Anchor the bloom just past the top-right corner so petals fan inward and
    // the rest tucks off-screen.
    final center = Offset(size.width * 0.82, size.height * 0.18);
    final petalLength = size.width * 0.5;
    final petalWidth = size.width * 0.19;

    // Outer ring of petals (dusty rose).
    _drawRing(
      canvas,
      center: center,
      count: 8,
      length: petalLength,
      width: petalWidth,
      startAngle: 0,
      colorTop: AppColors.primary,
      colorBottom: AppColors.primaryDeep,
    );

    // Inner ring, offset and smaller (champagne gold), for depth.
    _drawRing(
      canvas,
      center: center,
      count: 8,
      length: petalLength * 0.62,
      width: petalWidth * 0.78,
      startAngle: math.pi / 8, // half-step so it peeks between outer petals
      colorTop: AppColors.accent,
      colorBottom: AppColors.ovulationDeep,
    );

    // Flower centre.
    canvas.drawCircle(
      center,
      petalWidth * 0.42,
      Paint()..color = AppColors.accent,
    );
    canvas.drawCircle(
      center,
      petalWidth * 0.22,
      Paint()..color = AppColors.primaryDeep,
    );
  }

  void _drawRing(
    Canvas canvas, {
    required Offset center,
    required int count,
    required double length,
    required double width,
    required double startAngle,
    required Color colorTop,
    required Color colorBottom,
  }) {
    for (var i = 0; i < count; i++) {
      final angle = startAngle + (i * 2 * math.pi / count);
      canvas.save();
      canvas.translate(center.dx, center.dy);
      canvas.rotate(angle);
      final paint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [colorBottom, colorTop],
        ).createShader(Rect.fromLTWH(-width, -length, width * 2, length));
      canvas.drawPath(_petal(length, width), paint);
      canvas.restore();
    }
  }

  /// A single teardrop petal pointing "up" (negative Y) from the origin.
  Path _petal(double length, double width) {
    return Path()
      ..moveTo(0, 0)
      ..quadraticBezierTo(width, -length * 0.5, 0, -length)
      ..quadraticBezierTo(-width, -length * 0.5, 0, 0)
      ..close();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
