enum Subject {
  chinese('语文'),
  math('数学'),
  english('英语'),
  physics('物理'),
  chemistry('化学'),
  biology('生物'),
  history('历史'),
  geography('地理'),
  politics('政治'),
  science('科学'),
  custom('自定义');

  const Subject(this.label);
  final String label;
}
