import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';

abstract class QuestionRepository {
  Future<void> saveDraft(QuestionRecord record);
  Future<List<QuestionRecord>> listAll();
}

class InMemoryQuestionRepository implements QuestionRepository {
  final List<QuestionRecord> _items = <QuestionRecord>[];

  @override
  Future<List<QuestionRecord>> listAll() async => List<QuestionRecord>.unmodifiable(_items);

  @override
  Future<void> saveDraft(QuestionRecord record) async {
    _items.removeWhere((QuestionRecord item) => item.id == record.id);
    _items.add(record);
  }
}
