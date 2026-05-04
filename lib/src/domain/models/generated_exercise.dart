enum ExerciseGenerationMode { practice, similar, followUp, mistakeFocused }

class GeneratedExercise {
  const GeneratedExercise({
    required this.id,
    required this.questionId,
    required this.generationMode,
    required this.difficulty,
    required this.question,
    required this.answer,
    required this.explanation,
    required this.createdAt,
    this.order,
    this.isCorrect,
    this.options,
    this.userAnswer,
    this.roundIndex,
    this.roundTotal,
    this.roundGroupId,
    this.sourceExerciseId,
  });

  factory GeneratedExercise.fromJson(Map<String, dynamic> json) {
    List<String>? options;
    if (json['options'] != null) {
      options = List<String>.from(json['options'] as List);
    }

    final modeName = json['generationMode'] as String?;
    final generationMode = ExerciseGenerationMode.values.firstWhere(
      (mode) => mode.name == modeName,
      orElse: () => ExerciseGenerationMode.practice,
    );

    return GeneratedExercise(
      id: json['id'] as String? ?? '',
      questionId: json['questionId'] as String? ?? '',
      generationMode: generationMode,
      difficulty: json['difficulty'] as String? ?? '',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      explanation: json['explanation'] as String? ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ??
          DateTime.now(),
      order: json['order'] as int?,
      isCorrect: json['isCorrect'] as bool?,
      options: options,
      userAnswer: json['userAnswer'] as String?,
      roundIndex: json['roundIndex'] as int?,
      roundTotal: json['roundTotal'] as int?,
      roundGroupId: json['roundGroupId'] as String?,
      sourceExerciseId: json['sourceExerciseId'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'questionId': questionId,
      'generationMode': generationMode.name,
      'difficulty': difficulty,
      'question': question,
      'answer': answer,
      'explanation': explanation,
      'createdAt': createdAt.toIso8601String(),
      'order': order,
      'isCorrect': isCorrect,
      'options': options,
      'userAnswer': userAnswer,
      'roundIndex': roundIndex,
      'roundTotal': roundTotal,
      'roundGroupId': roundGroupId,
      'sourceExerciseId': sourceExerciseId,
    };
  }

  final String id;
  final String questionId;
  final ExerciseGenerationMode generationMode;
  final String difficulty;
  final String question;
  final String answer;
  final String explanation;
  final DateTime createdAt;
  final int? order;
  final bool? isCorrect;
  final List<String>? options;
  final String? userAnswer;
  final int? roundIndex;
  final int? roundTotal;
  final String? roundGroupId;
  final String? sourceExerciseId;

  GeneratedExercise copyWith({
    String? id,
    String? questionId,
    ExerciseGenerationMode? generationMode,
    int? order,
    Object? isCorrect = _sentinel,
    List<String>? options,
    Object? userAnswer = _sentinel,
    int? roundIndex,
    int? roundTotal,
    String? roundGroupId,
    String? sourceExerciseId,
  }) {
    return GeneratedExercise(
      id: id ?? this.id,
      questionId: questionId ?? this.questionId,
      generationMode: generationMode ?? this.generationMode,
      difficulty: difficulty,
      question: question,
      answer: answer,
      explanation: explanation,
      createdAt: createdAt,
      order: order ?? this.order,
      isCorrect:
          identical(isCorrect, _sentinel) ? this.isCorrect : isCorrect as bool?,
      options: options ?? this.options,
      userAnswer: identical(userAnswer, _sentinel)
          ? this.userAnswer
          : userAnswer as String?,
      roundIndex: roundIndex ?? this.roundIndex,
      roundTotal: roundTotal ?? this.roundTotal,
      roundGroupId: roundGroupId ?? this.roundGroupId,
      sourceExerciseId: sourceExerciseId ?? this.sourceExerciseId,
    );
  }
}

const Object _sentinel = Object();
