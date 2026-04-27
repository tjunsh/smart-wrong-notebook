import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/services/question_split_service.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_session.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

void main() {
  group('QuestionSplitService.split', () {
    const splitter = QuestionSplitService();

    test('splits numbered questions into multiple candidates', () async {
      final result = await splitter.split('1. 已知 x+1=3，求 x\n2. 已知 y-2=0，求 y');

      expect(result.strategy, QuestionSplitStrategy.numbered);
      expect(result.candidates.map((candidate) => candidate.text).toList(), <String>[
        '1. 已知 x+1=3，求 x',
        '2. 已知 y-2=0，求 y',
      ]);
    });

    test('splits blank-line separated questions into multiple candidates', () async {
      final result = await splitter.split('已知 x+1=3，求 x\n\n已知 y-2=0，求 y');

      expect(result.strategy, QuestionSplitStrategy.paragraph);
      expect(result.candidates.map((candidate) => candidate.text).toList(), <String>[
        '已知 x+1=3，求 x',
        '已知 y-2=0，求 y',
      ]);
    });

    test('keeps single question as one candidate when no split markers', () async {
      final result = await splitter.split('已知 x^2+1=5，求 x 的值');

      expect(result.strategy, QuestionSplitStrategy.fallback);
      expect(result.candidates.map((candidate) => candidate.text).toList(), <String>['已知 x^2+1=5，求 x 的值']);
    });
  });

  test('buildQuestionSplitSession reuses existing split result', () async {
    final source = QuestionRecord.draft(
      id: 'q-2',
      imagePath: '',
      subject: Subject.math,
      recognizedText: '整题文本',
    ).copyWith(
      splitResult: const QuestionSplitResult(
        sourceText: '整题文本',
        strategy: QuestionSplitStrategy.numbered,
        candidates: <QuestionSplitCandidate>[
          QuestionSplitCandidate(
            id: 'candidate-0',
            order: 1,
            text: '第一题',
            strategy: QuestionSplitStrategy.numbered,
          ),
          QuestionSplitCandidate(
            id: 'candidate-1',
            order: 2,
            text: '第二题',
            strategy: QuestionSplitStrategy.numbered,
          ),
        ],
      ),
    );

    final session = await buildQuestionSplitSession(source);

    expect(session.strategy, QuestionSplitStrategy.numbered);
    expect(session.drafts.map((draft) => draft.text).toList(), <String>['第一题', '第二题']);
  });

  test('buildSplitQuestionRecord stamps lineage metadata and candidate analysis', () {
    final now = DateTime(2026);
    final source = QuestionRecord.draft(
      id: 'root-1',
      imagePath: '/tmp/root.jpg',
      subject: Subject.math,
      recognizedText: '整题文本',
    ).copyWith(
      rootQuestionId: 'existing-root',
      splitResult: const QuestionSplitResult(
        sourceText: '整题文本',
        strategy: QuestionSplitStrategy.numbered,
        candidates: <QuestionSplitCandidate>[],
      ),
      candidateAnalyses: <CandidateAnalysisSnapshot>[
        CandidateAnalysisSnapshot(
          candidateId: 'candidate-2',
          order: 2,
          questionText: '第二题',
          analysisResult: const AnalysisResult(
            finalAnswer: 'B',
            steps: <String>['step'],
            aiTags: <String>['tag'],
            knowledgePoints: <String>['kp'],
            mistakeReason: 'reason',
            studyAdvice: 'advice',
            subject: Subject.physics,
          ),
          savedExercises: <GeneratedExercise>[
            GeneratedExercise(
              id: 'exercise-1',
              questionId: 'old-question',
              generationMode: ExerciseGenerationMode.practice,
              difficulty: '简单',
              question: '练习',
              answer: 'A',
              explanation: '解析',
              createdAt: now,
            ),
          ],
          subject: Subject.physics,
          aiTags: const <String>['tag'],
          aiKnowledgePoints: const <String>['kp'],
        ),
      ],
    );

    final child = buildSplitQuestionRecord(
      source: source,
      draft: const QuestionSplitDraft(
        id: 'candidate-2',
        text: '第二题',
        selected: true,
      ),
      sortOrder: 2,
    );

    expect(child.id, 'root-1-2');
    expect(child.parentQuestionId, 'root-1');
    expect(child.rootQuestionId, 'existing-root');
    expect(child.splitOrder, 2);
    expect(child.subject, Subject.physics);
    expect(child.analysisResult?.finalAnswer, 'B');
    expect(child.savedExercises.single.questionId, 'root-1-2');
    expect(child.aiTags, <String>['tag']);
    expect(child.aiKnowledgePoints, <String>['kp']);
  });

  test('buildQuestionBatchGroups groups siblings and sorts by split order', () {
    QuestionRecord record(String id, {String? rootId, int? splitOrder}) {
      return QuestionRecord.draft(
        id: id,
        imagePath: '',
        subject: Subject.math,
        recognizedText: id,
      ).copyWith(
        rootQuestionId: rootId,
        splitOrder: splitOrder,
      );
    }

    final groups = buildQuestionBatchGroups(<QuestionRecord>[
      record('standalone'),
      record('child-2', rootId: 'root-1', splitOrder: 2),
      record('child-1', rootId: 'root-1', splitOrder: 1),
      record('lonely-child', rootId: 'root-2', splitOrder: 1),
    ]);

    expect(groups.keys, <String>['root-1']);
    expect(groups['root-1']!.questions.map((question) => question.id).toList(), <String>['child-1', 'child-2']);
  });
}
