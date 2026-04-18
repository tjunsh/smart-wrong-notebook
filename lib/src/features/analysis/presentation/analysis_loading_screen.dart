import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';

class AnalysisLoadingScreen extends ConsumerStatefulWidget {
  const AnalysisLoadingScreen({super.key});

  @override
  ConsumerState<AnalysisLoadingScreen> createState() => _AnalysisLoadingScreenState();
}

class _AnalysisLoadingScreenState extends ConsumerState<AnalysisLoadingScreen> {
  @override
  void initState() {
    super.initState();
    _runAnalysis();
  }

  Future<void> _runAnalysis() async {
    final current = ref.read(currentQuestionProvider);
    if (current == null) {
      if (mounted) context.go('/');
      return;
    }

    final service = ref.read(aiAnalysisServiceProvider);
    final analysis = await service.analyzeQuestion(
      correctedText: current.correctedText,
      subjectName: current.subject.name,
    );

    final updated = current.copyWith(
      contentStatus: ContentStatus.ready,
      analysisResult: analysis,
    );
    ref.read(currentQuestionProvider.notifier).state = updated;

    if (mounted) {
      context.go('/analysis/result');
    }
  }

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
