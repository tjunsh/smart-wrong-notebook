import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/shared/widgets/katex_math_view.dart';

enum MathContentViewMode { full, compact }

/// Renders mixed text+LaTeX content.
///
/// Pipeline: normalize → detect → parse → render.
/// Layer 1: flutter_math_fork (native, ~0ms).
/// Layer 2: KaTeX WebView (complex formulas flutter_math can't handle).
/// Layer 3: Plain text fallback (readable Unicode substitution).
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
    final ts = (style ?? DefaultTextStyle.of(context).style).copyWith(
      color: color,
      fontWeight: fontWeight,
    );

    if (trimmed.isEmpty) {
      return Text('', style: ts, maxLines: maxLines, overflow: overflow);
    }

    if (mode == MathContentViewMode.compact) {
      return Text(
        _compactText(trimmed),
        style: ts,
        maxLines: maxLines,
        overflow: overflow ?? TextOverflow.ellipsis,
      );
    }

    final norm = _normalize(trimmed);
    if (!_hasMath(norm)) {
      return Text(norm, style: ts, maxLines: maxLines, overflow: overflow);
    }

    try {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: _parseDisplay(norm)
            .map((b) => _buildBlock(b, ts))
            .toList(),
      );
    } catch (_) {
      return Text(norm, style: ts, maxLines: maxLines, overflow: overflow);
    }
  }

  // ── Rendering ──

  Widget _buildBlock(_Span b, TextStyle ts) {
    if (b.math) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: _renderMath(b.text, ts, display: true),
      );
    }
    final segs = _parseInline(b.text);
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Wrap(
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 1,
        runSpacing: 4,
        children: segs
            .map((s) => s.math
                ? _renderMath(s.text, ts)
                : Text(s.text, style: ts))
            .toList(),
      ),
    );
  }

  Widget _renderMath(String raw, TextStyle ts, {bool display = false}) {
    final tex = _cleanTex(raw);
    final ms = display || _isDisplayTex(tex)
        ? MathStyle.display
        : MathStyle.text;
    try {
      return Math.tex(
        tex.trim(),
        mathStyle: ms,
        textStyle: ts,
        onErrorFallback: (_) => _katexFallback(tex, ts),
      );
    } catch (_) {
      return _katexFallback(tex, ts);
    }
  }

  Widget _katexFallback(String tex, TextStyle ts) {
    final plain = Text(_toReadable(tex), style: ts);
    if (!KatexMathView.enabled) return plain;
    return KatexMathView(tex, fallback: plain);
  }

  // ── Single normalization pass ──

  static final _reDoubleBS = RegExp(r'\\\\([a-zA-Z]+)');
  static final _reDoubleBSChar = RegExp(r'\\\\(.)');
  static final _reTriAngle = RegExp(r'(?<![A-Za-z\\])tri(?:\\angle|∠|(?=/))\s*');
  static final _reTextUnit =
      RegExp(r'(?<![A-Za-z\\])text(?=kg|m|cm|g|s|N|Pa|J|W|V|A|Ω)');
  static final _reMatrmBare = RegExp(r'\\?mathrm([A-Za-zΩ]+)(\^-?\d+)?');
  static final _reBrokenEq = RegExp(
    r'方程组[：:]\s*([^。]+?[A-Za-z]\s*=\s*[^\\。\n]+)(?:\\+|\n)\s*([^。]+?[A-Za-z]\s*=\s*[^\\。\n]+?)\s*\\*\s*[。.]?\s*$',
    multiLine: true,
  );
  static final _reParenBracket =
      RegExp(r'\(\[([^\[\]]*(?:\\[a-zA-Z]+|\\begin\{)[^\[\]]*)\]\)');
  static final _reDelimBracketCases = RegExp(
      r'\\[(\(]\[\\?begin\{(?:cases|aligned)\}[\s\S]*?\\?end\{(?:cases|aligned)\}\]\\[)\)]');
  static final _reBracketCases = RegExp(
      r'\[\\?begin\{(?:cases|aligned)\}[\s\S]*?\\?end\{(?:cases|aligned)\}\]');
  static final _reBracketLatex = RegExp(r'\[([^\[\]]+)\]');
  static final _reNakedCases = RegExp(
      r'(?<![\$\\])begin\{(?:cases|aligned)\}[\s\S]*?end\{(?:cases|aligned)\}');
  static final _reCasesBody = RegExp(
      r'(\\begin\{(?:cases|aligned)\})([\s\S]*?)(\\end\{(?:cases|aligned)\})');
  static final _reLoneBackslashSpace = RegExp(r'(?<!\\)\\ ');
  static final _reTrailingBackslash = RegExp(r'(?<!\\)\\\n');

  String _normalize(String v) {
    // Step 0: strip trailing backslash before newline (JSON artifact: \\\n → \\+LF)
    var r = v.replaceAll(_reTrailingBackslash, '\n');

    // Step 1: fix double-escaped backslashes from AI output
    r = r
        .replaceAllMapped(_reDoubleBS, (m) => '\\${m.group(1)}')
        .replaceAllMapped(_reDoubleBSChar, (m) => '\\${m.group(1)}');

    // Step 2: fix common AI output quirks
    r = r
        .replaceAll(_reTriAngle, r'\triangle ')
        .replaceAll(_reTextUnit, r'\mathrm')
        .replaceAllMapped(
          _reMatrmBare,
          (m) => '\\mathrm{${m.group(1)}}${m.group(2) ?? ''}',
        );

    // Step 3: broken equation system → cases environment
    if (r.contains('方程组') && !r.contains(r'\begin{cases}')) {
      r = r.replaceAllMapped(_reBrokenEq, (m) {
        final a = m.group(1)!.trim();
        final b = m.group(2)!.trim();
        return '方程组：\$\$\\begin{cases} $a \\\\ $b \\end{cases}\$\$';
      });
    }

    // Step 4: normalize delimiters to $ / $$
    r = r.replaceAllMapped(_reDelimBracketCases, (m) {
      final full = m.group(0)!;
      final bracketStart = full.indexOf('[');
      final bracketEnd = full.lastIndexOf(']');
      return '\$\$${full.substring(bracketStart + 1, bracketEnd)}\$\$';
    });
    r = r.replaceAllMapped(_reParenBracket, (m) => '[${m.group(1)}]');
    r = r.replaceAllMapped(_reBracketCases, (m) {
      final inner = m.group(0)!;
      return '\$\$${inner.substring(1, inner.length - 1)}\$\$';
    });
    r = r.replaceAllMapped(_reBracketLatex, (m) {
      final c = m.group(1)!;
      if (c.contains(r'\') || c.contains('^')) return '\$$c\$';
      return m.group(0)!;
    });
    r = r
        .replaceAll(r'\\(', r'$')
        .replaceAll(r'\\)', r'$')
        .replaceAll(r'\\[', r'$$')
        .replaceAll(r'\\]', r'$$')
        .replaceAll(r'\(', r'$')
        .replaceAll(r'\)', r'$')
        .replaceAll(r'\[', r'$$')
        .replaceAll(r'\]', r'$$');
    r = r.replaceAllMapped(_reNakedCases, (m) => '\$\$${m.group(0)}\$\$');

    // Step 5: fix lone backslash-space → \\ inside cases/aligned
    r = r.replaceAllMapped(_reCasesBody, (m) {
      final body = m.group(2)!.replaceAll(_reLoneBackslashSpace, r'\\ ');
      return '${m.group(1)}$body${m.group(3)}';
    });

    return r;
  }

  // ── TeX expression cleanup (per-formula, not per-document) ──

  static final _reNakedBegin = RegExp(r'(?<!\\)begin\{(cases|aligned)\}');
  static final _reNakedEnd = RegExp(r'(?<!\\)end\{(cases|aligned)\}');
  static final _reNakedAngle = RegExp(r'(?<![A-Za-z\\])angle\b');
  static final _reNakedCirc = RegExp(r'(?<![A-Za-z\\])circ\b');
  static final _reNakedPm = RegExp(r'(?<![A-Za-z\\])pm(?=\b|[0-9])');
  static final _reLeadingBrace = RegExp(r'^\\\{\s*');
  static final _reUnsupported = RegExp(r'\\([a-zA-Z]+)(?=\b|[0-9])');
  static const _envCmds = {'begin', 'end', 'cases', 'aligned'};

  String _cleanTex(String v) {
    var r = v
        .replaceAll(_reNakedBegin, r'\begin{$1}')
        .replaceAll(_reNakedEnd, r'\end{$1}')
        .replaceAll(_reNakedAngle, r'\angle')
        .replaceAll(_reNakedCirc, r'\circ')
        .replaceAll(_reNakedPm, r'\pm')
        .replaceAll(r'\newline', r' \\ ')
        .replaceAll(r'\qquad', ' ')
        .replaceAll(r'\quad', ' ')
        .replaceAll(r'\x', 'x');

    // Wrap bare \\ lines in aligned environment
    if (r.contains(r'\\') && !r.contains(r'\begin{')) {
      r = r'\begin{aligned} '
          '${r.trim().replaceFirst(_reLeadingBrace, '').replaceAll('&', '').trim()}'
          r' \end{aligned}';
    }

    // Strip unsupported commands, keep their name as text
    return r.replaceAllMapped(_reUnsupported, (m) {
      final cmd = m.group(1)!;
      if (_envCmds.contains(cmd)) return m.group(0)!;
      return _supported.contains(cmd) ? m.group(0)! : cmd;
    });
  }

  bool _isDisplayTex(String v) =>
      v.contains(r'\begin{cases}') ||
      v.contains(r'\begin{aligned}') ||
      v.contains(r'\\');

  // ── Detection ──

  static final _reHasLatex = RegExp(r'\\[a-zA-Z]+');
  static final _reHasAscii =
      RegExp(r'[A-Za-z0-9]+(?:\^[A-Za-z0-9]+)+|[A-Za-z0-9]+_[A-Za-z0-9]+');
  static final _reHasInline = RegExp(r'(?<!\\)\$[^\$]+\$');

  bool _hasMath(String v) {
    if (contentFormat == QuestionContentFormat.latexMixed) return true;
    return v.contains(r'$$') ||
        _reHasLatex.hasMatch(v) ||
        _reHasAscii.hasMatch(v) ||
        _reHasInline.hasMatch(v);
  }

  // ── Parsing ──

  static final _reDisplay = RegExp(r'\$\$([\s\S]*?)\$\$', multiLine: true);
  static final _reInline = RegExp(r'(?<!\\)\$([^\$]+)\$');
  static final _rePlainMath = RegExp(
      r'(\\?begin\{(?:cases|aligned)\}[\s\S]*?\\?end\{(?:cases|aligned)\}|\\[a-zA-Z]+(?:\{[^}]*\})*|[A-Za-z0-9]+(?:\^[A-Za-z0-9]+)+|[A-Za-z0-9]+_[A-Za-z0-9]+)');

  List<_Span> _parseDisplay(String v) {
    final out = <_Span>[];
    var cur = 0;
    for (final m in _reDisplay.allMatches(v)) {
      if (m.start > cur) out.add(_Span(v.substring(cur, m.start), false));
      out.add(_Span(m.group(1)!.trim(), true));
      cur = m.end;
    }
    if (cur < v.length) out.add(_Span(v.substring(cur), false));
    return out.where((b) => b.text.trim().isNotEmpty).toList();
  }

  List<_Span> _parseInline(String v) {
    final out = <_Span>[];
    var cur = 0;
    for (final m in _reInline.allMatches(v)) {
      if (m.start > cur) out.addAll(_splitPlain(v.substring(cur, m.start)));
      out.add(_Span(m.group(1)!.trim(), true));
      cur = m.end;
    }
    if (cur < v.length) out.addAll(_splitPlain(v.substring(cur)));
    return out.where((s) => s.text.isNotEmpty).toList();
  }

  List<_Span> _splitPlain(String v) {
    final out = <_Span>[];
    var cur = 0;
    for (final m in _rePlainMath.allMatches(v)) {
      if (m.start > cur) out.add(_Span(v.substring(cur, m.start), false));
      out.add(_Span(m.group(0)!, true));
      cur = m.end;
    }
    if (cur < v.length) out.add(_Span(v.substring(cur), false));
    return out;
  }

  // ── Layer 3: readable text ──

  static final _reBeginEnd = RegExp(r'\\?begin\{[^}]+\}|\\?end\{[^}]+\}');
  static final _reFrac = RegExp(r'\\frac\{([^}]*)\}\{([^}]*)\}');
  static final _reMatrm = RegExp(r'\\mathrm\{([^}]*)\}');
  static final _reCmd = RegExp(r'\\([a-zA-Z]+)(?=\b|[0-9])');
  static final _reNakedSymbols =
      RegExp(r'(?<![A-Za-z\\])(?:angle|triangle|circ|times|div|pm)(?=\b|[0-9])');
  static final _reSpaces = RegExp(r'[ \t]+');

  static const _symbols = {
    'angle': '∠', 'triangle': '△', 'circ': '°', 'pm': '±', 'mp': '∓',
    'times': '×', 'div': '÷', 'cdot': '·', 'leq': '≤', 'geq': '≥',
    'neq': '≠', 'approx': '≈', 'equiv': '≡', 'sim': '∼',
    'infty': '∞', 'perp': '⊥', 'parallel': '∥',
    'rightarrow': '→', 'leftarrow': '←',
    'Rightarrow': '⇒', 'Leftarrow': '⇐',
    'alpha': 'α', 'beta': 'β', 'gamma': 'γ', 'delta': 'δ',
    'epsilon': 'ε', 'varepsilon': 'ε', 'zeta': 'ζ', 'eta': 'η',
    'theta': 'θ', 'vartheta': 'ϑ', 'iota': 'ι', 'kappa': 'κ',
    'lambda': 'λ', 'mu': 'μ', 'nu': 'ν', 'xi': 'ξ',
    'pi': 'π', 'rho': 'ρ', 'varrho': 'ϱ',
    'sigma': 'σ', 'tau': 'τ', 'upsilon': 'υ',
    'phi': 'φ', 'varphi': 'ϕ', 'chi': 'χ', 'psi': 'ψ', 'omega': 'ω',
    'Gamma': 'Γ', 'Delta': 'Δ', 'Theta': 'Θ', 'Lambda': 'Λ',
    'Xi': 'Ξ', 'Pi': 'Π', 'Sigma': 'Σ', 'Upsilon': 'Υ',
    'Phi': 'Φ', 'Psi': 'Ψ', 'Omega': 'Ω',
    'partial': '∂', 'nabla': '∇', 'propto': '∝',
    'forall': '∀', 'exists': '∃', 'emptyset': '∅',
    'in': '∈', 'notin': '∉', 'subset': '⊂', 'supset': '⊃',
    'cup': '∪', 'cap': '∩',
  };

  String _toReadable(String v) {
    return v
        .replaceAll(_reBeginEnd, '')
        .replaceAll(r'\newline', '\n')
        .replaceAll(r'\\', '\n')
        .replaceAll('&', '')
        .replaceAll(r'\qquad', ' ')
        .replaceAll(r'\quad', ' ')
        .replaceAllMapped(_reFrac, (m) => '${m.group(1)}/${m.group(2)}')
        .replaceAllMapped(_reMatrm, (m) => m.group(1)!)
        .replaceAllMapped(_reCmd, (m) {
          final c = m.group(1)!;
          if (_symbols.containsKey(c)) return _symbols[c]!;
          return _supported.contains(c) ? '' : c;
        })
        .replaceAllMapped(
            _reNakedSymbols, (m) => _symbols[m.group(0)!] ?? m.group(0)!)
        .replaceAll(r'\x', 'x')
        .replaceAll(r'\{', '{')
        .replaceAll(r'\}', '}')
        .replaceAll(_reSpaces, ' ')
        .trim();
  }

  // ── Compact mode ──

  static final _reWS = RegExp(r'\s+');

  String _compactText(String v) {
    final norm = _normalize(v);
    final stripped = norm
        .replaceAll(_reDisplay, r' $1 ')
        .replaceAllMapped(_reInline, (m) => ' ${m.group(1)} ');
    return _toReadable(stripped).replaceAll(_reWS, ' ').trim();
  }
}

const _supported = <String>{
  'begin', 'end', 'frac', 'sqrt', 'angle', 'triangle', 'circ', 'degree',
  'times', 'div', 'cdot', 'pm', 'mp', 'leq', 'geq', 'neq', 'approx',
  'left', 'right', 'sin', 'cos', 'tan', 'log', 'ln', 'sec', 'csc', 'cot',
  // Greek lowercase
  'alpha', 'beta', 'gamma', 'delta', 'epsilon', 'varepsilon',
  'zeta', 'eta', 'theta', 'vartheta', 'iota', 'kappa',
  'lambda', 'mu', 'nu', 'xi', 'pi', 'varpi',
  'rho', 'varrho', 'sigma', 'varsigma', 'tau', 'upsilon',
  'phi', 'varphi', 'chi', 'psi', 'omega',
  // Greek uppercase
  'Gamma', 'Delta', 'Theta', 'Lambda', 'Xi', 'Pi',
  'Sigma', 'Upsilon', 'Phi', 'Psi', 'Omega',
  'mathrm', 'cases', 'aligned',
  'rightarrow', 'leftarrow', 'Rightarrow', 'Leftarrow',
  'text', 'textrm', 'textbf', 'textit', 'textup', 'textsf', 'texttt',
  'operatorname', 'overline', 'underline', 'hat', 'bar', 'vec',
  'dot', 'ddot', 'tilde', 'infty', 'sum', 'prod', 'int', 'lim',
  'to', 'gets', 'iff', 'implies', 'therefore', 'because',
  'forall', 'exists', 'in', 'notin', 'subset', 'supset',
  'cup', 'cap', 'setminus', 'emptyset', 'perp', 'parallel',
  'not', 'neg', 'land', 'lor', 'oplus', 'otimes',
  'partial', 'nabla', 'propto', 'equiv', 'sim', 'simeq',
};

class _Span {
  const _Span(this.text, this.math);
  final String text;
  final bool math;
}
