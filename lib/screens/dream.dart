import '../data/dream_base.dart';

import 'package:flutter/material.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../logic/interpret.dart';
import '../logic/memory.dart';
import '../main.dart';
import '../logic/share_content.dart';
import '../theme.dart';
import '../widgets/share_card.dart';

/// Сонник: голос или текст → толкование по источникам + личная часть + вопрос волшебницы.
class DreamScreen extends StatefulWidget {
  final AppState app;
  const DreamScreen({super.key, required this.app});
  @override
  State<DreamScreen> createState() => _DreamScreenState();
}

class _DreamScreenState extends State<DreamScreen> {
  final _speech = SpeechToText();
  final _input = TextEditingController();
  final _answer = TextEditingController();
  bool _voice = true;
  bool _listening = false;
  String _heard = '';
  String? _voiceError;
  DreamReading? _reading;
  bool _saved = false;

  @override
  void dispose() {
    _speech.stop();
    _input.dispose();
    _answer.dispose();
    super.dispose();
  }

  Future<void> _toggleMic() async {
    if (_listening) {
      await _speech.stop();
      return;
    }
    final ok = await _speech.initialize(
      onStatus: (s) {
        if ((s == 'done' || s == 'notListening') && mounted) {
          setState(() => _listening = false);
          if (_heard.trim().isNotEmpty && _reading?.text != _heard.trim()) _interpret(_heard.trim());
        }
      },
      onError: (e) => setState(() {
        _listening = false;
        _voiceError = 'Не получилось распознать речь. Попробуйте ещё раз или напишите сон текстом.';
      }),
    );
    if (!ok) {
      setState(
        () => _voiceError = 'Нет доступа к микрофону. Разрешите его в настройках телефона или напишите сон текстом.',
      );
      return;
    }
    setState(() {
      _listening = true;
      _heard = '';
      _voiceError = null;
    });
    await _speech.listen(
      listenOptions: SpeechListenOptions(
        partialResults: true,
        localeId: 'ru_RU',
        listenFor: const Duration(minutes: 2),
        pauseFor: const Duration(seconds: 5),
      ),
      onResult: (r) => setState(() => _heard = r.recognizedWords),
    );
  }

  void _interpret(String text) {
    FocusScope.of(context).unfocus();
    setState(() {
      _reading = interpretDream(text, widget.app.profile!, DateTime.now(), widget.app.memory);
      _answer.clear();
      _saved = false;
    });
    if (_reading!.symbols.isEmpty) DreamBase.logMissed(text);
  }

  Future<void> _saveAnswer() async {
    final r = _reading;
    final a = _answer.text.trim();
    if (r == null || a.isEmpty) return;
    await widget.app.memory.add(WitchAnswer(DateTime.now(), r.symbolNames, a, 'dream'));
    setState(() => _saved = true);
  }

  @override
  Widget build(BuildContext context) {
    final r = _reading;
    return Scaffold(
      appBar: AppBar(title: const Text('Сонник'), backgroundColor: AW.navy),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          const Text('Расскажите свой сон', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w500)),
          const SizedBox(height: 12),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: true, icon: Icon(Icons.mic_none, size: 18), label: Text('Голосом')),
              ButtonSegment(value: false, icon: Icon(Icons.edit_outlined, size: 18), label: Text('Текстом')),
            ],
            selected: {_voice},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _voice = s.first),
          ),
          const SizedBox(height: 16),
          if (_voice) ...[
            Center(
              child: GestureDetector(
                onTap: _toggleMic,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: const Cubic(0.22, 1, 0.36, 1),
                  width: 96,
                  height: 96,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AW.gold,
                    // Пока идёт запись — тонкое кольцо вокруг кнопки, чтобы было видно, что микрофон слушает.
                    border: Border.all(color: _listening ? AW.ink : Colors.transparent, width: 3),
                  ),
                  child: Icon(
                    _listening ? Icons.stop_rounded : Icons.mic_rounded,
                    size: 44,
                    color: const Color(0xFF1D1504),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              _voiceError ??
                  (_listening
                      ? (_heard.isEmpty ? 'Слушаю… Расскажите сон и нажмите ещё раз, чтобы закончить' : '«$_heard»')
                      : (_heard.isEmpty ? 'Нажмите и расскажите сон своими словами' : 'Распознано: «$_heard»')),
              textAlign: TextAlign.center,
              style: TextStyle(color: _voiceError != null ? Colors.orangeAccent : AW.soft),
            ),
          ] else ...[
            TextField(
              controller: _input,
              minLines: 3,
              maxLines: 6,
              decoration: const InputDecoration(hintText: 'Например: змея, или «я летала над морем»'),
            ),
            const SizedBox(height: 12),
            FilledButton(
              onPressed: () {
                final t = _input.text.trim();
                if (t.isNotEmpty) _interpret(t);
              },
              child: const Text('Толковать сон'),
            ),
          ],
          if (r != null) ...[
            const SizedBox(height: 20),
            GlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Толкование волшебницы',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: AW.gold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '«${r.text}»',
                    style: const TextStyle(color: AW.soft),
                  ),
                  const Divider(height: 24),
                  if (r.symbols.isEmpty)
                    const Text(
                      'Этого образа пока нет в нашей базе сонников. Волшебница не будет придумывать: '
                      'попробуйте назвать главный образ сна другим словом (например, «дождь», «река», «дом»). '
                      'Мы записали этот сон и добавим символ в базу.',
                    ),
                  for (final s in r.symbols) ...[
                    Text(s.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Label('Классический сонник · ${s.source}'),
                    Text(s.classic, style: const TextStyle(height: 1.4)),
                    if (s.folk != null) ...[
                      const SizedBox(height: 8),
                      const Label('Народные приметы'),
                      Text(s.folk!, style: const TextStyle(height: 1.4)),
                    ],
                    const SizedBox(height: 16),
                  ],
                  if (r.memoryLine != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AW.gold.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: IconLine(Icons.auto_stories_outlined, r.memoryLine!),
                    ),
                  Text(r.personal, style: const TextStyle(height: 1.4)),
                  const SizedBox(height: 12),
                  const Text(sourcesNote, style: TextStyle(color: AW.soft, fontSize: 13)),
                  const SizedBox(height: 12),
                  const Text(
                    signoff,
                    style: TextStyle(color: AW.gold, fontWeight: FontWeight.w500),
                  ),
                  if (r.symbols.isNotEmpty) ShareButton(content: () => shareDream(r)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.04),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AW.hairline),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Вопрос волшебницы', style: TextStyle(fontWeight: FontWeight.w500)),
                        const SizedBox(height: 4),
                        Text(r.witchQuestion),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _answer,
                          minLines: 2,
                          maxLines: 4,
                          decoration: const InputDecoration(hintText: 'Ответьте своими словами, волшебница запомнит'),
                        ),
                        const SizedBox(height: 8),
                        FilledButton(
                          onPressed: _saved ? null : _saveAnswer,
                          child: Text(_saved ? 'Ответ сохранён' : 'Запомнить ответ'),
                        ),
                        if (_saved)
                          const Padding(
                            padding: EdgeInsets.only(top: 8),
                            child: Text(
                              'Учту это в следующих толкованиях и прогнозах.',
                              style: TextStyle(color: AW.soft),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
