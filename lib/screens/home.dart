import 'dart:async';

import 'package:flutter/material.dart';

import '../logic/daily.dart';
import '../logic/moon.dart';
import '../logic/profile.dart';
import '../logic/zodiac.dart';
import '../main.dart';
import '../theme.dart';
import 'dream.dart';
import 'horoscope.dart';
import 'numerology.dart';
import 'omens.dart';
import 'sunmoon.dart';
import 'onboarding.dart';

enum Scene { morning, day, night }

/// Сцена определяется по времени телефона: утро 06–10, день 10–17, вечер и ночь 17–06.
Scene sceneFor(DateTime t) {
  final h = t.hour;
  if (h >= 6 && h < 10) return Scene.morning;
  if (h >= 10 && h < 17) return Scene.day;
  return Scene.night;
}

String greetingFor(DateTime t) {
  final h = t.hour;
  if (h >= 6 && h < 10) return 'Доброе утро';
  if (h >= 10 && h < 17) return 'Добрый день';
  if (h >= 17 && h < 23) return 'Добрый вечер';
  return 'Доброй ночи';
}

class HomeScreen extends StatefulWidget {
  final AppState app;
  const HomeScreen({super.key, required this.app});
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _soon(String name) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text('Раздел «$name» появится в следующей сборке')));
  }

  @override
  Widget build(BuildContext context) {
    final app = widget.app;
    final p = app.profile!;
    final scene = sceneFor(_now);
    final moon = moonFor(_now);
    final sign = signOf(p.birthday);
    final age = p.ageOn(_now);
    final easy = app.easy;
    final energy = sunEnergyFor(_now);
    final f = forecastFor(p, _now, easy: easy);
    final img = 'assets/images/witch-${scene.name}.jpg';

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          AnimatedSwitcher(
            duration: const Duration(seconds: 2),
            child: Image.asset(img, key: ValueKey(img), fit: BoxFit.cover, alignment: Alignment.topCenter),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: scene == Scene.night ? 0.25 : 0.05),
                  AW.navy.withValues(alpha: 0.55),
                  AW.navy.withValues(alpha: 0.96),
                ],
                stops: const [0, 0.35, 0.62],
              ),
            ),
          ),
          SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              children: [
                Row(
                  children: [
                    const Text(
                      'AstroWay',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AW.gold),
                    ),
                    const Spacer(),
                    Text(
                      '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
                const SizedBox(height: 180),
                Text(
                  '${greetingFor(_now)}, ${p.name}',
                  style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
                ),
                Text(
                  '${sign.symbol} ${sign.name} · $age ${yearsWord(age)}',
                  style: const TextStyle(color: AW.soft, fontSize: 15),
                ),
                const SizedBox(height: 12),
                _Prefs(app: app),
                const SizedBox(height: 12),
                GlassCard(
                  child: Row(
                    children: [
                      Text(
                        moon.phase == MoonPhase.full
                            ? '🌕'
                            : moon.phase == MoonPhase.newMoon
                            ? '🌑'
                            : moon.phase == MoonPhase.young
                            ? '🌒'
                            : '🌘',
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Label('Луна сегодня'),
                            const SizedBox(height: 4),
                            Text(moon.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                            Text(
                              '${moon.lunarDay}-й лунный день · освещена на ${moon.percent}%',
                              style: const TextStyle(color: AW.soft, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Text(moon.tip, style: const TextStyle(fontSize: 14)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _SunMoon(
                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SunMoonScreen(app: app))),
                  sunLvl: sunLevel(energy),
                  sunTx: sunText(energy, easy: easy),
                  moonLvl: moonLevel(moon.phase),
                  moonTx: moonText(moon.phase, easy: easy),
                  balance: balanceText(energy, easy: easy),
                ),
                const SizedBox(height: 12),
                GlassCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Label('Прогноз дня · ${sign.name}'),
                          const Spacer(),
                          TextButton(
                            onPressed: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => OnboardingScreen(app: app, initial: p),
                              ),
                            ),
                            child: const Text('Изменить'),
                          ),
                        ],
                      ),
                      _Line('Что принесёт день', '💞 ${f.love}\n💼 ${f.work}\n✨ ${f.mood}'),
                      _Line('Чего сторониться', f.avoid.map((e) => '• $e').join('\n')),
                      _Line('К чему готовиться', f.prepare.map((e) => '• $e').join('\n')),
                      if (p.birthSlot == slotUnknown)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Общий прогноз по знаку. Укажи время рождения, и прогноз станет личным.',
                            style: TextStyle(color: AW.soft, fontSize: 12.5),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 1.05,
                  children: [
                    _Tile(
                      '🌙',
                      'Сонник',
                      () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DreamScreen(app: app))),
                    ),
                    _Tile(
                      '☀️',
                      'Гороскоп',
                      () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HoroscopeScreen(app: app))),
                    ),
                    _Tile('🃏', 'Расклады', () => _soon('Расклады')),
                    _Tile(
                      '⭐',
                      'Знаки судьбы',
                      () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OmensScreen(app: app))),
                    ),
                    _Tile(
                      '🌗',
                      'Луна и Солнце',
                      () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SunMoonScreen(app: app))),
                    ),
                    _Tile(
                      '7',
                      'Нумерология',
                      () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => NumerologyScreen(app: app))),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                _Tile('✋', 'Тайны ладони', () => _soon('Тайны ладони'), wide: true),
                const SizedBox(height: 16),
                const Text(
                  'Приложение носит развлекательный характер. Не является рекомендацией для принятия важных решений.',
                  style: TextStyle(color: AW.soft, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Prefs extends StatelessWidget {
  final AppState app;
  const _Prefs({required this.app});
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('до 50')),
            ButtonSegment(value: true, label: Text('50+')),
          ],
          selected: {app.large},
          showSelectedIcon: false,
          onSelectionChanged: (s) => app.setLarge(s.first),
        ),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('Серьёзно')),
            ButtonSegment(value: true, label: Text('Легко')),
          ],
          selected: {app.easy},
          showSelectedIcon: false,
          onSelectionChanged: (s) => app.setEasy(s.first),
        ),
      ],
    );
  }
}

