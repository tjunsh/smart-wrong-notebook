import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: <Widget>[
          // Appearance
          Text('外观',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Row(
            children: <Widget>[
              _ThemeButton(
                  label: '系统',
                  icon: CupertinoIcons.device_phone_portrait,
                  isSelected: themeMode == ThemeMode.system,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setMode(ThemeMode.system)),
              const SizedBox(width: 8),
              _ThemeButton(
                  label: '浅色',
                  icon: CupertinoIcons.sun_max,
                  isSelected: themeMode == ThemeMode.light,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setMode(ThemeMode.light)),
              const SizedBox(width: 8),
              _ThemeButton(
                  label: '深色',
                  icon: CupertinoIcons.moon,
                  isSelected: themeMode == ThemeMode.dark,
                  onTap: () => ref
                      .read(themeModeProvider.notifier)
                      .setMode(ThemeMode.dark)),
            ],
          ),
          const SizedBox(height: 24),
          // Notifications
          Text('提醒',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _SettingsSection(
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: const _SettingsIcon(
                icon: CupertinoIcons.bell,
                iconColor: Color(0xFFF97316),
                lightBg: Color(0xFFFFF7ED),
              ),
              title: Text('复习提醒',
                  style: TextStyle(fontSize: 14, color: colorScheme.onSurface)),
              subtitle: Text('发送待复习错题通知',
                  style: TextStyle(
                      fontSize: 12, color: colorScheme.onSurfaceVariant)),
              trailing: FilledButton.tonal(
                onPressed: () async {
                  final svc = ref.read(notificationServiceProvider);
                  await svc.checkAndNotify();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('已发送复习提醒')),
                    );
                  }
                },
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(0, 32),
                ),
                child: const Text('发送', style: TextStyle(fontSize: 12)),
              ),
            ),
          ),
          const SizedBox(height: 24),
          // AI Service
          Text('AI 服务',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _SettingsSection(
            child: Column(
              children: <Widget>[
                _SettingsListItem(
                  icon: CupertinoIcons.sparkles,
                  iconColor: const Color(0xFF6366F1),
                  lightIconBg: const Color(0xFFEEF2FF),
                  title: 'AI 服务商配置',
                  onTap: () => context.go('/settings/provider'),
                ),
                Divider(
                    height: 1, indent: 56, color: colorScheme.outlineVariant),
                _SettingsListItem(
                  icon: CupertinoIcons.pencil,
                  iconColor: const Color(0xFFD97706),
                  lightIconBg: const Color(0xFFFFFBEB),
                  title: '提示词设置',
                  onTap: () => context.go('/settings/prompts'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          // Content
          Text('内容',
              style: theme.textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _SettingsSection(
            child: Column(
              children: <Widget>[
                _SettingsListItem(
                  icon: CupertinoIcons.folder,
                  iconColor: const Color(0xFF16A34A),
                  lightIconBg: const Color(0xFFF0FDF4),
                  title: '科目管理',
                  onTap: () => context.go('/settings/subjects'),
                ),
                Divider(
                    height: 1, indent: 56, color: colorScheme.outlineVariant),
                _SettingsListItem(
                  icon: CupertinoIcons.tray,
                  iconColor: const Color(0xFFEA580C),
                  lightIconBg: const Color(0xFFFFF7ED),
                  title: '数据管理',
                  subtitle: '导入 / 导出 / 清空',
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

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: child,
    );
  }
}

class _SettingsIcon extends StatelessWidget {
  const _SettingsIcon({
    required this.icon,
    required this.iconColor,
    required this.lightBg,
  });

  final IconData icon;
  final Color iconColor;
  final Color lightBg;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: isDark ? iconColor.withValues(alpha: 0.16) : lightBg,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Icon(icon, size: 18, color: iconColor),
    );
  }
}

class _SettingsListItem extends StatelessWidget {
  const _SettingsListItem({
    required this.icon,
    required this.iconColor,
    required this.lightIconBg,
    required this.title,
    this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color lightIconBg;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: <Widget>[
            _SettingsIcon(
              icon: icon,
              iconColor: iconColor,
              lightBg: lightIconBg,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(title,
                      style: TextStyle(
                          fontSize: 14, color: colorScheme.onSurface)),
                  if (subtitle != null) ...<Widget>[
                    const SizedBox(height: 2),
                    Text(subtitle!,
                        style: TextStyle(
                            fontSize: 12, color: colorScheme.onSurfaceVariant)),
                  ],
                ],
              ),
            ),
            Icon(CupertinoIcons.chevron_right,
                size: 22,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5)),
          ],
        ),
      ),
    );
  }
}

class _ThemeButton extends StatelessWidget {
  const _ThemeButton(
      {required this.label,
      required this.icon,
      required this.isSelected,
      required this.onTap});

  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected
                ? colorScheme.primary
                : colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
                color: isSelected
                    ? colorScheme.primary
                    : colorScheme.outlineVariant),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Icon(icon,
                  size: 20,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant),
              const SizedBox(height: 4),
              Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      color: isSelected
                          ? colorScheme.onPrimary
                          : colorScheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}
