---
name: progress-2026-04-20
description: End of session progress for smart-wrong-notebook
type: project
---

Done:
- Add GitHub Actions CI workflow: analyze + test on every push/PR to main
- Add GitHub Actions Release workflow: APK + AAB builds on version tags (v*)
- Remove dead code: mlkit_ocr_service.dart (unused, OcrService uses google_mlkit directly)
- Set flutter.minSdkVersion=21 in gradle.properties (ML Kit requirement)
- Add version 1.0.0+1 to pubspec.yaml
- All 35 tests pass, APK builds clean

Blockers:
- None (waiting for device to test full flow)

Next First Step:
- Install APK on device: `adb install build/app/outputs/flutter-apk/app-debug.apk`

Tomorrow first action:
- Connect Android device and test: onboarding → capture → OCR → AI → save → review
