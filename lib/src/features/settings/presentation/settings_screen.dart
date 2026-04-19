import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: <Widget>[
          Text('外观', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('深色模式', style: TextStyle(fontWeight: FontWeight.w500)),
                  const SizedBox(height: 8),
                  SegmentedButton<ThemeMode>(
                    segments: const [
                      ButtonSegment(value: ThemeMode.system, label: Text('系统')),
                      ButtonSegment(value: ThemeMode.light, label: Text('浅色')),
                      ButtonSegment(value: ThemeMode.dark, label: Text('深色')),
                    ],
                    selected: {themeMode},
                    onSelectionChanged: (set) {
                      ref.read(themeModeProvider.notifier).setMode(set.first);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('提醒', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: ListTile(
              leading: const Icon(Icons.notifications_outlined),
              title: const Text('复习提醒'),
              subtitle: const Text('发送待复习错题通知'),
              trailing: IconButton(
                icon: const Icon(Icons.send_outlined),
                onPressed: () async {
                  final svc = ref.read(notificationServiceProvider);
                  await svc.checkAndNotify();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已发送复习提醒')),
                    );
                  }
                },
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('AI 服务', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.smart_toy_outlined),
                  title: const Text('AI 服务商配置'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/settings/provider'),
                ),
                ListTile(
                  leading: const Icon(Icons.edit_note_outlined),
                  title: const Text('提示词设置'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/settings/prompts'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text('内容', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Card(
            child: Column(
              children: <Widget>[
                ListTile(
                  leading: const Icon(Icons.category_outlined),
                  title: const Text('科目管理'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/settings/subjects'),
                ),
                ListTile(
                  leading: const Icon(Icons.storage_outlined),
                  title: const Text('数据管理'),
                  subtitle: const Text('导入 / 导出 / 清空'),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => context.go('/settings/data'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
