import 'package:astroway/logic/daily.dart';
import 'package:astroway/logic/moon.dart';
import 'package:astroway/logic/notifier.dart';
import 'package:astroway/logic/notify_plan.dart';
import 'package:astroway/logic/profile.dart';
import 'package:astroway/main.dart';
import 'package:astroway/screens/notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FakeSink implements NoticeSink {
  List<PlannedNotice> last = [];
  int asked = 0;
  @override
  Future<void> replaceAll(List<PlannedNotice> plan) async => last = plan;
  @override
  Future<bool> askPermission() async {
    asked++;
    return true;
  }
}

void main() {
  final anna = Profile(name: 'Анна', gender: Gender.female, birthday: DateTime(1990, 11, 5), birthSlot: '09–12');
  final now = DateTime(2026, 11, 17, 10, 0);

  test('утренний прогноз: каждый день в выбранное время, сегодняшний прошедший не ставим', () {
    final plan = buildPlan(
      now: now,
      s: const NotifySettings(forecastMinutes: 8 * 60, moonOn: false),
      profile: anna,
    );
    expect(plan.length, forecastDaysAhead - 1); // сегодня 08:00 уже прошло
    expect(plan.first.at, DateTime(2026, 11, 18, 8, 0));
    expect(plan.every((n) => n.at.hour == 8 && n.at.minute == 0 && n.channel == 'forecast'), isTrue);
    expect(plan.map((n) => n.id).toSet().length, plan.length);

    final later = buildPlan(
      now: now,
      s: const NotifySettings(forecastMinutes: 21 * 60 + 30, moonOn: false),
      profile: anna,
    );
    expect(later.first.at, DateTime(2026, 11, 17, 21, 30));
    expect(later.length, forecastDaysAhead);
  });

  test('один день — один ответ: уведомление совпадает с прогнозом на главном экране', () {
    final day = DateTime(2026, 11, 20);
    final n = forecastNotice(anna, day, easy: false);
    for (final h in [0, 7, 12, 19, 23]) {
      final f = forecastFor(anna, DateTime(2026, 11, 20, h, 45), easy: false);
      expect(n.body, '${f.theme}\n${f.mood}');
    }
    expect(n.title, contains('Скорпион'));
    // повторный расчёт даёт тот же текст
    expect(forecastNotice(anna, day, easy: false).body, n.body);
    // лёгкий тон — свой текст, но тоже стабильный
    expect(forecastNotice(anna, day, easy: true).body, forecastNotice(anna, day, easy: true).body);
  });

  test('прогноз не меняется в течение дня даже в день смены фазы Луны', () {
    final days = moonChangeDays(DateTime(2026, 1, 1), 365);
    expect(days.length, greaterThan(40)); // 4 смены за ~29.5 суток
    for (final d in days) {
      final morning = forecastFor(anna, DateTime(d.year, d.month, d.day, 0, 5), easy: false);
      final night = forecastFor(anna, DateTime(d.year, d.month, d.day, 23, 55), easy: false);
      expect(morning.love, night.love);
      expect(morning.avoid, night.avoid);
    }
  });

  test('Луна: уведомления только в дни смены фазы и по порядку фаз', () {
    final plan = buildPlan(
      now: now,
      s: const NotifySettings(forecastOn: false, moonMinutes: 20 * 60),
      profile: anna,
    );
    expect(plan, isNotEmpty);
    expect(plan.every((n) => n.channel == 'moon' && n.at.hour == 20), isTrue);
    for (final n in plan) {
      final d = n.at;
      expect(phaseOfDay(d), isNot(phaseOfDay(DateTime(d.year, d.month, d.day - 1))));
      expect(n.title, contains(moonPhaseName(phaseOfDay(d))));
    }
    // между соседними сменами — не меньше суток, за 60 дней 7–9 смен
    expect(plan.length, inInclusiveRange(7, 9));
    const order = MoonPhase.values;
    for (var i = 1; i < plan.length; i++) {
      final a = phaseOfDay(plan[i - 1].at), b = phaseOfDay(plan[i].at);
      expect(b, order[(order.indexOf(a) + 1) % 4]);
    }
  });

  test('выключено — ничего не ставим; без профиля — только Луна', () {
    expect(buildPlan(now: now, s: const NotifySettings(forecastOn: false, moonOn: false), profile: anna), isEmpty);
    final noProfile = buildPlan(now: now, s: const NotifySettings());
    expect(noProfile.every((n) => n.channel == 'moon'), isTrue);
  });

  test('профиль с кодом входа: без личного текста', () {
    final n = forecastNotice(anna, now, easy: false, private: true);
    expect(n.body, isNot(contains('число')));
    expect(n.title, 'Прогноз дня готов');
  });

  test('настройки сохраняются и Notifier ставит план', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    expect(NotifyPrefs.read(prefs).forecastMinutes, 8 * 60);
    await NotifyPrefs.write(prefs, const NotifySettings(forecastMinutes: 7 * 60 + 15, moonOn: false));
    final s = NotifyPrefs.read(prefs);
    expect((s.forecastOn, s.forecastMinutes, s.moonOn), (true, 7 * 60 + 15, false));

    final sink = FakeSink();
    Notifier.sink = sink;
    await Notifier.refresh(prefs: prefs, entry: ProfileEntry('p1', anna), easy: false, now: now);
    expect(sink.last.length, forecastDaysAhead - 1);
    expect(sink.last.first.at, DateTime(2026, 11, 18, 7, 15));

    await Notifier.askOnce(prefs);
    await Notifier.askOnce(prefs);
    expect(sink.asked, 1);
  });

  testWidgets('экран уведомлений: выключатели и время', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final store = await Store.open();
    await store.addProfile(anna);
    final sink = FakeSink();
    Notifier.sink = sink;
    await tester.pumpWidget(MaterialApp(home: NotificationsScreen(app: AppState(store))));
    expect(find.text('Прогноз дня'), findsOneWidget);
    expect(find.text('Смена фазы Луны'), findsOneWidget);
    expect(find.text('Время: 08:00'), findsOneWidget);
    expect(find.text('Время: 20:00'), findsOneWidget);

    await tester.tap(find.byType(Switch).last);
    await tester.pumpAndSettle();
    expect(find.text('Время: 20:00'), findsNothing);
    expect(NotifyPrefs.read(store.prefs).moonOn, isFalse);
    expect(sink.last.every((n) => n.channel == 'forecast'), isTrue);
  });
}
