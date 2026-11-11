import 'moon.dart';
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

const _love = [
  'Тёплый разговор сблизит с любимым человеком.',
  'Одинокие могут встретить интересного человека в обычном месте.',
  'Партнёр оценит твоё внимание и заботу.',
  'Старые обиды лучше отпустить, они мешают двигаться дальше.',
];
const _work = [
  'Удачный день для переговоров и новых договорённостей.',
  'Дела пойдут быстрее, если начать с самого сложного.',
  'Коллеги поддержат твою идею, не бойся её предложить.',
  'Хорошо подвести итоги и навести порядок в бумагах.',
];
const _mood = [
  'Настроение ровное, силы на всё хватит.',
  'Возможна лёгкая усталость, береги себя.',
  'Вдохновение придёт неожиданно, запиши идеи.',
  'День подходит для отдыха и тихих радостей.',
];
const _avoid = [
  'Поспешных решений в денежных делах.',
  'Споров с близкими из-за мелочей.',
  'Обещаний, которые трудно выполнить.',
  'Лишних трат на импульсе.',
  'Сплетен и чужих тайн.',
  'Переутомления к вечеру.',
];
const _prepare = [
  'К неожиданной новости, она может быть приятной.',
  'К разговору, которого давно ждал.',
  'К предложению, над которым стоит подумать.',
  'К встрече со старым знакомым.',
  'К небольшим переменам в планах.',
  'К приятной покупке или подарку.',
];

class DayForecast {
  final String love, work, mood;
  final List<String> avoid, prepare;
  const DayForecast(this.love, this.work, this.mood, this.avoid, this.prepare);
}

DayForecast forecastFor(Profile p, DateTime date, {required bool easy}) {
  final sign = signOf(p.birthday).name;
  final k = '${p.name}|$sign|${p.birthSlot}|${dayKey(date)}';
  String t(List<String> l, String salt, String emoji) {
    final s = pick(l, k + salt);
    return easy ? _easy(s, emoji) : s;
  }

  final a1 = pick(_avoid, '${k}a1');
  var a2 = pick(_avoid, '${k}a2');
  if (a2 == a1) a2 = _avoid[(_avoid.indexOf(a1) + 1) % _avoid.length];
  final p1 = pick(_prepare, '${k}p1');
  var p2 = pick(_prepare, '${k}p2');
  if (p2 == p1) p2 = _prepare[(_prepare.indexOf(p1) + 1) % _prepare.length];
  return DayForecast(t(_love, 'l', '💞'), t(_work, 'w', '💼'), t(_mood, 'm', '✨'), [a1, a2], [p1, p2]);
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
