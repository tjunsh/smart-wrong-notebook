import 'generated_exercise.dart';

class AnalysisResult {
  const AnalysisResult({
    required this.finalAnswer,
    required this.steps,
    required this.knowledgePoints,
    required this.mistakeReason,
    required this.studyAdvice,
    required this.generatedExercises,
  });

  final String finalAnswer;
  final List<String> steps;
  final List<String> knowledgePoints;
  final String mistakeReason;
  final String studyAdvice;
  final List<GeneratedExercise> generatedExercises;

  AnalysisResult copyWith({List<GeneratedExercise>? generatedExercises}) {
    return AnalysisResult(
      finalAnswer: finalAnswer,
      steps: steps,
      knowledgePoints: knowledgePoints,
      mistakeReason: mistakeReason,
      studyAdvice: studyAdvice,
      generatedExercises: generatedExercises ?? this.generatedExercises,
    );
  }
}
