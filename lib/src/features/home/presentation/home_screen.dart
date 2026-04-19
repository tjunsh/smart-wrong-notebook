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
      padding: const EdgeInsets.all(24),
      children: <Widget>[
        Text(
          '开始拍错题',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        FilledButton.icon(
          onPressed: () => showModalBottomSheet<void>(
            context: context,
            builder: (_) => const CaptureEntrySheet(),
          ),
          icon: const Icon(Icons.camera_alt_outlined),
          label: const Text('拍照录题'),
          style: FilledButton.styleFrom(minimumSize: const Size(double.infinity, 52)),
        ),
        const SizedBox(height: 20),
        dueAsync.when(
          data: (due) => due.isNotEmpty
              ? _ReviewBanner(count: due.length, onTap: () => context.go('/review'))
              : const SizedBox.shrink(),
          loading: () => const SizedBox.shrink(),
          error: (_, __) => const SizedBox.shrink(),
        ),
        const SizedBox(height: 20),
        Text('学习统计', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
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
            Text('最近新增', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600)),
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
            Expanded(child: _StatCard(label: '题库总量', value: '$total', bg: const Color(0xFFEFF6FF), border: const Color(0xFFBFDBFE), text: const Color(0xFF2563EB))),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: '待复习', value: '$due', bg: const Color(0xFFFFF7ED), border: const Color(0xFFFED7AA), text: const Color(0xFFEA580C))),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(child: _StatCard(label: '已掌握', value: '$mastered', bg: const Color(0xFFF0FDF4), border: const Color(0xFFBBF7D0), text: const Color(0xFF16A34A))),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: '复习中', value: '$reviewing', bg: const Color(0xFFFEF3C7), border: const Color(0xFFFDE68A), text: const Color(0xFFD97706))),
            const SizedBox(width: 12),
            Expanded(child: _StatCard(label: '新增', value: '$newQ', bg: const Color(0xFFF9FAFB), border: const Color(0xFFE5E7EB), text: const Color(0xFF6B7280))),
          ],
        ),
      ],
    );
  }

  Widget _buildRecentList(BuildContext context, WidgetRef ref, List<QuestionRecord> questions) {
    if (questions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: <Widget>[
            Icon(Icons.quiz_outlined, size: 48, color: Colors.grey.shade300),
            const SizedBox(height: 12),
            const Text('暂无错题，拍照开始添加', style: TextStyle(color: Colors.grey)),
          ],
        ),
      );
    }
    return Column(
      children: questions.take(5).map((q) {
        final masteryColor = _masteryColor(q.masteryLevel);
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              leading: CircleAvatar(
                radius: 18,
                backgroundColor: masteryColor.withValues(alpha: 0.1),
                child: Icon(Icons.quiz_outlined, size: 16, color: masteryColor),
              ),
              title: Text(q.correctedText, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w500)),
              subtitle: Text(q.subject.label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              trailing: Icon(Icons.chevron_right, color: Colors.grey.shade300),
              onTap: () {
                ref.read(currentQuestionProvider.notifier).state = q;
                context.go('/notebook/question/${q.id}');
              },
            ),
          ),
        );
      }).toList(),
    );
  }

  Color _masteryColor(MasteryLevel level) {
    switch (level) {
      case MasteryLevel.newQuestion: return Colors.grey;
      case MasteryLevel.reviewing: return Colors.orange;
      case MasteryLevel.mastered: return Colors.green;
    }
  }
}

class _ReviewBanner extends StatelessWidget {
  const _ReviewBanner({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFED7AA)),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 44, height: 44,
              decoration: BoxDecoration(color: const Color(0xFFFFEDD5), borderRadius: BorderRadius.circular(22)),
              child: const Icon(Icons.refresh, color: Color(0xFFF97316), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('今日待复习', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF92400E))),
                  Text('$count 道错题等待巩固', style: TextStyle(fontSize: 12, color: Colors.orange.shade700)),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFFF97316), size: 22),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({required this.label, required this.value, required this.bg, required this.border, required this.text});

  final String label;
  final String value;
  final Color bg;
  final Color border;
  final Color text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: border),
      ),
      child: Column(
        children: <Widget>[
          Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: text)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(fontSize: 11, color: text)),
        ],
      ),
    );
  }
}
