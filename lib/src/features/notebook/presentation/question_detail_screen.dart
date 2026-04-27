import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/features/review/presentation/review_controller.dart';
import 'package:smart_wrong_notebook/src/shared/widgets/math_content_view.dart';

class QuestionDetailScreen extends ConsumerWidget {
  const QuestionDetailScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(currentQuestionProvider);

    if (current == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('错题详情')),
        body: const Center(child: Text('未找到该错题')),
      );
    }

    final result = current.analysisResult;
    final masteryColor = _masteryColor(current.masteryLevel);
    final batchGroups = ref.watch(questionBatchGroupsProvider).valueOrNull;
    final batchGroup = batchGroups?[questionBatchRootId(current)];

    return Scaffold(
      appBar: AppBar(
        title: const Text('错题详情'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => context.go('/notebook'),
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(CupertinoIcons.pencil),
            onPressed: () => _editQuestion(context, ref, current),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'delete') _confirmDelete(context, ref, current);
            },
            itemBuilder: (_) => [
              const PopupMenuItem(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(CupertinoIcons.trash, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('删除', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          // 统一标签分类框：科目 | AI识别 | 状态 | 知识点
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // 第一行：科目 + AI识别 + 状态
                Row(
                  children: <Widget>[
                    _TagChip(
                      label: current.subject.label,
                      bgColor: const Color(0xFFEEF2FF),
                      textColor: const Color(0xFF4F46E5),
                    ),
                    if (result?.subject != null) ...<Widget>[
                      const SizedBox(width: 8),
                      const _TagChip(
                        label: 'AI识别',
                        bgColor: Color(0xFFF0FDF4),
                        textColor: Color(0xFF16A34A),
                      ),
                    ],
                    const SizedBox(width: 8),
                    _TagChip(
                      label: _masteryLabel(current.masteryLevel),
                      bgColor: masteryColor.withValues(alpha: 0.1),
                      textColor: masteryColor,
                    ),
                    if (_batchLabel(current) != null) ...<Widget>[
                      const SizedBox(width: 8),
                      _TagChip(
                        label: _batchLabel(current)!,
                        bgColor: const Color(0xFFF8FAFC),
                        textColor: const Color(0xFF64748B),
                      ),
                    ],
                  ],
                ),
                // AI 短标签（橙色）
                if (current.aiTags.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 10),
                  Text('AI标签',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: current.aiTags
                        .map((tag) => _TagChip(
                              label: tag,
                              bgColor: const Color(0xFFFFF7ED),
                              textColor: const Color(0xFFD97706),
                            ))
                        .toList(),
                  ),
                ],
                // AI 知识点（橙色，详细）
                if (current.aiKnowledgePoints.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text('知识点',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: current.aiKnowledgePoints
                        .map((kp) => _TagChip(
                              label: kp,
                              bgColor: const Color(0xFFFFF7ED),
                              textColor: const Color(0xFFD97706),
                            ))
                        .toList(),
                  ),
                ],
                // 自定义标签（蓝色）
                if (current.customTags.isNotEmpty) ...<Widget>[
                  const SizedBox(height: 8),
                  Text('自定义标签',
                      style:
                          TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  const SizedBox(height: 4),
                  Wrap(
                    spacing: 6,
                    runSpacing: 4,
                    children: current.customTags
                        .map((t) => _TagChip(
                              label: t,
                              bgColor: const Color(0xFFEEF2FF),
                              textColor: const Color(0xFF4F46E5),
                            ))
                        .toList(),
                  ),
                ],
                // 添加标签按钮
                const SizedBox(height: 8),
                GestureDetector(
                  onTap: () => _showAddTagDialog(context, ref, current),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                          color: Colors.grey.shade300,
                          style: BorderStyle.solid),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        Icon(CupertinoIcons.plus,
                            size: 14, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Text('添加标签',
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (batchGroup != null) ...<Widget>[
            const SizedBox(height: 12),
            _BatchSiblingCard(
              current: current,
              group: batchGroup,
              onSelect: (question) {
                ref.read(currentQuestionProvider.notifier).state = question;
                context.go('/notebook/question/${question.id}');
              },
            ),
          ],
          const SizedBox(height: 12),
          MathContentView(
            current.correctedText,
            contentFormat: current.contentFormat,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          if (result == null) ...<Widget>[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: <Widget>[
                  Icon(CupertinoIcons.sparkles,
                      size: 40, color: Colors.grey.shade300),
                  const SizedBox(height: 12),
                  const Text('暂无 AI 解析结果', style: TextStyle(fontSize: 15)),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: () {
                      ref.read(currentQuestionProvider.notifier).state =
                          current;
                      context.go('/capture/correction');
                    },
                    icon: const Icon(CupertinoIcons.camera),
                    label: const Text('去添加'),
                  ),
                ],
              ),
            ),
          ],
          if (result != null) ...<Widget>[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      const Icon(CupertinoIcons.arrow_2_circlepath,
                          size: 18, color: Color(0xFF6366F1)),
                      const SizedBox(width: 8),
                      const Text('举一反三',
                          style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600)),
                      const Spacer(),
                      Text(
                        current.savedExercises.isEmpty
                            ? '暂无练习'
                            : '${current.savedExercises.where((e) => e.isCorrect != null).length}/${current.savedExercises.length} 已答',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    current.savedExercises.isEmpty
                        ? '这道错题还没有可继续的练习题。'
                        : '继续基于这道原题完成练习，已作答状态会保留。',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: current.savedExercises.isEmpty
                          ? null
                          : () {
                              ref.read(currentQuestionProvider.notifier).state =
                                  current;
                              context.go('/exercise/practice');
                            },
                      icon: const Icon(CupertinoIcons.play_fill),
                      label: Text(
                          current.savedExercises.isEmpty ? '暂无可练习内容' : '继续练习'),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            // 原题（包含图片和文本）
            _InfoCard(
              icon: CupertinoIcons.doc_text,
              iconColor: const Color(0xFF6366F1),
              bg: const Color(0xFFEEF2FF),
              border: const Color(0xFFC7D2FE),
              title: '原题',
              titleColor: const Color(0xFF4338CA),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // 图片预览
                  if (current.imagePath.isNotEmpty)
                    GestureDetector(
                      onTap: () => _showFullImage(context, current.imagePath),
                      child: Container(
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Stack(
                          children: <Widget>[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.file(
                                File(current.imagePath),
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.contain,
                                errorBuilder: (_, __, ___) => const Center(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      Icon(CupertinoIcons.photo,
                                          size: 30, color: Colors.grey),
                                      SizedBox(height: 4),
                                      Text('图片加载失败',
                                          style: TextStyle(
                                              color: Colors.grey,
                                              fontSize: 11)),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(CupertinoIcons.zoom_in,
                                        size: 12, color: Colors.white),
                                    SizedBox(width: 3),
                                    Text('查看原图',
                                        style: TextStyle(
                                            fontSize: 10, color: Colors.white)),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  if (current.imagePath.isNotEmpty) const SizedBox(height: 10),
                  MathContentView(
                    current.correctedText,
                    contentFormat: current.contentFormat,
                    style:
                        const TextStyle(fontSize: 14, color: Color(0xFF3730A3)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            // Answer
            _InfoCard(
              icon: CupertinoIcons.checkmark_circle,
              iconColor: const Color(0xFF16A34A),
              bg: const Color(0xFFF0FDF4),
              border: const Color(0xFFBBF7D0),
              title: '正确答案',
              titleColor: const Color(0xFF166534),
              child: MathContentView(
                result.finalAnswer,
                style: const TextStyle(fontSize: 14, color: Color(0xFF15803D)),
              ),
            ),
            const SizedBox(height: 10),
            // Mistake reason
            _InfoCard(
              icon: CupertinoIcons.exclamationmark_triangle,
              iconColor: const Color(0xFFEA580C),
              bg: const Color(0xFFFFF7ED),
              border: const Color(0xFFFED7AA),
              title: '错因分析',
              titleColor: const Color(0xFF9A3412),
              child: MathContentView(
                result.mistakeReason,
                style: const TextStyle(fontSize: 14, color: Color(0xFFC2410C)),
              ),
            ),
            const SizedBox(height: 10),
            // Study advice
            _InfoCard(
              icon: CupertinoIcons.lightbulb,
              iconColor: const Color(0xFFD97706),
              bg: const Color(0xFFFFFBEB),
              border: const Color(0xFFFDE68A),
              title: '学习建议',
              titleColor: const Color(0xFF92400E),
              child: MathContentView(
                result.studyAdvice,
                style: const TextStyle(fontSize: 14, color: Color(0xFFB45309)),
              ),
            ),
            // Knowledge points
            if (result.knowledgePoints.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              Text('知识点',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: result.knowledgePoints
                    .map((p) => Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFC7D2FE)),
                          ),
                          child: Text(p,
                              style: const TextStyle(
                                  fontSize: 12, color: Color(0xFF4F46E5))),
                        ))
                    .toList(),
              ),
            ],
            // Steps
            if (result.steps.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              Text('解题步骤',
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              ...result.steps.asMap().entries.map((e) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                              child: Text('${e.key + 1}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF4F46E5)))),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                            child: MathContentView(e.value,
                                style: const TextStyle(fontSize: 14))),
                      ],
                    ),
                  )),
            ],
            const SizedBox(height: 24),
            Row(
              children: <Widget>[
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _markResult(context, ref, current, false),
                    child: const Text('仍需复习'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () => _markResult(context, ref, current, true),
                    child: const Text('已掌握'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _masteryLabel(MasteryLevel level) {
    switch (level) {
      case MasteryLevel.newQuestion:
        return '未复习';
      case MasteryLevel.reviewing:
        return '复习中';
      case MasteryLevel.mastered:
        return '已掌握';
    }
  }

  Color _masteryColor(MasteryLevel level) {
    switch (level) {
      case MasteryLevel.newQuestion:
        return Colors.grey;
      case MasteryLevel.reviewing:
        return Colors.orange;
      case MasteryLevel.mastered:
        return Colors.green;
    }
  }

  String? _batchLabel(QuestionRecord question) {
    if (question.parentQuestionId == null && question.rootQuestionId == null) {
      return null;
    }
    final order = question.splitOrder;
    return order == null ? '拍照批次' : '拍照批次 · 第 $order 题';
  }

  void _editQuestion(
      BuildContext context, WidgetRef ref, QuestionRecord question) {
    final controller = TextEditingController(text: question.correctedText);
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('编辑题目'),
        content: TextFormField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              final updated = question.copyWith(
                  normalizedQuestionText: controller.text.trim());
              await ref.read(questionRepositoryProvider).update(updated);
              ref.read(currentQuestionProvider.notifier).state = updated;
              invalidateQuestionList(ref);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('保存'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
      BuildContext context, WidgetRef ref, QuestionRecord question) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认删除'),
        content: const Text('删除后无法恢复，确定要删除这道错题吗？'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () async {
              await ref.read(questionRepositoryProvider).delete(question.id);
              invalidateQuestionList(ref);
              if (ctx.mounted) Navigator.pop(ctx);
              if (context.mounted) context.go('/notebook');
            },
            child: const Text('删除', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showAddTagDialog(
      BuildContext context, WidgetRef ref, QuestionRecord question) {
    final controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('添加标签'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: '输入标签名称',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            Text('已有标签',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                ...question.aiTags
                    .map((tag) => _dialogTagChip(tag, Colors.orange)),
                ...question.aiKnowledgePoints
                    .map((kp) => _dialogTagChip(kp, Colors.orange)),
                ...question.customTags
                    .map((t) => _dialogTagChip(t, Colors.indigo)),
              ],
            ),
          ],
        ),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          FilledButton(
            onPressed: () async {
              final tag = controller.text.trim();
              if (tag.isEmpty) return;

              // 检查是否已存在（去重）
              final allTags = [
                ...question.aiTags,
                ...question.aiKnowledgePoints,
                ...question.customTags
              ];
              if (allTags.contains(tag)) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('标签已存在')),
                );
                return;
              }

              final newTags = [...question.customTags, tag];
              final updated = question.copyWith(customTags: newTags);
              await ref.read(questionRepositoryProvider).update(updated);
              ref.read(currentQuestionProvider.notifier).state = updated;
              invalidateQuestionList(ref);
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: const Text('添加'),
          ),
        ],
      ),
    );
  }

  Widget _dialogTagChip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(label, style: TextStyle(fontSize: 11, color: color)),
    );
  }

  void _showFullImage(BuildContext context, String imagePath) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            title: const Text('原图'),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.file(File(imagePath)),
            ),
          ),
        ),
      ),
    );
  }

  void _markResult(BuildContext context, WidgetRef ref, QuestionRecord question,
      bool mastered) async {
    final controller = ReviewController(
      repository: ref.read(questionRepositoryProvider),
      logRepository: ref.read(reviewLogRepositoryProvider),
    );
    final updated = mastered
        ? await controller.markMastered(question.id)
        : await controller.markReviewing(question.id);
    invalidateQuestionList(ref);
    ref.read(currentQuestionProvider.notifier).state = updated;
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mastered ? '已标记为已掌握' : '已标记为复习中')),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.iconColor,
    required this.bg,
    required this.border,
    required this.title,
    required this.titleColor,
    this.child,
  });

  final IconData icon;
  final Color iconColor;
  final Color bg;
  final Color border;
  final String title;
  final Color titleColor;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 18, color: iconColor),
              const SizedBox(width: 8),
              Text(title,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: titleColor)),
            ],
          ),
          const SizedBox(height: 10),
          if (child != null) child! else const SizedBox.shrink(),
        ],
      ),
    );
  }
}

