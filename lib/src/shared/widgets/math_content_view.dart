import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/shared/widgets/katex_math_view.dart';

enum MathContentViewMode { full, compact }

class MathContentView extends StatelessWidget {
  const MathContentView(
    this.content, {
    super.key,
    this.contentFormat,
    this.mode = MathContentViewMode.full,
    this.style,
    this.color,
    this.fontWeight,
    this.maxLines,
    this.overflow,
  });

  final String content;
  final QuestionContentFormat? contentFormat;
  final MathContentViewMode mode;
  final TextStyle? style;
  final Color? color;
  final FontWeight? fontWeight;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    final trimmed = content.trim();
    final effectiveStyle =
        (style ?? DefaultTextStyle.of(context).style).copyWith(
      color: color,
      fontWeight: fontWeight,
    );

    if (trimmed.isEmpty) {
      return Text('',
          style: effectiveStyle, maxLines: maxLines, overflow: overflow);
    }

    if (mode == MathContentViewMode.compact) {
      return Text(
        _compactText(trimmed),
        style: effectiveStyle,
        maxLines: maxLines,
        overflow: overflow ?? TextOverflow.ellipsis,
      );
    }

    final normalized = _normalizeMathDelimiters(_normalizeDisplayText(trimmed));
    if (!_shouldRenderMath(normalized)) {
      return Text(normalized,
          style: effectiveStyle, maxLines: maxLines, overflow: overflow);
    }

