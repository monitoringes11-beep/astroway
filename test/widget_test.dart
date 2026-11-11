import 'package:astroway/data/dream_base.dart';
import 'package:astroway/logic/daily.dart';
import 'package:astroway/logic/horoscope.dart';
import 'package:astroway/logic/interpret.dart';
import 'package:astroway/logic/memory.dart';
import 'package:astroway/logic/moon.dart';
import 'package:astroway/logic/numerology.dart';
import 'package:astroway/data/numerology_texts.dart';
import 'package:astroway/logic/profile.dart';
import 'package:astroway/logic/zodiac.dart';
import 'package:astroway/screens/home.dart';

import 'dart:io';

import 'package:astroway/main.dart';
import 'package:astroway/screens/horoscope.dart';
import 'package:astroway/screens/numerology.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() => DreamBase.load(File('assets/dreams_ru.json').readAsStringSync()));

  final anna = Profile(name: 'Анна', gender: Gender.female, birthday: DateTime(1990, 11, 5), birthSlot: '09–12');

  test('знак зодиака по дате', () {
    expect(signOf(DateTime(1990, 11, 5)).name, 'Скорпион');
    expect(signOf(DateTime(2000, 1, 19)).name, 'Козерог');
    expect(signOf(DateTime(2000, 1, 20)).name, 'Водолей');
    expect(signOf(DateTime(2000, 2, 29)).name, 'Рыбы');
    expect(signOf(DateTime(2000, 12, 22)).name, 'Козерог');
  });

  test('возраст и склонение', () {
    expect(anna.ageOn(DateTime(2026, 11, 4)), 35);
    expect(anna.ageOn(DateTime(2026, 11, 5)), 36);
    expect(yearsWord(36), 'лет');
    expect(yearsWord(21), 'год');
    expect(yearsWord(52), 'года');
  });

  test('фаза Луны: известные даты', () {
    expect(moonFor(DateTime.utc(2000, 1, 6, 19)).phase, MoonPhase.newMoon);
    // полнолуние 5 ноября 2025
    expect(moonFor(DateTime.utc(2025, 11, 5, 13)).phase, MoonPhase.full);
  });

  test('сцена по времени', () {
    expect(sceneFor(DateTime(2026, 1, 1, 6)), Scene.morning);
    expect(sceneFor(DateTime(2026, 1, 1, 9, 59)), Scene.morning);
    expect(sceneFor(DateTime(2026, 1, 1, 10)), Scene.day);
    expect(sceneFor(DateTime(2026, 1, 1, 17)), Scene.night);
    expect(sceneFor(DateTime(2026, 1, 1, 3)), Scene.night);
  });

  test('прогноз стабилен в течение дня и без повторов', () {
    final d = DateTime(2026, 11, 11, 9);
    final a = forecastFor(anna, d, easy: false);
    final b = forecastFor(anna, d.add(const Duration(hours: 5)), easy: false);
    expect(a.love, b.love);
    expect(a.avoid[0] == a.avoid[1], isFalse);
    expect(a.prepare[0] == a.prepare[1], isFalse);
  });

  test('сонник находит символы', () {
    names(String t) => findSymbols(t).map((s) => s.name).toList();
    expect(names('Я летала над морем и нашла монеты'), containsAll(['Море', 'Деньги', 'Полёт']));
    expect(names('Приснился дождь'), ['Дождь']);
    expect(names('Дождь'), ['Дождь']);
    expect(names('шёл сильный ливень'), ['Дождь']);
    expect(names('поднималась по лестнице в лесу'), containsAll(['Лестница', 'Лес']));
    expect(names('чёрный кот который сидел'), ['Кошка']);
    expect(names('левый берег'), isEmpty);
    expect(names('ничего похожего'), isEmpty);
    expect(DreamBase.symbols.length, greaterThan(150));
  });

  test('волшебница помнит ответ', () async {
    SharedPreferences.setMockInitialValues({});
    final mem = WitchMemory(await SharedPreferences.getInstance());
    final now = DateTime(2026, 11, 11);
    expect(interpretDream('вода', anna, now, mem).memoryLine, isNull);
    await mem.add(WitchAnswer(now, ['Вода'], 'переезд', 'dream'));
    final r = interpretDream('пила чистую воду', anna, now, mem);
    expect(r.memoryLine, contains('связала образ «Вода»'));
    expect(r.memoryLine, contains('переезд'));
    expect(r.witchQuestion, contains('Вода'));
  });

  test('гороскоп стабилен в течение дня и разный у знаков', () {
    final d = DateTime(2026, 11, 11, 9), e = DateTime(2026, 11, 11, 22);
    expect(horoscopeFor(10, d).general, horoscopeFor(10, e).general);
    expect(horoscopeFor(10, d, easy: true).general, contains(RegExp(r'[^\x00-\u04ff]')));
    expect(horoscopeFor(10, d, week: true).week, hasLength(3));
    expect(horoscopeFor(10, d).numbers.every((n) => n >= 1 && n <= 40), isTrue);
  });

  test('восточный знак и совместимость', () {
    expect(eastAnimals[eastIndexOf(DateTime(1990, 11, 5))][0], 'Лошадь');
    expect(eastAnimals[eastIndexOf(DateTime(1990, 1, 20))][0], 'Змея');
    expect(eastBestWith(6), ['Тигр', 'Собака']);
    expect(compatibility(3, 7).level, contains('Одна стихия'));
    expect(compatibility(0, 2).level, contains('дополняют'));
    expect(compatibility(0, 3).level, contains('компромисс'));
  });

  testWidgets('экран гороскопа открывается на всех вкладках', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState(Store(await SharedPreferences.getInstance()));
    await app.store.saveProfile(anna);
    await tester.pumpWidget(MaterialApp(home: HoroscopeScreen(app: app)));
    expect(find.textContaining('Скорпион'), findsWidgets);
    for (final tab in ['На неделю', 'Восточный', '💎 Совместимость', 'На сегодня']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Восточный'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Лошадь'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  test('нумерология: расчёты', () {
    final b = DateTime(1990, 11, 5);
    expect(lifePath(b).n, 8); // 0+5+1+1+1+9+9+0 = 26 → 8
    expect(lifePath(DateTime(1992, 11, 29)).n, 7); // 2+9+1+1+1+9+9+2 = 34 → 7
    expect(lifePath(DateTime(1960, 8, 18)).n, 33); // сумма 33 остаётся мастер-числом
    expect(nameNumber('Анна', b).n, 5); // А1 Н6 Н6 А1 = 14 → 5
    expect(personalYear(b, 2026).n, inInclusiveRange(1, 9));
    expect(dayNumber(b, DateTime(2026, 11, 11)).n, inInclusiveRange(1, 9));
    expect(genderize('Ты {способна|способен}', true), 'Ты способна');
    expect(genderize('Ты {способна|способен}', false), 'Ты способен');
    expect(genderize('Ты {способна|способен}', null), 'Ты способна (способен)');
    expect(sphereText(7, 'money', '', easy: true), easy7Money);
  });

  testWidgets('экран нумерологии открывается на всех вкладках', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState(Store(await SharedPreferences.getInstance()));
    await app.store.saveProfile(anna);
    await tester.pumpWidget(MaterialApp(home: NumerologyScreen(app: app)));
    await tester.pumpAndSettle();
    expect(find.text('8'), findsOneWidget);
    for (final tab in ['Число имени', 'Число дня', 'Личный год', '💎 Совместимость', 'Моё число']) {
      await tester.tap(find.text(tab));
      await tester.pumpAndSettle();
    }
    await tester.tap(find.text('Деньги и карьера'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Восьмёрка'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
