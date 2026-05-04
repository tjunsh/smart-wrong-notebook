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
      expect(
          result.candidates.map((candidate) => candidate.text).toList(),
          <String>[
            '1. 已知 x+1=3，求 x',
            '2. 已知 y-2=0，求 y',
          ]);
    });

    test('splits blank-line separated questions into multiple candidates',
        () async {
      final result = await splitter.split('已知 x+1=3，求 x\n\n已知 y-2=0，求 y');

      expect(result.strategy, QuestionSplitStrategy.paragraph);
      expect(
          result.candidates.map((candidate) => candidate.text).toList(),
          <String>[
            '已知 x+1=3，求 x',
            '已知 y-2=0，求 y',
          ]);
    });

    test('keeps English cloze passage as one composite question', () async {
      const text = '''1. Saving for a Rainy Day
In China, saving money has always been considered a traditional virtue. Chinese people _____ 1 _____ the habit of putting money aside.
Some young people save income, _____ 4 _____ spend most of it on travel.
1. A. keep B. kept C. have kept
2. A. saved B. was saved C. has saved
3. A. to interest B. interesting C. interested
4. A. others B. the other C. another
5. A. find B. finding C. to find''';

      final result = await splitter.split(text);

      expect(result.strategy, QuestionSplitStrategy.fallback);
      expect(result.candidates, hasLength(1));
      expect(result.candidates.single.text, text);
    });

    test('keeps Chinese classical worksheet as one composite question',
        () async {
      const text = '''《桃花源记》翻译卷
一、文常积累
本文作者______，名______，字______。
二、字词释义
晋太元中，武陵人捕鱼为业。缘（______）溪行，忘路之远近。忽逢桃花林，夹岸数百步，中无杂树，芳草鲜美（______），落英（______）缤纷（______）。''';

      final result = await splitter.split(text);

      expect(result.strategy, QuestionSplitStrategy.fallback);
      expect(result.candidates, hasLength(1));
      expect(result.candidates.single.text, text);
    });

    test('keeps history long fill-in worksheet as one composite question',
        () async {
      const text = '''中国古代史阶段复习填空
一、先秦时期
1. 西周实行______制，形成天子、诸侯、卿大夫、士的等级秩序。
2. 春秋战国时期，______变法推动秦国国力增强，为统一奠定基础。
二、秦汉时期
3. 秦始皇统一后建立______制度，地方推行______制。
4. 汉武帝接受董仲舒建议，实行“______”，加强思想控制。
三、隋唐至明清
5. 隋唐时期完善______制，扩大官吏选拔范围。
6. 明清时期君主专制强化，军机处设立于______时期。
请结合材料，概括这些制度变化对统一多民族国家发展的影响。''';

      final result = await splitter.split(text, subject: Subject.history);

      expect(result.strategy, QuestionSplitStrategy.fallback);
      expect(result.candidates, hasLength(1));
      expect(result.candidates.single.text, text);
    });

    test('keeps politics long fill-in worksheet as one composite question',
        () async {
      const text = '''道德与法治综合填空题
一、公民权利
1. 公民最基本、最重要的权利是______。
2. 依法行使权利时，不得损害国家的、社会的、集体的利益和其他公民的______。
二、国家制度
3. 我国的根本政治制度是______。
4. 全国人民代表大会是最高______机关。
三、法治建设
5. 全面依法治国的总目标是建设中国特色社会主义______体系。
6. 厉行法治要求推进科学立法、严格执法、公正司法、______守法。
请根据材料说明公民参与法治建设的意义。''';

      final result = await splitter.split(text, subject: Subject.politics);

      expect(result.strategy, QuestionSplitStrategy.fallback);
      expect(result.candidates, hasLength(1));
      expect(result.candidates.single.text, text);
    });

    test('still splits numbered math questions with blanks', () async {
      const text = '''1. 已知 x+______=3，求 x。
2. 已知 y-______=0，求 y。''';

      final result = await splitter.split(text, subject: Subject.math);

      expect(result.strategy, QuestionSplitStrategy.numbered);
      expect(result.candidates, hasLength(2));
    });

    test('keeps single question as one candidate when no split markers',
        () async {
      final result = await splitter.split('已知 x^2+1=5，求 x 的值');

      expect(result.strategy, QuestionSplitStrategy.fallback);
      expect(result.candidates.map((candidate) => candidate.text).toList(),
          <String>['已知 x^2+1=5，求 x 的值']);
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
    expect(session.drafts.map((draft) => draft.text).toList(),
        <String>['第一题', '第二题']);
  });

  test(
      'buildSplitQuestionRecord stamps lineage metadata and candidate analysis',
      () {
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
        originalOrder: 2,
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

  test(
      'buildSplitQuestionRecord does not copy parent analysis to unanalyzed siblings',
      () {
    final source = QuestionRecord.draft(
      id: 'root-2',
      imagePath: '/tmp/root.jpg',
      subject: Subject.math,
      recognizedText: '整题文本',
    ).copyWith(
      aiTags: const <String>['一元二次'],
      aiKnowledgePoints: const <String>['平方根'],
      analysisResult: const AnalysisResult(
        finalAnswer: '第一题答案',
        steps: <String>['第一题步骤'],
        aiTags: <String>['一元二次'],
        knowledgePoints: <String>['平方根'],
        mistakeReason: '第一题错因',
        studyAdvice: '第一题建议',
      ),
      splitResult: const QuestionSplitResult(
        sourceText: '1. 第一题\n2. 第二题',
        strategy: QuestionSplitStrategy.numbered,
        candidates: <QuestionSplitCandidate>[
          QuestionSplitCandidate(
            id: 'candidate-0',
            order: 1,
            text: '1. 第一题',
            strategy: QuestionSplitStrategy.numbered,
          ),
          QuestionSplitCandidate(
            id: 'candidate-1',
            order: 2,
            text: '2. 若 \\(\\frac{a}{b}=2\\) 且 \\(a+b=9\\)，求 \\(a,b\\)。',
            strategy: QuestionSplitStrategy.numbered,
          ),
        ],
      ),
      candidateAnalyses: const <CandidateAnalysisSnapshot>[
        CandidateAnalysisSnapshot(
          candidateId: 'candidate-0',
          order: 1,
          questionText: '1. 第一题',
          analysisResult: AnalysisResult(
            finalAnswer: '第一题答案',
            steps: <String>['第一题步骤'],
            aiTags: <String>['一元二次'],
            knowledgePoints: <String>['平方根'],
            mistakeReason: '第一题错因',
            studyAdvice: '第一题建议',
          ),
        ),
      ],
    );

    final child = buildSplitQuestionRecord(
      source: source,
      draft: const QuestionSplitDraft(
        id: 'candidate-1',
        text: '2. 若 \\(\\frac{a}{b}=2\\) 且 \\(a+b=9\\)，求 \\(a,b\\)。',
        selected: true,
        originalOrder: 2,
      ),
      sortOrder: 2,
    );

    expect(child.analysisResult, isNull);
    expect(child.aiTags, isEmpty);
    expect(child.aiKnowledgePoints, isEmpty);
    expect(child.savedExercises, isEmpty);
    expect(child.normalizedQuestionText, contains(r'\frac{a}{b}'));
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
    expect(groups['root-1']!.questions.map((question) => question.id).toList(),
        <String>['child-1', 'child-2']);
  });
}
