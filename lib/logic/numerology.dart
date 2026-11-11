import '../data/numerology_texts.dart';

/// Расчёты нумерологии как в макете. Мастер-числа 11, 22, 33 сохраняются
/// в числе жизненного пути и числе имени.
class NumResult {
  final int n;
  final List<String> steps; // цепочка расчёта для анимации
  const NumResult(this.n, this.steps);
}

const masters = [11, 22, 33];
const cyrillic = 'абвгдеёжзийклмнопрстуфхцчшщъыьэюя';
const latin = 'abcdefghijklmnopqrstuvwxyz';

List<int> digitsOf(String s) => s.replaceAll(RegExp(r'\D'), '').split('').map(int.parse).toList();

int _sum(List<int> d) => d.fold(0, (a, b) => a + b);

NumResult reduceNum(int n, {bool keepMaster = true}) {
  final steps = <String>[];
  while (n > 9 && !(keepMaster && masters.contains(n))) {
    final d = digitsOf('$n');
    final s = _sum(d);
    steps.add('${d.join('+')} = $s');
    n = s;
  }
  return NumResult(n, steps);
}

String _dd(int v) => v.toString().padLeft(2, '0');

NumResult lifePath(DateTime b) {
  final d = digitsOf('${_dd(b.day)}${_dd(b.month)}${b.year}');
  final s = _sum(d);
  final r = reduceNum(s);
  return NumResult(r.n, ['${d.join('+')} = $s', ...r.steps]);
}

int letterValue(String c) {
  final i = cyrillic.indexOf(c);
  if (i >= 0) return i % 9 + 1;
  return latin.indexOf(c) % 9 + 1;
}

/// Число имени. Если в имени нет букв, берём число жизненного пути.
NumResult nameNumber(String name, DateTime birthday) {
  final letters = name.toLowerCase().split('').where((c) => cyrillic.contains(c) || latin.contains(c)).toList();
  if (letters.isEmpty) {
    final lp = lifePath(birthday);
    return NumResult(lp.n, ['? = ${lp.n}']);
  }
  final vals = letters.map(letterValue).toList();
  final s = _sum(vals);
  final r = reduceNum(s);
  return NumResult(r.n, [
    '${[for (var i = 0; i < letters.length; i++) '${letters[i].toUpperCase()}${vals[i]}'].join(' ')} = $s',
    ...r.steps,
  ]);
}

NumResult dayNumber(DateTime birthday, DateTime today) {
  final lp = lifePath(birthday).n;
  final d = digitsOf('${_dd(today.day)}${_dd(today.month)}${today.year}');
  final t = reduceNum(_sum(d), keepMaster: false).n;
  final r = reduceNum(t + lp, keepMaster: false);
  return NumResult(r.n, ['сегодня ${d.join('+')} → $t', '+ твоё $lp = ${t + lp}', ...r.steps]);
}

NumResult personalYear(DateTime birthday, int year) {
  final d = digitsOf('${_dd(birthday.day)}${_dd(birthday.month)}$year');
  final s = _sum(d);
  final r = reduceNum(s, keepMaster: false);
  return NumResult(r.n, ['${d.join('+')} = $s', ...r.steps]);
}

class NumCompat {
  final int a, b;
  final String level, text;
  const NumCompat(this.a, this.b, this.level, this.text);
}

NumCompat numCompatibility(DateTime me, DateTime partner) {
  final a = lifePath(me).n, b = lifePath(partner).n;
  const groups = [
    [1, 5, 7],
    [2, 4, 8],
    [3, 6, 9],
  ];
  int base(int x) => x > 9 ? reduceNum(x, keepMaster: false).n : x;
  final ga = groups.indexWhere((g) => g.contains(base(a)));
  final gb = groups.indexWhere((g) => g.contains(base(b)));
  final level = a == b
      ? 'Зеркальная пара'
      : ga == gb
      ? 'Высокая совместимость'
      : 'Совместимость через компромисс';
  final text = ga == gb
      ? 'Ваши числа из одной гармоничной группы: вы понимаете друг друга без слов и смотрите в одну сторону.'
      : 'Вы разные, и в этом ваша сила: ${numMeanings[a]![1]} встречается с ${numMeanings[b]![1]}. '
            'Договаривайтесь, и пара станет крепче.';
  return NumCompat(a, b, level, text);
}

/// Подставляет формы {женская|мужская}; если пол не указан, пишет «женская (мужская)».
String genderize(String s, bool? female) => s.replaceAllMapped(RegExp(r'\{([^|}]+)\|([^}]+)\}'), (m) {
  if (female == true) return m[1]!;
  if (female == false) return m[2]!;
  return '${m[1]} (${m[2]})';
});

String _firstSentence(String t) => t.split(RegExp(r'(?<=\.)\s')).first.replaceAll(RegExp(r'\.$'), '');

const sphereEmoji = {'general': '✨', 'love': '💞', 'money': '💰', 'health': '🌿'};

/// Текст по сфере с учётом тона «Легко».
String sphereText(int n, String sphere, String base, {required bool easy}) {
  if (sphere == 'general') return easy ? '${_firstSentence(base)} 🔮' : base;
  final t = sphereTexts[sphere]![n]!;
  if (!easy) return t;
  if (n == 7 && sphere == 'money') return easy7Money;
  return '${_firstSentence(t)} ${sphereEmoji[sphere]}';
}
