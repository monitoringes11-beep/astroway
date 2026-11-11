import 'package:flutter/material.dart';

import '../data/slavic.dart';
import '../logic/zodiac.dart';
import '../main.dart';
import '../theme.dart';

/// Символы славян: подлинные узоры народной культуры и современный «Сварожий круг».
class SlavicScreen extends StatefulWidget {
  final AppState app;
  const SlavicScreen({super.key, required this.app});
  @override
  State<SlavicScreen> createState() => _SlavicScreenState();
}

class _SlavicScreenState extends State<SlavicScreen> {
  bool _circle = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Символы славян'), backgroundColor: AW.navy),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
        children: [
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Народные узоры')),
              ButtonSegment(value: true, label: Text('Сварожий круг')),
            ],
            selected: {_circle},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _circle = s.first),
          ),
          const SizedBox(height: 16),
          if (!_circle) ..._motifs() else ..._chertogs(),
        ],
      ),
    );
  }

  List<Widget> _motifs() {
    final sign = signIndexOf(widget.app.profile!.birthday.month, widget.app.profile!.birthday.day);
    final el = elements[sign % 4];
    final mine = slavicMotifs.where((m) => m.element == el).map((m) => m.name).toList();
    return [
      const Text(
        'Эти узоры известны по народной вышивке, резьбе и украшениям. Ниже рассказано, что они означали '
        'и когда их использовали.',
        style: TextStyle(color: AW.soft, height: 1.4),
      ),
      const SizedBox(height: 12),
      GlassCard(
        color: AW.gold.withValues(alpha: 0.12),
        child: Text(
          'Твой знак — ${signs[sign].name}, стихия $el. Близки по духу: ${mine.join(', ')}. '
          'Это подсказка AstroWay: в народной традиции узоры не делили по знакам зодиака.',
          style: const TextStyle(height: 1.4),
        ),
      ),
      const SizedBox(height: 12),
      for (final m in slavicMotifs) ...[
        GlassCard(
          child: Material(
            type: MaterialType.transparency,
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                tilePadding: EdgeInsets.zero,
                childrenPadding: const EdgeInsets.only(bottom: 4),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                leading: SizedBox(
                  width: 40,
                  child: Center(
                    child: Text(m.glyph, style: const TextStyle(fontSize: 26, color: AW.gold)),
                  ),
                ),
                title: Text(m.name, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(
                  'стихия: ${m.element.toLowerCase()}',
                  style: const TextStyle(color: AW.soft, fontSize: 12.5),
                ),
                children: [
                  Text(m.meaning, style: const TextStyle(height: 1.4)),
                  const SizedBox(height: 10),
                  const Label('Где встречается'),
                  const SizedBox(height: 3),
                  Text(m.where, style: const TextStyle(height: 1.4)),
                  const SizedBox(height: 10),
                  const Label('Когда лучше использовать'),
                  const SizedBox(height: 3),
                  Text(m.when, style: const TextStyle(height: 1.4)),
                  if (m.note != null) ...[
                    const SizedBox(height: 8),
                    Text(m.note!, style: const TextStyle(color: AW.soft, fontSize: 12.5)),
                  ],
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
      ],
      const SizedBox(height: 6),
      const Text(
        'Описания основаны на народных толкованиях, собранных этнографами. Узоры носят культурный и '
        'развлекательный характер.',
        style: TextStyle(color: AW.soft, fontSize: 12),
      ),
    ];
  }

  List<Widget> _chertogs() {
    final mine = chertogOf(widget.app.profile!.birthday);
    List<String> overlap(Chertog c) => zodiacOverlap(c, signIndexOf, [for (final s in signs) s.name]);
    Widget card(Chertog c, {bool highlight = false}) => GlassCard(
      color: highlight ? AW.gold.withValues(alpha: 0.14) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Чертог ${c.name}',
            style: TextStyle(fontSize: highlight ? 19 : 16.5, fontWeight: FontWeight.w700, color: AW.gold),
          ),
          const SizedBox(height: 4),
          Text('${c.dates} · знаки: ${overlap(c).join(', ')}', style: const TextStyle(color: AW.soft, fontSize: 13)),
          const SizedBox(height: 8),
          Text(c.text, style: const TextStyle(height: 1.4)),
          const SizedBox(height: 6),
          Text('Покровитель: ${c.patron} · священное дерево: ${c.tree}', style: const TextStyle(fontSize: 13.5)),
        ],
      ),
    );
    return [
      const GlassCard(
        child: Text(
          '«Сварожий круг» — современная традиция. Её придумали родноверы в конце 1990-х, в старинных источниках '
          'её нет. Год в ней делится на 16 чертогов, поэтому они не совпадают с 12 знаками зодиака.',
          style: TextStyle(height: 1.4),
        ),
      ),
      const SizedBox(height: 12),
      const Label('Твой чертог'),
      const SizedBox(height: 6),
      card(mine, highlight: true),
      const SizedBox(height: 16),
      const Label('Все 16 чертогов'),
      const SizedBox(height: 6),
      for (final c in chertogs) ...[card(c), const SizedBox(height: 10)],
    ];
  }
}
