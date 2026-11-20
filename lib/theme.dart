import 'package:flutter/material.dart';

class AW {
  static const navy = Color(0xFF0B1430);
  static const deep = Color(0xFF101C44);
  static const gold = Color(0xFFF3C96B);
  static const ink = Color(0xFFEAF0FF);
  static const soft = Color(0xFFA9B8E0);
  /// Подписи и мета: тише основного текста, но читаемо на тёмно-синем.
  static const muted = Color(0xFF8593BC);
  /// Тонкая линия-разделитель вместо цветных рамок.
  static const hairline = Color(0x14FFFFFF);
  static const darkText = Color(0xFF14203F);
}

ThemeData buildTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AW.gold,
      brightness: Brightness.dark,
      primary: AW.gold,
      onPrimary: const Color(0xFF1D1504),
      surface: AW.deep,
    ),
    scaffoldBackgroundColor: AW.navy,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(bodyColor: AW.ink, displayColor: AW.ink),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white.withValues(alpha: 0.06),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
      ),
    ),
  );
}

/// Полупрозрачная карточка: тёмно-синяя поверхность и тонкая линия по краю.
class GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  const GlassCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    final card = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AW.deep.withValues(alpha: 0.78),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AW.hairline),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: BorderRadius.circular(16), onTap: onTap, child: card),
    );
  }
}

/// Подпись раздела: обычный регистр, без разрядки, приглушённый цвет.
class Label extends StatelessWidget {
  final String text;
  final Color color;
  const Label(this.text, {super.key, this.color = AW.soft});
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w500),
  );
}

/// Строка «иконка + текст»: одна линейная иконка 18 px в цвете подписи,
/// одинаковый отступ до текста, чтобы тексты стояли в одну колонку.
class IconLine extends StatelessWidget {
  final IconData icon;
  final String text;
  final TextStyle? style;
  const IconLine(this.icon, this.text, {super.key, this.style});
  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: Icon(icon, size: 18, color: AW.muted),
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(text, style: style ?? const TextStyle(fontSize: 15, height: 1.4))),
    ],
  );
}
