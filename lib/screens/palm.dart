import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../data/palm.dart';
import '../logic/memory.dart';
import '../logic/svg_path.dart';
import '../main.dart';
import '../theme.dart';

enum PalmTab { scheme, type, photo }

/// «Тайны ладони»: схема линий, тип руки и 💎 разбор по своему фото.
/// Фото обрабатывается только на телефоне и по умолчанию удаляется при выходе.
class PalmScreen extends StatefulWidget {
  final AppState app;
  const PalmScreen({super.key, required this.app});
  @override
  State<PalmScreen> createState() => _PalmScreenState();
}

class _PalmScreenState extends State<PalmScreen> {
  PalmTab _tab = PalmTab.scheme;
  String _line = 'life';
  final Map<String, String> _answers = {};
  bool? _squarePalm, _shortFingers;
  File? _photo;
  bool _noSave = true;
  bool _savedToDiary = false;

  @override
  void dispose() {
    if (_noSave) _deletePhoto();
    super.dispose();
  }

  void _deletePhoto() {
    try {
      _photo?.deleteSync();
    } catch (_) {}
    _photo = null;
  }

  Future<void> _pick(ImageSource src) async {
    final x = await ImagePicker().pickImage(source: src, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    if (_noSave) _deletePhoto();
    setState(() => _photo = File(x.path));
  }

  Future<void> _answer(String line, String variant) async {
    setState(() => _answers[line] = variant);
    if (_answers.length == palmLines.length && !_savedToDiary) {
      _savedToDiary = true;
      final summary = palmLines
          .map((l) => '${l.name}: ${l.variants.firstWhere((v) => v.id == _answers[l.id]).label.toLowerCase()}')
          .join('; ');
      await widget.app.memory.add(WitchAnswer(DateTime.now(), ['Ладонь'], summary, 'palm'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Тайны ладони'), backgroundColor: AW.navy),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (t, label) in [
                (PalmTab.scheme, 'Схема линий'),
                (PalmTab.type, 'Тип руки'),
                (PalmTab.photo, '💎 По фото'),
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
          ...switch (_tab) {
            PalmTab.scheme => _scheme(),
            PalmTab.type => _type(),
            PalmTab.photo => _photoTab(),
          },
          const SizedBox(height: 16),
          const Text(
            'Хиромантия не имеет научного обоснования и носит развлекательный характер. Линии говорят об энергии '
            'и характере, а не о сроках жизни или здоровье.',
            style: TextStyle(color: AW.soft, fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<Widget> _questionsAndReading() {
    final l = palmLines.firstWhere((x) => x.id == _line);
    final left = palmLines.where((x) => !_answers.containsKey(x.id)).map((x) => x.name.replaceFirst('Линия ', ''));
    return [
      Text(
        left.isEmpty
            ? 'Все четыре линии прочитаны ✓ Результат сохранён в дневник.'
            : 'Нажми на линию на схеме. Осталось: ${left.join(', ')}',
        style: const TextStyle(color: AW.soft),
      ),
      const SizedBox(height: 10),
      Text(l.question, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final v in l.variants)
            ChoiceChip(
              label: Text(v.label),
              selected: _answers[l.id] == v.id,
              showCheckmark: false,
              onSelected: (_) => _answer(l.id, v.id),
            ),
        ],
      ),
      if (_answers[l.id] != null) ...[
        const SizedBox(height: 14),
        _reading(l, l.variants.firstWhere((v) => v.id == _answers[l.id])),
      ],
    ];
  }

  List<Widget> _scheme() => [
    Center(
      child: PalmScheme(selected: _line, done: _answers.keys.toSet(), onPick: (id) => setState(() => _line = id)),
    ),
    const SizedBox(height: 12),
    ..._questionsAndReading(),
  ];

  Widget _reading(PalmLine l, PalmVariant v) {
    final easy = widget.app.easy;
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${l.name}: ${v.label.toLowerCase()}',
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: AW.gold),
          ),
          const SizedBox(height: 4),
          Text(l.sphere, style: const TextStyle(color: AW.soft, fontSize: 13)),
          const SizedBox(height: 10),
          for (final (h, t) in [
            ('Что говорит традиция', easy ? v.traditionEasy : v.traditionSerious),
            ('Совет', easy ? v.adviceEasy : v.adviceSerious),
            ('А как думаете вы?', l.reflection),
          ]) ...[
            Label(h),
            const SizedBox(height: 3),
            Text(t, style: const TextStyle(height: 1.4)),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }

  List<Widget> _type() {
    Widget q(String title, bool? value, String a, String b, void Function(bool) set) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: const TextStyle(color: AW.soft)),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: Text(a),
              selected: value == true,
              showCheckmark: false,
              onSelected: (_) => setState(() => set(true)),
            ),
            ChoiceChip(
              label: Text(b),
              selected: value == false,
              showCheckmark: false,
              onSelected: (_) => setState(() => set(false)),
            ),
          ],
        ),
        const SizedBox(height: 14),
      ],
    );
    final ready = _squarePalm != null && _shortFingers != null;
    final h = ready ? handTypes[handTypeKey(squarePalm: _squarePalm!, shortFingers: _shortFingers!)]! : null;
    return [
      q(
        'Посмотри на свою ладонь (без пальцев). Она скорее:',
        _squarePalm,
        'Квадратная, ширина ≈ длине',
        'Вытянутая, длиннее, чем шире',
        (v) => _squarePalm = v,
      ),
      q(
        'А пальцы по сравнению с ладонью:',
        _shortFingers,
        'Короче ладони',
        'Почти как ладонь или длиннее',
        (v) => _shortFingers = v,
      ),
      if (h != null)
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                h[0],
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AW.gold),
              ),
              const SizedBox(height: 6),
              Text('${h[1]}${widget.app.easy ? ' ✨' : ''}', style: const TextStyle(height: 1.4)),
            ],
          ),
        ),
    ];
  }

  List<Widget> _photoTab() => [
    GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Label('Премиум · в подписке'),
          const SizedBox(height: 6),
          const Text('Как сделать фото', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          const Text(
            'Сними кольца, расслабь руку и сфотографируй раскрытую ладонь при дневном свете. '
            'Поверх фото появится схема линий: сравни её со своей ладонью и ответь на вопросы.',
            style: TextStyle(height: 1.4),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: () => _pick(ImageSource.camera),
                  icon: const Icon(Icons.photo_camera),
                  label: const Text('Камера'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                  onPressed: () => _pick(ImageSource.gallery),
                  icon: const Icon(Icons.photo_library),
                  label: const Text('Галерея'),
                ),
              ),
            ],
          ),
          InkWell(
            onTap: () => setState(() => _noSave = !_noSave),
            child: Row(
              children: [
                Checkbox(value: _noSave, onChanged: (v) => setState(() => _noSave = v ?? true)),
                const Expanded(
                  child: Text(
                    'Не сохранять фото. Оно обрабатывается только на телефоне и никуда не отправляется.',
                    style: TextStyle(fontSize: 13.5),
                  ),
                ),
              ],
            ),
          ),
          const Text('💎 В тестовой сборке открыто.', style: TextStyle(color: AW.soft, fontSize: 12.5)),
        ],
      ),
    ),
    if (_photo != null) ...[
      const SizedBox(height: 14),
      ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Image.file(_photo!, height: 330, width: double.infinity, fit: BoxFit.cover),
            PalmScheme(
              selected: _line,
              done: _answers.keys.toSet(),
              onPick: (id) => setState(() => _line = id),
              showHand: false,
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      ..._questionsAndReading(),
    ],
  ];
}

