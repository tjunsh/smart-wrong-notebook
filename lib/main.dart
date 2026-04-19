import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wrong_notebook/src/app/app.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/app/router.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/files/image_storage_service.dart';
import 'package:smart_wrong_notebook/src/data/repositories/drift_settings_repository.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Create settings repository with database
  final settingsRepo = DriftSettingsRepository();
  final router = buildRouter(settingsRepo);

  runApp(ProviderScope(
    overrides: [
      settingsRepositoryProvider.overrideWithValue(settingsRepo),
      aiAnalysisServiceProvider.overrideWithValue(AiAnalysisService.fake()),
      imageStorageServiceProvider.overrideWithValue(ImageStorageService()),
    ],
    child: SmartWrongNotebookApp(routerConfig: router),
  ));
}
