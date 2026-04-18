import 'analysis_result.dart';
import 'content_status.dart';
import 'mastery_level.dart';
import 'subject.dart';

class QuestionRecord {
  const QuestionRecord({
    required this.id,
    required this.imagePath,
    required this.subject,
    required this.recognizedText,
    required this.correctedText,
    required this.tags,
    required this.createdAt,
    required this.updatedAt,
    required this.lastReviewedAt,
    required this.reviewCount,
    required this.isFavorite,
    required this.contentStatus,
    required this.masteryLevel,
    required this.analysisResult,
  });

  factory QuestionRecord.draft({
    required String id,
    required String imagePath,
    required Subject subject,
    required String recognizedText,
  }) {
    final now = DateTime.now();
    return QuestionRecord(
      id: id,
      imagePath: imagePath,
      subject: subject,
      recognizedText: recognizedText,
      correctedText: recognizedText,
      tags: const <String>[],
      createdAt: now,
      updatedAt: now,
      lastReviewedAt: null,
      reviewCount: 0,
      isFavorite: false,
      contentStatus: ContentStatus.processing,
      masteryLevel: MasteryLevel.newQuestion,
      analysisResult: null,
    );
  }

  final String id;
  final String imagePath;
  final Subject subject;
  final String recognizedText;
  final String correctedText;
  final List<String> tags;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? lastReviewedAt;
  final int reviewCount;
  final bool isFavorite;
  final ContentStatus contentStatus;
  final MasteryLevel masteryLevel;
  final AnalysisResult? analysisResult;
}
