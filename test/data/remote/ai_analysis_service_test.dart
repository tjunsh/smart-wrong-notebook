import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/features/analysis/presentation/analysis_controller.dart';

void main() {
  test(
      'fake analysis controller returns ready record with persistent exercises',
      () async {
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
    expect(extraction.normalizedQuestionText,
        r'已知 \angle A=30^\circ，求 \frac{1}{2}x 的值。');
  });

  test('service parses extraction json with raw parenthesis latex delimiters',
      () {
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
  test(
      'service recovers extraction json with doubled delimiters around raw frac',
      () {
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
  test('service preserves valid json escape sequences when repairing latex',
      () {
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

    final exercises = service.extractGeneratedExercisesFromContent(raw,
        questionId: 'q-latex');

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

    final exercises =
        service.extractGeneratedExercisesFromContent(raw, questionId: 'q-2');

    expect(exercises.length, 3);
    expect(exercises.first.questionId, 'q-2');
    expect(exercises.first.generationMode.name, 'practice');
  });

  test('service normalizes double backslashes in generated exercise content',
      () {
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
      "options": ["A. \\(1\\)", "B. \\(2\\)", "C. \\(3\\)", "D. \\(4\\)"],
      "answer": "B",
      "explanation": "因为 \\frac{4}{2}=2"
    }
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(raw,
        questionId: 'q-latex-normalized');

    expect(exercises.single.question, r'解方程：\(x^2+1=5\)');
    expect(exercises.single.question, isNot(contains(r'\\(')));
    expect(exercises.single.explanation, r'因为 \frac{4}{2}=2');
    expect(exercises.single.options, <String>[
      r'A. \(1\)',
      r'B. \(2\)',
      r'C. \(3\)',
      r'D. \(4\)',
    ]);
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

    final exercises =
        service.extractGeneratedExercisesFromContent(raw, questionId: 'q-1');

    expect(exercises.length, 1);
    expect(exercises.first.id, 'g1');
    expect(exercises.first.questionId, 'q-1');
    expect(exercises.first.question, '2x+1=5，求 x 的值');
    expect(exercises.first.options, ['A. 1', 'B. 2', 'C. 3', 'D. 4']);
  });

  test('service rejects linear drift for quadratic root source and falls back',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "由 \(x^2+1=5\) 可得 \(x=\pm 2\)。",
  "steps": ["先得到 \(x^2=4\)", "再开平方，得到 \(x=\pm 2\)"],
  "aiTags": ["一元二次", "平方根", "解方程"],
  "knowledgePoints": ["解含平方项的简单方程", "由 \(x^2=a\) 得 \(x=\pm \sqrt{a}\)"],
  "mistakeReason": "容易漏掉负根",
  "studyAdvice": "整理成 \(x^2=a\) 后再开平方",
  "generatedExercises": [
    {"id": "bad1", "difficulty": "简单", "question": "x+1=4，求 x 的值", "options": ["A. 2", "B. 3", "C. 4", "D. 5"], "answer": "B", "explanation": "移项得 x=4-1=3"},
    {"id": "bad2", "difficulty": "同级", "question": "2x=8，求 x 的值", "options": ["A. 2", "B. 3", "C. 4", "D. 6"], "answer": "C", "explanation": "两边同时除以 2 得 x=4"},
    {"id": "bad3", "difficulty": "提高", "question": "3x+2=11，求 x 的值", "options": ["A. 2", "B. 3", "C. 4", "D. 5"], "answer": "B", "explanation": "先减 2 再除以 3 得 x=3"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-quadratic',
      sourceQuestionText: r'已知 \(x^2+1=5\)，求 \(x\) 的值。',
    );

    expect(exercises.length, 3);
    expect(exercises.map((exercise) => exercise.id), isNot(contains('bad1')));
    expect(exercises.first.question, contains('x^2'));
    expect(exercises.any((exercise) => exercise.explanation.contains(r'\pm')),
        isTrue);
  });

  test(
      'service falls back to function evaluation exercises for function source',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "把 x=3 代入 f(x)=x^2-2x+1，得 f(3)=4。",
  "steps": ["代入 x=3", "计算 3^2-2\\times3+1=4"],
  "aiTags": ["函数"],
  "knowledgePoints": ["函数值", "代入求值"],
  "mistakeReason": "代入计算错误",
  "studyAdvice": "按运算顺序计算",
  "generatedExercises": [
    {"id": "bad1", "difficulty": "简单", "question": "解方程 x^2=9，求 x", "options": ["A. 3", "B. -3", "C. \\pm3", "D. 9"], "answer": "C", "explanation": "开平方得 x=\\pm3"},
    {"id": "bad2", "difficulty": "同级", "question": "解方程 (x-1)^2=16", "options": ["A. 5", "B. -3", "C. 5或-3", "D. 16"], "answer": "C", "explanation": "开平方"},
    {"id": "bad3", "difficulty": "提高", "question": "解方程 x^2+4=20", "options": ["A. 4", "B. \\pm4", "C. 8", "D. \\pm8"], "answer": "B", "explanation": "开平方"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-function',
      sourceQuestionText: r'已知函数 \(f(x)=x^2-2x+1\)，求 \(f(3)\) 的值。',
    );

    expect(exercises.length, 3);
    expect(exercises.first.question, contains('函数'));
    expect(exercises.first.question, contains(r'f('));
    expect(exercises.map((exercise) => exercise.question).join(' '),
        isNot(contains('x^2=9')));
  });

  test('service falls back to volume exercises for cone volume source', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "V=12\\pi",
  "steps": ["V=\\frac{1}{3}\\pi r^2h", "代入 r=3，h=4"],
  "aiTags": ["立体几何"],
  "knowledgePoints": ["圆锥体积", "公式代入"],
  "mistakeReason": "公式记错",
  "studyAdvice": "记住圆锥体积是圆柱的三分之一",
  "generatedExercises": [
    {"id": "bad1", "difficulty": "简单", "question": "解方程 x^2=49，则 x 的值是", "options": ["A. 7", "B. -7", "C. \\pm7", "D. 49"], "answer": "C", "explanation": "开平方"},
    {"id": "bad2", "difficulty": "同级", "question": "解方程 (x-1)^2=16", "options": ["A. 5", "B. -3", "C. 5或-3", "D. 16"], "answer": "C", "explanation": "开平方"},
    {"id": "bad3", "difficulty": "提高", "question": "x^2+1=50，求 x", "options": ["A. 7", "B. \\pm7", "C. 49", "D. 50"], "answer": "B", "explanation": "先移项再开平方"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-volume',
      sourceQuestionText: r'圆锥底面半径 r=3，高 h=4，求体积 V=\frac{1}{3}\pi r^2h。',
    );

    expect(exercises.length, 3);
    expect(exercises.first.question, contains('圆锥'));
    expect(exercises.map((exercise) => exercise.question).join(' '),
        isNot(contains('解方程')));
  });

  test('service rejects equation system drift to linear equation', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "x=4,y=3",
  "steps": ["两式相加消元", "代入求 y"],
  "aiTags": ["方程组"],
  "knowledgePoints": ["加减消元"],
  "mistakeReason": "消元错误",
  "studyAdvice": "先观察系数",
  "generatedExercises": [
    {"id": "bad1", "difficulty": "简单", "question": "解方程 x+1=4", "options": ["A. 1", "B. 2", "C. 3", "D. 4"], "answer": "C", "explanation": "移项得 x=3"},
    {"id": "bad2", "difficulty": "同级", "question": "解方程 2x=8", "options": ["A. 2", "B. 3", "C. 4", "D. 5"], "answer": "C", "explanation": "除以 2"},
    {"id": "bad3", "difficulty": "提高", "question": "解方程 3x+2=11", "options": ["A. 2", "B. 3", "C. 4", "D. 5"], "answer": "B", "explanation": "移项"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-system',
      sourceQuestionText: r'解方程组：\begin{cases} x+y=7 \\ x-y=1 \end{cases}',
    );

    expect(exercises.length, 3);
    expect(exercises.first.question, contains('方程组'));
    expect(exercises.first.question, contains('cases'));
  });

  test('service rejects triangle angle drift to algebra equation', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "70°",
  "steps": ["三角形内角和为 180°", "180-50-60=70"],
  "aiTags": ["三角形"],
  "knowledgePoints": ["内角和"],
  "mistakeReason": "角度关系不清",
  "studyAdvice": "先标出已知角",
  "generatedExercises": [
    {"id": "bad1", "difficulty": "简单", "question": "解方程 x+1=4", "options": ["A. 1", "B. 2", "C. 3", "D. 4"], "answer": "C", "explanation": "移项得 x=3"},
    {"id": "bad2", "difficulty": "同级", "question": "解方程 2x=8", "options": ["A. 2", "B. 3", "C. 4", "D. 5"], "answer": "C", "explanation": "除以 2"},
    {"id": "bad3", "difficulty": "提高", "question": "解方程 3x+2=11", "options": ["A. 2", "B. 3", "C. 4", "D. 5"], "answer": "B", "explanation": "移项"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-triangle',
      sourceQuestionText:
          r'在 \triangle ABC 中，\angle A=50^\circ，\angle B=60^\circ，求 \angle C。',
    );

    expect(exercises.length, 3);
    expect(exercises.first.question, contains(r'\triangle'));
    expect(exercises.map((exercise) => exercise.question).join(' '),
        isNot(contains('解方程 x+1')));
  });

  test('service preserves valid function evaluation generated exercises', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "4",
  "steps": ["代入 x=3"],
  "aiTags": ["函数"],
  "knowledgePoints": ["函数值"],
  "mistakeReason": "代入错误",
  "studyAdvice": "先代入再计算",
  "generatedExercises": [
    {"id": "good-f", "difficulty": "同级", "question": "已知函数 f(x)=x^2+1，求 f(2)", "options": ["A. 3", "B. 4", "C. 5", "D. 6"], "answer": "C", "explanation": "代入 x=2，f(2)=4+1=5"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-function-valid',
      sourceQuestionText: r'已知函数 \(f(x)=x^2-2x+1\)，求 \(f(3)\) 的值。',
    );

    expect(exercises.length, 1);
    expect(exercises.single.id, 'good-f');
  });

  test('service preserves valid volume generated exercises', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "12\\pi",
  "steps": ["代入体积公式"],
  "aiTags": ["立体几何"],
  "knowledgePoints": ["圆锥体积"],
  "mistakeReason": "公式错误",
  "studyAdvice": "区分圆锥和圆柱公式",
  "generatedExercises": [
    {"id": "good-v", "difficulty": "同级", "question": "圆锥底面半径为 2，高为 6，求体积", "options": ["A. 6π", "B. 8π", "C. 10π", "D. 12π"], "answer": "B", "explanation": "体积 V=1/3πr^2h=1/3π×4×6=8π"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-volume-valid',
      sourceQuestionText: r'圆锥底面半径 r=3，高 h=4，求体积 V=\frac{1}{3}\pi r^2h。',
    );

    expect(exercises.length, 1);
    expect(exercises.single.id, 'good-v');
  });

  test(
      'service falls back to proportional relation exercises for fraction source',
      () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "a=6,b=3",
  "steps": ["由 \\(\\frac{a}{b}=2\\) 得 \\(a=2b\\)", "代入 \\(a+b=9\\)"],
  "aiTags": ["分式关系", "代入法", "二元关系"],
  "knowledgePoints": ["比值关系", "和式条件"],
  "mistakeReason": "比例关系转化错误",
  "studyAdvice": "先把比值转成倍数关系",
  "generatedExercises": [
    {"id": "bad1", "difficulty": "简单", "question": "解方程 \\(x^2=9\\)，求 \\(x\\)", "options": ["A. \\(3\\)", "B. \\(-3\\)", "C. \\(\\pm3\\)", "D. \\(9\\)"], "answer": "C", "explanation": "开平方"},
    {"id": "bad2", "difficulty": "同级", "question": "解方程组：\\begin{cases} x+y=5 \\\\ x-y=1 \\end{cases}", "options": ["A. 1", "B. 2", "C. 3", "D. 4"], "answer": "C", "explanation": "加减消元"},
    {"id": "bad3", "difficulty": "提高", "question": "已知函数 f(x)=x^2，求 f(3)", "options": ["A. 3", "B. 6", "C. 9", "D. 12"], "answer": "C", "explanation": "代入"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-proportion',
      sourceQuestionText: r'若 \(\frac{a}{b}=2\)，且 \(a+b=9\)，求 \(a,b\)。',
    );

    expect(exercises.length, 3);
    expect(exercises.first.question, contains(r'\frac'));
    expect(exercises.map((exercise) => exercise.question).join(' '),
        isNot(contains('方程组')));
    expect(exercises.map((exercise) => exercise.question).join(' '),
        isNot(contains('x^2')));
  });

  test('service preserves valid proportional relation generated exercises', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "a=6,b=3",
  "steps": ["由 \\(\\frac{a}{b}=2\\) 得 \\(a=2b\\)"],
  "aiTags": ["分式关系", "代入法"],
  "knowledgePoints": ["比值关系", "和式条件"],
  "mistakeReason": "比例关系转化错误",
  "studyAdvice": "先转化再代入",
  "generatedExercises": [
    {"id": "good-ratio", "difficulty": "同级", "question": "若 \\(\\frac{x}{y}=3\\)，且 \\(x+y=16\\)，求 \\(x\\) 的值。", "options": ["A. \\(4\\)", "B. \\(8\\)", "C. \\(12\\)", "D. \\(16\\)"], "answer": "C", "explanation": "由 \\(\\frac{x}{y}=3\\) 得 \\(x=3y\\)，代入 \\(x+y=16\\) 得 \\(4y=16\\)，所以 \\(x=12\\)。"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-proportion-valid',
      sourceQuestionText: r'若 \(\frac{a}{b}=2\)，且 \(a+b=9\)，求 \(a,b\)。',
    );

    expect(exercises.length, 1);
    expect(exercises.single.id, 'good-ratio');
  });

  test('service triangle fallback wraps angle latex in inline math', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "70°",
  "steps": ["三角形内角和为 180°"],
  "aiTags": ["三角形"],
  "knowledgePoints": ["内角和"],
  "mistakeReason": "角度关系不清",
  "studyAdvice": "先标出已知角",
  "generatedExercises": []
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-triangle-fallback-format',
      sourceQuestionText:
          r'在 \(\triangle ABC\) 中，若 \(AB=AC\)，且 \(\angle A=40^\circ\)，求 \(\angle B\)。',
    );

    expect(exercises.first.question, contains(r'\(\angle A=50^\circ\)'));
    expect(exercises.first.question, isNot(contains(r'\\angle')));
    expect(exercises.first.explanation, contains(r'\(180^\circ\)'));
  });
  test('service preserves valid quadratic root generated exercises', () {
    final service = AiAnalysisService.fake();
    const raw = r'''
{
  "subject": "数学",
  "finalAnswer": "\(x=\pm2\)",
  "steps": ["\(x^2=4\)", "\(x=\pm2\)"],
  "aiTags": ["一元二次", "平方根"],
  "knowledgePoints": ["由 \(x^2=a\) 求正负根"],
  "mistakeReason": "漏负根",
  "studyAdvice": "注意正负根",
  "generatedExercises": [
    {"id": "good1", "difficulty": "同级", "question": "已知 \(x^2=16\)，求 \(x\) 的值。", "options": ["A. \(4\)", "B. \(-4\)", "C. \(\pm4\)", "D. \(16\)"], "answer": "C", "explanation": "由 \(x^2=16\) 得 \(x=\pm4\)。"}
  ]
}
''';

    final exercises = service.extractGeneratedExercisesFromContent(
      raw,
      questionId: 'q-valid-quadratic',
      sourceQuestionText: r'已知 \(x^2+1=5\)，求 \(x\) 的值。',
    );

    expect(exercises.length, 1);
    expect(exercises.single.id, 'good1');
    expect(exercises.single.question, contains('x^2'));
  });
}
