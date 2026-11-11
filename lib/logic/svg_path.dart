import 'dart:ui';

/// Мини-парсер путей SVG (команды M, L, C, Z в абсолютных координатах),
/// чтобы рисовать схему ладони без сторонних библиотек.
Path parseSvgPath(String d) {
  final path = Path();
  final tokens = RegExp(r'[MLCZ]|-?\d+(\.\d+)?').allMatches(d).map((m) => m[0]!).toList();
  var i = 0;
  String cmd = 'M';
  double n() => double.parse(tokens[i++]);
  while (i < tokens.length) {
    if (RegExp(r'[MLCZ]').hasMatch(tokens[i])) cmd = tokens[i++];
    switch (cmd) {
      case 'M':
        path.moveTo(n(), n());
        cmd = 'L';
      case 'L':
        path.lineTo(n(), n());
      case 'C':
        path.cubicTo(n(), n(), n(), n(), n(), n());
      case 'Z':
        path.close();
    }
  }
  return path;
}

/// Точки вдоль пути, чтобы понять, по какой линии нажали.
List<Offset> samplePath(Path p, {int steps = 40}) {
  final pts = <Offset>[];
  for (final m in p.computeMetrics()) {
    for (var s = 0; s <= steps; s++) {
      final t = m.getTangentForOffset(m.length * s / steps);
      if (t != null) pts.add(t.position);
    }
  }
  return pts;
}
