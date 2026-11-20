import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../logic/moon.dart';

/// Луна, нарисованная по настоящему возрасту: освещённая часть совпадает
/// с тем, что видно на небе сегодня (северное полушарие, растущая справа).
class MoonGlyph extends StatelessWidget {
  final MoonInfo moon;
  final double size;
  const MoonGlyph(this.moon, {super.key, this.size = 48});

  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CustomPaint(painter: _MoonPainter(moon.age / synodicMonth)),
  );
}

class _MoonPainter extends CustomPainter {
  final double cycle; // 0 новолуние, 0.5 полнолуние, 1 снова новолуние
  _MoonPainter(this.cycle);

  static const _dark = Color(0xFF1F2B52);
  static const _lit = Color(0xFFF1E3BC);

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.shortestSide / 2;
    final c = size.center(Offset.zero);
    canvas.drawCircle(c, r, Paint()..color = _dark);

    final theta = 2 * math.pi * cycle;
    final waxing = cycle < 0.5;
    final path = Path();
    const steps = 48;
    // Внешний край освещённой части.
    for (var i = 0; i <= steps; i++) {
      final y = -r + 2 * r * i / steps;
      final w = math.sqrt(math.max(0, r * r - y * y));
      final x = waxing ? w : -w;
      i == 0 ? path.moveTo(c.dx + x, c.dy + y) : path.lineTo(c.dx + x, c.dy + y);
    }
    // Терминатор — граница света и тени, идём обратно снизу вверх.
    for (var i = steps; i >= 0; i--) {
      final y = -r + 2 * r * i / steps;
      final w = math.sqrt(math.max(0, r * r - y * y));
      final x = waxing ? math.cos(theta) * w : -math.cos(theta) * w;
      path.lineTo(c.dx + x, c.dy + y);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = _lit);
    canvas.drawCircle(
      c,
      r - 0.5,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = const Color(0x1FFFFFFF),
    );
  }

  @override
  bool shouldRepaint(_MoonPainter old) => old.cycle != cycle;
}
