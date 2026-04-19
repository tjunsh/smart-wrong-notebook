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
          ListTile(
            leading: const Icon(Icons.dark_mode_outlined),
            title: const Text('深色模式'),
            trailing: DropdownButton<ThemeMode>(
              value: themeMode,
              underline: const SizedBox(),
              onChanged: (mode) {
                if (mode != null) {
                  ref.read(themeModeProvider.notifier).setMode(mode);
                }
              },
              items: const [
                DropdownMenuItem(value: ThemeMode.system, child: Text('跟随系统')),
                DropdownMenuItem(value: ThemeMode.light, child: Text('浅色')),
                DropdownMenuItem(value: ThemeMode.dark, child: Text('深色')),
              ],
            ),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.notifications_outlined),
            title: const Text('复习提醒'),
            subtitle: const Text('检查待复习错题数量'),
            trailing: IconButton(
              icon: const Icon(Icons.notifications_active_outlined),
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
          const Divider(),
          ListTile(
            leading: const Icon(Icons.smart_toy_outlined),
            title: const Text('AI 服务商配置'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/provider'),
          ),
          ListTile(
            leading: const Icon(Icons.category_outlined),
            title: const Text('科目管理'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/subjects'),
          ),
          ListTile(
            leading: const Icon(Icons.edit_note_outlined),
            title: const Text('提示词设置'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/prompts'),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.storage_outlined),
            title: const Text('数据管理'),
            subtitle: const Text('导入/导出/清空'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.go('/settings/data'),
          ),
        ],
      ),
    );
  }
}
