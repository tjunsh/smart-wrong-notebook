import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/features/analysis/presentation/analysis_controller.dart';

void main() {
  test('fake analysis controller returns ready record with persistent exercises', () async {
    final controller = AnalysisController.fake();
    final record = await controller.analyze(
      questionId: 'q-1',
      correctedText: '解方程 x+2=5',
      subjectName: '数学',
    );

    expect(record.analysisResult?.finalAnswer, 'x = 3');
    expect(record.savedExercises.length, 3);
    expect(record.savedExercises.first.difficulty, '简单');
  });

  test('service parses extracted question structure json', () {
    final service = AiAnalysisService.fake();
    const raw = '''
{
  "subject": "物理",
  "extractedQuestionText": "如图所示，求电阻 R 两端电压。",
  "normalizedQuestionText": "如图所示，求电阻 R 两端的电压。"
}
''';

    final extraction = service.parseExtractionResultForTest(raw);

    expect(extraction.subject, Subject.physics);
    expect(extraction.extractedQuestionText, '如图所示，求电阻 R 两端电压。');
    expect(extraction.normalizedQuestionText, '如图所示，求电阻 R 两端的电压。');
  });

  test('service falls back to default exercises when raw json has none', () {
    final service = AiAnalysisService.fake();
    const raw = '''
{
  "subject": "数学",
  "finalAnswer": "x=3",
  "steps": ["移项", "求解"],
  "aiTags": ["方程"],
  "knowledgePoints": ["一元一次方程"],
  "mistakeReason": "计算粗心",
  "studyAdvice": "多练习"
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(raw, questionId: 'q-2');

    expect(exercises.length, 3);
    expect(exercises.first.questionId, 'q-2');
    expect(exercises.first.generationMode.name, 'practice');
  });

  test('service extracts generated exercises from raw ai json', () {
    final service = AiAnalysisService.fake();
    const raw = '''
{
  "subject": "数学",
  "finalAnswer": "x=2",
  "steps": ["移项", "求解"],
  "aiTags": ["方程"],
  "knowledgePoints": ["一元一次方程"],
  "mistakeReason": "计算粗心",
  "studyAdvice": "多练习",
  "generatedExercises": [
    {
      "id": "g1",
      "difficulty": "同级",
      "question": "2x+1=5，求 x 的值",
      "options": ["A. 1", "B. 2", "C. 3", "D. 4"],
      "answer": "B",
      "explanation": "2x=4，所以 x=2"
    }
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(raw, questionId: 'q-1');

    expect(exercises.length, 1);
    expect(exercises.first.id, 'g1');
    expect(exercises.first.questionId, 'q-1');
    expect(exercises.first.question, '2x+1=5，求 x 的值');
    expect(exercises.first.options, ['A. 1', 'B. 2', 'C. 3', 'D. 4']);
  });
}
