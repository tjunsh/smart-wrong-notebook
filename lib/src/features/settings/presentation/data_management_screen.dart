import 'dart:convert';
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';

class DataManagementScreen extends ConsumerWidget {
  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionListProvider);
    final reviewLogsAsync = ref.watch(reviewLogListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('数据管理'),
        leading: IconButton(
            icon: const Icon(CupertinoIcons.chevron_left),
            onPressed: () => Navigator.of(context).pop()),
      ),
      body: questionsAsync.when(
        data: (questions) => ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            _DataCard(
              icon: CupertinoIcons.tray,
              title: '题库总量',
              trailing: '${questions.length} 题',
            ),
            const SizedBox(height: 8),
            _DataCard(
              icon: CupertinoIcons.clock,
              title: '复习记录总量',
              trailingWidget: reviewLogsAsync.when(
                data: (logs) =>
                    Text('${logs.length} 条', style: _trailingStyle(context)),
                loading: () => const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)),
                error: (_, __) => Text('加载失败', style: _subtitleStyle(context)),
              ),
            ),
            const SizedBox(height: 16),
            _DataCard(
              icon: CupertinoIcons.arrow_up,
              title: '导入错题',
              subtitle: '从 JSON 文件导入错题记录',
              onTap: () => _importQuestions(context, ref),
            ),
            const SizedBox(height: 8),
            _DataCard(
              icon: CupertinoIcons.arrow_down,
              title: '导出当前题库',
              subtitle: '导出所有错题为 JSON 文件，可分享',
              onTap: questions.isEmpty
                  ? null
                  : () => _exportQuestions(context, questions),
            ),
            const SizedBox(height: 8),
            _DataCard(
              icon: CupertinoIcons.trash,
              iconColor: Colors.red,
              title: '清空所有数据',
              titleColor: Colors.red,
              subtitle: '删除所有错题和复习记录，不可恢复',
              onTap: () => _confirmClearAll(context, ref, questions.length),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Future<void> _exportQuestions(
      BuildContext context, List<QuestionRecord> questions) async {
    try {
      final dir = await getApplicationDocumentsDirectory();
      final exportDir = Directory('${dir.path}/exports');
      if (!exportDir.existsSync()) {
        await exportDir.create(recursive: true);
      }

      final now = DateTime.now();
      final ms = now.millisecond;
      final filename = 'wrong_notebook_$ms.json';
      final file = File('${exportDir.path}/$filename');

      final list = questions.map(_questionToJson).toList();
      file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(list));

      if (!context.mounted) return;
      await Share.shareXFiles([XFile(file.path)],
          text: '导出 ${questions.length} 道错题');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导出失败: $e')),
        );
      }
    }
  }

  Map<String, dynamic> _questionToJson(QuestionRecord q) => q.toJson();

  Future<void> _importQuestions(BuildContext context, WidgetRef ref) async {
    try {
      final result = await FilePicker.platform
          .pickFiles(type: FileType.custom, allowedExtensions: ['json']);
      if (result == null || result.files.isEmpty) return;

      final file = File(result.files.first.path!);
      final content = await file.readAsString();
      final list = jsonDecode(content) as List;
      final repo = ref.read(questionRepositoryProvider);
      int imported = 0;

      for (final item in list) {
        final map = item as Map<String, dynamic>;
        final record = _jsonToQuestion(map);
        if (record != null) {
          await repo.saveDraft(record);
          imported++;
        }
      }

      invalidateQuestionList(ref);

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('成功导入 $imported 道错题')),
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('导入失败: $e')),
        );
      }
    }
  }

  QuestionRecord? _jsonToQuestion(Map<String, dynamic> map) {
    try {
      return QuestionRecord.fromJson(map);
    } catch (_) {
      return null;
    }
  }

  void _confirmClearAll(BuildContext context, WidgetRef ref, int count) {
    if (count == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('题库为空，无需清空')),
      );
      return;
    }
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认清空'),
        content: Text('确定要删除全部 $count 道错题及其复习记录吗？此操作不可恢复。'),
        actions: <Widget>[
          TextButton(
              onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _clearAllData(ref, context);
            },
            child: const Text('清空', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _clearAllData(WidgetRef ref, BuildContext context) async {
    final repo = ref.read(questionRepositoryProvider);
    final all = await repo.listAll();
    for (final q in all) {
      await repo.delete(q.id);
    }
    await ref.read(reviewLogRepositoryProvider).clear();
    invalidateQuestionList(ref);
    ref.read(currentQuestionProvider.notifier).state = null;

    try {
      for (final q in all) {
        final file = File(q.imagePath);
        if (await file.exists()) await file.delete();
      }
    } catch (_) {}

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('已清空 ${all.length} 道错题')),
      );
    }
  }
}

class _DataCard extends StatelessWidget {
  const _DataCard({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.trailingWidget,
    this.iconColor,
    this.titleColor,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? trailing;
  final Widget? trailingWidget;
  final Color? iconColor;
  final Color? titleColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final effectiveIconColor = iconColor ?? colorScheme.onSurfaceVariant;

    return Material(
      color: colorScheme.surface,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: colorScheme.outlineVariant),
          ),
          child: Row(
            children: <Widget>[
              Icon(icon, size: 24, color: effectiveIconColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(title, style: _titleStyle(context, color: titleColor)),
                    if (subtitle != null) ...<Widget>[
                      const SizedBox(height: 4),
                      Text(subtitle!, style: _subtitleStyle(context)),
                    ],
                  ],
                ),
              ),
              if (trailingWidget != null)
                trailingWidget!
              else if (trailing != null)
                Text(trailing!, style: _trailingStyle(context))
              else if (onTap != null)
                Icon(
                  CupertinoIcons.chevron_right,
                  size: 22,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

TextStyle _titleStyle(BuildContext context, {Color? color}) {
  final colorScheme = Theme.of(context).colorScheme;
  return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: color ?? colorScheme.onSurface);
}

TextStyle _subtitleStyle(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return TextStyle(
      fontSize: 12, color: colorScheme.onSurfaceVariant, height: 1.35);
}

TextStyle _trailingStyle(BuildContext context) {
  final colorScheme = Theme.of(context).colorScheme;
  return TextStyle(
      fontSize: 16, fontWeight: FontWeight.w600, color: colorScheme.onSurface);
}
