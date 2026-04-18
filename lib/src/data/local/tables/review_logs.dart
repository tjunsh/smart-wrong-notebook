import 'package:drift/drift.dart';
import 'question_records.dart';

class ReviewLogs extends Table {
  TextColumn get id => text()();
  TextColumn get questionRecordId => text().references(QuestionRecords, #id)();
  DateTimeColumn get reviewedAt => dateTime()();
  TextColumn get result => text()();
  TextColumn get masteryAfter => text()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
