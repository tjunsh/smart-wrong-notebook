import 'dart:async';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

class KatexMathView extends StatefulWidget {
  const KatexMathView(this.formula, {super.key, this.onHeight});

  final String formula;
  final ValueChanged<double>? onHeight;

  /// Enable/disable KaTeX WebView fallback.
  /// Set to false in widget tests for deterministic behavior.
  /// Disabled by default due to WebView initialization overhead on scroll.
  static bool enabled = false;

  /// Global WebView controller cache for performance optimization.
  /// Avoids re-creating WebView for each formula.
  static WebViewController? _cachedController;

  @override
  State<KatexMathView> createState() => _KatexMathViewState();
}

class _KatexMathViewState extends State<KatexMathView> {
  late WebViewController _controller;
  double _height = 40;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  Future<void> _initWebView() async {
    // Try to reuse cached controller for performance
    if (KatexMathView._cachedController != null) {
      _controller = KatexMathView._cachedController!;
      _ready = true;
      return;
    }

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.transparent)
      ..addJavaScriptChannel(
        'HeightChannel',
        onMessageReceived: (message) {
          final h = double.tryParse(message.message) ?? 40;
          if (h != _height) {
            setState(() => _height = h + 16);
            widget.onHeight?.call(_height);
          }
        },
      )
      ..setNavigationDelegate(NavigationDelegate(
        onPageFinished: (_) {
          if (mounted) setState(() => _ready = true);
          KatexMathView._cachedController ??= _controller;
        },
      ))
      ..loadHtmlString(_katexBaseHtml, baseUrl: 'asset:///assets/katex/');
  }

  String _escapeFormula(String s) {
    return s
        .replaceAll('\\', '\\\\')
        .replaceAll('"', '\\"')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r');
  }

  @override
  Widget build(BuildContext context) {
    // If using cached controller, inject formula via JavaScript
    if (_cachedReady && KatexMathView._cachedController != null) {
      _controller.runJavaScript(_buildJsCall(widget.formula));
    }
    return SizedBox(
      height: _height,
      child: AnimatedOpacity(
        opacity: _ready ? 1 : 0,
        duration: const Duration(milliseconds: 150),
        child: WebViewWidget(controller: _controller),
      ),
    );
  }

  String _buildJsCall(String formula) {
    return '''
try {
  var formula = "${_escapeFormula(formula)}";
  katex.render(formula, document.getElementById('formula'), {
    throwOnError: false, strict: false, trust: true, displayMode: false
  });
  var h = document.body.scrollHeight;
  HeightChannel.postMessage(h.toString());
} catch(e) {
  HeightChannel.postMessage('40');
}
''';
  }

  bool get _cachedReady => !_ready && KatexMathView._cachedController != null;

  static const _katexBaseHtml = '''
<!DOCTYPE html>
<html>
<head>
<meta name="viewport" content="width=device-width, initial-scale=1, maximum-scale=1">
<link rel="stylesheet" href="katex.min.css">
<style>
body{margin:0;padding:8px;overflow:hidden;background:transparent}
</style>
</head>
<body>
<span id="formula"></span>
<script src="katex.min.js"></script>
<script>
HeightChannel.postMessage('40');
</script>
</body>
</html>
''';
}