    try {
      final blocks = _parseBlocks(normalized);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children:
            blocks.map((block) => _buildBlock(block, effectiveStyle)).toList(),
      );
    } catch (_) {
      return Text(normalized,
          style: effectiveStyle, maxLines: maxLines, overflow: overflow);
    }
  }

  Widget _buildBlock(_MathBlock block, TextStyle effectiveStyle) {
    if (block.isMath) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: _buildMath(block.value, effectiveStyle),
      );
    }

    final segments = _parseInlineSegments(block.value);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 1,
        runSpacing: 4,
        children: segments
            .map((segment) => segment.isMath
                ? _buildMath(segment.value, effectiveStyle)
                : Text(segment.value, style: effectiveStyle))
            .toList(),
      ),
    );
  }

  Widget _buildMath(String value, TextStyle effectiveStyle) {
    final normalized = _normalizeMathExpression(value);
    final mathStyle =
        _isDisplayMath(normalized) ? MathStyle.display : MathStyle.text;
    try {
      return Math.tex(
        normalized.trim(),
        mathStyle: mathStyle,
        textStyle: effectiveStyle,
        onErrorFallback: (_) => _tryKatex(normalized, effectiveStyle),
      );
    } catch (_) {
      return _tryKatex(normalized, effectiveStyle);
    }
  }

  Widget _tryKatex(String value, TextStyle effectiveStyle) {
    if (KatexMathView.enabled) {
      return KatexMathView(value, onHeight: (h) {});
    }
    return Text(_readableMathText(value), style: effectiveStyle);
  }

  String _normalizeDisplayText(String value) {
    return _normalizeBrokenEquationSystem(_normalizeDoubleBackslashLatex(value))
        .replaceAll(RegExp(r'(?<![A-Za-z\\])tri\\angle\s*'), r'\triangle ')
        .replaceAll(RegExp(r'(?<![A-Za-z\\])tri∠'), r'\triangle ')
        .replaceAll(RegExp(r'(?<![A-Za-z\\])tri(?=\\angle|/)'), r'\triangle')
        .replaceAll(
            RegExp(r'(?<![A-Za-z\\])text(?=kg|m|cm|g|s|N|Pa|J|W|V|A|Ω)'),
            r'\mathrm')
        .replaceAllMapped(
          RegExp(r'\\?mathrm([A-Za-zΩ]+)(\^-?\d+)?'),
          (match) => '\\mathrm{${match.group(1)}}${match.group(2) ?? ''}',
        );
  }

  String _normalizeDoubleBackslashLatex(String value) {
    return value
        .replaceAllMapped(
          RegExp(r'\\\\([a-zA-Z]+)'),
          (match) => '\\${match.group(1)}',
        )
        .replaceAllMapped(
          RegExp(r'\\\\(.)'),
          (match) => '\\${match.group(1)}',
        )
        // 具体的 LaTeX 命令（覆盖通用规则处理不到的复杂情况）
        .replaceAll(RegExp(r'\\\\times\b'), r'\times')
        .replaceAll(RegExp(r'\\\\cdot\b'), r'\cdot')
        .replaceAll(RegExp(r'\\\\pi\b'), r'\pi')
        .replaceAll(RegExp(r'\\\\alpha\b'), r'\alpha')
        .replaceAll(RegExp(r'\\\\beta\b'), r'\beta')
        .replaceAll(RegExp(r'\\\\gamma\b'), r'\gamma')
        .replaceAll(RegExp(r'\\\\theta\b'), r'\theta')
        .replaceAll(RegExp(r'\\\\Delta\b'), r'\Delta')
        .replaceAll(RegExp(r'\\\\sqrt\b'), r'\sqrt')
        .replaceAll(RegExp(r'\\\\angle\b'), r'\angle')
        .replaceAll(RegExp(r'\\\\triangle\b'), r'\triangle')
        .replaceAll(RegExp(r'\\\\circ\b'), r'\circ')
        .replaceAll(RegExp(r'\\\\sin\b'), r'\sin')
        .replaceAll(RegExp(r'\\\\cos\b'), r'\cos')
        .replaceAll(RegExp(r'\\\\tan\b'), r'\tan')
        .replaceAll(RegExp(r'\\\\log\b'), r'\log')
        .replaceAll(RegExp(r'\\\\ln\b'), r'\ln')
        .replaceAll(RegExp(r'\\\\div\b'), r'\div')
        .replaceAll(RegExp(r'\\\\pm\b'), r'\pm')
        .replaceAll(RegExp(r'\\\\leq\b'), r'\leq')
        .replaceAll(RegExp(r'\\\\geq\b'), r'\geq')
        .replaceAll(RegExp(r'\\\\neq\b'), r'\neq')
        .replaceAll(RegExp(r'\\\\approx\b'), r'\approx')
        .replaceAll(RegExp(r'\\\\,'), r'\,');
  }

  String _normalizeBrokenEquationSystem(String value) {
    if (!value.contains('方程组') || value.contains(r'\begin{cases}')) {
      return value;
    }

    return value.replaceAllMapped(
      RegExp(
        r'方程组[：:]\s*([^。]+?[A-Za-z]\s*=\s*[^\\。\n]+)(?:\\+|\n)\s*([^。]+?[A-Za-z]\s*=\s*[^\\。\n]+?)\s*\\*\s*[。.]?\s*$',
        multiLine: true,
      ),
      (match) {
        final first = match.group(1)!.trim();
        final second = match.group(2)!.trim();
        return '方程组：\$\$\\begin{cases} $first \\\\ $second \\end{cases}\$\$';
      },
    );
  }

  String _normalizeMathExpression(String value) {
    final multilineNormalized = _normalizeMultilineMath(value)
        .replaceAll(r'\qquad', ' ')
        .replaceAll(r'\quad', ' ')
        .replaceAll(r'\x', 'x');

    return multilineNormalized.replaceAllMapped(
      RegExp(r'\\([a-zA-Z]+)\b'),
      (match) {
        final cmd = match.group(1)!;
        // 这些命令需要保留 \ 前缀，不能单独处理
        if (['begin', 'end', 'cases', 'aligned'].contains(cmd)) {
          return match.group(0)!;
        }
        return _supportedLatexCommands.contains(cmd)
            ? match.group(0)!
            : cmd;
      },
    );
  }

  String _normalizeMultilineMath(String value) {
    final processed = _normalizeDisplayText(value)
        .replaceAll(RegExp(r'(?<!\\)begin\{(cases|aligned)\}'), r'\begin{$1}')
        .replaceAll(RegExp(r'(?<!\\)end\{(cases|aligned)\}'), r'\end{$1}')
        .replaceAll(RegExp(r'(?<!\\)angle\b'), r'\angle')
        .replaceAll(RegExp(r'(?<!\\)circ\b'), r'\circ')
        .replaceAllMapped(RegExp(r'(?<!\\)pm(?=[A-Za-z0-9])'), (_) => r'\pm ')
        .replaceAll(RegExp(r'(?<!\\)pm\b'), r'\pm')
        .replaceAll(r'\newline', r' \\ ');
    if (!processed.contains(r'\\') || processed.contains(r'\begin{')) {
      return processed;
    }

    final trimmed = processed.trim();
    final body = trimmed
        .replaceFirst(RegExp(r'^\\\{\s*'), '')
        .replaceAll('&', '')
        .trim();

    return r'\begin{aligned} ' + body + r' \end{aligned}';
  }

  String _readableMathText(String value) {
    return _normalizeDisplayText(value)
        .replaceAll(RegExp(r'\\?begin\{[^}]+\}|\\?end\{[^}]+\}'), '')
        .replaceAll(r'\newline', '\n')
        .replaceAll(r'\\', '\n')
        .replaceAll('&', '')
        .replaceAll(r'\qquad', ' ')
        .replaceAll(r'\quad', ' ')
        .replaceAll(r'\left', '')
        .replaceAll(r'\right', '')
        .replaceAll(r'\angle', '∠')
        .replaceAll(RegExp(r'(?<![A-Za-z])angle\b'), '∠')
        .replaceAll(r'\triangle', '△')
        .replaceAll(RegExp(r'(?<![A-Za-z])triangle\b'), '△')
        .replaceAll(r'\circ', '°')
        .replaceAll(RegExp(r'(?<![A-Za-z])circ\b'), '°')
        .replaceAll(r'\pm', '±')
        .replaceAllMapped(RegExp(r'(?<![A-Za-z])pm(?=[A-Za-z0-9])'), (_) => '±')
        .replaceAll(RegExp(r'(?<![A-Za-z])pm\b'), '±')
        .replaceAll(r'\times', '×')
        .replaceAll(RegExp(r'(?<![A-Za-z])times\b'), '×')
        .replaceAll(r'\div', '÷')
        .replaceAll(RegExp(r'(?<![A-Za-z])div\b'), '÷')
        .replaceAllMapped(
          RegExp(r'\\frac\{([^}]*)\}\{([^}]*)\}'),
          (match) => '${match.group(1)}/${match.group(2)}',
        )
        .replaceAllMapped(
          RegExp(r'\\mathrm\{([^}]*)\}'),
          (match) => match.group(1)!,
        )
        .replaceAllMapped(
          RegExp(r'\\([a-zA-Z]+)\b'),
          (match) => _supportedLatexCommands.contains(match.group(1))
              ? ''
              : match.group(1)!,
        )
        .replaceAll(r'\x', 'x')
        .replaceAll(r'\{', '{')
        .replaceAll(r'\}', '}')
        .replaceAll(r'\(', '')
        .replaceAll(r'\)', '')
        .replaceAll(r'\[', '')
        .replaceAll(r'\]', '')
        .replaceAll(RegExp(r'[ \t]+'), ' ')
        .trim();
  }

  bool _shouldRenderMath(String value) {
    if (contentFormat == QuestionContentFormat.latexMixed) {
      return true;
    }

    return value.contains(r'$$') ||
        value.contains(r'\(') ||
        value.contains(r'\)') ||
        value.contains(r'\[') ||
        value.contains(r'\]') ||
        _hasLatexCommand(value) ||
        _hasAsciiFormula(value) ||
        RegExp(r'(?<!\\)\$[^\$]+\$').hasMatch(value);
  }

  List<_MathBlock> _parseBlocks(String value) {
    final blockPattern = RegExp(r'\$\$([\s\S]*?)\$\$', multiLine: true);
    final blocks = <_MathBlock>[];
    var cursor = 0;

    for (final blockMatch in blockPattern.allMatches(value)) {
      if (blockMatch.start > cursor) {
        blocks
            .add(_MathBlock(value.substring(cursor, blockMatch.start), false));
      }
      blocks.add(_MathBlock(blockMatch.group(1)!.trim(), true));
      cursor = blockMatch.end;
    }

    if (cursor < value.length) {
      blocks.add(_MathBlock(value.substring(cursor), false));
    }

    return blocks.where((block) => block.value.trim().isNotEmpty).toList();
  }

  List<_MathSegment> _parseInlineSegments(String value) {
    final pattern = RegExp(r'(?<!\\)\$([^\$]+)\$');
    final segments = <_MathSegment>[];
    var cursor = 0;

    for (final match in pattern.allMatches(value)) {
      if (match.start > cursor) {
        segments.addAll(_splitPlainText(value.substring(cursor, match.start)));
      }
      segments.add(_MathSegment(match.group(1)!.trim(), true));
      cursor = match.end;
    }

    if (cursor < value.length) {
      segments.addAll(_splitPlainText(value.substring(cursor)));
    }

    return segments.where((segment) => segment.value.isNotEmpty).toList();
  }

  List<_MathSegment> _splitPlainText(String value) {
    final parts = <_MathSegment>[];
    final pattern = RegExp(
        r'(\$\$[\s\S]*?\$\$|\\?begin\{(?:cases|aligned)\}[\s\S]*?\\?end\{(?:cases|aligned)\}|\\[a-zA-Z]+(?:\{[^}]*\})*(?:\{[^}]*\})*|[A-Za-z0-9]+(?:\^[A-Za-z0-9]+)+|[A-Za-z0-9]+_[A-Za-z0-9]+)');
    var cursor = 0;

    for (final match in pattern.allMatches(value)) {
      if (match.start > cursor) {
        parts.add(_MathSegment(value.substring(cursor, match.start), false));
      }
      parts.add(_MathSegment(match.group(0)!, true));
      cursor = match.end;
    }

    if (cursor < value.length) {
      parts.add(_MathSegment(value.substring(cursor), false));
    }

    return parts;
  }

  String _normalizeMathDelimiters(String value) {
    // 1. 先处理方括号包裹的 cases 环境（最优先，因为后续转换会破坏格式）
    // 例如: [\begin{cases} x+y=5 \\ x-y=1 \end{cases}] → $$\begin{cases} x+y=5 \\ x-y=1 \end{cases}$$
    var result = value.replaceAllMapped(
      RegExp(r'\[\\?\begin\{(?:cases|aligned)\}[\s\S]*?\\?\end\{(?:cases|aligned)\}\]'),
      (match) {
        final inner = match.group(0)!;
        // 去掉首尾的方括号，保留 LaTeX 内容
        final stripped = inner.substring(1, inner.length - 1);
        return '\$\$$stripped\$\$';
      },
    );

    // 2. 处理方括号包裹的普通 LaTeX（如 [x^2] → $x^2$）
    result = result.replaceAllMapped(
      RegExp(r'\[([^\[\]]+)\]'),
      (match) {
        final content = match.group(1)!;
        if (content.contains(r'\') || content.contains('^') || content.contains(r'\frac') || content.contains(r'\times') || content.contains(r'\begin')) {
          return '\$$content\$';
        }
        return match.group(0)!;
      },
    );

    // 3. 处理带反斜杠的转义括号
    result = result
        .replaceAll(r'\\(', r'$')
        .replaceAll(r'\\)', r'$')
        .replaceAll(r'\\[', r'$$')
        .replaceAll(r'\\]', r'$$');

    // 4. 处理普通圆括号
    result = result
        .replaceAll(r'\(', r'$')
        .replaceAll(r'\)', r'$');

    // 5. 处理普通方括号
    result = result
        .replaceAll(r'\[', r'$$')
        .replaceAll(r'\]', r'$$');

    // 6. 处理裸 cases 环境
    result = result.replaceAllMapped(
      RegExp(r'(?<!\\)(?:begin\{(?:cases|aligned)\}[\s\S]*?end\{(?:cases|aligned)\})'),
      (match) => '\$\$${match.group(0)}\$\$',
    );

    // 7. 处理 triangle 简写
    result = result.replaceAllMapped(
      RegExp(r'(?<![A-Za-z\\])tri\\angle\s*|(?<![A-Za-z\\])tri∠'),
      (_) => r'\triangle ',
    );

    return result;
  }

  bool _hasLatexCommand(String value) {
    return RegExp(r'\\[a-zA-Z]+').hasMatch(value);
  }

  bool _hasAsciiFormula(String value) {
    return RegExp(r'[A-Za-z0-9]+(?:\^[A-Za-z0-9]+)+|[A-Za-z0-9]+_[A-Za-z0-9]+')
        .hasMatch(value);
  }

  bool _isDisplayMath(String value) {
    return value.contains(r'\begin{cases}') ||
        value.contains(r'\begin{aligned}') ||
        value.contains(r'\\');
  }

  String _compactText(String value) {
    return _readableMathText(_normalizeMathDelimiters(
                _normalizeDisplayText(value))
            .replaceAll(RegExp(r'\$\$([\s\S]*?)\$\$', multiLine: true), r' $1 ')
            .replaceAllMapped(RegExp(r'(?<!\\)\$([^\$]+)\$'),
                (match) => ' ${match.group(1)} '))
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

const _supportedLatexCommands = <String>{
  'begin',
  'end',
  'frac',
  'sqrt',
  'angle',
  'triangle',
  'circ',
  'degree',
  'times',
  'div',
  'cdot',
  'pm',
  'leq',
  'geq',
  'neq',
  'approx',
  'left',
  'right',
  'sin',
  'cos',
  'tan',
  'log',
  'ln',
  'pi',
  'alpha',
  'beta',
  'gamma',
  'theta',
  'Delta',
  'mathrm',
  'cases',
  'aligned',
};

class _MathBlock {
  const _MathBlock(this.value, this.isMath);

  final String value;
  final bool isMath;
}

class _MathSegment {
  const _MathSegment(this.value, this.isMath);

  final String value;
  final bool isMath;
}
