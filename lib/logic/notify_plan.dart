import 'daily.dart';
import 'moon.dart';
import 'profile.dart';
import 'zodiac.dart';

/// Настройки уведомлений. Хранятся только на телефоне.
class NotifySettings {
  final bool forecastOn;
  final int forecastMinutes; // минуты от полуночи
  final bool moonOn;
  final int moonMinutes;

  const NotifySettings({
    this.forecastOn = true,
    this.forecastMinutes = 8 * 60,
    this.moonOn = true,
    this.moonMinutes = 20 * 60,
  });

  NotifySettings copyWith({bool? forecastOn, int? forecastMinutes, bool? moonOn, int? moonMinutes}) => NotifySettings(
    forecastOn: forecastOn ?? this.forecastOn,
    forecastMinutes: forecastMinutes ?? this.forecastMinutes,
    moonOn: moonOn ?? this.moonOn,
    moonMinutes: moonMinutes ?? this.moonMinutes,
  );
}

String hhmm(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

/// Одно запланированное уведомление: когда, что и под каким номером.
class PlannedNotice {
  final int id;
  final DateTime at; // местное время телефона
  final String title, body;
  final String channel; // 'forecast' или 'moon'
  const PlannedNotice(this.id, this.at, this.title, this.body, this.channel);
}

const int forecastIdBase = 1000;
const int moonIdBase = 2000;

/// На сколько дней вперёд ставим уведомления. При каждом открытии приложения план обновляется.
const int forecastDaysAhead = 30;
const int moonDaysAhead = 60;

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

String moonPhaseName(MoonPhase p) => switch (p) {
  MoonPhase.newMoon => 'Новолуние',
  MoonPhase.young => 'Молодая Луна',
  MoonPhase.full => 'Полнолуние',
  MoonPhase.old => 'Старая Луна',
};

String _moonEmoji(MoonPhase p) => switch (p) {
  MoonPhase.newMoon => '🌑',
  MoonPhase.young => '🌒',
  MoonPhase.full => '🌕',
  MoonPhase.old => '🌘',
};

const _moonBody = {
  MoonPhase.newMoon: 'Время загадывать желания и задумывать новое. Загляни за заговором на новолуние.',
  MoonPhase.young: 'Луна растёт: хорошо начинать дела и притягивать. Загляни за заговором на растущую Луну.',
  MoonPhase.full: 'Пик силы: эмоции яркие, сны самые сильные. Загляни за заговором на полнолуние.',
  MoonPhase.old: 'Луна убывает: время отпускать и завершать. Загляни за заговором на убывающую Луну.',
};

/// Дни, в которые Луна переходит в новую фазу (по сравнению со вчерашним днём).
List<DateTime> moonChangeDays(DateTime from, int days) {
  final start = _day(from);
  final out = <DateTime>[];
  var prev = phaseOfDay(start.subtract(const Duration(days: 1)));
  for (var i = 0; i < days; i++) {
    final d = DateTime(start.year, start.month, start.day + i);
    final p = phaseOfDay(d);
    if (p != prev) out.add(d);
    prev = p;
  }
  return out;
}

/// Текст утреннего уведомления. Берётся из того же прогноза, что на главном экране,
/// поэтому в один день — один и тот же ответ.
({String title, String body}) forecastNotice(Profile p, DateTime day, {required bool easy, bool private = false}) {
  final sign = signOf(p.birthday);
  final title = '${sign.symbol} Прогноз дня · ${sign.name}';
  if (private) return (title: 'Прогноз дня готов', body: 'Волшебница ждёт тебя в AstroWay ✨');
  final f = forecastFor(p, DateTime(day.year, day.month, day.day, 12), easy: easy);
  return (title: title, body: '${f.theme}\n${f.mood}');
}

({String title, String body}) moonNotice(MoonPhase p) =>
    (title: '${_moonEmoji(p)} Сегодня: ${moonPhaseName(p)}', body: _moonBody[p]!);

/// Полный план уведомлений от момента [now]. Прошедшие на сегодня не ставим.
/// [profile] — чей прогноз присылать; null — прогноз не присылаем (никто не вошёл).
List<PlannedNotice> buildPlan({
  required DateTime now,
  required NotifySettings s,
  Profile? profile,
  bool easy = false,
  bool private = false,
}) {
  final plan = <PlannedNotice>[];
  final today = _day(now);
  if (s.forecastOn && profile != null) {
    for (var i = 0; i < forecastDaysAhead; i++) {
      final d = DateTime(today.year, today.month, today.day + i);
      final at = DateTime(d.year, d.month, d.day, s.forecastMinutes ~/ 60, s.forecastMinutes % 60);
      if (!at.isAfter(now)) continue;
      final n = forecastNotice(profile, d, easy: easy, private: private);
      plan.add(PlannedNotice(forecastIdBase + i, at, n.title, n.body, 'forecast'));
    }
  }
  if (s.moonOn) {
    var i = 0;
    for (final d in moonChangeDays(today, moonDaysAhead)) {
      final at = DateTime(d.year, d.month, d.day, s.moonMinutes ~/ 60, s.moonMinutes % 60);
      if (!at.isAfter(now)) continue;
      final n = moonNotice(phaseOfDay(d));
      plan.add(PlannedNotice(moonIdBase + i++, at, n.title, n.body, 'moon'));
    }
  }
  return plan;
}
