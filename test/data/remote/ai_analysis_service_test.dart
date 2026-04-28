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

  test('service parses extraction json with raw latex backslashes', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "extractedQuestionText": "已知 \angle A=30^\circ，求 \frac{1}{2}x 的值。",
  "normalizedQuestionText": "已知 \angle A=30^\circ，求 \frac{1}{2}x 的值。"
}
''';

    final extraction = service.parseExtractionResultForTest(raw);

    expect(extraction.subject, Subject.math);
    expect(extraction.normalizedQuestionText, r'已知 \angle A=30^\circ，求 \frac{1}{2}x 的值。');
  });

  test('service parses extraction json with raw parenthesis latex delimiters', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "extractedQuestionText": "1. 已知 \(x^2+1=5\)，求 \(x\) 的值。\n2. 若 \(\frac{a}{b}=2\)，求 \(a\)。",
  "normalizedQuestionText": "1. 已知 \(x^2+1=5\)，求 \(x\) 的值。\n2. 若 \(\frac{a}{b}=2\)，求 \(a\)。"
}
''';

    final extraction = service.parseExtractionResultForTest(raw);

    expect(extraction.subject, Subject.math);
    expect(extraction.normalizedQuestionText, contains(r'\(x^2+1=5\)'));
    expect(extraction.normalizedQuestionText, contains(r'\frac{a}{b}'));
    expect(extraction.normalizedQuestionText, contains('\n'));
  });
  test('service repairs mixed escaped delimiters and raw latex commands', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "extractedQuestionText": "1. 已知 \\(x^2+1=5\\)，求 \\(x\\) 的值。\n2. 若 \\(\frac{a}{b}=2\\)，求 \\(a\\)。",
  "normalizedQuestionText": "1. 已知 \\(x^2+1=5\\)，求 \\(x\\) 的值。\n2. 若 \\(\frac{a}{b}=2\\)，求 \\(a\\)。"
}
''';

    final extraction = service.parseExtractionResultForTest(raw);

    expect(extraction.subject, Subject.math);
    expect(extraction.normalizedQuestionText, contains(r'\(x^2+1=5\)'));
    expect(extraction.normalizedQuestionText, isNot(contains(r'\\(')));
    expect(extraction.normalizedQuestionText, contains(r'\(\frac{a}{b}=2\)'));
    expect(extraction.normalizedQuestionText, contains('\n'));
  });
  test('service parses extraction json with literal newline in string', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "extractedQuestionText": "1. 已知 \(x^2+1=5\)，求 \(x\) 的值。
2. 若 \(\frac{a}{b}=2\)，求 \(a\)。",
  "normalizedQuestionText": "1. 已知 \(x^2+1=5\)，求 \(x\) 的值。
2. 若 \(\frac{a}{b}=2\)，求 \(a\)。"
}
''';

    final extraction = service.parseExtractionResultForTest(raw);

    expect(extraction.subject, Subject.math);
    expect(extraction.normalizedQuestionText, contains(r'\(x^2+1=5\)'));
    expect(extraction.normalizedQuestionText, contains(r'\(\frac{a}{b}=2\)'));
  });
  test('service recovers extraction json with doubled delimiters around raw frac', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "extractedQuestionText": "1. 已知 \(x^2+1=5\)，求 \(x\) 的值。 \n2. 若 \(\frac{a}{b}=2\)，求 \(a\)。",
  "normalizedQuestionText": "1. 已知 \(x^2+1=5\)，求 \(x\) 的值。 \n2. 若 \(\frac{a}{b}=2\)，求 \(a\)。",
  "extra": "尾部字段"
}
''';

    final extraction = service.parseExtractionResultForTest(raw);

    expect(extraction.subject, Subject.math);
    expect(extraction.normalizedQuestionText, contains(r'\(x^2+1=5\)'));
    expect(extraction.normalizedQuestionText, isNot(contains(r'\\(')));
    expect(extraction.normalizedQuestionText, contains(r'\(\frac{a}{b}=2\)'));
  });
  test('service preserves valid json escape sequences when repairing latex', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "第一行\n第二行，公式 \frac{1}{2}",
  "steps": ["使用公式 \times 2", "保留换行\n继续"],
  "aiTags": ["几何"],
  "knowledgePoints": ["角度与分式"],
  "mistakeReason": "漏看 \angle 标记",
  "studyAdvice": "规范书写"
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(raw, questionId: 'q-latex');

    expect(exercises.length, 3);
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

  test('service normalizes double backslashes in generated exercise content', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "答案为 \\(x=2\\)",
  "steps": ["使用 \\frac{1}{2}"],
  "aiTags": ["方程"],
  "knowledgePoints": ["一元一次方程"],
  "mistakeReason": "计算粗心",
  "studyAdvice": "多练习",
  "generatedExercises": [
    {
      "id": "g-latex",
      "difficulty": "同级",
      "question": "解方程：\\(x^2+1=5\\)",
      "options": ["A. \\(1\\)", "B. \\(2\\)"],
      "answer": "B",
      "explanation": "因为 \\frac{4}{2}=2"
    }
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(raw, questionId: 'q-latex-normalized');

    expect(exercises.single.question, r'解方程：\(x^2+1=5\)');
    expect(exercises.single.question, isNot(contains(r'\\(')));
    expect(exercises.single.explanation, r'因为 \frac{4}{2}=2');
    expect(exercises.single.options, <String>[r'A. \(1\)', r'B. \(2\)']);
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
