import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';

class AnalysisResultScreen extends ConsumerWidget {
  const AnalysisResultScreen({super.key, required this.record});

  final QuestionRecord record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = record.analysisResult;
    return Scaffold(
      appBar: AppBar(title: const Text('AI 解析结果')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          if (result != null) ...<Widget>[
            Text('答案：${result.finalAnswer}'),
            const SizedBox(height: 12),
            Text('错因：${result.mistakeReason}'),
            const SizedBox(height: 12),
            Text('学习建议：${result.studyAdvice}'),
            const SizedBox(height: 16),
            Text('举一反三：', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...result.generatedExercises.map((e) => Card(
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('[${e.difficulty}] ${e.question}'),
                    const SizedBox(height: 4),
                    Text('答案：${e.answer}'),
                  ],
                ),
              ),
            )),
          ] else
            const Text('暂无解析结果'),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () async {
              await ref.read(questionRepositoryProvider).saveDraft(record);
              ref.read(currentQuestionProvider.notifier).state = null;
              if (context.mounted) {
                context.go('/notebook');
              }
            },
            child: const Text('保存到错题本'),
          ),
        ],
      ),
    );
  }
}
