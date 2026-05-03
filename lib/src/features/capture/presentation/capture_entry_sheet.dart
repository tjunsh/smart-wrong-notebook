import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';

class CaptureEntrySheet extends ConsumerStatefulWidget {
  const CaptureEntrySheet({super.key});

  @override
  ConsumerState<CaptureEntrySheet> createState() => _CaptureEntrySheetState();
}

class _CaptureEntrySheetState extends ConsumerState<CaptureEntrySheet> {
  bool _isLoading = false;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    const orange = Color(0xFFEA580C);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '添加错题',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              Container(
                padding: const EdgeInsets.all(40),
                child: Column(
                  children: <Widget>[
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    Text('正在打开相机...',
                        style: TextStyle(color: colorScheme.onSurfaceVariant)),
                  ],
                ),
              )
            else ...<Widget>[
              _EntryOption(
                icon: CupertinoIcons.camera,
                iconColor: const Color(0xFF6366F1),
                iconBg: isDark
                    ? const Color(0xFF6366F1).withValues(alpha: 0.16)
                    : const Color(0xFFEEF2FF),
                label: '拍照',
                description: '使用相机拍摄错题',
                onTap: () => _pickAndNavigate(fromCamera: true),
              ),
              const SizedBox(height: 10),
              _EntryOption(
                icon: CupertinoIcons.photo,
                iconColor: const Color(0xFFD97706),
                iconBg: isDark
                    ? const Color(0xFFD97706).withValues(alpha: 0.16)
                    : const Color(0xFFFFFBEB),
                label: '相册',
                description: '从相册选择图片',
                onTap: () => _pickAndNavigate(fromCamera: false),
              ),
            ],
            if (_errorMessage != null) ...<Widget>[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isDark
                      ? orange.withValues(alpha: 0.14)
                      : const Color(0xFFFFF7ED),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                      color: isDark
                          ? orange.withValues(alpha: 0.35)
                          : const Color(0xFFFED7AA)),
                ),
                child: Row(
                  children: <Widget>[
                    const Icon(CupertinoIcons.exclamationmark_triangle,
                        size: 18, color: orange),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(_errorMessage!,
                          style: TextStyle(
                              fontSize: 12,
                              color:
                                  isDark ? orange : const Color(0xFF9A3412))),
                    ),
                    IconButton(
                      icon: const Icon(CupertinoIcons.xmark, size: 16),
                      onPressed: () => setState(() => _errorMessage = null),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndNavigate({required bool fromCamera}) async {
    final router = GoRouter.of(context);

    // 先检查 AI 是否已配置
    final config =
        await ref.read(settingsRepositoryProvider).getAiProviderConfig();
    if (config == null ||
        config.baseUrl.isEmpty ||
        config.apiKey.isEmpty ||
        config.model.isEmpty) {
      setState(() => _isLoading = false);
      setState(() => _errorMessage = '请先在设置中配置 AI 服务');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final capture = ref.read(captureServiceProvider);
      final result = fromCamera
          ? await capture.pickFromCamera()
          : await capture.pickFromGallery();

      if (!mounted) return;

      setState(() => _isLoading = false);

      if (result.isCancelled) {
        // User cancelled - just close the sheet silently
        Navigator.pop(context);
        return;
      }

      if (result.errorMessage != null) {
        // Show error message
        String message;
        if (result.errorMessage!.contains('permission')) {
          message = '相机权限被拒绝，请在系统设置中开启';
        } else {
          message = '打开失败: ${result.errorMessage}';
        }
        setState(() => _errorMessage = message);
        return;
      }

      if (result.record != null) {
        Navigator.pop(context);
        ref.read(currentQuestionProvider.notifier).state = result.record;
        debugPrint('[CaptureEntrySheet] Navigating to /capture/crop');
        router.go('/capture/crop');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '操作失败: $e';
      });
    }
  }
}

class _EntryOption extends StatelessWidget {
  const _EntryOption({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.description,
    required this.onTap,
  });

  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final String description;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorScheme.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, size: 22, color: iconColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(label,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface)),
                  const SizedBox(height: 2),
                  Text(description,
                      style: TextStyle(
                          fontSize: 12, color: colorScheme.onSurfaceVariant)),
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
