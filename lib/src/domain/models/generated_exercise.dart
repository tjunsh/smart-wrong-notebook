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
      createdAt: DateTime.tryParse(json['createdAt'] as String? ?? '') ?? DateTime.now(),
      order: json['order'] as int?,
      isCorrect: json['isCorrect'] as bool?,
      options: options,
      userAnswer: json['userAnswer'] as String?,
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

  GeneratedExercise copyWith({
    String? id,
    String? questionId,
    ExerciseGenerationMode? generationMode,
    int? order,
    bool? isCorrect,
    List<String>? options,
    String? userAnswer,
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
      isCorrect: isCorrect ?? this.isCorrect,
      options: options ?? this.options,
      userAnswer: userAnswer ?? this.userAnswer,
    );
  }
}
