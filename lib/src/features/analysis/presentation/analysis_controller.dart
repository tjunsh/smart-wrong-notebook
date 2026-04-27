import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

class AnalysisController {
  AnalysisController(this._service);

  final AiAnalysisService _service;

  factory AnalysisController.fake() => AnalysisController(AiAnalysisService.fake());

  Future<QuestionRecord> analyze({
    required String questionId,
    required String correctedText,
    required String subjectName,
  }) async {
    final analysis = await _service.analyzeQuestion(
      correctedText: correctedText,
      subjectName: subjectName,
    );

    return QuestionRecord.draft(
      id: questionId,
      imagePath: '/tmp/$questionId.jpg',
      subject: Subject.math,
      recognizedText: correctedText,
    ).copyWith(
      normalizedQuestionText: correctedText,
      contentStatus: ContentStatus.ready,
      analysisResult: analysis,
      savedExercises: _defaultExercises(questionId),
    );
  }

  List<GeneratedExercise> _defaultExercises(String questionId) {
    final now = DateTime.now();
    return <GeneratedExercise>[
      GeneratedExercise(
        id: 'e1',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '简单',
        question: 'x+1=4，求 x 的值',
        options: const ['A. 2', 'B. 3', 'C. 4', 'D. 5'],
        answer: 'B',
        explanation: '移项得 x=4-1=3',
        createdAt: now,
        order: 0,
      ),
      GeneratedExercise(
        id: 'e2',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '同级',
        question: '2x=8，求 x 的值',
        options: const ['A. 2', 'B. 3', 'C. 4', 'D. 6'],
        answer: 'C',
        explanation: '两边同时除以 2 得 x=4',
        createdAt: now,
        order: 1,
      ),
      GeneratedExercise(
        id: 'e3',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '提高',
        question: '3x+2=11，求 x 的值',
        options: const ['A. 2', 'B. 3', 'C. 4', 'D. 5'],
        answer: 'B',
        explanation: '先减 2 再除以 3: 3x=9, x=3',
        createdAt: now,
        order: 2,
      ),
    ];
  }
}
