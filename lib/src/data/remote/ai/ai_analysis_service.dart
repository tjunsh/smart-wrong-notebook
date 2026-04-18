import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';

class AiAnalysisService {
  const AiAnalysisService();

  factory AiAnalysisService.fake() => const AiAnalysisService();

  Future<AnalysisResult> analyzeQuestion({
    required String correctedText,
    required String subjectName,
  }) async {
    return const AnalysisResult(
      finalAnswer: 'x = 3',
      steps: <String>['移项得到 x = 5 - 2', '计算得到 x = 3'],
      knowledgePoints: <String>['一元一次方程', '移项'],
      mistakeReason: '对移项规则不熟悉',
      studyAdvice: '先用简单方程练熟移项，再做文字题。',
      generatedExercises: <GeneratedExercise>[
        GeneratedExercise(id: 'e1', difficulty: '简单', question: 'x+1=4', answer: 'x=3', explanation: '两边同时减 1'),
        GeneratedExercise(id: 'e2', difficulty: '同级', question: '2x=8', answer: 'x=4', explanation: '两边同时除以 2'),
        GeneratedExercise(id: 'e3', difficulty: '提高', question: '3x+2=11', answer: 'x=3', explanation: '先减 2 再除以 3'),
      ],
    );
  }
}
