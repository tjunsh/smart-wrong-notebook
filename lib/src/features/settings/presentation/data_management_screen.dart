import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';

class DataManagementScreen extends ConsumerWidget {
  const DataManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('数据管理')),
      body: questionsAsync.when(
        data: (questions) => ListView(
          padding: const EdgeInsets.all(16),
          children: <Widget>[
            Card(
              child: ListTile(
                leading: const Icon(Icons.storage_outlined),
                title: const Text('题库总量'),
                trailing: Text('${questions.length} 题', style: Theme.of(context).textTheme.titleMedium),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              child: ListTile(
                leading: const Icon(Icons.download_outlined),
                title: const Text('导出当前题库'),
                subtitle: const Text('导出所有错题为 JSON 文件'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('导出功能开发中')),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            Card(
              child: ListTile(
                leading: const Icon(Icons.delete_outline, color: Colors.red),
                title: const Text('清空所有数据', style: TextStyle(color: Colors.red)),
                subtitle: const Text('删除所有错题记录，不可恢复'),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => _confirmClearAll(context, ref, questions.length),
              ),
            ),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
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
        content: Text('确定要删除全部 $count 道错题吗？此操作不可恢复。'),
        actions: <Widget>[
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('取消')),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('清空功能开发中')),
              );
            },
            child: const Text('清空', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
