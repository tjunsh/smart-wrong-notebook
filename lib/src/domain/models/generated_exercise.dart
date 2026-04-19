class GeneratedExercise {
  const GeneratedExercise({
    required this.id,
    required this.difficulty,
    required this.question,
    required this.answer,
    required this.explanation,
    this.isCorrect,
  });

  final String id;
  final String difficulty;
  final String question;
  final String answer;
  final String explanation;
  final bool? isCorrect;

  GeneratedExercise copyWith({bool? isCorrect}) {
    return GeneratedExercise(
      id: id,
      difficulty: difficulty,
      question: question,
      answer: answer,
      explanation: explanation,
      isCorrect: isCorrect ?? this.isCorrect,
    );
  }
}
