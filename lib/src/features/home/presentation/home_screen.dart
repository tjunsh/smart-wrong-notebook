import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/features/capture/presentation/capture_entry_sheet.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionListProvider);
    final dueAsync = ref.watch(dueReviewProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: <Widget>[
        Text('开始拍错题', style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            builder: (_) => const CaptureEntrySheet(),
          ),
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('拍照录题'),
        ),
        const SizedBox(height: 24),
        Text('学习统计', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 12),
        questionsAsync.when(
          data: (questions) => _buildStatsGrid(context, questions, dueAsync),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('加载失败: $e'),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Text('最近新增', style: Theme.of(context).textTheme.titleLarge),
            TextButton(
              onPressed: () => context.go('/notebook'),
              child: const Text('查看全部'),
            ),
          ],
        ),
        const SizedBox(height: 8),
        questionsAsync.when(
          data: (questions) => _buildRecentList(context, ref, questions),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Text('加载失败: $e'),
        ),
      ],
    );
  }

  Widget _buildStatsGrid(BuildContext context, List<QuestionRecord> questions, AsyncValue<List<QuestionRecord>> dueAsync) {
    final total = questions.length;
    final mastered = questions.where((q) => q.masteryLevel == MasteryLevel.mastered).length;
    final reviewing = questions.where((q) => q.masteryLevel == MasteryLevel.reviewing).length;
    final newQ = questions.where((q) => q.masteryLevel == MasteryLevel.newQuestion).length;
    final due = dueAsync.valueOrNull?.length ?? 0;

    return Column(
      children: <Widget>[
        Row(
          children: <Widget>[
            Expanded(child: _StatCard(label: '题库总量', value: '$total', color: Colors.blue)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: '待复习', value: '$due', color: Colors.orange)),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(child: _StatCard(label: '已掌握', value: '$mastered', color: Colors.green)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: '复习中', value: '$reviewing', color: Colors.amber)),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: '新增', value: '$newQ', color: Colors.grey)),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentList(BuildContext context, WidgetRef ref, List<QuestionRecord> questions) {
    if (questions.isEmpty) {
      return const Text('暂无错题，拍照开始添加', style: TextStyle(color: Colors.grey));
    }
    return Column(
      children: questions.take(5).map((q) {
        return Card(
          child: ListTile(
            title: Text(q.correctedText, maxLines: 1, overflow: TextOverflow.ellipsis),
            subtitle: Text(q.subject.label),
            trailing: IconButton(
              icon: const Icon(Icons.chevron_right),
              onPressed: () {
                ref.read(currentQuestionProvider.notifier).state = q;
                context.go('/notebook/question/${q.id}');
              },
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.color});

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: <Widget>[
            Text(value, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 12, color: color)),
          ],
        ),
      ),
    );
  }
}
