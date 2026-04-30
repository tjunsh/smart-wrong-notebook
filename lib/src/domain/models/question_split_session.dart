import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_result.dart';

class QuestionSplitDraft {
  const QuestionSplitDraft({
    required this.id,
    required this.text,
    required this.selected,
    required this.originalOrder,
    this.contentFormat,
  });

  final String id;
  final String text;
  final bool selected;
  final int originalOrder;
  final QuestionContentFormat? contentFormat;

  QuestionSplitDraft copyWith({
    String? text,
    bool? selected,
    QuestionContentFormat? contentFormat,
  }) {
    return QuestionSplitDraft(
      id: id,
      text: text ?? this.text,
      selected: selected ?? this.selected,
      originalOrder: originalOrder,
      contentFormat: contentFormat ?? this.contentFormat,
    );
  }
}

class QuestionSplitSession {
  const QuestionSplitSession({
    required this.source,
    required this.drafts,
    required this.strategy,
  });

  final QuestionRecord source;
  final List<QuestionSplitDraft> drafts;
  final QuestionSplitStrategy strategy;

  bool get hasSelectedDrafts => drafts.any((draft) => draft.selected && draft.text.trim().isNotEmpty);

  QuestionSplitSession copyWith({
    QuestionRecord? source,
    List<QuestionSplitDraft>? drafts,
    QuestionSplitStrategy? strategy,
  }) {
    return QuestionSplitSession(
      source: source ?? this.source,
      drafts: drafts ?? this.drafts,
      strategy: strategy ?? this.strategy,
    );
  }
}
