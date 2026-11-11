import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:shared_preferences/shared_preferences.dart';

/// Символ сонника. Толкования пересказаны по-русски по соннику Миллера (1901,
/// общественное достояние); у части символов есть народные приметы.
class DreamSymbol {
  final String name;
  final List<String> keys;
  final String classic;
  final String? folk;
  final String source;
  const DreamSymbol(this.name, this.keys, this.classic, this.folk, this.source);

  factory DreamSymbol.fromJson(Map<String, dynamic> j) => DreamSymbol(
    j['ru'] as String,
    (j['k'] as List).cast<String>(),
    j['t'] as String,
    j['f'] as String?,
    (j['src'] as String?) ?? 'Миллер, 1901',
  );
}

/// База символов, загружается из assets/dreams_ru.json.
class DreamBase {
  static List<DreamSymbol> symbols = [];
  static const asset = 'assets/dreams_ru.json';
  static const _missedKey = 'astroway-missed-dreams';

  static Future<void> loadAsset() async => load(await rootBundle.loadString(asset));

  static void load(String json) {
    symbols = (jsonDecode(json) as List).map((e) => DreamSymbol.fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Запоминаем на устройстве сны, для которых не нашлось символа,
  /// чтобы пополнять базу в первую очередь этими словами.
  static Future<void> logMissed(String text) async {
    final p = await SharedPreferences.getInstance();
    final list = p.getStringList(_missedKey) ?? [];
    list.add(text);
    await p.setStringList(_missedKey, list.length > 100 ? list.sublist(list.length - 100) : list);
  }

  static Future<List<String>> missed() async => (await SharedPreferences.getInstance()).getStringList(_missedKey) ?? [];
}

String _norm(String s) => s.toLowerCase().replaceAll('ё', 'е');

/// Ищет символы в тексте сна. Ключ с «=» на конце означает точную форму слова,
/// без «=» это основа (начало слова). Для каждого слова берётся самое длинное
/// совпадение, чтобы «лестница» не путалась с «лесом».
List<DreamSymbol> findSymbols(String text, {int limit = 5}) {
  final words = RegExp(r'[а-яa-z]+').allMatches(_norm(text)).map((m) => m[0]!);
  final found = <DreamSymbol>[];
  for (final w in words) {
    if (w.length < 2) continue;
    DreamSymbol? best;
    var bestLen = 0;
    for (final s in DreamBase.symbols) {
      for (final k in s.keys) {
        final exact = k.endsWith('=');
        final stem = exact ? k.substring(0, k.length - 1) : k;
        final ok = exact ? w == stem : w.startsWith(stem);
        if (ok && stem.length > bestLen) {
          best = s;
          bestLen = stem.length;
        }
      }
    }
    if (best != null && !found.contains(best)) found.add(best);
    if (found.length >= limit) break;
  }
  return found;
}
