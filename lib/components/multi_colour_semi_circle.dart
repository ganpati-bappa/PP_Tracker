import 'dart:math';
import 'package:pp_tracker/models/menstrual_cycle.dart';
import 'package:flutter/cupertino.dart';

class MultiColourSemiCircleDart extends StatefulWidget {
  final MenstrualCycle cycle;
  final double size;
  final double strokeWidth;
  final int durationMs;
  static const gap = 5;
  static const List<Color> segmentColors = [
    Color.fromRGBO(254, 144, 169, 1),
    Color.fromRGBO(146, 193, 255, 1),
    Color.fromRGBO(255, 240, 100, 1),
    Color.fromRGBO(159, 254, 124, 1),
  ];

  const MultiColourSemiCircleDart({
    super.key,
    this.strokeWidth = 16,
    this.size = 200,
    this.durationMs = 1500,
    required this.cycle,
  });

  @override
  State<MultiColourSemiCircleDart> createState() => _MultiColourSemiCircleDartState();
}

class _MultiColourSemiCircleDartState extends State<MultiColourSemiCircleDart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  final DateTime now = DateTime.now();
  late final CycleDay cycleDay;
  late final double targetAngle;

  @override
  void initState() {
    super.initState();
    cycleDay = widget.cycle.calculateCycleForToday(now);
    targetAngle = (pi + (cycleDay.date.inDays / widget.cycle.cycleLength) * pi);
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500));
    _animation = Tween<double>(
      begin: pi,
      end: targetAngle,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInCubic));
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        return Stack(
          children: [
            CustomPaint(
              size: Size(widget.size, widget.size / 2),
              painter: SemiCirclePainter(widget.strokeWidth, widget.cycle),
            ),
            CustomPaint(
              size: Size(widget.size, widget.size / 2),
              painter: Pointer(angle: _animation.value, strokeWidth: widget.strokeWidth),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/phases/${cycleDay.phase.toName()}.png',
                    width: 140,
                    height: 140,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${cycleDay.phase.toName()} Phase',
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: CupertinoColors.systemPink,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class SemiCirclePainter extends CustomPainter {
  final double strokeWidth;
  final MenstrualCycle cycle;

  SemiCirclePainter(this.strokeWidth, this.cycle);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.width);
    const piUnit = pi / 180;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final shadowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth + 4
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, 8);

    final List<int> phases = cycle.getPhaseDurations();

    final sweepSegment = (pi - MultiColourSemiCircleDart.gap * 4 * piUnit);
    double startAngle = pi;

    for (int i = 0; i < phases.length; i++) {
      final color = MultiColourSemiCircleDart.segmentColors[i];
      final sweepPerSegment = (phases[i] / cycle.cycleLength) * sweepSegment;
      paint.color = color;
      shadowPaint.color = color.withValues(alpha: 0.8);

      canvas.drawArc(
        rect.shift(const Offset(2, 4)),
        startAngle,
        sweepPerSegment,
        false,
        shadowPaint,
      );

      canvas.drawArc(rect, startAngle, sweepPerSegment, false, paint);
      startAngle += sweepPerSegment + MultiColourSemiCircleDart.gap * piUnit;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class Pointer extends CustomPainter {
  final double angle;
  final double strokeWidth;

  Pointer({required this.angle, this.strokeWidth = 4});

  @override
  void paint(Canvas canvas, Size size) {
    // Must match SemiCirclePainter
    final rect = Rect.fromLTWH(0, 0, size.width, size.width);
    final center = rect.center;
    final radius = rect.width / 2;

    // Put pointer on the middle of the stroke
    final effectiveRadius = radius - strokeWidth / 2 + 4; // +4 to visually align with the arc

    final pointerEnd = Offset(
      center.dx + effectiveRadius * cos(angle),
      center.dy + effectiveRadius * sin(angle),
    );

    final paint = Paint()
      ..color = const Color.fromRGBO(255, 100, 135, 1)
      ..style = PaintingStyle.fill;

    final shadowPaint = Paint()
      ..color = const Color.fromRGBO(255, 100, 135, 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);

    canvas.drawCircle(pointerEnd, 12, shadowPaint);
    canvas.drawCircle(pointerEnd, 10, paint);
  }

  @override
  bool shouldRepaint(covariant Pointer oldDelegate) {
    return oldDelegate.angle != angle;
  }
}

class SemiCircleSegment extends CustomPainter {
  final int segmentIndex;

  SemiCircleSegment(this.segmentIndex);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(15, 15, size.width - 30, size.width - 20);
    final paint = Paint()
      ..color = MultiColourSemiCircleDart.segmentColors[segmentIndex].withAlpha(120)
      ..style = PaintingStyle.fill
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.butt;
    canvas.drawArc(rect, pi, pi, true, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