class _SunMoon extends StatelessWidget {
  final String sunLvl, sunTx, moonLvl, moonTx, balance;
  final VoidCallback onTap;
  const _SunMoon({
    required this.onTap,
    required this.sunLvl,
    required this.sunTx,
    required this.moonLvl,
    required this.moonTx,
    required this.balance,
  });

  Widget _half(String label, Color c, String lvl, String tx) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AW.navy.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(14)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Label(label, color: c),
          const SizedBox(height: 4),
          Text(lvl, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(tx, style: const TextStyle(fontSize: 13.5, height: 1.35)),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(colors: [Color(0x55FFCE6E), Color(0x556EA0FF)]),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _half('Энергия Солнца', AW.gold, sunLvl, sunTx),
                  const SizedBox(width: 8),
                  _half('Настроение Луны', const Color(0xFFA9C8FF), moonLvl, moonTx),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AW.navy.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(14)),
              child: Text('Баланс дня: $balance  ›', style: const TextStyle(fontSize: 14, height: 1.35)),
            ),
          ],
        ),
      ),
    );
  }
}

class _Line extends StatelessWidget {
  final String title, body;
  const _Line(this.title, this.body);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, color: AW.soft),
        ),
        const SizedBox(height: 2),
        Text(body, style: const TextStyle(fontSize: 14.5, height: 1.4)),
      ],
    ),
  );
}

class _Tile extends StatelessWidget {
  final String icon, title;
  final VoidCallback onTap;
  final bool wide;
  const _Tile(this.icon, this.title, this.onTap, {this.wide = false});
  @override
  Widget build(BuildContext context) {
    final iconW = Text(
      icon,
      style: const TextStyle(fontSize: 26, color: AW.gold, fontWeight: FontWeight.w700),
    );
    final titleW = Text(
      title,
      textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.w600),
    );
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(12),
      child: wide
          ? Row(children: [iconW, const SizedBox(width: 12), titleW])
          : Column(mainAxisAlignment: MainAxisAlignment.center, children: [iconW, const SizedBox(height: 8), titleW]),
    );
  }
}
