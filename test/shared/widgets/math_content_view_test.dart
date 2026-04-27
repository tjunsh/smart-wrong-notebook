import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/shared/widgets/math_content_view.dart';

void main() {
  testWidgets('renders plain text without markdown fallback issues', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentView('已知 2x+1=5，求 x 的值'),
        ),
      ),
    );

    expect(find.text('已知 2x+1=5，求 x 的值'), findsOneWidget);
  });

  testWidgets('renders latex mixed content', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentView(r'解方程：$x^2+1=5$'),
        ),
      ),
    );

    expect(find.textContaining('解方程'), findsOneWidget);
  });

  testWidgets('uses compact mode for preview text', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentView(
            r'已知 $$\frac{a}{b}$$ 求值',
            mode: MathContentViewMode.compact,
            maxLines: 1,
          ),
        ),
      ),
    );

    expect(find.textContaining('已知'), findsOneWidget);
    expect(find.textContaining('求值'), findsOneWidget);
  });
}
