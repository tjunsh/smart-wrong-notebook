import 'package:drift/drift.dart';

class QuestionRecords extends Table {
  TextColumn get id => text()();
  TextColumn get imagePath => text()();
  TextColumn get subject => text()();
  TextColumn get recognizedText => text()();
  TextColumn get correctedText => text()();
  TextColumn get tagsJson => text().withDefault(const Constant('[]'))();
  TextColumn get contentStatus => text()();
  TextColumn get masteryLevel => text()();
  TextColumn get analysisJson => text().nullable()();
  BoolColumn get isFavorite => boolean().withDefault(const Constant(false))();
  IntColumn get reviewCount => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  DateTimeColumn get lastReviewedAt => dateTime().nullable()();

  @override
  Set<Column<Object>> get primaryKey => <Column<Object>>{id};
}
