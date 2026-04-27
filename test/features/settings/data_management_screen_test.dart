import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/review_log.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/domain/repositories/review_log_repository.dart';
import 'package:smart_wrong_notebook/src/features/settings/presentation/data_management_screen.dart';

QuestionRecord _question(String id) {
  final now = DateTime(2026);
  return QuestionRecord(
    id: id,
    imagePath: '',
    subject: Subject.math,
    extractedQuestionText: '题目',
    normalizedQuestionText: '题目',
    contentFormat: QuestionContentFormat.plain,
    tags: const <String>[],
    createdAt: now,
    updatedAt: now,
    lastReviewedAt: null,
    reviewCount: 0,
    isFavorite: false,
    contentStatus: ContentStatus.ready,
    masteryLevel: MasteryLevel.newQuestion,
    analysisResult: null,
  );
}

ReviewLog _reviewLog(String questionId) {
  return ReviewLog(
    id: 'log-$questionId',
    questionRecordId: questionId,
    reviewedAt: DateTime(2026),
    result: 'reviewing',
    masteryAfter: MasteryLevel.reviewing,
  );
}

void main() {
  testWidgets('shows review log count and clears questions with logs',
      (tester) async {
    final questionRepository = InMemoryQuestionRepository();
    final reviewLogRepository = InMemoryReviewLogRepository();
    await questionRepository.saveDraft(_question('q-1'));
    await reviewLogRepository.insert(_reviewLog('q-1'));

    await tester.pumpWidget(ProviderScope(
      overrides: <Override>[
        questionRepositoryProvider.overrideWithValue(questionRepository),
        reviewLogRepositoryProvider.overrideWithValue(reviewLogRepository),
      ],
      child: const MaterialApp(home: DataManagementScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('题库总量'), findsOneWidget);
    expect(find.text('1 题'), findsOneWidget);
    expect(find.text('复习记录总量'), findsOneWidget);
    expect(find.text('1 条'), findsOneWidget);
    expect(find.text('删除所有错题和复习记录，不可恢复'), findsOneWidget);

    await tester.tap(find.text('清空所有数据'));
    await tester.pumpAndSettle();
    expect(find.text('确定要删除全部 1 道错题及其复习记录吗？此操作不可恢复。'), findsOneWidget);

    await tester.tap(find.text('清空'));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(await questionRepository.listAll(), isEmpty);
    expect(await reviewLogRepository.listAll(), isEmpty);
    expect(find.text('0 题'), findsOneWidget);
    expect(find.text('0 条'), findsOneWidget);
  });
}
