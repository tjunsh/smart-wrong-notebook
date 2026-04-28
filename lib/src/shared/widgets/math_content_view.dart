import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';

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
        onErrorFallback: (_) =>
            Text(_readableMathText(normalized), style: effectiveStyle),
      );
    } catch (_) {
      return Text(_readableMathText(normalized), style: effectiveStyle);
    }
  }

  String _normalizeDisplayText(String value) {
    return _normalizeBrokenEquationSystem(value)
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
      (match) => _supportedLatexCommands.contains(match.group(1))
          ? match.group(0)!
          : match.group(1)!,
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
    return value
        .replaceAll(r'\\(', r'$')
        .replaceAll(r'\\)', r'$')
        .replaceAll(r'\(', r'$')
        .replaceAll(r'\)', r'$')
        .replaceAll(r'\\[', r'$$')
        .replaceAll(r'\\]', r'$$')
        .replaceAll(r'\[', r'$$')
        .replaceAll(r'\]', r'$$')
        .replaceAllMapped(
          RegExp(
              r'(?<!\\)(?:begin\{(cases|aligned)\}[\s\S]*?end\{(?:cases|aligned)\})'),
          (match) => '\$\$${match.group(0)}\$\$',
        )
        .replaceAllMapped(
          RegExp(r'(?<![A-Za-z\\])tri\\angle\s*|(?<![A-Za-z\\])tri∠'),
          (_) => r'\triangle ',
        );
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