/// Схема ладони с четырьмя линиями; по линии можно нажать.
class PalmScheme extends StatelessWidget {
  final String selected;
  final Set<String> done;
  final ValueChanged<String> onPick;
  final bool showHand;
  const PalmScheme({super.key, required this.selected, required this.done, required this.onPick, this.showHand = true});

  static const _w = 220.0, _h = 270.0;
  static final _hand = parseSvgPath(handPath);
  static final _lines = {for (final l in palmLines) l.id: parseSvgPath(l.path)};
  static final _samples = {for (final e in _lines.entries) e.key: samplePath(e.value)};

  @override
  Widget build(BuildContext context) {
    const scale = 1.2;
    return GestureDetector(
      onTapUp: (d) {
        final p = d.localPosition / scale;
        String? best;
        var bestD = 22.0;
        _samples.forEach((id, pts) {
          for (final q in pts) {
            final dist = (q - p).distance;
            if (dist < bestD) {
              bestD = dist;
              best = id;
            }
          }
        });
        if (best != null) onPick(best!);
      },
      child: CustomPaint(
        size: const Size(_w * scale, _h * scale),
        painter: _PalmPainter(selected, done, showHand, scale),
      ),
    );
  }
}

class _PalmPainter extends CustomPainter {
  final String selected;
  final Set<String> done;
  final bool showHand;
  final double scale;
  _PalmPainter(this.selected, this.done, this.showHand, this.scale);

  @override
  void paint(Canvas canvas, Size size) {
    canvas.scale(scale);
    if (showHand) {
      canvas.drawPath(PalmScheme._hand, Paint()..color = const Color(0x33A9C8FF));
      canvas.drawPath(
        PalmScheme._hand,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5
          ..color = const Color(0x88A9C8FF),
      );
    }
    for (final e in PalmScheme._lines.entries) {
      final on = e.key == selected;
      final color = on ? AW.gold : (done.contains(e.key) ? const Color(0xFF8FE3B0) : const Color(0xCCEAF0FF));
      if (on) {
        canvas.drawPath(
          e.value,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = 9
            ..strokeCap = StrokeCap.round
            ..color = AW.gold.withValues(alpha: 0.25),
        );
      }
      canvas.drawPath(
        e.value,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = on ? 4 : 3
          ..strokeCap = StrokeCap.round
          ..color = color,
      );
    }
  }

  @override
  bool shouldRepaint(_PalmPainter old) => old.selected != selected || old.done.length != done.length;
}
