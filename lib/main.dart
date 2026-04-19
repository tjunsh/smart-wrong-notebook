import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wrong_notebook/src/app/app.dart';

void main() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    if (kDebugMode) debugPrint('FlutterError: ${details.exception}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) debugPrint('PlatformError: $error\n$stack');
    return true;
  };

  runZonedGuarded(
    () => runApp(const ProviderScope(child: SmartWrongNotebookApp())),
    (error, stack) {
      if (kDebugMode) debugPrint('UncaughtError: $error\n$stack');
    },
  );
}
