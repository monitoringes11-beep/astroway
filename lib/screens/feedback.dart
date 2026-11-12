import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/dream_base.dart';
import '../main.dart';
import '../theme.dart';

/// Адрес, куда приходят отзывы. Пустой: почтовое приложение откроется без получателя.
const feedbackEmail = '';

const feedbackKinds = ['💛 Нравится', '😕 Не нравится', '✨ Не хватает', '🐞 Ошибка'];
const feedbackSections = [
  'Главный экран',
  'Прогноз дня',
  'Сонник',
  'Гороскоп',
  'Расклады',
  'Знаки судьбы',
  'Луна и Солнце',
  'Нумерология',
  'Тайны ладони',
  'Профили и вход',
  'Другое',
];
const feedbackMoods = ['😍', '🙂', '😐', '🙁'];

/// Собирает письмо. Имя и дата рождения не отправляются, только то, что человек выбрал и написал.
String feedbackBody({
  required String? mood,
  required Set<String> kinds,
  required Set<String> sections,
  required String text,
  List<String> missed = const [],
}) {
  final b = StringBuffer();
  if (mood != null) b.writeln('Оценка: $mood');
  if (kinds.isNotEmpty) b.writeln('Тип: ${kinds.join(', ')}');
  if (sections.isNotEmpty) b.writeln('Раздел: ${sections.join(', ')}');
  b.writeln();
  b.writeln(text.trim());
  if (missed.isNotEmpty) {
    b.writeln();
    b.writeln('Слова, которых не нашлось в соннике: ${missed.join('; ')}');
  }
  b.writeln();
  b.writeln('AstroWay 1.0');
  return b.toString();
}

class FeedbackScreen extends StatefulWidget {
  final AppState app;
  const FeedbackScreen({super.key, required this.app});
  @override
  State<FeedbackScreen> createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  final _text = TextEditingController();
  String? _mood;
  final _kinds = <String>{};
  final _sections = <String>{};
  bool _withMissed = true;
  List<String> _missed = [];

  @override
  void initState() {
    super.initState();
    DreamBase.missed().then((m) {
      if (mounted) setState(() => _missed = m.reversed.take(20).toList());
    });
  }

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  bool get _ready => _text.text.trim().isNotEmpty || _mood != null;

  Future<void> _send() async {
    final body = feedbackBody(
      mood: _mood,
      kinds: _kinds,
      sections: _sections,
      text: _text.text,
      missed: _withMissed ? _missed : const [],
    );
    final uri = Uri(
      scheme: 'mailto',
      path: feedbackEmail,
      query: 'subject=${Uri.encodeComponent('AstroWay: отзыв')}&body=${Uri.encodeComponent(body)}',
    );
    final ok = await launchUrl(uri);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok ? 'Спасибо! Осталось нажать «Отправить» в почте.' : 'Не нашлось почтового приложения на телефоне.',
        ),
      ),
    );
  }

  Widget _chips(List<String> items, Set<String> selected) => Wrap(
    spacing: 8,
    runSpacing: 8,
    children: [
      for (final k in items)
        FilterChip(
          label: Text(k),
          selected: selected.contains(k),
          showCheckmark: false,
          onSelected: (v) => setState(() => v ? selected.add(k) : selected.remove(k)),
        ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Обратная связь'), backgroundColor: AW.navy),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          const Text(
            'Расскажи, что нравится, чего не хватает и что мешает. Мы читаем каждый отзыв и по ним дополняем приложение.',
            style: TextStyle(height: 1.4),
          ),
          const SizedBox(height: 16),
          const Label('Как тебе AstroWay?'),
          const SizedBox(height: 6),
          Row(
            children: [
              for (final m in feedbackMoods)
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(m, style: const TextStyle(fontSize: 24)),
                    selected: _mood == m,
                    showCheckmark: false,
                    onSelected: (v) => setState(() => _mood = v ? m : null),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          const Label('О чём отзыв'),
          const SizedBox(height: 6),
          _chips(feedbackKinds, _kinds),
          const SizedBox(height: 16),
          const Label('Какой раздел'),
          const SizedBox(height: 6),
          _chips(feedbackSections, _sections),
          const SizedBox(height: 16),
          TextField(
            controller: _text,
            minLines: 4,
            maxLines: 10,
            maxLength: 2000,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(
              hintText: 'Например: хочу расклад на отношения, а в соннике не нашлось слова «вокзал»',
            ),
          ),
          if (_missed.isNotEmpty) ...[
            Material(
              type: MaterialType.transparency,
              child: InkWell(
                onTap: () => setState(() => _withMissed = !_withMissed),
                child: Row(
                  children: [
                    Checkbox(value: _withMissed, onChanged: (v) => setState(() => _withMissed = v ?? false)),
                    Expanded(
                      child: Text(
                        'Добавить слова, которых не нашлось в соннике (${_missed.length})',
                        style: const TextStyle(color: AW.soft),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(onPressed: _ready ? _send : null, child: const Text('Отправить отзыв')),
          const SizedBox(height: 10),
          const Text(
            'Откроется почта с готовым письмом. Имя и дата рождения не отправляются.',
            style: TextStyle(color: AW.soft, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
