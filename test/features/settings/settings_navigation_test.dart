import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/features/settings/presentation/settings_screen.dart';

void main() {
  testWidgets('settings screen shows provider, subject, prompt, and export entries', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

    expect(find.text('AI 服务商配置'), findsOneWidget);
    expect(find.text('科目管理'), findsOneWidget);
    expect(find.text('提示词设置'), findsOneWidget);
    expect(find.text('导出当前题库'), findsOneWidget);
  });
}
