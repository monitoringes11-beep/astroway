import '../data/dream_base.dart';
import '../data/palm.dart';
import 'daily.dart';
import 'interpret.dart';
import 'tarot.dart';
import 'zodiac.dart';

/// Блок карточки «Поделиться»: заголовок и текст.
class ShareSection {
  final String title, body;
  const ShareSection(this.title, this.body);
}

/// Что попадёт на картинку и в текст при отправке.
/// Только общие толкования: без имени, даты рождения, возраста, ответов волшебнице,
/// текста сна и вопроса к картам.
class ShareContent {
  final String title;
  final String? subtitle;
  final List<ShareSection> sections;
  final String? note;
  const ShareContent({required this.title, this.subtitle, required this.sections, this.note});

  static const brand = 'AstroWay — сонник, гороскоп, расклады';

  /// Текст, который уходит вместе с картинкой (часть приложений берёт только его).
  String get plainText {
    final b = StringBuffer(title);
    if (subtitle != null) b.write('\n$subtitle');
    for (final s in sections) {
      b.write('\n\n${s.title}\n${s.body}');
    }
    if (note != null) b.write('\n\n$note');
    b.write('\n\n$brand');
    return b.toString();
  }
}

const _months = [
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

String shareDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';

/// Короткий текст для картинки: до [max] знаков, обрезка по концу предложения или слова.
String shorten(String s, [int max = 240]) {
  final t = s.trim();
  if (t.length <= max) return t;
  final cut = t.substring(0, max);
  final dot = cut.lastIndexOf(RegExp(r'[.!?]\s'));
  if (dot > max ~/ 2) return cut.substring(0, dot + 1);
  final sp = cut.lastIndexOf(' ');
  return '${cut.substring(0, sp > 0 ? sp : max).trimRight()}…';
}

/// Прогноз дня: знак и дата, без имени и строки «Волшебница помнит».
ShareContent shareForecast(DayForecast f, ZodiacSign sign, DateTime date) => ShareContent(
  title: 'Прогноз дня',
  subtitle: '${sign.symbol} ${sign.name} · ${shareDate(date)}',
  sections: [
    ShareSection('Тема дня', f.theme),
    ShareSection('Что принесёт день', '${f.love}\n${f.work}\n${f.mood}'),
    ShareSection('Чего сторониться', f.avoid.map((e) => '• $e').join('\n')),
    ShareSection('К чему готовиться', f.prepare.map((e) => '• $e').join('\n')),
  ],
);

/// Толкование сна: только символы из сонника. Текст сна, личная часть и память не попадают.
ShareContent shareDream(DreamReading r) {
  final syms = r.symbols.take(3).toList();
  return ShareContent(
    title: 'Толкование сна',
    subtitle: syms.isEmpty ? null : 'Образы: ${syms.map((s) => s.name.toLowerCase()).join(', ')}',
    sections: [for (final DreamSymbol s in syms) ShareSection('${s.name} · ${s.source}', shorten(s.classic))],
    note: signoff,
  );
}

ShareContent shareCardOfDay(Arcana c, DateTime date) => ShareContent(
  title: 'Карта дня',
  subtitle: shareDate(date),
  sections: [ShareSection('${c.numeral} · ${c.name}', '${capitalize(c.upright)}.')],
  note: 'Расклад — подсказка, а не приговор.',
);

/// Расклад на три карты без вопроса: вопрос — личное.
ShareContent shareSpread(List<DrawnCard> s) => ShareContent(
  title: 'Расклад на три карты',
  subtitle: 'Прошлое · Настоящее · Будущее',
  sections: [
    for (var i = 0; i < s.length; i++)
      ShareSection(
        '${spreadPositions[i]}: ${s[i].card.name}${s[i].reversed ? ' (перевёрнутая)' : ''}',
        '${capitalize(s[i].meaning)}.',
      ),
  ],
  note: 'Совет: опирайтесь на карту «${s[1].card.name}», она показывает, на чём сейчас сила.',
);

/// Итог по линиям ладони, без фото.
ShareContent sharePalm(Map<String, String> answers, {required bool easy}) => ShareContent(
  title: 'Тайны ладони',
  subtitle: 'Итог по всем линиям',
  sections: [
    for (final l in palmLines)
      if (answers[l.id] != null)
        ShareSection('${l.sphere} · ${l.name}', () {
          final v = l.variants.firstWhere((v) => v.id == answers[l.id]);
          return easy ? v.adviceEasy : v.adviceSerious;
        }()),
  ],
  note: 'Хиромантия — развлечение: линии говорят о характере, а не о судьбе.',
);
