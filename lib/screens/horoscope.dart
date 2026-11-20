import 'package:flutter/material.dart';

import '../logic/daily.dart';
import '../logic/horoscope.dart';
import '../logic/zodiac.dart';
import '../main.dart';
import '../theme.dart';

enum HoroTab { today, week, east, comp }

/// Гороскоп: на сегодня, на неделю, восточный, совместимость (по подписке).
class HoroscopeScreen extends StatefulWidget {
  final AppState app;
  const HoroscopeScreen({super.key, required this.app});
  @override
  State<HoroscopeScreen> createState() => _HoroscopeScreenState();
}

class _HoroscopeScreenState extends State<HoroscopeScreen> {
  HoroTab _tab = HoroTab.today;
  late final int _own = signIndexOf(widget.app.profile!.birthday.month, widget.app.profile!.birthday.day);
  late int _sign = _own;
  late int _partner = (_own + 4) % 12;

  static const _months = [
    'января',
    'февраля',
    'марта',
    'апреля',
    'мая',
    'июня',
    'июля',
    'августа',
    'сентября',
    'октября',
    'ноября',
    'декабря',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Гороскоп'), backgroundColor: AW.navy),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (t, label) in [
                (HoroTab.today, 'На сегодня'),
                (HoroTab.week, 'На неделю'),
                (HoroTab.east, 'Восточный'),
                (HoroTab.comp, 'Совместимость'),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: _tab == t,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _tab = t),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_tab != HoroTab.east) ...[
            Text(
              _tab == HoroTab.comp
                  ? 'Выберите знак партнёра'
                  : _sign == _own
                  ? 'Ваш знак. Нажмите другой, чтобы посмотреть его прогноз'
                  : 'Прогноз для знака ${signs[_sign].name}',
              style: const TextStyle(color: AW.soft),
            ),
            const SizedBox(height: 8),
            _wheel(_tab == HoroTab.comp ? _partner : _sign, (i) {
              setState(() => _tab == HoroTab.comp ? _partner = i : _sign = i);
            }),
            const SizedBox(height: 16),
          ],
          switch (_tab) {
            HoroTab.today => _forecast(week: false),
            HoroTab.week => _forecast(week: true),
            HoroTab.east => _east(),
            HoroTab.comp => _comp(),
          },
          const SizedBox(height: 16),
          const Text(
            'Гороскоп носит развлекательный характер и не заменяет советов специалистов.',
            style: TextStyle(color: AW.soft, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _wheel(int selected, ValueChanged<int> onPick) => GridView.count(
    crossAxisCount: 4,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 8,
    crossAxisSpacing: 8,
    childAspectRatio: 1.25,
    children: [
      for (var i = 0; i < 12; i++)
        Material(
          color: i == selected ? AW.gold.withValues(alpha: 0.16) : Colors.white.withValues(alpha: 0.04),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: i == selected ? AW.gold : AW.hairline),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => onPick(i),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(signs[i].symbol, style: const TextStyle(fontSize: 22)),
                Text(signs[i].name, style: const TextStyle(fontSize: 12), overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ),
    ],
  );

  Widget _forecast({required bool week}) {
    final now = DateTime.now();
    final h = horoscopeFor(_sign, now, week: week, easy: widget.app.easy);
    final z = signs[_sign];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${z.symbol} ${z.name} · ${week ? 'неделя' : '${now.day} ${_months[now.month - 1]}'}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AW.gold),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Text(h.mood, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w500)),
              _tag(h.energy),
            ],
          ),
          const SizedBox(height: 12),
          if (week) ...[
            Text(h.general, style: const TextStyle(height: 1.4)),
            const Divider(height: 24),
            _sphere(Icons.favorite_border, 'Любовь', h.love),
            _sphere(Icons.payments_outlined, 'Деньги и карьера', h.money),
            _sphere(Icons.spa_outlined, 'Здоровье и энергия', h.health),
          ] else
            for (final (title, text) in dailyHoroscope(_sign, now, easy: widget.app.easy)) ...[
              Text(
                title,
                style: const TextStyle(fontWeight: FontWeight.w500, color: AW.soft, fontSize: 15),
              ),
              const SizedBox(height: 4),
              Text(text, style: const TextStyle(height: 1.45)),
              const SizedBox(height: 16),
            ],
          if (h.week != null) ...[
            Text(h.week!.join(' · '), style: const TextStyle(color: AW.soft, height: 1.4)),
            const SizedBox(height: 12),
          ],
          _advice('${week ? 'Совет недели' : 'Совет дня'}: ${h.advice}'),
          const SizedBox(height: 12),
          _luck([
            'Стихия: ${elements[_sign % 4]}',
            'Числа: ${h.numbers.join(', ')}',
            'Цвет: ${h.color}',
          ]),
        ],
      ),
    );
  }

  Widget _east() {
    final b = widget.app.profile!.birthday;
    final a = eastIndexOf(b);
    final animal = eastAnimals[a];
    final z = signs[_own];
    final easy = widget.app.easy;
    final key = '${animal[0]}${dayKey(DateTime.now())}';
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${z.name} + ${animal[0]}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AW.gold),
          ),
          const SizedBox(height: 12),
          Text(
            '${easy ? 'Яркое сочетание. ' : ''}В вас соединяются черты знака ${z.name} и восточного знака '
            '${animal[0]}: ${animal[1]}. Это сочетание даёт умение видеть цель и находить к ней свой путь, '
            'не теряя тепла к людям.',
            style: const TextStyle(height: 1.4),
          ),
          const SizedBox(height: 12),
          Text(
            'Лучше ладит с людьми года ${eastBestWith(a).join(' и ')}. С остальными знаками отношения строятся '
            'через терпение и уважение к различиям.',
            style: const TextStyle(height: 1.4),
          ),
          const SizedBox(height: 12),
          _luck([
            'Год рождения: ${b.year}${beforeEastNewYear(b) ? ' (до восточного Нового года)' : ''}',
            'Числа: ${[for (var i = 1; i <= 3; i++) stableHash('$key$i') % 40 + 1].join(', ')}',
            'Цвет дня: ${pick(luckyColors, key)}',
          ]),
        ],
      ),
    );
  }

  Widget _comp() {
    final c = compatibility(_own, _partner);
    final a = signs[_own], b = signs[_partner];
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${a.symbol} ${a.name} + ${b.symbol} ${b.name}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w500, color: AW.gold),
          ),
          const SizedBox(height: 12),
          _advice(c.level),
          const SizedBox(height: 12),
          Text(c.text, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 12),
          const Text(
            'Подробная совместимость входит в подписку. В тестовой сборке открыта.',
            style: TextStyle(color: AW.muted, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _tag(String t) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: AW.hairline),
    ),
    child: Text(t, style: const TextStyle(fontSize: 13, color: AW.soft)),
  );

  Widget _sphere(IconData icon, String name, String text) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: Icon(icon, size: 18, color: AW.muted),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name, style: const TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(text, style: const TextStyle(height: 1.4)),
            ],
          ),
        ),
      ],
    ),
  );

  Widget _advice(String t) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(color: AW.gold.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(8)),
    child: Text(t, style: const TextStyle(height: 1.4, fontWeight: FontWeight.w500)),
  );

  Widget _luck(List<String> items) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final s in items)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.06),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(s, style: const TextStyle(fontSize: 13)),
        ),
    ],
  );
}
