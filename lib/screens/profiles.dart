import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../logic/profile.dart';
import '../logic/zodiac.dart';
import '../main.dart';
import '../theme.dart';
import 'onboarding.dart';

/// Вход: выбор профиля на этом телефоне. У каждого свой прогноз и своя память волшебницы.
class ProfilesScreen extends StatelessWidget {
  final AppState app;
  const ProfilesScreen({super.key, required this.app});

  Future<void> _enter(BuildContext context, ProfileEntry e) async {
    if (e.pinHash != null) {
      final pin = await askPin(context, 'Код входа для ${e.profile.name}');
      if (pin == null) return;
      if (!app.store.checkPin(e, pin)) {
        if (context.mounted) _toast(context, 'Неверный код');
        return;
      }
    }
    await app.login(e);
  }

  Future<void> _delete(BuildContext context, ProfileEntry e) async {
    if (e.pinHash != null) {
      final pin = await askPin(context, 'Код входа для ${e.profile.name}');
      if (pin == null) return;
      if (!app.store.checkPin(e, pin)) {
        if (context.mounted) _toast(context, 'Неверный код');
        return;
      }
    }
    if (!context.mounted) return;
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Удалить профиль ${e.profile.name}?'),
        content: const Text('Удалятся данные профиля и ответы волшебнице. Вернуть их будет нельзя.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Отмена')),
          TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Удалить')),
        ],
      ),
    );
    if (ok == true) await app.deleteProfile(e.id);
  }

  @override
  Widget build(BuildContext context) {
    final list = app.profiles;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 32, 20, 32),
          children: [
            const Text(
              'AstroWay',
              style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: AW.gold),
            ),
            const SizedBox(height: 6),
            const Text('Кто заходит?', style: TextStyle(color: AW.soft, fontSize: 17)),
            const SizedBox(height: 20),
            for (final e in list) ...[
              GlassCard(
                child: Material(
                  type: MaterialType.transparency,
                  child: InkWell(
                    onTap: () => _enter(context, e),
                    child: Row(
                      children: [
                        Text(signOf(e.profile.birthday).symbol, style: const TextStyle(fontSize: 30, color: AW.gold)),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(e.profile.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                              Text(signOf(e.profile.birthday).name, style: const TextStyle(color: AW.soft)),
                            ],
                          ),
                        ),
                        if (e.pinHash != null) const Icon(Icons.lock_outline, color: AW.soft, size: 20),
                        IconButton(
                          tooltip: 'Удалить профиль',
                          icon: const Icon(Icons.delete_outline, color: AW.soft),
                          onPressed: () => _delete(context, e),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
            const SizedBox(height: 6),
            OutlinedButton.icon(
              onPressed: () =>
                  Navigator.of(context)
                      .push(MaterialPageRoute(builder: (_) => OnboardingScreen(app: app, addNew: true))),
              icon: const Icon(Icons.add),
              label: const Text('Добавить профиль'),
            ),
            const SizedBox(height: 16),
            const Text(
              'Профили хранятся только на этом телефоне. Код входа можно поставить в меню на главном экране.',
              style: TextStyle(color: AW.soft, fontSize: 12.5),
            ),
          ],
        ),
      ),
    );
  }
}

void _toast(BuildContext context, String text) =>
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));

/// Окно ввода кода из 4 цифр. Возвращает код или null, если отменили.
Future<String?> askPin(BuildContext context, String title) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: c,
        autofocus: true,
        obscureText: true,
        keyboardType: TextInputType.number,
        maxLength: 4,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(hintText: '4 цифры'),
        onSubmitted: (v) => v.length == 4 ? Navigator.pop(ctx, v) : null,
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
        TextButton(
          onPressed: () => c.text.length == 4 ? Navigator.pop(ctx, c.text) : null,
          child: const Text('Готово'),
        ),
      ],
    ),
  );
}

/// Меню профиля на главном: код входа и выход.
class ProfileMenu extends StatelessWidget {
  final AppState app;
  const ProfileMenu({super.key, required this.app});

  @override
  Widget build(BuildContext context) {
    final e = app.store.active;
    return PopupMenuButton<String>(
      tooltip: 'Профиль',
      icon: const Icon(Icons.account_circle_outlined, color: AW.gold),
      onSelected: (v) async {
        if (e == null) return;
        switch (v) {
          case 'pin':
            final pin = await askPin(context, 'Новый код входа');
            if (pin != null) {
              await app.setPin(e.id, pin);
              if (context.mounted) _toast(context, 'Код входа сохранён');
            }
          case 'nopin':
            await app.setPin(e.id, null);
            if (context.mounted) _toast(context, 'Код входа убран');
          case 'logout':
            await app.logout();
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(enabled: false, child: Text(e?.profile.name ?? '')),
        PopupMenuItem(value: 'pin', child: Text(e?.pinHash == null ? 'Поставить код входа' : 'Сменить код входа')),
        if (e?.pinHash != null) const PopupMenuItem(value: 'nopin', child: Text('Убрать код входа')),
        const PopupMenuItem(value: 'logout', child: Text('Выйти и сменить профиль')),
      ],
    );
  }
}
