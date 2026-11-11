import 'package:astroway/data/dream_base.dart';
import 'package:astroway/logic/daily.dart';
import 'package:astroway/logic/interpret.dart';
import 'package:astroway/logic/memory.dart';
import 'package:astroway/logic/moon.dart';
import 'package:astroway/logic/profile.dart';
import 'package:astroway/logic/zodiac.dart';
import 'package:astroway/screens/home.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
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
    expect(findSymbols('Я летала над морем и нашла монеты').map((s) => s.name), containsAll(['Вода', 'Деньги', 'Полёт']));
    expect(findSymbols('ничего похожего'), isEmpty);
  });

  test('волшебница помнит ответ', () async {
    SharedPreferences.setMockInitialValues({});
    final mem = WitchMemory(await SharedPreferences.getInstance());
    final now = DateTime(2026, 11, 11);
    expect(interpretDream('вода', anna, now, mem).memoryLine, isNull);
    await mem.add(WitchAnswer(now, ['Вода'], 'переезд', 'dream'));
    final r = interpretDream('плавала в море', anna, now, mem);
    expect(r.memoryLine, contains('связала образ «Вода»'));
    expect(r.memoryLine, contains('переезд'));
    expect(r.witchQuestion, contains('Вода'));
  });
}
