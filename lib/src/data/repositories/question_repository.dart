import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';

abstract class QuestionRepository {
  Future<void> saveDraft(QuestionRecord record);
  Future<void> saveDrafts(List<QuestionRecord> records);
  Future<List<QuestionRecord>> listAll();
  Future<QuestionRecord?> getById(String id);
  Future<void> delete(String id);
  Future<void> update(QuestionRecord record);
}

class InMemoryQuestionRepository implements QuestionRepository {
  final List<QuestionRecord> _items = <QuestionRecord>[];

  @override
  Future<List<QuestionRecord>> listAll() async => List<QuestionRecord>.unmodifiable(_items);

  @override
  Future<QuestionRecord?> getById(String id) async {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  @override
  Future<void> saveDraft(QuestionRecord record) async {
    _items.removeWhere((QuestionRecord item) => item.id == record.id);
    _items.add(record);
  }

  @override
  Future<void> saveDrafts(List<QuestionRecord> records) async {
    for (final record in records) {
      _items.removeWhere((QuestionRecord item) => item.id == record.id);
      _items.add(record);
    }
  }

  @override
  Future<void> delete(String id) async {
    _items.removeWhere((QuestionRecord item) => item.id == id);
  }

  @override
  Future<void> update(QuestionRecord record) async {
    final index = _items.indexWhere((QuestionRecord item) => item.id == record.id);
    if (index >= 0) {
      _items[index] = record;
    }
  }
}