class _BatchSiblingCard extends StatelessWidget {
  const _BatchSiblingCard(
      {required this.current, required this.group, required this.onSelect});

  final QuestionRecord current;
  final QuestionBatchGroup group;
  final void Function(QuestionRecord question) onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(CupertinoIcons.square_grid_2x2,
                  size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text('同批题目',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.grey.shade700)),
              const SizedBox(width: 6),
              Text('${group.questions.length} 题',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: group.questions.map((question) {
              final selected = question.id == current.id;
              return GestureDetector(
                onTap: selected ? null : () => onSelect(question),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: selected ? const Color(0xFF6366F1) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: selected
                            ? const Color(0xFF6366F1)
                            : const Color(0xFFE2E8F0)),
                  ),
                  child: Text(
                    _siblingLabel(question),
                    style: TextStyle(
                        fontSize: 12,
                        color: selected ? Colors.white : Colors.grey.shade700,
                        fontWeight: FontWeight.w500),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _siblingLabel(QuestionRecord question) {
    final order = question.splitOrder;
    return order == null ? '同批题' : '第 $order 题';
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip(
      {required this.label, required this.bgColor, required this.textColor});

  final String label;
  final Color bgColor;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, color: textColor, fontWeight: FontWeight.w500)),
    );
  }
}
