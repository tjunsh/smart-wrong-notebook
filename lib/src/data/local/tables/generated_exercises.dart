import 'package:drift/drift.dart';
import 'question_records.dart';

class GeneratedExercises extends Table {
  TextColumn get id => text()();
  TextColumn get questionId => text().references(QuestionRecords, #id)();
  TextColumn get generationMode =>
      text().withDefault(const Constant('practice'))();
  IntColumn get orderIndex => integer().nullable()();
  TextColumn get difficulty => text()();
  TextColumn get question => text()();
  TextColumn get answer => text()();
  TextColumn get explanation => text().nullable()();
  TextColumn get optionsJson => text().nullable()();
  TextColumn get userAnswer => text().nullable()();
  BoolColumn get isCorrect => boolean().nullable()();
  IntColumn get roundIndex => integer().nullable()();
  IntColumn get roundTotal => integer().nullable()();
  TextColumn get roundGroupId => text().nullable()();
  TextColumn get sourceExerciseId => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
