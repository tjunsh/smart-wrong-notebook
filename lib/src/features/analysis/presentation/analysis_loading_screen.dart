import 'package:flutter/material.dart';

class AnalysisLoadingScreen extends StatelessWidget {
  const AnalysisLoadingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('AI 正在思考...'),
          ],
        ),
      ),
    );
  }
}
