import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../data/omens.dart';
import '../logic/daily.dart';
import '../logic/memory.dart';
import '../logic/profile.dart';
import '../main.dart';
import '../theme.dart';

/// Знаки судьбы: «Знак дня» (задание) и «Словарь» с поиском, фильтрами и голосом.
class OmensScreen extends StatefulWidget {
  final AppState app;
  const OmensScreen({super.key, required this.app});
  @override
  State<OmensScreen> createState() => _OmensScreenState();
}

class _OmensScreenState extends State<OmensScreen> {
  final _speech = SpeechToText();
  final _query = TextEditingController();
  bool _dict = false;
  bool? _met; // null — ещё не отметили
  String _polarity = '', _sphere = '';
  String? _selected;
  bool _listening = false;
  String? _voiceHint;

  @override
  void dispose() {
    _speech.stop();
    _query.dispose();
    super.dispose();
  }

  bool get _male => widget.app.profile?.gender == Gender.male;

  Future<void> _mic() async {
    if (_listening) {
      await _speech.stop();
      return;
    }
    final ok = await _speech.initialize(
      onStatus: (s) {
        if ((s == 'done' || s == 'notListening') && mounted) {
          setState(() {
            _listening = false;
            _voiceHint = null;
          });
        }
      },
      onError: (e) => setState(() {
        _listening = false;
        _voiceHint = 'Не получилось распознать. Попробуй ещё раз или напиши текстом.';
      }),
    );
    if (!ok) {
      setState(() => _voiceHint = 'Нет доступа к микрофону. Разреши его в настройках или напиши текстом.');
      return;
    }
    setState(() {
      _listening = true;
      _voiceHint = 'Слушаю… Расскажи, что случилось';
    });
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        partialResults: true,
        localeId: 'ru_RU',
        listenFor: const Duration(seconds: 30),
        pauseFor: const Duration(seconds: 3),
      ),
      onResult: (r) => setState(() {
        _query.text = r.recognizedWords;
        _selected = null;
      }),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Знаки судьбы'), backgroundColor: AW.navy),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Знак дня')),
              ButtonSegment(value: true, label: Text('Словарь')),
            ],
            selected: {_dict},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _dict = s.first),
          ),
          const SizedBox(height: 16),
          if (!_dict) ..._day() else ..._dictionary(),
          const SizedBox(height: 16),
          const Text(
            'Знаки и приметы — часть народной культуры и носят развлекательный характер. '
            'Это повод присмотреться к себе, а не предсказание.',
            style: TextStyle(color: AW.soft, fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<Widget> _day() {
    final t = omenTaskFor(dayKey(DateTime.now()), stableHash);
    return [
      GlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Label('Задание на сегодня'),
            const SizedBox(height: 6),
            Text(t[0], style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(t[1], style: const TextStyle(color: AW.soft)),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    onPressed: () => setState(() => _met = true),
                    child: Text(_male ? 'Встретил знак' : 'Встретила знак'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    onPressed: () => setState(() => _met = false),
                    child: Text(_male ? 'Не встретил' : 'Не встретила'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      if (_met == true) _OmenCard(omen: omens.firstWhere((o) => o.id == t[2]), app: widget.app),
      if (_met == false)
        const GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Знак не встретился',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AW.gold),
              ),
              SizedBox(height: 6),
              Text(
                'Это тоже ответ: сегодня день без подсказок, а значит, решения в ваших руках. '
                'Завтра будет новое задание.',
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _dictionary() {
    final res = searchOmens(_query.text, polarity: _polarity, sphere: _sphere);
    final sel = res.where((o) => o.id == _selected).firstOrNull;
    return [
      Row(
        children: [
          Expanded(
            child: TextField(
              controller: _query,
              decoration: const InputDecoration(hintText: 'Что случилось? Например: соль, птица, ладонь'),
              onChanged: (_) => setState(() => _selected = null),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            iconSize: 26,
            onPressed: _mic,
            icon: Icon(_listening ? Icons.stop : Icons.mic),
            tooltip: 'Сказать голосом',
          ),
        ],
      ),
      if (_voiceHint != null)
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(_voiceHint!, style: const TextStyle(color: AW.soft, fontSize: 13)),
        ),
      const SizedBox(height: 10),
      _chips(
        {'': 'Все', 'good': '☀ Добрые', 'warning': '⚠ Предупреждение', 'neutral': '◯ Нейтральные'},
        _polarity,
        (v) => _polarity = v,
      ),
      const SizedBox(height: 6),
      _chips(
        {
          '': 'Все сферы',
          'love': '💞 Любовь',
          'money': '💰 Деньги',
          'road': '🛤 Дорога',
          'home': '🏠 Дом',
          'decision': '🧭 Решения',
        },
        _sphere,
        (v) => _sphere = v,
      ),
      const SizedBox(height: 12),
      if (res.isEmpty)
        const Text(
          'Такого знака пока нет в словаре. Попробуй описать другими словами.',
          style: TextStyle(color: AW.soft),
        ),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final o in res)
            ChoiceChip(
              label: Text(o.name),
              selected: o.id == _selected,
              showCheckmark: false,
              onSelected: (_) => setState(() => _selected = o.id),
            ),
        ],
      ),
      if (sel != null) ...[const SizedBox(height: 14), _OmenCard(key: ValueKey(sel.id), omen: sel, app: widget.app)],
    ];
  }

  Widget _chips(Map<String, String> items, String value, void Function(String) set) => Wrap(
    spacing: 6,
    runSpacing: 6,
    children: [
      for (final e in items.entries)
        ChoiceChip(
          label: Text(e.value, style: const TextStyle(fontSize: 13)),
          selected: value == e.key,
          showCheckmark: false,
          visualDensity: VisualDensity.compact,
          onSelected: (_) => setState(() {
            set(e.key);
            _selected = null;
          }),
        ),
    ],
  );
}

/// Карточка знака в три слоя: что говорит примета, подсказка, вопрос к себе + своя трактовка в дневник.
class _OmenCard extends StatefulWidget {
  final Omen omen;
  final AppState app;
  const _OmenCard({super.key, required this.omen, required this.app});
  @override
  State<_OmenCard> createState() => _OmenCardState();
}

class _OmenCardState extends State<_OmenCard> {
  final _note = TextEditingController();
  bool _saved = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final o = widget.omen;
    final easy = widget.app.easy;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            o.name,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AW.gold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final t in [
                polarityLabels[o.polarity]!,
                ...o.spheres.map((s) => sphereLabels[s]!),
                'традиция: ${o.tradition}',
              ])
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.07),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(t, style: const TextStyle(fontSize: 12.5)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          for (final (h, t) in [
            ('Что говорит примета', easy ? o.literalEasy : o.literalSerious),
            ('Подсказка', easy ? o.adviceEasy : o.adviceSerious),
            ('А как думаете вы?', o.reflection),
          ]) ...[
            Label(h),
            const SizedBox(height: 3),
            Text(t, style: const TextStyle(height: 1.4)),
            const SizedBox(height: 10),
          ],
          TextField(
            controller: _note,
            minLines: 2,
            maxLines: 4,
            decoration: const InputDecoration(hintText: 'Запишите свою трактовку, волшебница её запомнит'),
          ),
          const SizedBox(height: 8),
          OutlinedButton(
            onPressed: _saved
                ? null
                : () async {
                    final text = _note.text.trim();
                    if (text.isEmpty) return;
                    await widget.app.memory.add(WitchAnswer(DateTime.now(), [o.name], text, 'omen'));
                    setState(() => _saved = true);
                  },
            child: Text(_saved ? '★ Сохранено в дневник' : '☆ В дневник'),
          ),
        ],
      ),
    );
  }
}
