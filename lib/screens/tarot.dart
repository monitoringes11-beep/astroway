import 'dart:math';

import 'package:flutter/material.dart';

import '../logic/tarot.dart';
import '../main.dart';
import '../theme.dart';

/// Расклады Таро: карта дня и «Прошлое, настоящее, будущее» на старших арканах.
class TarotScreen extends StatefulWidget {
  final AppState app;
  final Random? random; // для тестов
  const TarotScreen({super.key, required this.app, this.random});
  @override
  State<TarotScreen> createState() => _TarotScreenState();
}

class _TarotScreenState extends State<TarotScreen> {
  bool _three = false;
  bool _dayOpen = false;
  final _question = TextEditingController();
  List<DrawnCard>? _spread;
  int _opened = 0; // сколько карт расклада уже перевёрнуто
  int _deal = 0;

  @override
  void dispose() {
    _question.dispose();
    super.dispose();
  }

  Future<void> _draw() async {
    FocusScope.of(context).unfocus();
    final deal = ++_deal;
    setState(() {
      _spread = drawThree(widget.random);
      _opened = 0;
    });
    for (var i = 1; i <= 3; i++) {
      await Future.delayed(const Duration(milliseconds: 550));
      if (!mounted || deal != _deal) return;
      setState(() => _opened = i);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Расклады'), backgroundColor: AW.navy),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Карта дня')),
              ButtonSegment(value: true, label: Text('3 карты')),
            ],
            selected: {_three},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _three = s.first),
          ),
          const SizedBox(height: 18),
          if (!_three) ..._day() else ..._spreadView(),
          const SizedBox(height: 16),
          const Text(
            'Старшие арканы, классические значения. Расклад — подсказка, а не приговор. Развлекательный характер.',
            style: TextStyle(color: AW.soft, fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<Widget> _day() {
    final p = widget.app.profile!;
    final c = cardOfDay(p.name, DateTime.now());
    return [
      Center(
        child: GestureDetector(
          onTap: () => setState(() => _dayOpen = true),
          child: TarotCard(card: c, open: _dayOpen, width: 150),
        ),
      ),
      const SizedBox(height: 12),
      if (!_dayOpen)
        const Center(
          child: Text('Нажми на карту, чтобы открыть', style: TextStyle(color: AW.soft)),
        )
      else
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Карта дня: ${c.name}',
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AW.gold),
              ),
              const SizedBox(height: 8),
              Text('${p.name}, сегодня с тобой ${c.name}: ${c.upright}.', style: const TextStyle(height: 1.4)),
              const SizedBox(height: 8),
              const Text(
                'Карта одна на весь день. Завтра будет новая.',
                style: TextStyle(color: AW.soft, fontSize: 12.5),
              ),
            ],
          ),
        ),
    ];
  }

  List<Widget> _spreadView() {
    final s = _spread;
    final name = widget.app.profile!.name;
    final q = _question.text.trim();
    return [
      const Text('Загадай вопрос (можно не писать, а просто подумать о нём)', style: TextStyle(color: AW.soft)),
      const SizedBox(height: 6),
      TextField(
        controller: _question,
        decoration: const InputDecoration(hintText: 'Например: что ждёт меня в работе?'),
      ),
      const SizedBox(height: 16),
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          for (var i = 0; i < 3; i++)
            Column(
              children: [
                TarotCard(
                  key: ValueKey('$_deal-$i'),
                  card: s?[i].card,
                  open: s != null && _opened > i,
                  reversed: s?[i].reversed ?? false,
                  width: 96,
                ),
                const SizedBox(height: 6),
                Text(spreadPositions[i], style: const TextStyle(color: AW.soft, fontSize: 13)),
              ],
            ),
        ],
      ),
      const SizedBox(height: 16),
      FilledButton(onPressed: _draw, child: Text(s == null ? 'Разложить карты' : 'Разложить заново')),
      if (s != null && _opened == 3) ...[
        const SizedBox(height: 16),
        GlassCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Толкование волшебницы',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AW.gold),
              ),
              const SizedBox(height: 8),
              Text(
                q.isEmpty ? '$name, вот что показали карты.' : '$name, твой вопрос: «$q».',
                style: const TextStyle(height: 1.4),
              ),
              const SizedBox(height: 8),
              for (var i = 0; i < 3; i++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: '${spreadPositions[i]}: ${s[i].card.name}${s[i].reversed ? ' (перевёрнутая)' : ''}. ',
                          style: const TextStyle(fontWeight: FontWeight.w700, color: AW.gold),
                        ),
                        TextSpan(text: '${capitalize(s[i].meaning)}.'),
                      ],
                    ),
                    style: const TextStyle(height: 1.4),
                  ),
                ),
              Text(
                'Совет волшебницы: опирайся на карту «${s[1].card.name}», она показывает, на чём сейчас твоя сила.',
                style: const TextStyle(height: 1.4, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
      ],
    ];
  }
}

/// Карта Таро с переворотом: рубашка → лицо (номер аркана и название).
class TarotCard extends StatelessWidget {
  final Arcana? card;
  final bool open, reversed;
  final double width;
  const TarotCard({super.key, required this.card, required this.open, this.reversed = false, this.width = 100});

  @override
  Widget build(BuildContext context) {
    final h = width * 1.6;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: open ? 1 : 0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      builder: (context, v, _) {
        final showFace = v >= 0.5 && card != null;
        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateY(pi * v),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..rotateY(showFace ? pi : 0),
            child: Container(
              width: width,
              height: h,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(width * 0.1),
                border: Border.all(color: AW.gold.withValues(alpha: 0.8), width: 1.5),
                boxShadow: const [BoxShadow(color: Colors.black45, blurRadius: 14, offset: Offset(0, 6))],
                gradient: showFace
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFF6E3B0), Color(0xFFD9A949)],
                      )
                    : const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF1B2A5E), Color(0xFF0B1430)],
                      ),
              ),
              child: showFace
                  ? RotatedBox(
                      quarterTurns: reversed ? 2 : 0,
                      child: Padding(
                        padding: EdgeInsets.all(width * 0.08),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              card!.numeral,
                              style: TextStyle(
                                color: const Color(0xFF2A1D05),
                                fontWeight: FontWeight.w800,
                                fontSize: width * 0.18,
                              ),
                            ),
                            Text(
                              '✦',
                              style: TextStyle(color: const Color(0xFF6B4A0E), fontSize: width * 0.3),
                            ),
                            Text(
                              card!.name,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: const Color(0xFF2A1D05),
                                fontWeight: FontWeight.w700,
                                fontSize: width * 0.12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Center(
                      child: Text(
                        '✶',
                        style: TextStyle(color: AW.gold, fontSize: width * 0.35),
                      ),
                    ),
            ),
          ),
        );
      },
    );
  }
}
