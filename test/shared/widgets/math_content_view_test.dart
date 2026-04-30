import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/shared/widgets/math_content_view.dart';
import 'package:smart_wrong_notebook/src/shared/widgets/katex_math_view.dart';

void main() {
  setUpAll(() {
    KatexMathView.enabled = false;
  });

  testWidgets('renders plain text without markdown fallback issues',
      (tester) async {
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

  testWidgets('renders escaped parenthesis delimiters without visible slashes',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentView(r'已知 \(x^2 + 1 = 5\)，求 \(x\) 的值。'),
        ),
      ),
    );

    expect(find.textContaining(r'\('), findsNothing);
    expect(find.textContaining(r'\)'), findsNothing);
    expect(find.textContaining('已知'), findsOneWidget);
  });

  testWidgets(
      'renders single slash parenthesis delimiters without visible slashes',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentView(r'若 \frac{a}{b}=2，且 \(a+b=9\)，求 \(a,b\)。'),
        ),
      ),
    );

    expect(find.textContaining(r'\('), findsNothing);
    expect(find.textContaining(r'\)'), findsNothing);
    expect(find.textContaining('若'), findsOneWidget);
  });

  testWidgets('renders caret formulas without dollar delimiters',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentView(r'已知 x^2 = 9，求 x 的值。'),
        ),
      ),
    );

    expect(find.textContaining('已知'), findsOneWidget);
    expect(find.textContaining('x^2'), findsNothing);
  });

  testWidgets('keeps mixed inline math in one flowing line group',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentView(r'1. 已知 $x^2 + 1 = 5$，求 $x$ 的值。'),
        ),
      ),
    );

    expect(find.byType(Wrap), findsOneWidget);
    expect(find.textContaining(r'$x'), findsNothing);
  });

  testWidgets('falls back gracefully for invalid latex control sequence',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentView(r'解方程组：\x。'),
        ),
      ),
    );

    expect(find.textContaining('Parser Error'), findsNothing);
    expect(find.textContaining('Undefined control sequence'), findsNothing);
    expect(find.textContaining('解方程组'), findsOneWidget);
  });

  testWidgets('does not show parser errors for newline equation systems',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentView(
              r'根据三角形内角和定理：$\angle A + \angle B + \angle C = 180^\circ \newline x + y = 5$。'),
        ),
      ),
    );

    expect(find.textContaining('Parser Error'), findsNothing);
    expect(find.textContaining(r'\newline'), findsNothing);
    expect(find.textContaining('根据三角形内角和定理'), findsOneWidget);
  });

  testWidgets('does not show parser errors for unsupported malformed commands',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentView(r'用消元法解方程组：$\a + b = 5$，a 的值是？'),
        ),
      ),
    );

    expect(find.textContaining('Parser Error'), findsNothing);
    expect(find.textContaining('Undefined control sequence'), findsNothing);
    expect(find.textContaining('用消元法解方程组'), findsOneWidget);
  });

  testWidgets('keeps compact equation-system text readable', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentView(
            r'解方程组：\{x+y=5\newline x-y=1',
            mode: MathContentViewMode.compact,
            maxLines: 1,
          ),
        ),
      ),
    );

    expect(find.textContaining('解方程组'), findsOneWidget);
    expect(find.textContaining(r'\newline'), findsNothing);
  });

  testWidgets('normalizes newline formulas into supported multiline math',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentView(r'解方程组：$x+y=5\newline x-y=1$。'),
        ),
      ),
    );

    expect(find.textContaining('Parser Error'), findsNothing);
    expect(find.textContaining(r'\newline'), findsNothing);
    expect(find.textContaining('解方程组'), findsOneWidget);
  });

  testWidgets('renders cases equation systems without visible parser fallback',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body:
              MathContentView(r'$$\begin{cases} x+y=5 \\ x-y=1 \end{cases}$$'),
        ),
      ),
    );

    expect(find.textContaining('Parser Error'), findsNothing);
    expect(find.textContaining(r'\begin{cases}'), findsNothing);
  });

  testWidgets('repairs AI output that lost slashes before cases commands',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body:
              MathContentView(r'解方程组：$begin{cases} x+y=5 \\ x-y=1 end{cases}$'),
        ),
      ),
    );

    expect(find.textContaining('Parser Error'), findsNothing);
    expect(find.textContaining('begincases'), findsNothing);
    expect(find.textContaining('endcases'), findsNothing);
    expect(find.textContaining('解方程组'), findsOneWidget);
  });

  testWidgets('readable fallback hides broken latex command names',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentView(r'答案：$begin{cases} x=pm2 end{cases}$。'),
        ),
      ),
    );

    expect(find.textContaining('Parser Error'), findsNothing);
    expect(find.textContaining('begincases'), findsNothing);
    expect(find.textContaining('pm2'), findsNothing);
  });

  testWidgets(
      'repairs triangle formulas that lost slashes before angle and circ',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentView(
              r'因为 $angle A + angle B + angle C = 180^circ$，且 $angle A=40^circ$。'),
        ),
      ),
    );

    expect(find.textContaining('Parser Error'), findsNothing);
    expect(find.textContaining('angle'), findsNothing);
    expect(find.textContaining('circ'), findsNothing);
    expect(find.textContaining('因为'), findsOneWidget);
  });

  testWidgets('repairs malformed triangle and physical unit latex',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              MathContentView(
                  r'6. 在 tri\angle ABC 中，若 AB = AC，且 angle A = 40circ，求 angle B。'),
              MathContentView(r'水的密度是 $1.0 \times 10^3 textkg/textm^3$'),
            ],
          ),
        ),
      ),
    );

    expect(find.textContaining('Parser Error'), findsNothing);
    expect(find.textContaining('tri'), findsNothing);
    expect(find.textContaining('textkg'), findsNothing);
    expect(find.textContaining('textm'), findsNothing);
  });

  testWidgets('repairs exact malformed equation and triangle outputs',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Column(
            children: <Widget>[
              MathContentView(r'4. 解方程组： x + y = 5 \ x - y = 1 \\.',
                  mode: MathContentViewMode.compact),
              MathContentView(r'在 tri∠DEF 中，若 DE = DF，且 ∠D = 50°，则 ∠E 等于多少度？'),
            ],
          ),
        ),
      ),
    );

    expect(find.textContaining('Parser Error'), findsNothing);
    expect(find.textContaining(r'\ \'), findsNothing);
    expect(find.textContaining('tri'), findsNothing);
  });

  testWidgets('renders cases environment without stripping begin/end',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentView(
              r'$$\begin{cases} x+y=5 \\ x-y=1 \end{cases}$$'),
        ),
      ),
    );

    expect(find.textContaining('Parser Error'), findsNothing);
    expect(find.textContaining(r'\begin{cases}'), findsNothing);
    expect(find.textContaining('begin{cases}'), findsNothing);
    expect(find.textContaining('end{cases}'), findsNothing);
  });

  testWidgets('tri∠ABC renders as triangle without leftover angle symbol',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentView(r'在 tri∠ABC 中，若 AB = AC，且 ∠A = 40°，求 ∠B。'),
        ),
      ),
    );

    expect(find.textContaining('Parser Error'), findsNothing);
    expect(find.textContaining('tri'), findsNothing);
  });

  testWidgets('equation system with newline separator renders as cases',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MathContentView('解方程组：x + y = 5\n x - y = 1'),
        ),
      ),
    );

    expect(find.textContaining('Parser Error'), findsNothing);
    expect(find.textContaining('解方程组'), findsOneWidget);
  });

  testWidgets(
      'equation system with coefficients renders correctly in compact mode',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentView(
            r'解方程组：2x + 3y = 8 \ x - y = 1',
            mode: MathContentViewMode.compact,
            maxLines: 1,
          ),
        ),
      ),
    );

    expect(find.textContaining('Parser Error'), findsNothing);
    expect(find.textContaining('解方程组'), findsOneWidget);
  });


  testWidgets('does not treat option A as a physics unit', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentView('A. 密度与质量成正比，与体积成反比'),
        ),
      ),
    );

    expect(find.textContaining('A.'), findsOneWidget);
    expect(find.textContaining(r'\mathrm'), findsNothing);
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

  testWidgets('renders equations with extra square brackets around cases',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentView(
            r'解是[\\begin{cases} x=3 \\ y=2 \\end{cases}]。'),
        ),
      ),
    );

    expect(find.textContaining('Parser Error'), findsNothing);
    expect(find.textContaining('begin{cases}'), findsNothing);
    expect(find.textContaining('end{cases}'), findsNothing);
    expect(find.textContaining(r'\['), findsNothing);
  });

  testWidgets('renders double-bracket equation systems', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentView(
            r'方程组[[\begin{cases} x+y=5 \\ x-y=1 \end{cases}]]的解是'),
        ),
      ),
    );

    expect(find.textContaining('Parser Error'), findsNothing);
    expect(find.textContaining('[['), findsNothing);
    expect(find.textContaining(']]'), findsNothing);
    expect(find.textContaining('方程组'), findsOneWidget);
  });

  testWidgets('cases environment with lone backslash-space gets line breaks',
      (tester) async {
    // AI outputs single backslash+space instead of double backslash for line breaks
    // JSON: "\\begin{cases} x+y=5 \\ x-y=1 \\ \\ \\end{cases}"
    // After JSON decode: \begin{cases} x+y=5 \ x-y=1 \ \ \end{cases}
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MathContentView(
            '\\\$\\\$\\begin{cases} x+y=5 \\ x-y=1 \\ \\ \\end{cases}\\\$\\\$',
          ),
        ),
      ),
    );

    expect(find.textContaining('Parser Error'), findsNothing);
    expect(find.textContaining('begin{cases}'), findsNothing);
  });

  testWidgets('triangle is not corrupted by naked angle regex',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentView(r'在 $\triangle ABC$ 中，$\angle B=70^\circ$'),
        ),
      ),
    );

    // \triangle should NOT become \tri\angle
    expect(find.textContaining(r'\tri'), findsNothing);
    expect(find.textContaining('Parser Error'), findsNothing);
  });

  testWidgets('Greek letters are preserved in formulas', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentView(
            r'密度 $\rho$，效率 $\eta$，角速度 $\omega$，电阻 $\Omega$',
          ),
        ),
      ),
    );

    // Greek letters should not be stripped to plain text
    expect(find.textContaining('rho'), findsNothing);
    expect(find.textContaining('eta'), findsNothing);
    expect(find.textContaining('omega'), findsNothing);
  });

  testWidgets('text command is preserved inside formulas', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentView(
            r'底角公式 $\frac{180^\circ-\text{顶角}}{2}$',
          ),
        ),
      ),
    );

    expect(find.textContaining('Parser Error'), findsNothing);
    // \text should not be stripped
    expect(find.textContaining('text{'), findsNothing);
  });

  testWidgets('bracket-wrapped cases with backslash-begin renders correctly',
      (tester) async {
    // This tests the _reBracketCases regex fix (\b word boundary bug)
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: MathContentView(
            r'解方程组：$[\begin{cases} x+y=5 \\ x-y=1 \end{cases}]$',
          ),
        ),
      ),
    );

    expect(find.textContaining('Parser Error'), findsNothing);
    expect(find.textContaining('['), findsNothing);
    expect(find.textContaining(']'), findsNothing);
  });

  testWidgets('strips trailing backslash before newline on option lines',
      (tester) async {
    // JSON: "A. 选项一\\\nB. 选项二" → after decode: "A. 选项一\<LF>B. 选项二"
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MathContentView('A. 受力面积一定时，压强与压力成正比\\\nB. 压力一定时，压强与受力面积成反比'),
        ),
      ),
    );

    expect(find.textContaining(r'\'), findsNothing);
    expect(find.textContaining('受力面积'), findsOneWidget);
  });

  testWidgets('renders cases wrapped in \\( [ ] \\) delimiters',
      (tester) async {
    // After JSON decode + Step 1: \([\begin{cases} x+y=5 \ x-y=1 \ \ \end{cases}]\)
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MathContentView(
            '4. 解方程组：\\([\\begin{cases} x+y=5 \\ x-y=1 \\ \\ \\end{cases}]\\)',
          ),
        ),
      ),
    );

    expect(find.textContaining('Parser Error'), findsNothing);
    expect(find.textContaining('begin{cases}'), findsNothing);
    expect(find.textContaining('解方程组'), findsOneWidget);
  });

  testWidgets('cases inside \\( \\) without brackets upgrades to display math',
      (tester) async {
    // JSON: "\\(\\\\\\begin{cases} x+y=5 \\ x-y=1 \\ \\ \\end{cases}\\)。"
    // After JSON decode: \(\\\begin{cases} x+y=5 \ x-y=1 \ \ \end{cases}\)。
    // After Step 1: \(\begin{cases} x+y=5 \ x-y=1 \ \ \end{cases}\)。
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MathContentView(
            '4. 解方程组：\\(\\begin{cases} x+y=5 \\ x-y=1 \\ \\ \\end{cases}\\)。',
          ),
        ),
      ),
    );

    expect(find.textContaining('Parser Error'), findsNothing);
    expect(find.textContaining('begin{cases}'), findsNothing);
    expect(find.textContaining(r'\('), findsNothing);
    expect(find.textContaining(r'\)'), findsNothing);
    expect(find.textContaining(r'$\'), findsNothing);
    expect(find.textContaining('解方程组'), findsOneWidget);
  });

  testWidgets('exercise cases with \\[ \\] delimiters renders correctly',
      (tester) async {
    // Exercise JSON: "\\[\\\\begin{cases} x+y=8 \\ x-y=2 \\ \\end{cases}\\]"
    // After decode: \[\\begin{cases} x+y=8 \ x-y=2 \ \end{cases}\]
    // After Step 1: \[\begin{cases} x+y=8 \ x-y=2 \ \end{cases}\]
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MathContentView(
            '解方程组：\\[\\begin{cases} x+y=8 \\ x-y=2 \\ \\end{cases}\\]则 x 的值是',
          ),
        ),
      ),
    );

    expect(find.textContaining('Parser Error'), findsNothing);
    expect(find.textContaining('begin{cases}'), findsNothing);
    expect(find.textContaining('解方程组'), findsOneWidget);
  });
}

