import 'dart:ui' show Color;

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import 'notify_plan.dart';
import 'profile.dart';

/// Где хранятся настройки уведомлений (общие для телефона).
class NotifyPrefs {
  static const _fOn = 'astroway-notify-forecast';
  static const _fAt = 'astroway-notify-forecast-at';
  static const _mOn = 'astroway-notify-moon';
  static const _mAt = 'astroway-notify-moon-at';

  static NotifySettings read(SharedPreferences p) {
    const d = NotifySettings();
    return NotifySettings(
      forecastOn: p.getBool(_fOn) ?? d.forecastOn,
      forecastMinutes: p.getInt(_fAt) ?? d.forecastMinutes,
      moonOn: p.getBool(_mOn) ?? d.moonOn,
      moonMinutes: p.getInt(_mAt) ?? d.moonMinutes,
    );
  }

  static Future<void> write(SharedPreferences p, NotifySettings s) async {
    await p.setBool(_fOn, s.forecastOn);
    await p.setInt(_fAt, s.forecastMinutes);
    await p.setBool(_mOn, s.moonOn);
    await p.setInt(_mAt, s.moonMinutes);
  }
}

/// Куда отправляются уведомления. В тестах подменяется заглушкой.
abstract class NoticeSink {
  Future<void> replaceAll(List<PlannedNotice> plan);
  Future<bool> askPermission();
}

/// Локальные уведомления Android. Без сервера и интернета: всё ставится в будильники телефона.
class LocalNoticeSink implements NoticeSink {
  final _plugin = FlutterLocalNotificationsPlugin();
  bool _ready = false;

  Future<void> _init() async {
    if (_ready) return;
    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(android: AndroidInitializationSettings('ic_stat_astroway')),
    );
    _ready = true;
  }

  AndroidFlutterLocalNotificationsPlugin? get _android =>
      _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();

  @override
  Future<bool> askPermission() async {
    await _init();
    return await _android?.requestNotificationsPermission() ?? false;
  }

  static const _channels = {
    'forecast': ('Прогноз дня', 'Утренний личный прогноз по знаку'),
    'moon': ('Фазы Луны', 'Когда Луна переходит в новую фазу'),
  };

  @override
  Future<void> replaceAll(List<PlannedNotice> plan) async {
    await _init();
    await _plugin.cancelAllPendingNotifications();
    for (final n in plan) {
      final ch = _channels[n.channel]!;
      await _plugin.zonedSchedule(
        id: n.id,
        title: n.title,
        body: n.body,
        // местное время телефона переводим в точный момент (UTC), часовой пояс не нужен
        scheduledDate: tz.TZDateTime.from(n.at, tz.UTC),
        notificationDetails: NotificationDetails(
          android: AndroidNotificationDetails(
            n.channel,
            ch.$1,
            channelDescription: ch.$2,
            styleInformation: BigTextStyleInformation(n.body),
            color: const Color(0xFFF3C96B),
          ),
        ),
        // неточный будильник: не нужно особое разрешение, Android может сдвинуть на несколько минут
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }
}

/// Пересобирает план уведомлений: при запуске, смене профиля, тона и настроек.
class Notifier {
  static NoticeSink sink = LocalNoticeSink();
  static Future<void> _queue = Future.value();
  static const _askedKey = 'astroway-notify-asked';

  /// Один раз спрашиваем разрешение на уведомления (Android 13+), когда профиль уже есть.
  static Future<void> askOnce(SharedPreferences prefs) async {
    if (prefs.getBool(_askedKey) == true) return;
    await prefs.setBool(_askedKey, true);
    try {
      await sink.askPermission();
    } catch (e) {
      debugPrint('Разрешение на уведомления не запрошено: $e');
    }
  }

  /// Пересборки идут по очереди, чтобы не перемешались отмена и постановка.
  static Future<void> refresh({
    required SharedPreferences prefs,
    required ProfileEntry? entry,
    required bool easy,
    DateTime? now,
  }) => _queue = _queue.then((_) => _refresh(prefs: prefs, entry: entry, easy: easy, now: now));

  static Future<void> _refresh({
    required SharedPreferences prefs,
    required ProfileEntry? entry,
    required bool easy,
    DateTime? now,
  }) async {
    final plan = buildPlan(
      now: now ?? DateTime.now(),
      s: NotifyPrefs.read(prefs),
      profile: entry?.profile,
      easy: easy,
      // профиль с кодом входа: на экране блокировки не показываем личный прогноз
      private: entry?.pinHash != null,
    );
    try {
      await sink.replaceAll(plan);
    } catch (e) {
      debugPrint('Уведомления не поставлены: $e');
    }
  }
}
