enum QuestionSplitStrategy {
  numbered,
  paragraph,
  fallback,
}

class QuestionSplitCandidate {
  const QuestionSplitCandidate({
    required this.id,
    required this.order,
    required this.text,
    required this.strategy,
  });

  factory QuestionSplitCandidate.fromJson(Map<String, dynamic> json) {
    return QuestionSplitCandidate(
      id: json['id'] as String? ?? '',
      order: json['order'] as int? ?? 0,
      text: json['text'] as String? ?? '',
      strategy: QuestionSplitStrategy.values.firstWhere(
        (strategy) => strategy.name == json['strategy'],
        orElse: () => QuestionSplitStrategy.fallback,
      ),
    );
  }

  final String id;
  final int order;
  final String text;
  final QuestionSplitStrategy strategy;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'order': order,
      'text': text,
      'strategy': strategy.name,
    };
  }
}

class QuestionSplitResult {
  const QuestionSplitResult({
    required this.sourceText,
    required this.candidates,
    required this.strategy,
  });

  factory QuestionSplitResult.fromJson(Map<String, dynamic> json) {
    return QuestionSplitResult(
      sourceText: json['sourceText'] as String? ?? '',
      candidates: (json['candidates'] as List? ?? const <Object>[])
          .map((item) => QuestionSplitCandidate.fromJson(item as Map<String, dynamic>))
          .toList(),
      strategy: QuestionSplitStrategy.values.firstWhere(
        (strategy) => strategy.name == json['strategy'],
        orElse: () => QuestionSplitStrategy.fallback,
      ),
    );
  }

  final String sourceText;
  final List<QuestionSplitCandidate> candidates;
  final QuestionSplitStrategy strategy;

  bool get hasMultipleCandidates => candidates.length >= 2;

  Map<String, dynamic> toJson() {
    return {
      'sourceText': sourceText,
      'candidates': candidates.map((candidate) => candidate.toJson()).toList(),
      'strategy': strategy.name,
    };
  }
}
