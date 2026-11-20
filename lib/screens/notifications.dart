import 'package:flutter/material.dart';

import '../logic/notifier.dart';
import '../logic/notify_plan.dart';
import '../main.dart';
import '../theme.dart';

/// Настройки уведомлений: утренний прогноз и смена фазы Луны. Время и вкл/выкл — у каждого своё.
class NotificationsScreen extends StatefulWidget {
  final AppState app;
  const NotificationsScreen({super.key, required this.app});
  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late NotifySettings s = NotifyPrefs.read(widget.app.store.prefs);

  Future<void> _save(NotifySettings v) async {
    setState(() => s = v);
    await NotifyPrefs.write(widget.app.store.prefs, v);
    if (v.forecastOn || v.moonOn) await Notifier.sink.askPermission().catchError((_) => false);
    await widget.app.refreshNotices();
  }

  Future<int?> _pickTime(int minutes) async {
    final t = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: minutes ~/ 60, minute: minutes % 60),
      helpText: 'Во сколько присылать',
      cancelText: 'Отмена',
      confirmText: 'Готово',
      builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    return t == null ? null : t.hour * 60 + t.minute;
  }

  Widget _block({
    required IconData icon,
    required String title,
    required String hint,
    required bool on,
    required int minutes,
    required ValueChanged<bool> onToggle,
    required ValueChanged<int> onTime,
  }) {
    return GlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 24, color: AW.soft),
              const SizedBox(width: 12),
              Expanded(
                child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w500)),
              ),
              Switch(value: on, onChanged: onToggle),
            ],
          ),
          const SizedBox(height: 4),
          Text(hint, style: const TextStyle(color: AW.soft, fontSize: 14)),
          if (on) ...[
            const SizedBox(height: 8),
            OutlinedButton.icon(
              icon: const Icon(Icons.schedule),
              label: Text('Время: ${hhmm(minutes)}'),
              onPressed: () async {
                final m = await _pickTime(minutes);
                if (m != null) onTime(m);
              },
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.app.store.active?.pinHash != null;
    return Scaffold(
      appBar: AppBar(title: const Text('Уведомления'), backgroundColor: Colors.transparent),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _block(
            icon: Icons.wb_sunny_outlined,
            title: 'Прогноз дня',
            hint: locked
                ? 'Профиль с кодом входа: в уведомлении будет только «Прогноз дня готов», без личного текста.'
                : 'Тема дня и настроение по вашему знаку — тот же прогноз, что на главном экране.',
            on: s.forecastOn,
            minutes: s.forecastMinutes,
            onToggle: (v) => _save(s.copyWith(forecastOn: v)),
            onTime: (m) => _save(s.copyWith(forecastMinutes: m)),
          ),
          const SizedBox(height: 12),
          _block(
            icon: Icons.bedtime_outlined,
            title: 'Смена фазы Луны',
            hint: 'Новолуние, растущая Луна, полнолуние, убывающая Луна — и подсказка, какой заговор подходит.',
            on: s.moonOn,
            minutes: s.moonMinutes,
            onToggle: (v) => _save(s.copyWith(moonOn: v)),
            onTime: (m) => _save(s.copyWith(moonMinutes: m)),
          ),
          const SizedBox(height: 16),
          const Text(
            'Уведомления ставятся прямо на телефоне, без интернета. Если Android их не показывает, '
            'проверьте в настройках телефона, что уведомления для AstroWay разрешены.',
            style: TextStyle(color: AW.soft, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
