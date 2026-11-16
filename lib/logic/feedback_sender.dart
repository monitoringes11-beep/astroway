import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// Отправка отзывов прямо из приложения через бесплатный сервис пересылки FormSubmit.
/// Письмо приходит на почту владельца, человек адрес не видит. Без интернета отзыв
/// ждёт в очереди на телефоне и уходит сам при следующем запуске или отправке.
class FeedbackSender {
  // Адрес хранится закодированным, в интерфейсе он нигде не показывается.
  static const _to = 'bW9uaXRvcmluZ2VzMTFAZ21haWwuY29t';
  static const _queueKey = 'astroway-feedback-queue';

  static Uri get _endpoint => Uri.parse('https://formsubmit.co/ajax/${utf8.decode(base64.decode(_to))}');

  /// Для тестов можно подменить отправку.
  static Future<bool> Function(Map<String, String>) transport = _post;

  static Future<bool> _post(Map<String, String> fields) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.postUrl(_endpoint);
      req.headers.contentType = ContentType.json;
      req.headers.set(HttpHeaders.acceptHeader, 'application/json');
      req.add(
        utf8.encode(jsonEncode({'_subject': 'AstroWay: отзыв', '_template': 'table', '_captcha': 'false', ...fields})),
      );
      final res = await req.close().timeout(const Duration(seconds: 20));
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) return false;
      final j = jsonDecode(body);
      return j is Map && '${j['success']}' == 'true';
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
