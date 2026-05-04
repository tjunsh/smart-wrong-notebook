import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

final _reBlank = RegExp(r'_{2,}|＿{2,}|\(\s*\)|（\s*）');
final _reOptionRows =
    RegExp(r'(^|\n)\s*\d+[\.、．)]\s*[A-C][\.、．)]\s+', multiLine: true);
final _reEnglishPassage = RegExp(
    r'\b(the|that|which|while|however|because|people|money|family|should|china|saving|some|they|was|for|with|and|of|to)\b',
    caseSensitive: false);
final _reChineseMarker = RegExp(r'文常积累|字词释义|翻译卷|课文|文言文|释义');
final _reClassicalChinese = RegExp(r'问所从来|落英|缤纷|阡陌|桃花源记|岳阳楼记|醉翁亭记|出师表|陋室铭');
final _reHumanitiesMarker =
    RegExp(r'材料|阅读|填空|文综|历史|地理|政治|朝代|制度|事件|背景|原因|意义|影响|疆域|气候|地形|人口|公民|法治');
final _reNumberedBlanks =
    RegExp(r'(^|[^\d])(?:[1-9]|10)\s*[\.、．)]?\s*[A-C][\.、．)]', multiLine: true);

bool isCompositeLanguageWorksheet(String text, {Subject? subject}) {
  if (subject != null && !_supportsCompositeWorksheetDetection(subject)) {
    return false;
  }

  final hasEnglishPassage = _reEnglishPassage.allMatches(text).length >= 8;
  final optionRows = _reOptionRows.allMatches(text).length;
  final numberedBlanks = _reNumberedBlanks.allMatches(text).length;

  if (hasEnglishPassage && (optionRows >= 3 || numberedBlanks >= 5)) {
    return true;
  }

  if (_reChineseMarker.hasMatch(text)) return true;
  if (_reClassicalChinese.allMatches(text).length >= 2) return true;

  final blankCount = _reBlank.allMatches(text).length;
  return _isHumanitiesSubject(subject) &&
      blankCount >= 6 &&
      _reHumanitiesMarker.hasMatch(text);
}

bool _supportsCompositeWorksheetDetection(Subject subject) {
  return subject == Subject.chinese ||
      subject == Subject.english ||
      _isHumanitiesSubject(subject);
}

bool _isHumanitiesSubject(Subject? subject) {
  return subject == Subject.history ||
      subject == Subject.geography ||
      subject == Subject.politics;
}
