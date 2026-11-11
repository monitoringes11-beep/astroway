import 'package:flutter/material.dart';

import '../logic/daily.dart';
import '../logic/memory.dart';
import '../logic/moon.dart';
import '../logic/sunmoon.dart';
import '../logic/zodiac.dart';
import '../main.dart';
import '../theme.dart';

/// «Луна и Солнце»: общая энергия дня, личный разбор по знаку и мини-задание по фазе Луны.
class SunMoonScreen extends StatefulWidget {
  final AppState app;
  const SunMoonScreen({super.key, required this.app});
  @override
  State<SunMoonScreen> createState() => _SunMoonScreenState();
}

class _SunMoonScreenState extends State<SunMoonScreen> {
  final _note = TextEditingController();
  bool _saved = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.app.profile!;
    final easy = widget.app.easy;
    final now = DateTime.now();
    final sign = signIndexOf(p.birthday.month, p.birthday.day);
    final energy = sunEnergyFor(now);
    final moon = moonFor(now);
    final task = moonTask(moon.phase);

    Widget layer(String h, String t) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Label(h),
          const SizedBox(height: 3),
          Text(t, style: const TextStyle(height: 1.4)),
        ],
      ),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Луна и Солнце'), backgroundColor: AW.navy),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Сегодня для всех',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AW.gold),
                ),
                const SizedBox(height: 10),
                layer('Энергия Солнца · ${sunLevel(energy)}', sunText(energy, easy: easy)),
                layer(
                  'Настроение Луны · ${moonLevel(moon.phase)}',
                  '${moonText(moon.phase, easy: easy)} ${moon.lunarDay}-й лунный день, освещена на ${moon.percent}%.',
                ),
                Text(
                  'Баланс дня: ${balanceText(energy, easy: easy)}',
                  style: const TextStyle(fontWeight: FontWeight.w600, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${p.name}, твои Солнце и Луна сегодня',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AW.gold),
                ),
                const SizedBox(height: 10),
                layer('☀️ Солнце: ${signs[sign].name}', personalSun(sign, energy)),
                layer('🌙 Луна: эмоциональный фон', personalMoon(moon.phase, easy: easy)),
                layer('☯ Как это сочетается с днём', rhythmText(rhythmFits(sign, energy, moon.phase))),
              ],
            ),
          ),
          const SizedBox(height: 14),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Label('Знак Луны · мини-задание'),
                const SizedBox(height: 6),
                Text(task[0], style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text(task[1], style: const TextStyle(height: 1.4)),
                const SizedBox(height: 10),
                TextField(
                  controller: _note,
                  minLines: 2,
                  maxLines: 4,
                  decoration: const InputDecoration(hintText: 'Запишите здесь, волшебница это запомнит'),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _saved
                      ? null
                      : () async {
                          final t = _note.text.trim();
                          if (t.isEmpty) return;
                          await widget.app.memory.add(WitchAnswer(now, [moon.name], t, 'moon'));
                          setState(() => _saved = true);
                        },
                  child: Text(_saved ? '★ Сохранено в дневник' : '☆ В дневник'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Только общие рекомендации, без точных прогнозов. Развлекательный характер.',
            style: TextStyle(color: AW.soft, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
