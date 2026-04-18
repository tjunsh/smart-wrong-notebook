import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';

void main() {
  test('service parses final answer and generated exercises', () async {
    final service = AiAnalysisService.fake();
    final result = await service.analyzeQuestion(
      correctedText: '解方程 x+2=5',
      subjectName: '数学',
    );

    expect(result.finalAnswer, 'x = 3');
    expect(result.generatedExercises.length, 3);
    expect(result.generatedExercises.first.difficulty, '简单');
  });
}
