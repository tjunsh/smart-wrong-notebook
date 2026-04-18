import 'package:drift/drift.dart';
import 'question_records.dart';

class GeneratedExercises extends Table {
  TextColumn get id => text()();
  TextColumn get questionRecordId => text().references(QuestionRecords, #id)();
  TextColumn get difficulty => text()();
  TextColumn get question => text()();
  TextColumn get answer => text()();
  TextColumn get explanation => text()();
  BoolColumn get isCorrect => boolean().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
