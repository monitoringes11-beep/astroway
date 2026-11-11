import 'dart:math' as math;

/// Фазы Луны, которые использует приложение.
enum MoonPhase { newMoon, young, full, old }

class MoonInfo {
  final double age; // возраст Луны в сутках
  final double illumination; // 0..1
  final MoonPhase phase;
  final int lunarDay;

  const MoonInfo(this.age, this.illumination, this.phase, this.lunarDay);

  String get name => switch (phase) {
        MoonPhase.newMoon => 'Новолуние',
        MoonPhase.young => 'Молодая Луна',
        MoonPhase.full => 'Полнолуние',
        MoonPhase.old => 'Старая Луна',
      };

  String get tip => switch (phase) {
        MoonPhase.newMoon => 'Время загадывать желания и задумывать новое.',
        MoonPhase.young => 'Луна растёт: хорошо начинать дела и притягивать.',
        MoonPhase.full => 'Пик силы: эмоции яркие, сны самые сильные.',
        MoonPhase.old => 'Луна убывает: время отпускать и завершать.',
      };

  int get percent => (illumination * 100).round();
}

const double synodicMonth = 29.530588853;
final DateTime _reference = DateTime.utc(2000, 1, 6, 18, 14);

MoonInfo moonFor(DateTime date) {
  final days = date.toUtc().difference(_reference).inSeconds / 86400.0;
  final age = ((days % synodicMonth) + synodicMonth) % synodicMonth;
  final illumination = (1 - math.cos(2 * math.pi * age / synodicMonth)) / 2;
  final MoonPhase phase;
  if (age < 1 || age > synodicMonth - 1) {
    phase = MoonPhase.newMoon;
  } else if (age < 13.8) {
    phase = MoonPhase.young;
  } else if (age < 15.8) {
    phase = MoonPhase.full;
  } else {
    phase = MoonPhase.old;
  }
  return MoonInfo(age, illumination, phase, age.floor() + 1);
}
