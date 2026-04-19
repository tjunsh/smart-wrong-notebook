import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wrong_notebook/src/app/app.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/app/router.dart';
import 'package:smart_wrong_notebook/src/data/repositories/drift_settings_repository.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/data/files/image_storage_service.dart';

void main() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) debugPrint('FlutterError: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) debugPrint('PlatformError: $error\n$stack');
    return true;
  };

  final settingsRepo = DriftSettingsRepository();
  final router = buildRouter(settingsRepo);

  runZonedGuarded(
    () => runApp(ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        aiAnalysisServiceProvider.overrideWithValue(AiAnalysisService.fake()),
        imageStorageServiceProvider.overrideWithValue(ImageStorageService()),
      ],
      child: SmartWrongNotebookApp(routerConfig: router),
    )),
    (error, stack) {
      if (kDebugMode) debugPrint('UncaughtError: $error\n$stack');
    },
  );
}
