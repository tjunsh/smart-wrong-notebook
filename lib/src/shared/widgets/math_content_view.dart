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
    final effectiveStyle = (style ?? DefaultTextStyle.of(context).style).copyWith(
      color: color,
      fontWeight: fontWeight,
    );

    if (trimmed.isEmpty) {
      return Text('', style: effectiveStyle, maxLines: maxLines, overflow: overflow);
    }

    if (!_shouldRenderMath(trimmed)) {
      return Text(trimmed, style: effectiveStyle, maxLines: maxLines, overflow: overflow);
    }

    if (mode == MathContentViewMode.compact) {
      return Text(
        _compactText(trimmed),
        style: effectiveStyle,
        maxLines: maxLines,
        overflow: overflow ?? TextOverflow.ellipsis,
      );
    }

    try {
      final segments = _parseSegments(trimmed);
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: segments.map((segment) => _buildSegment(segment, effectiveStyle)).toList(),
      );
    } catch (_) {
      return Text(trimmed, style: effectiveStyle, maxLines: maxLines, overflow: overflow);
    }
  }

  Widget _buildSegment(_MathSegment segment, TextStyle effectiveStyle) {
    if (!segment.isMath) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(segment.value, style: effectiveStyle),
      );
    }

    try {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Math.tex(
          segment.value,
          mathStyle: MathStyle.text,
          textStyle: effectiveStyle,
        ),
      );
    } catch (_) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: Text(segment.value, style: effectiveStyle),
      );
    }
  }

  bool _shouldRenderMath(String value) {
    if (contentFormat == QuestionContentFormat.latexMixed) {
      return true;
    }

    return value.contains(r'$$') ||
        value.contains(r'\\(') ||
        value.contains(r'\\)') ||
        value.contains(r'\\[') ||
        value.contains(r'\\]') ||
        RegExp(r'(?<!\\)\$[^\$]+\$').hasMatch(value);
  }

  List<_MathSegment> _parseSegments(String value) {
    final blockPattern = RegExp(r'\$\$([\s\S]*?)\$\$', multiLine: true);
    final inlinePattern = RegExp(r'(?<!\\)\$([^\$]+)\$');
    final segments = <_MathSegment>[];
    var cursor = 0;

    for (final blockMatch in blockPattern.allMatches(value)) {
      if (blockMatch.start > cursor) {
        segments.addAll(_parseInlineSegments(value.substring(cursor, blockMatch.start), inlinePattern));
      }
      segments.add(_MathSegment(blockMatch.group(1)!.trim(), true));
      cursor = blockMatch.end;
    }

    if (cursor < value.length) {
      segments.addAll(_parseInlineSegments(value.substring(cursor), inlinePattern));
    }

    return segments.where((segment) => segment.value.isNotEmpty).toList();
  }

  List<_MathSegment> _parseInlineSegments(String value, RegExp pattern) {
    final segments = <_MathSegment>[];
    var cursor = 0;

    for (final match in pattern.allMatches(value)) {
      if (match.start > cursor) {
        segments.add(_MathSegment(value.substring(cursor, match.start), false));
      }
      segments.add(_MathSegment(match.group(1)!.trim(), true));
      cursor = match.end;
    }

    if (cursor < value.length) {
      segments.add(_MathSegment(value.substring(cursor), false));
    }

    return segments;
  }

  String _compactText(String value) {
    return value
        .replaceAll(RegExp(r'\$\$([\s\S]*?)\$\$', multiLine: true), r' $1 ')
        .replaceAllMapped(RegExp(r'(?<!\\)\$([^\$]+)\$'), (match) => ' ${match.group(1)} ')
        .replaceAll(r'\\(', '')
        .replaceAll(r'\\)', '')
        .replaceAll(r'\\[', '')
        .replaceAll(r'\\]', '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _MathSegment {
  const _MathSegment(this.value, this.isMath);

  final String value;
  final bool isMath;
}
