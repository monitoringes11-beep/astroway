import '../data/forecast_bank.dart';
import 'memory.dart';
import 'moon.dart';
import 'numerology.dart';
import 'profile.dart';
import 'zodiac.dart';

/// Стабильный хэш FNV-1a: один и тот же текст для пользователя весь день.
int stableHash(String s) {
  var h = 0x811c9dc5;
  for (final c in s.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h;
}

T pick<T>(List<T> list, String key) => list[stableHash(key) % list.length];

String dayKey(DateTime d) => '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _easy(String s, String emoji) => '${s.replaceAll(RegExp(r'\.$'), '')} $emoji';

class DayForecast {
  final String theme, love, work, mood, timing;
  final List<String> avoid, prepare;
  final String? memory;
  const DayForecast({
    required this.theme,
    required this.love,
    required this.work,
    required this.mood,
    required this.timing,
    required this.avoid,
    required this.prepare,
    this.memory,
  });
}

/// Группа времени рождения: 0 утро, 1 день, 2 вечер, 3 ночь, 4 не указано.
int slotGroup(String slot) {
  final i = birthSlots.indexOf(slot);
  return i < 0 ? 4 : i ~/ 2;
}

int elementOf(DateTime birthday) => signs.indexOf(signOf(birthday)) % 4;

/// Личный прогноз дня. Всё считается на телефоне, без интернета:
/// стихия знака и время рождения задают смысл фраз, Луна, Солнце и число дня
/// дают оттенок дня, а имя и дата перемешивают выбор, чтобы у всех было по-своему.
DayForecast forecastFor(Profile p, DateTime date, {required bool easy, WitchAnswer? recall}) {
  final el = elementOf(p.birthday);
  final slot = slotGroup(p.birthSlot);
  final moon = moonFor(date).phase.index;
  final sun = sunEnergyFor(date).index;
  final num = dayNumber(p.birthday, date).n;
  final female = switch (p.gender) {
    Gender.female => true,
    Gender.male => false,
    Gender.unspecified => null,
  };
  final k = '${p.name}|${p.birthday.toIso8601String().substring(0, 10)}|${p.birthSlot}|${dayKey(date)}';
  String g(String s) => genderize(s, female);
  String two(String a, String b, String emoji) {
    final s = g('$a $b');
    return easy ? _easy(s, emoji) : s;
  }

  final avoid1 = stableHash('${k}a') % 2 == 0 ? pick(avoidByMoon[moon], '${k}am') : pick(avoidByElement[el], '${k}ae');
  final prep1 = pick(prepareByDay[num], '${k}pd');
  String? memory;
  if (recall != null && date.difference(recall.date).inDays <= 14 && recall.answer.trim().isNotEmpty) {
    final a = recall.answer.trim();
    final short = a.length > 80 ? '${a.substring(0, 80).trimRight()}…' : a;
    final sym = recall.symbols.isEmpty ? 'знак' : recall.symbols.first.toLowerCase();
    memory = g(pick(memoryHints, '${k}mem').replaceAll('{s}', sym).replaceAll('{a}', short));
  }
  return DayForecast(
    theme: '${pick(dayTheme[num], '${k}th')} · число $num',
    love: two(pick(loveByElement[el], '${k}le'), pick(loveByMoon[moon], '${k}lm'), '💞'),
    work: two(pick(workByElement[el], '${k}we'), pick(workByDay[num], '${k}wd'), '💼'),
    mood: two(pick(moodBySun[sun], '${k}ms'), pick(moodBySlot[slot], '${k}mt'), '✨'),
    timing: g(pick(timingBySlot[slot], '${k}ti')),
    avoid: [g(avoid1), g(pick(avoidCommon, '${k}ac'))],
    prepare: [g(prep1), g(pick(prepareCommon, '${k}pc'))],
    memory: memory,
  );
}

// ===== Солнце и Луна =====
enum SunEnergy { high, mid, low }

SunEnergy sunEnergyFor(DateTime d) => SunEnergy.values[stableHash('${dayKey(d)}sun') % 3];

String sunLevel(SunEnergy e) => switch (e) {
  SunEnergy.high => '☀️ Высокая',
  SunEnergy.mid => '🌤 Ровная',
  SunEnergy.low => '⛅ Мягкая',
};

const _sunText = {
  SunEnergy.high: [
    'День благоприятен для решительных шагов и публичных выступлений.',
    'Солнце светит ярко — сегодня можно смело брать инициативу! ☀️',
  ],
  SunEnergy.mid: [
    'Энергия дня устойчивая: подходит для системной работы и завершения дел.',
    'Ровный солнечный день: закрываем хвосты и не перегораем 🌤',
  ],
  SunEnergy.low: [
    'Активность снижена: лучше сосредоточиться на одном главном деле.',
    'Солнце сегодня ленивое — и вам можно не геройствовать ⛅',
  ],
};

String sunText(SunEnergy e, {required bool easy}) => _sunText[e]![easy ? 1 : 0];

String moonLevel(MoonPhase p) => switch (p) {
  MoonPhase.newMoon => '🌑 Луна скрыта',
  MoonPhase.young => '🌒 Растущая Луна',
  MoonPhase.full => '🌕 Полнолуние',
  MoonPhase.old => '🌘 Убывающая Луна',
};

const _moonText = {
  MoonPhase.newMoon: [
    'Луна скрыта — день для внутреннего поиска и тихих намерений.',
    'Луна спряталась — самое время побыть с собой 🌑',
  ],
  MoonPhase.young: [
    'Эмоции на подъёме, легко загораться идеями; избегайте поспешных обещаний.',
    'Луна растёт, и настроение тоже 🌒 Только не обещайте лишнего!',
  ],
  MoonPhase.full: [
    'Эмоциональная чувствительность повышена; избегайте поспешных выводов.',
    'Луна сегодня шепчет: «не торопись». Прислушайтесь к себе 🌙',
  ],
  MoonPhase.old: [
    'Время отпускать лишнее и завершать начатое; эмоции спокойнее.',
    'Луна убывает — отпускаем всё лишнее 🌘',
  ],
};

String moonText(MoonPhase p, {required bool easy}) => _moonText[p]![easy ? 1 : 0];

const _balance = {
  SunEnergy.high: [
    'Действуйте уверенно, но с учётом возможных рисков и эмоционального фона.',
    'Смело шагайте вперёд, но держите внутренний тормоз включённым 💛',
  ],
  SunEnergy.mid: [
    'Сочетайте решительность с внимательностью к деталям и своему состоянию.',
    'Смело шагайте, но не забывайте оглядываться 💛',
  ],
  SunEnergy.low: [
    'Делайте главное в первой половине дня, вечер оставьте для отдыха.',
    'Утром — дела, вечером — плед и чай ☕',
  ],
};

String balanceText(SunEnergy e, {required bool easy}) => _balance[e]![easy ? 1 : 0];
