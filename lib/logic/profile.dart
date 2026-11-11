import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

enum Gender { female, male, unspecified }

/// Интервалы времени рождения: 8 по 3 часа или «не помню».
const List<String> birthSlots = ['06–09', '09–12', '12–15', '15–18', '18–21', '21–24', '00–03', '03–06'];
const String slotUnknown = 'unknown';

class Profile {
  final String name;
  final Gender gender;
  final DateTime birthday;
  final String birthSlot; // один из birthSlots или slotUnknown

  const Profile({required this.name, required this.gender, required this.birthday, required this.birthSlot});

  bool get isFemale => gender != Gender.male;

  int ageOn(DateTime now) {
    var age = now.year - birthday.year;
    if (now.month < birthday.month || (now.month == birthday.month && now.day < birthday.day)) {
      age--;
    }
    return age;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'gender': gender.name,
    'birthday': birthday.toIso8601String().substring(0, 10),
    'birthSlot': birthSlot,
  };

  factory Profile.fromJson(Map<String, dynamic> j) => Profile(
    name: j['name'] as String,
    gender: Gender.values.firstWhere((g) => g.name == j['gender'], orElse: () => Gender.unspecified),
    birthday: DateTime.parse(j['birthday'] as String),
    birthSlot: j['birthSlot'] as String? ?? slotUnknown,
  );
}

String yearsWord(int n) {
  final m10 = n % 10, m100 = n % 100;
  if (m10 == 1 && m100 != 11) return 'год';
  if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return 'года';
  return 'лет';
}

/// Настройки и профиль хранятся только на телефоне (shared_preferences).
class Store {
  static const _profileKey = 'astroway-profile';
  static const _toneKey = 'astroway-tone-easy';
  static const _largeKey = 'astroway-large-font';

  final SharedPreferences prefs;
  Store(this.prefs);

  static Future<Store> open() async => Store(await SharedPreferences.getInstance());

  Profile? get profile {
    final raw = prefs.getString(_profileKey);
    if (raw == null) return null;
    try {
      return Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  Future<void> saveProfile(Profile p) => prefs.setString(_profileKey, jsonEncode(p.toJson()));

  bool get easyTone => prefs.getBool(_toneKey) ?? false;
  Future<void> setEasyTone(bool v) => prefs.setBool(_toneKey, v);

  bool? get largeFont => prefs.getBool(_largeKey);
  Future<void> setLargeFont(bool v) => prefs.setBool(_largeKey, v);
}
