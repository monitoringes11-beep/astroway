import 'dart:async';

import 'package:flutter/material.dart';

import '../logic/daily.dart';
import '../logic/moon.dart';
import '../logic/profile.dart';
import '../logic/zodiac.dart';
import '../main.dart';
import '../logic/share_content.dart';
import '../theme.dart';
import '../data/horoscope_bank.dart' show weekdayNames;
import '../widgets/moon_glyph.dart';
import '../widgets/share_card.dart';
import 'dream.dart';
import 'feedback.dart';
import 'horoscope.dart';
import 'numerology.dart';
import 'omens.dart';
import 'palm.dart';
import 'profiles.dart';
import 'sunmoon.dart';
import 'tarot.dart';
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
    final mem = app.memory.all();
    final f = forecastFor(p, _now, easy: easy, recall: mem.isEmpty ? null : mem.last);
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
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AW.gold),
                    ),
                    const Spacer(),
                    Text(
                      '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 16, fontFeatures: [FontFeature.tabularFigures()]),
                    ),
                    ProfileMenu(app: app),
                  ],
                ),
                const SizedBox(height: 160),
                Text(
                  '${weekdayNames[_now.weekday - 1]}, ${shareDate(_now)}',
                  style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w500, height: 1.15),
                ),
                const SizedBox(height: 4),
                Text(
                  '${greetingFor(_now)}, ${p.name} · ${sign.symbol} ${sign.name} · $age ${yearsWord(age)}',
                  style: const TextStyle(color: AW.soft, fontSize: 15),
                ),
                const SizedBox(height: 12),
                _Prefs(app: app),
                const SizedBox(height: 12),
                GlassCard(
                  child: Row(
                    children: [
                      MoonGlyph(moon, size: 56),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Label('Луна сегодня'),
                            const SizedBox(height: 4),
                            Text(moon.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
                            Text(
                              '${moon.lunarDay}-й лунный день · освещена на ${moon.percent}\u00A0%',
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
                      Text(
                        f.theme,
                        style: const TextStyle(color: AW.gold, fontSize: 15, fontWeight: FontWeight.w500),
                      ),
                      _Section('Что принесёт день', [
                        IconLine(Icons.favorite_border, f.love),
                        IconLine(Icons.work_outline, f.work),
                        IconLine(Icons.light_mode_outlined, f.mood),
                      ]),
                      _Section('Лучшее время', [IconLine(Icons.schedule, f.timing)]),
                      _Section('Чего сторониться', [for (final e in f.avoid) IconLine(Icons.remove, e)]),
                      _Section('К чему готовиться', [for (final e in f.prepare) IconLine(Icons.check, e)]),
                      if (f.memory != null) _Section('Волшебница помнит', [IconLine(Icons.auto_stories_outlined, f.memory!)]),
                      if (p.birthSlot == slotUnknown)
                        const Padding(
                          padding: EdgeInsets.only(top: 8),
                          child: Text(
                            'Это общий прогноз по знаку. Укажите время рождения, и он станет личным',
                            style: TextStyle(color: AW.muted, fontSize: 13),
                          ),
                        ),
                      ShareButton(content: () => shareForecast(f, sign, _now)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.05,
                  children: [
                    _Tile(
                      Icons.bedtime_outlined,
                      'Сонник',
                      () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => DreamScreen(app: app))),
                    ),
                    _Tile(
                      Icons.wb_sunny_outlined,
                      'Гороскоп',
                      () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => HoroscopeScreen(app: app))),
                    ),
                    _Tile(
                      Icons.style_outlined,
                      'Расклады',
                      () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => TarotScreen(app: app))),
                    ),
                    _Tile(
                      Icons.explore_outlined,
                      'Знаки судьбы',
                      () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => OmensScreen(app: app))),
                    ),
                    _Tile(
                      Icons.brightness_4_outlined,
                      'Луна и Солнце',
                      () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => SunMoonScreen(app: app))),
                    ),
                    _Tile(
                      Icons.numbers,
                      'Нумерология',
                      () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => NumerologyScreen(app: app))),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _Tile(
                  Icons.back_hand_outlined,
                  'Тайны ладони',
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => PalmScreen(app: app))),
                  wide: true,
                ),
                const SizedBox(height: 12),
                _Tile(
                  Icons.chat_bubble_outline,
                  'Обратная связь',
                  () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => FeedbackScreen(app: app))),
                  wide: true,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Приложение носит развлекательный характер. Не является рекомендацией для принятия важных решений.',
                  style: TextStyle(color: AW.muted, fontSize: 12),
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

  Widget _half(String label, IconData icon, String lvl, String tx) => Expanded(
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AW.navy.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: AW.muted),
              const SizedBox(width: 8),
              Expanded(child: Label(label)),
            ],
          ),
          const SizedBox(height: 8),
          Text(lvl, style: const TextStyle(fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(tx, style: const TextStyle(fontSize: 14, height: 1.4)),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      onTap: onTap,
      padding: const EdgeInsets.all(8),
      child: Column(
          children: [
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _half('Энергия Солнца', Icons.wb_sunny_outlined, sunLvl, sunTx),
                  const SizedBox(width: 8),
                  _half('Настроение Луны', Icons.bedtime_outlined, moonLvl, moonTx),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AW.navy.withValues(alpha: 0.7), borderRadius: BorderRadius.circular(8)),
              child: Row(
                children: [
                  Expanded(child: Text('Баланс дня: $balance', style: const TextStyle(fontSize: 14, height: 1.4))),
                  const SizedBox(width: 8),
                  const Icon(Icons.chevron_right, size: 18, color: AW.muted),
                ],
              ),
            ),
          ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> lines;
  const _Section(this.title, this.lines);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Label(title),
        for (final l in lines) Padding(padding: const EdgeInsets.only(top: 8), child: l),
      ],
    ),
  );
}

class _Tile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;
  final bool wide;
  const _Tile(this.icon, this.title, this.onTap, {this.wide = false});
  @override
  Widget build(BuildContext context) {
    final iconW = Icon(icon, size: 24, color: AW.soft);
    final titleW = Text(
      title,
      textAlign: TextAlign.center,
      style: const TextStyle(fontWeight: FontWeight.w500),
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
