import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/repositories/question_repository.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/features/settings/presentation/settings_screen.dart';

void main() {
  testWidgets('settings screen shows provider, subject, prompt, and data entries', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [
        settingsRepositoryProvider.overrideWithValue(InMemorySettingsRepository()),
        questionRepositoryProvider.overrideWithValue(InMemoryQuestionRepository()),
      ],
      child: const MaterialApp(home: SettingsScreen()),
    ));
    await tester.pumpAndSettle();

    expect(find.text('深色模式'), findsOneWidget);
    expect(find.text('复习提醒'), findsOneWidget);
    expect(find.text('AI 服务商配置'), findsOneWidget);
    expect(find.text('科目管理'), findsOneWidget);
    expect(find.text('数据管理'), findsOneWidget);
  });
}
