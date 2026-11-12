import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Ответ пользователя на вопрос волшебницы. Используется в следующих толкованиях.
class WitchAnswer {
  final DateTime date;
  final List<String> symbols;
  final String answer;
  final String type; // dream, omen, ...

  const WitchAnswer(this.date, this.symbols, this.answer, this.type);

  Map<String, dynamic> toJson() => {'date': date.toIso8601String(), 'symbols': symbols, 'answer': answer, 'type': type};

  factory WitchAnswer.fromJson(Map<String, dynamic> j) => WitchAnswer(
    DateTime.parse(j['date'] as String),
    (j['symbols'] as List).cast<String>(),
    j['answer'] as String,
    j['type'] as String? ?? 'dream',
  );
}

class WitchMemory {
  static const _limit = 200;
  final SharedPreferences prefs;
  final String _key;
  WitchMemory(this.prefs, [this._key = 'astroway-answers']);

  List<WitchAnswer> all() {
    final raw = prefs.getString(_key);
    if (raw == null) return [];
    try {
      return (jsonDecode(raw) as List).map((e) => WitchAnswer.fromJson(e as Map<String, dynamic>)).toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> add(WitchAnswer a) async {
    final list = [...all(), a];
    final trimmed = list.length > _limit ? list.sublist(list.length - _limit) : list;
    await prefs.setString(_key, jsonEncode(trimmed.map((e) => e.toJson()).toList()));
  }

  /// Последний ответ с общим символом, иначе самый последний ответ.
  WitchAnswer? recallFor(List<String> symbols) {
    final list = all();
    if (list.isEmpty) return null;
    for (final a in list.reversed) {
      if (a.symbols.any(symbols.contains)) return a;
    }
    return list.last;
  }

  Future<void> clear() => prefs.remove(_key);
}
