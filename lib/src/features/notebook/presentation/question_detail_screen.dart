import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';

class QuestionDetailScreen extends ConsumerWidget {
  const QuestionDetailScreen({super.key, required this.record});

  final dynamic record;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = record is QuestionRecord
        ? record as QuestionRecord
        : ref.watch(currentQuestionProvider);

    if (current == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('错题详情')),
        body: const Center(child: Text('未找到该错题')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: Text('${current.subject.label} 错题详情')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('题目：${current.correctedText}', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 12),
          Text('掌握状态：${current.masteryLevel.name}'),
          Text('复习次数：${current.reviewCount}'),
          const SizedBox(height: 24),
          if (current.analysisResult != null) ...<Widget>[
            Text('答案：${current.analysisResult!.finalAnswer}'),
            const SizedBox(height: 8),
            Text('错因：${current.analysisResult!.mistakeReason}'),
          ],
          const SizedBox(height: 24),
          FilledButton(
            onPressed: () {
              ref.read(currentQuestionProvider.notifier).state = current;
              context.go('/analysis/result');
            },
            child: const Text('查看 AI 解析'),
          ),
        ],
      ),
    );
  }
}
