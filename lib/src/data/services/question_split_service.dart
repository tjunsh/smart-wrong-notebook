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
