import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
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
}
