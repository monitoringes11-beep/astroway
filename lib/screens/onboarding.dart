import 'package:flutter/material.dart';

import '../logic/profile.dart';
import '../logic/zodiac.dart';
import '../main.dart';
import '../theme.dart';

/// Регистрация: имя, пол (необязательно), дата рождения, время рождения, согласие 152-ФЗ.
class OnboardingScreen extends StatefulWidget {
  final AppState app;
  final Profile? initial;
  const OnboardingScreen({super.key, required this.app, this.initial});
  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  late final TextEditingController _name = TextEditingController(text: widget.initial?.name ?? '');
  late Gender _gender = widget.initial?.gender ?? Gender.unspecified;
  late DateTime? _birthday = widget.initial?.birthday;
  late String _slot = widget.initial?.birthSlot ?? slotUnknown;
  late bool _consent = widget.initial != null;

  bool get _valid => _name.text.trim().isNotEmpty && _birthday != null && _consent && _oldEnough;

  bool get _oldEnough {
    final b = _birthday;
    if (b == null) return false;
    final p = Profile(name: '', gender: _gender, birthday: b, birthSlot: _slot);
    return p.ageOn(DateTime.now()) >= 16;
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _birthday ?? DateTime(now.year - 30, 6, 15),
      firstDate: DateTime(1920),
      lastDate: now,
      helpText: 'Дата рождения',
      initialEntryMode: DatePickerEntryMode.input,
    );
    if (d != null) setState(() => _birthday = d);
  }

  Future<void> _save() async {
    final p = Profile(name: _name.text.trim(), gender: _gender, birthday: _birthday!, birthSlot: _slot);
    await widget.app.saveProfile(p);
    if (mounted && widget.initial != null) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final b = _birthday;
    final p = b == null ? null : Profile(name: '', gender: _gender, birthday: b, birthSlot: _slot);
    final age = p?.ageOn(DateTime.now());
    return Scaffold(
      appBar: widget.initial != null ? AppBar(title: const Text('Мой профиль')) : null,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
          children: [
            if (widget.initial == null) ...[
              const Text(
                'AstroWay',
                style: TextStyle(fontSize: 34, fontWeight: FontWeight.w700, color: AW.gold),
              ),
              const SizedBox(height: 6),
              const Text('Сонник, гороскоп, расклады', style: TextStyle(color: AW.soft, fontSize: 16)),
              const SizedBox(height: 24),
              const Text('Давай познакомимся, чтобы прогнозы были именно для тебя.', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 20),
            ],
            TextField(
              controller: _name,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Как тебя зовут?'),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 18),
            const Label('Пол (необязательно)'),
            const SizedBox(height: 8),
            SegmentedButton<Gender>(
              segments: const [
                ButtonSegment(value: Gender.female, label: Text('Женщина')),
                ButtonSegment(value: Gender.male, label: Text('Мужчина')),
                ButtonSegment(value: Gender.unspecified, label: Text('Не указывать')),
              ],
              selected: {_gender},
              showSelectedIcon: false,
              onSelectionChanged: (s) => setState(() => _gender = s.first),
            ),
            const SizedBox(height: 18),
            const Label('Дата рождения'),
            const SizedBox(height: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: _pickDate,
              child: Text(
                b == null
                    ? 'Выбрать дату'
                    : '${b.day.toString().padLeft(2, '0')}.${b.month.toString().padLeft(2, '0')}.${b.year}',
              ),
            ),
            if (b != null) ...[
              const SizedBox(height: 8),
              Text(
                '${signOf(b).symbol} ${signOf(b).name} · $age ${yearsWord(age!)}',
                style: const TextStyle(color: AW.gold),
              ),
              if (!_oldEnough)
                const Padding(
                  padding: EdgeInsets.only(top: 6),
                  child: Text('Приложение для пользователей от 16 лет.', style: TextStyle(color: Colors.orangeAccent)),
                ),
            ],
            const SizedBox(height: 18),
            const Label('Время рождения (если знаешь)'),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final s in birthSlots)
                  ChoiceChip(label: Text(s), selected: _slot == s, onSelected: (_) => setState(() => _slot = s)),
                ChoiceChip(
                  label: const Text('Не помню'),
                  selected: _slot == slotUnknown,
                  onSelected: (_) => setState(() => _slot = slotUnknown),
                ),
              ],
            ),
            const SizedBox(height: 18),
            CheckboxListTile(
              value: _consent,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              onChanged: (v) => setState(() => _consent = v ?? false),
              title: const Text(
                'Мне есть 16 лет. Я согласна(ен) на обработку персональных данных (152-ФЗ) и понимаю, что прогнозы носят развлекательный характер.',
                style: TextStyle(fontSize: 13.5),
              ),
            ),
            const SizedBox(height: 12),
            FilledButton(onPressed: _valid ? _save : null, child: const Text('Сохранить')),
          ],
        ),
      ),
    );
  }
}
