import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:webview_flutter/webview_flutter.dart';

class KatexMathView extends StatefulWidget {
  const KatexMathView(this.formula, {super.key, this.fallback});

  final String formula;
  final Widget? fallback;

  static bool enabled = true;
  static const _maxConcurrent = 3;
  static int _activeCount = 0;
  static String? _templateHtml;

  static Future<void> preload() async {
    _templateHtml ??=
        await rootBundle.loadString('assets/katex/katex_template.html');
  }

  @override
  State<KatexMathView> createState() => _KatexMathViewState();
}

class _KatexMathViewState extends State<KatexMathView> {
  WebViewController? _controller;
  double _height = 40;
  bool _ready = false;
  bool _acquired = false;

  @override
  void initState() {
    super.initState();
    if (KatexMathView._activeCount >= KatexMathView._maxConcurrent) return;
    final template = KatexMathView._templateHtml;
    if (template == null) return;
    KatexMathView._activeCount++;
    _acquired = true;
    _initWebView(template);
  }

  void _initWebView(String template) {
    final escaped = widget.formula
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "\\'")
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');

    final isDisplay = widget.formula.contains(r'\begin{') ||
        widget.formula.contains(r'\\');

    final html = template
        .replaceFirst('FORMULA_PLACEHOLDER', escaped)
        .replaceFirst('DISPLAY_MODE', isDisplay.toString());

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'HeightChannel',
        onMessageReceived: (msg) {
          final h = double.tryParse(msg.message) ?? 40;
          if (mounted && h != _height) {
            setState(() {
              _height = h + 16;
              _ready = true;
            });
          }
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted && !_ready) setState(() => _ready = true);
        },
      ))
      ..loadHtmlString(html, baseUrl: 'asset:///assets/katex/');
  }

  @override
  void dispose() {
    if (_acquired) KatexMathView._activeCount--;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_controller == null) {
      return widget.fallback ?? const SizedBox.shrink();
    }
    return SizedBox(
      height: _height,
      child: AnimatedOpacity(
        opacity: _ready ? 1 : 0,
        duration: const Duration(milliseconds: 150),
        child: WebViewWidget(controller: _controller!),
      ),
    );
  }
}
