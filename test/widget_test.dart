import 'package:astroway/data/forecast_bank.dart';
import 'package:astroway/data/dream_base.dart';
import 'package:astroway/logic/daily.dart';
import 'package:astroway/logic/horoscope.dart';
import 'package:astroway/logic/interpret.dart';
import 'package:astroway/logic/memory.dart';
import 'package:astroway/logic/moon.dart';
import 'package:astroway/logic/numerology.dart';
import 'package:astroway/data/numerology_texts.dart';
import 'package:astroway/data/omens.dart';
import 'package:astroway/logic/sunmoon.dart';
import 'package:astroway/data/palm.dart';
import 'package:astroway/logic/svg_path.dart';
import 'package:astroway/logic/tarot.dart';
import 'package:astroway/data/slavic.dart';
import 'package:astroway/logic/profile.dart';
import 'package:astroway/logic/zodiac.dart';
import 'package:astroway/screens/home.dart';

import 'dart:io';

import 'package:astroway/main.dart';
import 'package:astroway/screens/horoscope.dart';
import 'package:astroway/screens/numerology.dart';
import 'package:astroway/screens/omens.dart';
import 'package:astroway/screens/sunmoon.dart';
import 'package:astroway/screens/palm.dart';
import 'package:astroway/screens/tarot.dart';
import 'package:astroway/screens/slavic.dart';
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

  test('прогноз дня зависит от стихии, времени рождения и пола', () {
    final d = DateTime(2026, 11, 12, 9);
    final leo = Profile(name: 'Анна', gender: Gender.female, birthday: DateTime(1990, 8, 1), birthSlot: '21–24');
    final a = forecastFor(anna, d, easy: false);
    final l = forecastFor(leo, d, easy: false);
    expect(loveByElement[2].any(a.love.startsWith), isTrue); // Скорпион, вода
    expect(loveByElement[3].any(l.love.startsWith), isTrue); // Лев, огонь
    expect(timingBySlot[0], contains(a.timing));
    expect(timingBySlot[2], contains(l.timing));
    expect(a.theme, contains('число'));
    expect(a.memory, isNull);
    // За год ни одной незаменённой метки пола и ни одного повтора внутри блока.
    final man = Profile(name: 'Олег', gender: Gender.male, birthday: DateTime(1985, 3, 30), birthSlot: slotUnknown);
    final loves = <String>{};
    for (var i = 0; i < 365; i++) {
      for (final p in [anna, leo, man]) {
        final f = forecastFor(p, d.add(Duration(days: i)), easy: p != anna && i.isEven);
        final all = [f.love, f.work, f.mood, f.timing, ...f.avoid, ...f.prepare].join(' ');
        expect(all.contains('{'), isFalse, reason: all);
        expect(f.avoid[0] == f.avoid[1], isFalse);
        expect(f.prepare[0] == f.prepare[1], isFalse);
        if (p == anna) loves.add([f.love, f.work, f.mood, f.timing, ...f.avoid, ...f.prepare].join());
      }
    }
    expect(loves.length, 365); // целиком прогноз за год не повторяется ни разу
  });

  test('прогноз вспоминает ответ волшебнице за последние две недели', () {
    final d = DateTime(2026, 11, 12, 9);
    final fresh = WitchAnswer(DateTime(2026, 11, 10), ['Вода'], 'думаю о переезде', 'dream');
    final old = WitchAnswer(DateTime(2026, 9, 1), ['Вода'], 'думаю о переезде', 'dream');
    final f = forecastFor(anna, d, easy: false, recall: fresh);
    expect(f.memory, contains('думаю о переезде'));
    expect(f.memory, contains('«вода»'));
    expect(forecastFor(anna, d, easy: false, recall: old).memory, isNull);
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

  test('знаки судьбы: поиск и знак дня', () {
    expect(searchOmens('рассыпала соль').first.id, 'salt');
    expect(searchOmens('птица стучала в окно').first.id, 'bird');
    expect(searchOmens('чёрный кот перебежал дорогу').first.id, 'cat');
    expect(searchOmens('', polarity: 'good').every((o) => o.polarity == 'good'), isTrue);
    expect(searchOmens('', sphere: 'money').every((o) => o.spheres.contains('money')), isTrue);
    expect(searchOmens('динозавр'), isEmpty);
    for (final t in omenTasks) {
      expect(omens.any((o) => o.id == t[2]), isTrue);
    }
  });

  testWidgets('экран знаков судьбы', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState(Store(await SharedPreferences.getInstance()));
    await app.store.saveProfile(anna);
    await tester.pumpWidget(MaterialApp(home: OmensScreen(app: app)));
    await tester.tap(find.text('Встретила знак'));
    await tester.pumpAndSettle();
    expect(find.text('ЧТО ГОВОРИТ ПРИМЕТА'), findsOneWidget);
    await tester.tap(find.text('Словарь'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).first, 'соль');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Рассыпать соль'));
    await tester.pumpAndSettle();
    expect(find.textContaining('традиция'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('луна и солнце: личный разбор', () {
    expect(personalSun(10, SunEnergy.high), contains('глубина и сила воли'));
    expect(personalMoon(MoonPhase.full, easy: false), contains('не принимайте решений на эмоциях'));
    expect(rhythmFits(3, SunEnergy.high, MoonPhase.old), isTrue); // огонь + высокая энергия
    expect(rhythmFits(3, SunEnergy.low, MoonPhase.old), isFalse);
    for (final ph in MoonPhase.values) {
      expect(moonTask(ph), hasLength(2));
    }
  });

  testWidgets('экран луны и солнца', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState(Store(await SharedPreferences.getInstance()));
    await app.store.saveProfile(anna);
    await tester.pumpWidget(MaterialApp(home: SunMoonScreen(app: app)));
    expect(find.textContaining('твои Солнце и Луна'), findsOneWidget);
    expect(find.textContaining('СКОРПИОН'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('ладонь: данные и тип руки', () {
    expect(palmLines.map((l) => l.id), ['life', 'heart', 'head', 'fate', 'sun', 'bond']);
    expect(handTypes[handTypeKey(squarePalm: true, shortFingers: true)]![0], 'Земная рука');
    expect(handTypes[handTypeKey(squarePalm: false, shortFingers: false)]![0], 'Водная рука');
    for (final l in palmLines) {
      expect(samplePath(parseSvgPath(l.path)).length, greaterThan(10));
    }
  });

  testWidgets('экран ладони: схема и тип руки', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState(Store(await SharedPreferences.getInstance()));
    await app.store.saveProfile(anna);
    await tester.pumpWidget(MaterialApp(home: PalmScreen(app: app)));
    await tester.scrollUntilVisible(
      find.text('Широкой дугой к центру ладони'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Широкой дугой к центру ладони'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Линия жизни: широкой дугой'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Дальше: Линия сердца →'),
      150,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Дальше: Линия сердца →'));
    await tester.pumpAndSettle();
    expect(find.text('Где заканчивается линия сердца?'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Солнца'), 150, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Солнца'));
    await tester.pumpAndSettle();
    expect(find.text('Есть ли линия к безымянному пальцу?'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, 3000));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Тип руки'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Квадратная, ширина ≈ длине'));
    await tester.tap(find.text('Короче ладони'));
    await tester.pumpAndSettle();
    expect(find.text('Земная рука'), findsOneWidget);
    await tester.tap(find.text('💎 По фото'));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  test('таро: карта дня и расклад', () {
    expect(majorArcana, hasLength(22));
    final d = DateTime(2026, 11, 11, 8), e = DateTime(2026, 11, 11, 23);
    expect(cardOfDay('Анна', d).name, cardOfDay('Анна', e).name);
    String names(List<DrawnCard> l) => l.map((c) => '${c.card.name}${c.reversed}').join();
    final s = spreadFor('Анна', 'Как пройдёт мой день?', d);
    expect(s.map((c) => c.card.name).toSet(), hasLength(3));
    expect(names(spreadFor('Анна', 'как пройдет день', e)), names(s));
    expect(normalizeQuestion('Как пройдёт мой день?'), normalizeQuestion('как пройдет день'));
    // вопрос про день меняется завтра, вопрос без времени не меняется
    final tomorrow = d.add(const Duration(days: 1));
    final days = {for (var i = 0; i < 10; i++) names(spreadFor('Анна', 'как пройдет день', d.add(Duration(days: i))))};
    expect(days.length, greaterThan(1));
    expect(names(spreadFor('Анна', 'Выйду ли я замуж?', d)), names(spreadFor('Анна', 'выйду замуж', tomorrow)));
  });

  testWidgets('экран раскладов', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState(Store(await SharedPreferences.getInstance()));
    await app.store.saveProfile(anna);
    await tester.pumpWidget(MaterialApp(home: TarotScreen(app: app)));
    await tester.tap(find.byType(TarotCard));
    await tester.pumpAndSettle();
    expect(find.textContaining('Карта дня:'), findsOneWidget);
    await tester.tap(find.text('3 карты'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Разложить карты'));
    await tester.pump(const Duration(seconds: 3));
    await tester.pumpAndSettle();
    expect(find.text('Толкование волшебницы'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('славянские символы: чертоги по дате', () {
    expect(chertogs, hasLength(16));
    expect(chertogOf(DateTime(1990, 11, 5)).name, 'Лебедь');
    expect(chertogOf(DateTime(1990, 2, 24)).name, 'Бусел (Аист)');
    expect(chertogOf(DateTime(1990, 2, 25)).name, 'Волк');
    expect(chertogOf(DateTime(1990, 1, 3)).name, 'Ворон');
    expect(chertogOf(DateTime(1990, 12, 31)).name, 'Ворон');
    final names = [for (final s in signs) s.name];
    expect(zodiacOverlap(chertogs.firstWhere((c) => c.name == 'Лебедь'), signIndexOf, names), ['Скорпион', 'Стрелец']);
    for (final e in elements) {
      expect(slavicMotifs.where((m) => m.element == e), isNotEmpty);
    }
  });

  testWidgets('экран славянских символов', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final app = AppState(Store(await SharedPreferences.getInstance()));
    await app.store.saveProfile(anna);
    await tester.pumpWidget(MaterialApp(home: SlavicScreen(app: app)));
    await tester.tap(find.text('Солнечная розетка'));
    await tester.pumpAndSettle();
    expect(find.text('КОГДА ЛУЧШЕ ИСПОЛЬЗОВАТЬ'), findsOneWidget);
    await tester.tap(find.text('Сварожий круг'));
    await tester.pumpAndSettle();
    expect(find.text('Чертог Лебедь'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
