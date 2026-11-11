class ZodiacSign {
  final String symbol;
  final String name;
  final String range;
  const ZodiacSign(this.symbol, this.name, this.range);
}

/// Порядок как в макете: индекс % 4 даёт стихию (0 земля, 1 воздух, 2 вода, 3 огонь).
const List<ZodiacSign> signs = [
  ZodiacSign('♑︎', 'Козерог', '22 декабря – 19 января'),
  ZodiacSign('♒︎', 'Водолей', '20 января – 18 февраля'),
  ZodiacSign('♓︎', 'Рыбы', '19 февраля – 20 марта'),
  ZodiacSign('♈︎', 'Овен', '21 марта – 19 апреля'),
  ZodiacSign('♉︎', 'Телец', '20 апреля – 20 мая'),
  ZodiacSign('♊︎', 'Близнецы', '21 мая – 20 июня'),
  ZodiacSign('♋︎', 'Рак', '21 июня – 22 июля'),
  ZodiacSign('♌︎', 'Лев', '23 июля – 22 августа'),
  ZodiacSign('♍︎', 'Дева', '23 августа – 22 сентября'),
  ZodiacSign('♎︎', 'Весы', '23 сентября – 22 октября'),
  ZodiacSign('♏︎', 'Скорпион', '23 октября – 21 ноября'),
  ZodiacSign('♐︎', 'Стрелец', '22 ноября – 21 декабря'),
];

const List<String> elements = ['Земля', 'Воздух', 'Вода', 'Огонь'];

int signIndexOf(int month, int day) {
  const order = [
    [1, 20, 1], [2, 19, 2], [3, 21, 3], [4, 20, 4], [5, 21, 5], [6, 21, 6],
    [7, 23, 7], [8, 23, 8], [9, 23, 9], [10, 23, 10], [11, 22, 11], [12, 22, 0],
  ];
  var idx = 0;
  for (final o in order) {
    if (month > o[0] || (month == o[0] && day >= o[1])) idx = o[2];
  }
  return idx;
}

ZodiacSign signOf(DateTime birthday) => signs[signIndexOf(birthday.month, birthday.day)];
