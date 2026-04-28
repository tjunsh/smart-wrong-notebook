import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_result.dart';

class QuestionSplitService {
  const QuestionSplitService({this.aiAnalysisService});

  final AiAnalysisService? aiAnalysisService;

  Future<QuestionSplitResult> split(String text) async {
    if (aiAnalysisService != null) {
      return aiAnalysisService!.splitQuestionCandidates(
        text: text,
        fallbackSplit: _splitLocally,
      );
    }
    return _splitLocally(text);
  }

  QuestionSplitResult _splitLocally(String text) {
    final normalized = text.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) {
      return const QuestionSplitResult(
        sourceText: '',
        candidates: <QuestionSplitCandidate>[],
        strategy: QuestionSplitStrategy.fallback,
      );
    }

    if (_isCompositeLanguageWorksheet(normalized)) {
      return QuestionSplitResult(
        sourceText: normalized,
        candidates: _buildCandidates(<String>[normalized], QuestionSplitStrategy.fallback),
        strategy: QuestionSplitStrategy.fallback,
      );
    }

    final numberedSegments = _splitByNumberedQuestions(normalized);
    if (numberedSegments.length >= 2) {
      return QuestionSplitResult(
        sourceText: normalized,
        candidates: _buildCandidates(numberedSegments, QuestionSplitStrategy.numbered),
        strategy: QuestionSplitStrategy.numbered,
      );
    }

    final paragraphSegments = normalized
        .split(RegExp(r'\n\s*\n+'))
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (paragraphSegments.length >= 2) {
      return QuestionSplitResult(
        sourceText: normalized,
        candidates: _buildCandidates(paragraphSegments, QuestionSplitStrategy.paragraph),
        strategy: QuestionSplitStrategy.paragraph,
      );
    }

    return QuestionSplitResult(
      sourceText: normalized,
      candidates: _buildCandidates(<String>[normalized], QuestionSplitStrategy.fallback),
      strategy: QuestionSplitStrategy.fallback,
    );
  }

  List<QuestionSplitCandidate> _buildCandidates(List<String> segments, QuestionSplitStrategy strategy) {
    return segments.asMap().entries.map((entry) {
      return QuestionSplitCandidate(
        id: 'candidate-${entry.key}',
        order: entry.key + 1,
        text: entry.value,
        strategy: strategy,
      );
    }).toList();
  }

  bool _isCompositeLanguageWorksheet(String text) {
    final blankCount = RegExp(r'_{2,}|＿{2,}|\(\s*\)|（\s*）').allMatches(text).length;
    final optionRows = RegExp(r'(^|\n)\s*\d+[\.、．)]\s*[A-C][\.、．)]\s+', multiLine: true)
        .allMatches(text)
        .length;
    final hasEnglishPassage = RegExp(r'\b(the|that|which|while|however|because|people|money|family|should|china|saving|some|they|was|for|with|and|of|to)\b', caseSensitive: false)
        .allMatches(text)
        .length >=
        8;
    final hasChineseWorksheetMarker = RegExp(r'文常积累|字词释义|翻译卷|课文|文言文|释义|翻译').hasMatch(text);
    final hasClassicalChinese = RegExp(r'之|其|乃|遂|为|问所从来|落英|缤纷|阡陌|桃花源记').allMatches(text).length >= 4;
    final numberedBlankCount = RegExp(r'(^|[^\d])(?:[1-9]|10)\s*[\.、．)]?\s*[A-C][\.、．)]', multiLine: true)
        .allMatches(text)
        .length;

    if (hasEnglishPassage && (optionRows >= 3 || numberedBlankCount >= 5)) {
      return true;
    }

    if (hasChineseWorksheetMarker || hasClassicalChinese) {
      return true;
    }

    return blankCount >= 5 && (hasChineseWorksheetMarker || hasClassicalChinese);
  }

  List<String> _splitByNumberedQuestions(String text) {
    final matches = RegExp(r'(^|\n)\s*(?:第\s*\d+\s*题|\d+[\.、．)])\s*', multiLine: true).allMatches(text).toList();
    if (matches.length < 2) return const <String>[];

    final segments = <String>[];
    for (var index = 0; index < matches.length; index++) {
      final current = matches[index];
      final start = current.start + (current.group(1)?.length ?? 0);
      final end = index + 1 < matches.length ? matches[index + 1].start : text.length;
      final segment = text.substring(start, end).trim();
      if (segment.isNotEmpty) {
        segments.add(segment);
      }
    }
    return segments;
  }
}
