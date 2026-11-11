import 'package:flutter/material.dart';

import '../data/numerology_texts.dart';
import '../logic/numerology.dart';
import '../logic/profile.dart';
import '../main.dart';
import '../theme.dart';

enum NumTab { life, name, day, year, comp }

/// Нумерология: моё число, число имени, число дня, личный год, совместимость (💎).
class NumerologyScreen extends StatefulWidget {
  final AppState app;
  const NumerologyScreen({super.key, required this.app});
  @override
  State<NumerologyScreen> createState() => _NumerologyScreenState();
}

class _NumerologyScreenState extends State<NumerologyScreen> {
  NumTab _tab = NumTab.life;
  String _sphere = 'general';
  DateTime _partner = DateTime(1988, 7, 14);

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

  String _date(DateTime d) => '${d.day} ${_months[d.month - 1]} ${d.year}';

  @override
  Widget build(BuildContext context) {
    final p = widget.app.profile!;
    final easy = widget.app.easy;
    final female = p.gender == Gender.unspecified ? null : p.isFemale;
    final now = DateTime.now();

    late NumResult r;
    late String head, text, when;
    String? title;
    switch (_tab) {
      case NumTab.life:
        r = lifePath(p.birthday);
        head = 'Число жизненного пути';
        text = numMeanings[r.n]![2];
        when = 'Считается из полной даты рождения. Главное число, оно не меняется.';
      case NumTab.name:
        r = nameNumber(p.name, p.birthday);
        head = 'Число имени «${p.name}»';
        text = 'Как тебя видят люди: ${numMeanings[r.n]![1]}. ${numMeanings[r.n]![2]}';
        when = 'Каждая буква имеет число (А=1, Б=2 … по кругу до 9).';
      case NumTab.day:
        r = dayNumber(p.birthday, now);
        head = 'Число дня: ${now.day} ${_months[now.month - 1]}';
        text = dayTexts[r.n]!;
        when = 'Меняется каждый день и зависит от твоего числа жизненного пути.';
      case NumTab.year:
        r = personalYear(p.birthday, now.year);
        head = 'Личный год ${now.year}';
        text = '${yearTexts[r.n]} ${numMeanings[r.n]![2]}';
        when = 'День и месяц рождения + текущий год. Обновляется в день рождения.';
      case NumTab.comp:
        final c = numCompatibility(p.birthday, _partner);
        r = NumResult(0, ['ты: ${c.a}', 'партнёр: ${c.b}']);
        title = '${c.a} + ${c.b}';
        head = c.level;
        text = c.text;
        when = 'Сравниваются числа жизненного пути. 💎 В магазине будет по подписке, в тестовой сборке открыто.';
    }
    if (_tab != NumTab.comp) {
      text = sphereText(r.n, _sphere, text, easy: easy);
      if (_sphere != 'general') head += ' · ${_sphereNames[_sphere]}';
    }
    text = genderize(text, female);
    final big = title ?? '${r.n}';

    return Scaffold(
      appBar: AppBar(title: const Text('Нумерология'), backgroundColor: AW.navy),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (t, label) in [
                (NumTab.life, 'Моё число'),
                (NumTab.name, 'Число имени'),
                (NumTab.day, 'Число дня'),
                (NumTab.year, 'Личный год'),
                (NumTab.comp, '💎 Совместимость'),
              ])
                ChoiceChip(
                  label: Text(label),
                  selected: _tab == t,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _tab = t),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (_tab != NumTab.comp)
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final e in _sphereNames.entries)
                  ChoiceChip(
                    label: Text(e.value, style: const TextStyle(fontSize: 13)),
                    selected: _sphere == e.key,
                    showCheckmark: false,
                    visualDensity: VisualDensity.compact,
                    onSelected: (_) => setState(() => _sphere = e.key),
                  ),
              ],
            ),
          if (_tab == NumTab.comp) ...[
            const Text('Дата рождения партнёра или подруги', style: TextStyle(color: AW.soft)),
            const SizedBox(height: 6),
            OutlinedButton.icon(
              icon: const Icon(Icons.calendar_month),
              label: Text(_date(_partner)),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _partner,
                  firstDate: DateTime(1920),
                  lastDate: DateTime.now(),
                  locale: const Locale('ru'),
                );
                if (d != null) setState(() => _partner = d);
              },
            ),
          ],
          const SizedBox(height: 16),
          _Calc(
            key: ValueKey('$_tab$big$_partner'),
            steps: r.steps,
            big: big,
            name: title == null ? '${numMeanings[r.n]![0]} · ${numMeanings[r.n]![1]}' : '',
          ),
          const SizedBox(height: 16),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  head,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AW.gold),
                ),
                const SizedBox(height: 8),
                Text(text, style: const TextStyle(height: 1.45)),
                const SizedBox(height: 10),
                Text(when, style: const TextStyle(color: AW.soft, fontSize: 12.5)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Нумерология носит развлекательный характер и не является точной наукой. Имя считаем по кириллической '
            'таблице AstroWay: А=1, Б=2 … И=1 и далее по кругу до 9 (Ё, Й, Ъ, Ь тоже считаются). Другие калькуляторы '
            'могут дать другой результат.',
            style: TextStyle(color: AW.soft, fontSize: 12),
          ),
        ],
      ),
    );
  }

  static const _sphereNames = {'general': 'Общее', 'love': 'Любовь', 'money': 'Деньги и карьера', 'health': 'Здоровье'};
}

/// Цепочка расчёта появляется по шагам, затем «выплывает» большое число.
class _Calc extends StatelessWidget {
  final List<String> steps;
  final String big, name;
  const _Calc({super.key, required this.steps, required this.big, required this.name});

  @override
  Widget build(BuildContext context) {
    final total = steps.length * 350 + 700;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: total),
      builder: (context, v, _) {
        final ms = v * total;
        final bigT = ((ms - steps.length * 350) / 700).clamp(0.0, 1.0);
        return Column(
          children: [
            Wrap(
              alignment: WrapAlignment.center,
              children: [
                for (var i = 0; i < steps.length; i++)
                  Opacity(
                    opacity: ((ms - i * 350) / 350).clamp(0.0, 1.0),
                    child: Text(
                      '${i > 0 ? ' → ' : ''}${steps[i]}',
                      style: const TextStyle(color: AW.soft, fontSize: 13.5),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Opacity(
              opacity: bigT,
              child: Transform.scale(
                scale: 0.6 + 0.4 * Curves.easeOutBack.transform(bigT),
                child: Text(
                  big,
                  style: const TextStyle(
                    fontSize: 64,
                    fontWeight: FontWeight.w800,
                    color: AW.gold,
                    shadows: [Shadow(color: Color(0x88F3C96B), blurRadius: 24)],
                  ),
                ),
              ),
            ),
            if (name.isNotEmpty)
              Text(
                name,
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
          ],
        );
      },
    );
  }
}
