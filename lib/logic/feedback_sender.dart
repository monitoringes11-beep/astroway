import 'dart:convert';
import 'dart:io';

import 'package:shared_preferences/shared_preferences.dart';

/// Отправка отзывов прямо из приложения в Telegram владельцу через его бота.
/// Ключ бота и номер чата подставляются при сборке из секретных настроек GitHub
/// (--dart-define), в открытом коде их нет, и человек их нигде не видит.
/// Без интернета или пока бот не подключён отзыв ждёт в очереди и уходит сам позже.
class FeedbackSender {
  static const _botToken = String.fromEnvironment('TG_TOKEN');
  static const _chatId = String.fromEnvironment('TG_CHAT');
  static const _queueKey = 'astroway-feedback-queue';

  static bool get configured => _botToken.isNotEmpty && _chatId.isNotEmpty;

  /// Для тестов можно подменить отправку.
  static Future<bool> Function(Map<String, String>) transport = _post;

  static String messageText(Map<String, String> fields) =>
      ['📝 AstroWay: новый отзыв', for (final e in fields.entries) '${e.key}: ${e.value}'].join('\n');

  static Future<bool> _post(Map<String, String> fields) async {
    if (!configured) return false;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.postUrl(Uri.parse('https://api.telegram.org/bot$_botToken/sendMessage'));
      req.headers.contentType = ContentType.json;
      req.add(utf8.encode(jsonEncode({'chat_id': _chatId, 'text': messageText(fields)})));
      final res = await req.close().timeout(const Duration(seconds: 20));
      final body = await res.transform(utf8.decoder).join();
      if (res.statusCode != 200) return false;
      final j = jsonDecode(body);
      return j is Map && j['ok'] == true;
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
