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

/// Профиль на телефоне: данные человека и необязательный код входа (хранится только хэш).
class ProfileEntry {
  final String id;
  final Profile profile;
  final String? pinHash;
  const ProfileEntry(this.id, this.profile, [this.pinHash]);

  Map<String, dynamic> toJson() => {'id': id, 'profile': profile.toJson(), if (pinHash != null) 'pin': pinHash};

  factory ProfileEntry.fromJson(Map<String, dynamic> j) =>
      ProfileEntry(j['id'] as String, Profile.fromJson(j['profile'] as Map<String, dynamic>), j['pin'] as String?);
}

String hashPin(String id, String pin) {
  var h = 0x811c9dc5;
  for (final c in '$id:$pin:astroway'.codeUnits) {
    h ^= c;
    h = (h * 0x01000193) & 0xFFFFFFFF;
  }
  return h.toRadixString(16);
}

/// Настройки и профили хранятся только на телефоне (shared_preferences).
/// Профилей может быть несколько (семья на одном телефоне), один из них активный.
class Store {
  static const _legacyProfileKey = 'astroway-profile';
  static const _profilesKey = 'astroway-profiles';
  static const _activeKey = 'astroway-active';
  static const _toneKey = 'astroway-tone-easy';
  static const _largeKey = 'astroway-large-font';
  static const legacyId = 'main';

  final SharedPreferences prefs;
  Store(this.prefs) {
    _migrate();
  }

  static Future<Store> open() async => Store(await SharedPreferences.getInstance());

  /// Старые версии хранили один профиль: переносим его в список и делаем активным.
  void _migrate() {
    final raw = prefs.getString(_legacyProfileKey);
    if (raw == null || prefs.getString(_profilesKey) != null) return;
    try {
      final p = Profile.fromJson(jsonDecode(raw) as Map<String, dynamic>);
      prefs.setString(_profilesKey, jsonEncode([ProfileEntry(legacyId, p).toJson()]));
      prefs.setString(_activeKey, legacyId);
    } catch (_) {}
    prefs.remove(_legacyProfileKey);
  }

  List<ProfileEntry> get profiles {
    final raw = prefs.getString(_profilesKey);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => ProfileEntry.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _saveAll(List<ProfileEntry> list) =>
      prefs.setString(_profilesKey, jsonEncode(list.map((e) => e.toJson()).toList()));

  String? get activeId {
    final id = prefs.getString(_activeKey);
    return profiles.any((e) => e.id == id) ? id : null;
  }

  ProfileEntry? get active {
    final id = activeId;
    if (id == null) return null;
    return profiles.firstWhere((e) => e.id == id);
  }

  Profile? get profile => active?.profile;

  /// Обновляет активный профиль или, если входа нет, создаёт новый и входит в него.
  Future<void> saveProfile(Profile p) async {
    final list = profiles;
    final id = activeId;
    final i = list.indexWhere((e) => e.id == id);
    if (i >= 0) {
      list[i] = ProfileEntry(list[i].id, p, list[i].pinHash);
      await _saveAll(list);
    } else {
      await addProfile(p);
    }
  }

  Future<String> addProfile(Profile p) async {
    final id = 'p${DateTime.now().microsecondsSinceEpoch}';
    await _saveAll([...profiles, ProfileEntry(id, p)]);
    await prefs.setString(_activeKey, id);
    return id;
  }

  Future<void> login(String id) => prefs.setString(_activeKey, id);
  Future<void> logout() => prefs.remove(_activeKey);

  Future<void> deleteProfile(String id) async {
    await _saveAll(profiles.where((e) => e.id != id).toList());
    await prefs.remove(memoryKeyFor(id));
    if (prefs.getString(_activeKey) == id) await logout();
  }

  Future<void> setPin(String id, String? pin) async {
    final list = profiles;
    final i = list.indexWhere((e) => e.id == id);
    if (i < 0) return;
    list[i] = ProfileEntry(id, list[i].profile, pin == null || pin.isEmpty ? null : hashPin(id, pin));
    await _saveAll(list);
  }

  bool checkPin(ProfileEntry e, String pin) => e.pinHash == null || e.pinHash == hashPin(e.id, pin);

  /// Ответы волшебнице у каждого профиля свои. Старый единственный профиль сохраняет прежний ключ.
  static String memoryKeyFor(String id) => id == legacyId ? 'astroway-answers' : 'astroway-answers-$id';

  bool get easyTone => prefs.getBool(_toneKey) ?? false;
  Future<void> setEasyTone(bool v) => prefs.setBool(_toneKey, v);

  bool? get largeFont => prefs.getBool(_largeKey);
  Future<void> setLargeFont(bool v) => prefs.setBool(_largeKey, v);
}
