import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wrong_notebook/src/data/files/image_storage_service.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';

// --- Repository providers ---

final Provider<QuestionRepository> questionRepositoryProvider = Provider<QuestionRepository>((ref) {
  return InMemoryQuestionRepository();
});

final Provider<SettingsRepository> settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return InMemorySettingsRepository();
});

// --- Service providers ---

final Provider<AiAnalysisService> aiAnalysisServiceProvider = Provider<AiAnalysisService>((ref) {
  return AiAnalysisService.fake();
});

final Provider<ImageStorageService> imageStorageServiceProvider = Provider<ImageStorageService>((ref) {
  return ImageStorageService();
});

// --- Current question flow ---

final StateProvider<QuestionRecord?> currentQuestionProvider = StateProvider<QuestionRecord?>((ref) => null);

// --- Capture draft ---

FutureProvider<void> captureDraftProvider = FutureProvider<void>((ref) async {
  // No-op at app startup; used imperatively via capture flow
});

// --- All questions list ---

final FutureProvider<List<QuestionRecord>> questionListProvider = FutureProvider<List<QuestionRecord>>((ref) async {
  return ref.read(questionRepositoryProvider).listAll();
});

// --- Question count ---

final Provider<int> questionCountProvider = Provider<int>((ref) {
  return ref.watch(questionListProvider).maybeWhen(
    data: (list) => list.length,
    orElse: () => 0,
  );
});

// --- Current question with AI analysis ---

final FutureProvider<QuestionRecord?> analyzeAndSaveProvider = FutureProvider<QuestionRecord?>((ref) async {
  final current = ref.read(currentQuestionProvider);
  if (current == null) return null;

  final service = ref.read(aiAnalysisServiceProvider);
  final analysis = await service.analyzeQuestion(
    correctedText: current.correctedText,
    subjectName: current.subject.name,
  );

  final updated = current.copyWith(
    contentStatus: ContentStatus.ready,
    analysisResult: analysis,
  );

  await ref.read(questionRepositoryProvider).saveDraft(updated);
  return updated;
});
