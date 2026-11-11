import 'package:flutter/material.dart';

class AW {
  static const navy = Color(0xFF0B1430);
  static const deep = Color(0xFF101C44);
  static const gold = Color(0xFFF3C96B);
  static const ink = Color(0xFFEAF0FF);
  static const soft = Color(0xFFA9B8E0);
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
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
  );
}

/// Полупрозрачная карточка в стиле макета.
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: child,
    );
    if (onTap == null) return card;
    return Material(
      color: Colors.transparent,
      child: InkWell(borderRadius: BorderRadius.circular(20), onTap: onTap, child: card),
    );
  }
}

class Label extends StatelessWidget {
  final String text;
  final Color color;
  const Label(this.text, {super.key, this.color = AW.gold});
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(),
      style: TextStyle(color: color, fontSize: 11.5, letterSpacing: 0.8, fontWeight: FontWeight.w600));
}
