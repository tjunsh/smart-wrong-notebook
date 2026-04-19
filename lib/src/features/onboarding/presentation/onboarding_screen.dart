import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  int _page = 0;

  final _pages = const [
    _OnboardingPage(
      icon: Icons.camera_alt_outlined,
      title: '拍照录题',
      desc: '对准错题拍照，AI 自动识别文字并校正',
    ),
    _OnboardingPage(
      icon: Icons.auto_awesome_outlined,
      title: 'AI 智能分析',
      desc: 'DeepSeek 分析错因，生成举一反三练习题',
    ),
    _OnboardingPage(
      icon: Icons.school_outlined,
      title: '随时复习',
      desc: '根据记忆曲线安排复习，巩固知识点',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final lastPage = _page == _pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Align(
              alignment: Alignment.topRight,
              child: TextButton(
                onPressed: _finish,
                child: const Text('跳过'),
              ),
            ),
            Expanded(
              child: PageView.builder(
                onPageChanged: (i) => setState(() => _page = i),
                itemCount: _pages.length,
                itemBuilder: (_, i) => _pages[i],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pages.length, (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    _page == i ? Icons.circle : Icons.circle_outlined,
                    size: 8,
                    color: _page == i ? Theme.of(context).colorScheme.primary : Colors.grey,
                  ),
                )),
              ),
            ),
            FilledButton(
              onPressed: lastPage ? _finish : () {
                setState(() => _page++);
              },
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: Text(lastPage ? '开始使用' : '下一步'),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Future<void> _finish() async {
    await ref.read(settingsRepositoryProvider).setString('onboarding_done', 'true');
    if (mounted) context.go('/');
  }
}

class _OnboardingPage extends StatelessWidget {
  const _OnboardingPage({required this.icon, required this.title, required this.desc});

  final IconData icon;
  final String title;
  final String desc;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, size: 96, color: Theme.of(context).colorScheme.primary),
          const SizedBox(height: 32),
          Text(title, style: Theme.of(context).textTheme.headlineMedium),
          const SizedBox(height: 16),
          Text(desc, style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey)),
          const SizedBox(height: 48),
        ],
      ),
    );
  }
}
