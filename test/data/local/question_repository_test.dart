import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

void main() {
  test('repository saves and loads a question record', () async {
    final repository = InMemoryQuestionRepository();

    final record = QuestionRecord.draft(
      id: 'q-1',
      imagePath: '/tmp/q-1.jpg',
      subject: Subject.math,
      recognizedText: '1+1=?',
    );

    await repository.saveDraft(record);
    final items = await repository.listAll();

    expect(items.single.id, 'q-1');
    expect(items.single.recognizedText, '1+1=?');
    expect(items.single.subject, Subject.math);
  });

  test('repository gets record by id', () async {
    final repository = InMemoryQuestionRepository();
    final record = QuestionRecord.draft(
      id: 'q-2',
      imagePath: '/tmp/q-2.jpg',
      subject: Subject.english,
      recognizedText: 'hello world',
    );
    await repository.saveDraft(record);

    final found = await repository.getById('q-2');
    expect(found, isNotNull);
    expect(found!.recognizedText, 'hello world');

    final notFound = await repository.getById('nonexistent');
    expect(notFound, isNull);
  });

  test('repository deletes a record', () async {
    final repository = InMemoryQuestionRepository();
    final record = QuestionRecord.draft(
      id: 'q-3',
      imagePath: '/tmp/q-3.jpg',
      subject: Subject.physics,
      recognizedText: 'F=ma',
    );
    await repository.saveDraft(record);
    expect(await repository.listAll(), hasLength(1));

    await repository.delete('q-3');
    expect(await repository.listAll(), isEmpty);
  });

  test('repository updates a record in place', () async {
    final repository = InMemoryQuestionRepository();
    final record = QuestionRecord.draft(
      id: 'q-4',
      imagePath: '/tmp/q-4.jpg',
      subject: Subject.math,
      recognizedText: '2x+3=7',
    );
    await repository.saveDraft(record);

    final updated = record.copyWith(
      correctedText: '2x + 3 = 7',
      masteryLevel: MasteryLevel.reviewing,
      reviewCount: 1,
    );
    await repository.update(updated);

    final items = await repository.listAll();
    expect(items, hasLength(1));
    expect(items.single.correctedText, '2x + 3 = 7');
    expect(items.single.masteryLevel, MasteryLevel.reviewing);
    expect(items.single.reviewCount, 1);
  });
}
