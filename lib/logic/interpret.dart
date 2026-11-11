import '../data/dream_base.dart';
import 'memory.dart';
import 'moon.dart';
import 'profile.dart';
import 'zodiac.dart';

class DreamReading {
  final String text;
  final List<DreamSymbol> symbols;
  final String personal;
  final String? memoryLine;
  final String witchQuestion;
  const DreamReading(this.text, this.symbols, this.personal, this.memoryLine, this.witchQuestion);

  List<String> get symbolNames => symbols.map((s) => s.name).toList();
}

const signoff = 'Толкование — подсказка, а не приговор. Сравни сон со своей жизнью.';
const sourcesNote =
    'Источники: классические сонники (Миллер 1901 и старые русские сонники) и народные приметы, '
    'пересказанные нашими словами. Если символа нет в базе, волшебница честно скажет об этом.';

String _phaseText(MoonPhase p) => switch (p) {
      MoonPhase.newMoon => 'сны в новолуние говорят о начале: то, что приснилось, связано с новым этапом.',
      MoonPhase.young => 'на растущей Луне сны показывают, что набирает силу в твоей жизни.',
      MoonPhase.full => 'в полнолуние сны самые яркие: отнесись к этому сну внимательно.',
      MoonPhase.old => 'на убывающей Луне сны подсказывают, что пора отпустить.',
    };

String _dateRu(DateTime d) {
  const m = ['января', 'февраля', 'марта', 'апреля', 'мая', 'июня', 'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря'];
  return '${d.day} ${m[d.month - 1]}';
}

DreamReading interpretDream(String text, Profile p, DateTime now, WitchMemory memory) {
  final found = findSymbols(text);
  final names = found.map((s) => s.name).toList();
  final sign = signOf(p.birthday);
  final moon = moonFor(now);
  final personal = '${p.name}, ${_phaseText(moon.phase)} Для знака ${sign.name} этот сон советует '
      'довериться интуиции и не спешить с решениями ближайшие три дня.';

  String? memoryLine;
  final prev = memory.recallFor(names);
  if (prev != null) {
    final same = prev.symbols.where(names.contains).toList();
    if (same.isNotEmpty) {
      final verb = p.isFemale ? 'связала' : 'связал';
      memoryLine = 'Волшебница помнит: ${_dateRu(prev.date)} ты $verb образ «${same.first}» с: «${prev.answer}». '
          'Сегодня он снова рядом, возможно, тема ещё не закрыта.';
    } else {
      memoryLine = 'Волшебница помнит: ${_dateRu(prev.date)} ты писал${p.isFemale ? 'а' : ''}: «${prev.answer}». '
          'Посмотри, нет ли связи с сегодняшним сном.';
    }
  }
  final q = 'С чем образ «${names.isEmpty ? 'из этого сна' : names.first}» связан у тебя сейчас?';
  return DreamReading(text, found, personal, memoryLine, q);
}
