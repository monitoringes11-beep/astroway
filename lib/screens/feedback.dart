import 'package:flutter/material.dart';

import '../data/dream_base.dart';
import '../logic/feedback_sender.dart';
import '../main.dart';
import '../theme.dart';

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

/// Поля письма. Имя и дата рождения не отправляются, только то, что человек выбрал и написал.
Map<String, String> feedbackFields({
  required String? mood,
  required Set<String> kinds,
  required Set<String> sections,
  required String text,
  List<String> missed = const [],
}) => {
  'Оценка': ?mood,
  if (kinds.isNotEmpty) 'Тип': kinds.join(', '),
  if (sections.isNotEmpty) 'Раздел': sections.join(', '),
  if (text.trim().isNotEmpty) 'Отзыв': text.trim(),
  if (missed.isNotEmpty) 'Не нашлось в соннике': missed.join('; '),
  'Версия': 'AstroWay 1.0',
};

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

  bool _sending = false;

  Future<void> _send() async {
    setState(() => _sending = true);
    final ok = await FeedbackSender.send(
      feedbackFields(
        mood: _mood,
        kinds: _kinds,
        sections: _sections,
        text: _text.text,
        missed: _withMissed ? _missed : const [],
      ),
    );
    if (!mounted) return;
    setState(() {
      _sending = false;
      _text.clear();
      _mood = null;
      _kinds.clear();
      _sections.clear();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          ok
              ? 'Спасибо! Отзыв отправлен.'
              : 'Сейчас нет связи. Отзыв сохранён и отправится сам, когда появится интернет.',
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
          FilledButton(
            onPressed: _ready && !_sending ? _send : null,
            child: Text(_sending ? 'Отправляю…' : 'Отправить отзыв'),
          ),
          const SizedBox(height: 10),
          const Text(
            'Отзыв уйдёт прямо из приложения. Имя и дата рождения не отправляются.',
            style: TextStyle(color: AW.soft, fontSize: 12.5),
          ),
        ],
      ),
    );
  }
}
