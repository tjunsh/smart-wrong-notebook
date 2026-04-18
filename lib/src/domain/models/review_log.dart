import 'mastery_level.dart';

class ReviewLog {
  const ReviewLog({
    required this.id,
    required this.questionRecordId,
    required this.reviewedAt,
    required this.result,
    required this.masteryAfter,
  });

  final String id;
  final String questionRecordId;
  final DateTime reviewedAt;
  final String result;
  final MasteryLevel masteryAfter;
}
