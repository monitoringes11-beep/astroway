import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// Отправка отзывов прямо из приложения в Google Таблицу владельца через его скрипт Google
/// (Apps Script). Скрипт пишет отзыв в таблицу и присылает письмо. Адреса почты нет ни в
/// приложении, ни в коде: он хранится только в скрипте у владельца. Без интернета или
/// пока скрипт не подключён отзыв ждёт в очереди на телефоне и уходит сам позже.
class FeedbackSender {
  /// Адрес веб-приложения Apps Script (https://script.google.com/macros/s/.../exec).
  static const scriptUrl = '';
  static const _token = 'astroway-feedback-1';
  static const _queueKey = 'astroway-feedback-queue';

  /// Для тестов можно подменить отправку.
  static Future<bool> Function(Map<String, String>) transport = _post;

  static Future<bool> _post(Map<String, String> fields) async {
    if (scriptUrl.isEmpty) return false;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.postUrl(Uri.parse(scriptUrl));
      req.followRedirects = false; // Google отвечает 302 уже после того, как скрипт отработал
      req.headers.contentType = ContentType('text', 'plain', charset: 'utf-8');
      req.add(utf8.encode(jsonEncode({'token': _token, ...fields})));
      final res = await req.close().timeout(const Duration(seconds: 25));
      await res.drain<void>();
      return res.statusCode == 200 || res.statusCode == 302;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  /// Отправляет отзыв. Если не вышло, кладёт в очередь и возвращает false.
  static Future<bool> send(Map<String, String> fields) async {
    await flushQueue();
    if (await transport(fields)) return true;
    final p = await SharedPreferences.getInstance();
    final q = p.getStringList(_queueKey) ?? [];
    final all = [...q, jsonEncode(fields)];
    await p.setStringList(_queueKey, all.length > 20 ? all.sublist(all.length - 20) : all);
    return false;
  }

  /// Пробует отправить всё, что ждёт в очереди.
  static Future<void> flushQueue() async {
    final p = await SharedPreferences.getInstance();
    final q = p.getStringList(_queueKey) ?? [];
    if (q.isEmpty) return;
    final left = <String>[];
    for (final raw in q) {
      final fields = (jsonDecode(raw) as Map).map((k, v) => MapEntry('$k', '$v'));
      if (!await transport(fields)) left.add(raw);
    }
    await p.setStringList(_queueKey, left);
  }

  static Future<int> queued() async => ((await SharedPreferences.getInstance()).getStringList(_queueKey) ?? []).length;
}
