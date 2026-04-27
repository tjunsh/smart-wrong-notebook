import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/data/local/app_database.dart' hide GeneratedExercise, QuestionRecord;
import 'package:smart_wrong_notebook/src/data/repositories/drift_question_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

void main() {
  late AppDatabase database;
  late DriftQuestionRepository repository;

  setUp(() {
    database = AppDatabase.memory();
    repository = DriftQuestionRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  test('preserves lineage metadata and saved exercises', () async {
    final now = DateTime(2026, 4, 28);
    final record = QuestionRecord(
      id: 'q-child-1',
      imagePath: '/tmp/q-child-1.jpg',
      subject: Subject.math,
      extractedQuestionText: '第一题',
      normalizedQuestionText: '第一题',
      contentFormat: QuestionContentFormat.latexMixed,
      tags: const <String>['manual'],
      createdAt: now,
      updatedAt: now,
      lastReviewedAt: DateTime(2026, 4, 29),
      reviewCount: 3,
      isFavorite: true,
      contentStatus: ContentStatus.ready,
      masteryLevel: MasteryLevel.reviewing,
      analysisResult: null,
      savedExercises: <GeneratedExercise>[
        GeneratedExercise(
          id: 'exercise-1',
          questionId: 'stale-id',
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '简单',
          question: '1+1=?',
          options: const <String>['A. 1', 'B. 2'],
          answer: 'B',
          explanation: '基础加法',
          createdAt: now,
          order: 1,
          userAnswer: 'B',
          isCorrect: true,
        ),
      ],
      aiTags: const <String>['计算'],
      aiKnowledgePoints: const <String>['加法'],
      customTags: const <String>['课堂'],
      parentQuestionId: 'q-parent',
      rootQuestionId: 'q-root',
      splitOrder: 1,
    );

    await repository.saveDraft(record);

    final loaded = await repository.getById('q-child-1');

    expect(loaded, isNotNull);
    expect(loaded!.parentQuestionId, 'q-parent');
    expect(loaded.rootQuestionId, 'q-root');
    expect(loaded.splitOrder, 1);
    expect(loaded.savedExercises.single.questionId, 'q-child-1');
    expect(loaded.savedExercises.single.options, <String>['A. 1', 'B. 2']);
    expect(loaded.savedExercises.single.userAnswer, 'B');
    expect(loaded.savedExercises.single.isCorrect, isTrue);
    expect(loaded.aiTags, <String>['计算']);
    expect(loaded.aiKnowledgePoints, <String>['加法']);
    expect(loaded.customTags, <String>['课堂']);
  });
}
