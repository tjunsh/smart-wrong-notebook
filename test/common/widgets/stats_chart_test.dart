import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:smart_wrong_notebook/src/common/widgets/stats_chart.dart';

void main() {
  group('StatsGrid', () {
    testWidgets('displays all stat values correctly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsGrid(
              total: 10,
              mastered: 3,
              reviewing: 4,
              newQ: 3,
              due: 5,
            ),
          ),
        ),
      );

      expect(find.text('10'), findsOneWidget); // total
      expect(find.text('5'), findsOneWidget); // due
      expect(find.text('3'), findsNWidgets(2)); // mastered and newQ (value 3)
      expect(find.text('4'), findsOneWidget); // reviewing
    });

    testWidgets('displays all stat labels', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsGrid(
              total: 0,
              mastered: 0,
              reviewing: 0,
              newQ: 0,
              due: 0,
            ),
          ),
        ),
      );

      expect(find.text('题库总量'), findsOneWidget);
      expect(find.text('待复习'), findsOneWidget);
      expect(find.text('已掌握'), findsOneWidget);
      expect(find.text('复习中'), findsOneWidget);
      expect(find.text('新增'), findsOneWidget);
    });
  });

  group('StatsBarChart', () {
    testWidgets('displays chart with data', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsBarChart(
              total: 10,
              mastered: 3,
              reviewing: 4,
              newQ: 3,
            ),
          ),
        ),
      );

      expect(find.byType(BarChart), findsOneWidget);
    });

    testWidgets('displays legend items', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsBarChart(
              total: 10,
              mastered: 3,
              reviewing: 4,
              newQ: 3,
            ),
          ),
        ),
      );

      expect(find.text('已掌握 (3)'), findsOneWidget);
      expect(find.text('复习中 (4)'), findsOneWidget);
      expect(find.text('新增 (3)'), findsOneWidget);
    });

    testWidgets('handles zero values gracefully', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatsBarChart(
              total: 0,
              mastered: 0,
              reviewing: 0,
              newQ: 0,
            ),
          ),
        ),
      );

      expect(find.byType(BarChart), findsOneWidget);
      expect(find.text('已掌握 (0)'), findsOneWidget);
    });
  });
}
