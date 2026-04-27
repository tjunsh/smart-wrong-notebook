import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';

class OcrConfirmationScreen extends ConsumerStatefulWidget {
  const OcrConfirmationScreen({super.key});

  @override
  ConsumerState<OcrConfirmationScreen> createState() => _OcrConfirmationScreenState();
}

class _OcrConfirmationScreenState extends ConsumerState<OcrConfirmationScreen> {
  late final TextEditingController _textController;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(currentQuestionProvider);
    final hasImage = current?.imagePath != null && File(current!.imagePath).existsSync();

    if (current == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('保存确认')),
        body: const Center(child: Text('未找到题目记录')),
      );
    }

    final initialText = current.normalizedQuestionText.isNotEmpty
        ? current.normalizedQuestionText
        : current.extractedQuestionText;
    if (_textController.text != initialText) {
      _textController.value = TextEditingValue(
        text: initialText,
        selection: TextSelection.collapsed(offset: initialText.length),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('保存确认'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => context.go('/analysis/result'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (hasImage)
                GestureDetector(
                  onTap: () => _showFullImage(context, current.imagePath),
                  child: Container(
                    width: double.infinity,
                    constraints: const BoxConstraints(maxHeight: 220),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.file(
                        File(current.imagePath),
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: double.infinity,
                  height: 160,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(child: Text('暂无图片', style: TextStyle(color: Colors.grey))),
                ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const Icon(CupertinoIcons.book, size: 14, color: Color(0xFF4F46E5)),
                          const SizedBox(width: 4),
                          Text(
                            current.subject.label,
                            style: const TextStyle(fontSize: 13, color: Color(0xFF4F46E5), fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Text('保存前可编辑', style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                '确认题目内容',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                '保存到错题本前，确认结构化题目文本，方便后续检索、分类与继续练习。',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _textController,
                maxLines: 10,
                minLines: 8,
                onChanged: (_) {
                  if (_errorMessage != null) {
                    setState(() => _errorMessage = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: '如果识别结果为空，可以手动补充题目内容',
                  errorText: _errorMessage,
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.grey.shade300),
                  ),
                ),
              ),
              if (_errorMessage != null) ...<Widget>[
                const SizedBox(height: 10),
                Text(
                  _errorMessage!,
                  style: const TextStyle(fontSize: 12, color: Color(0xFFB91C1C)),
                ),
              ],
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () => context.go('/analysis/result'),
                icon: const Icon(CupertinoIcons.chevron_left, size: 18),
                label: const Text('返回结果页'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
              const SizedBox(height: 12),
              FilledButton.icon(
                onPressed: () async {
                  final text = _textController.text.trim();
                  if (text.isEmpty) {
                    setState(() => _errorMessage = '请先补充题目内容，再保存到错题本');
                    return;
                  }

                  final updated = current.copyWith(
                    extractedQuestionText: current.extractedQuestionText.isNotEmpty
                        ? current.extractedQuestionText
                        : text,
                    normalizedQuestionText: text,
                  );
                  ref.read(currentQuestionProvider.notifier).state = updated;
                  final messenger = ScaffoldMessenger.of(context);
                  final router = GoRouter.of(context);
                  await ref.read(questionRepositoryProvider).saveDraft(updated);
                  invalidateQuestionList(ref);
                  ref.read(currentQuestionProvider.notifier).state = null;
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(
                      content: Text('已保存到错题本'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                  router.go('/notebook');
                },
                icon: const Icon(CupertinoIcons.checkmark_alt, size: 18),
                label: const Text('确认并保存到错题本'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                ),
              ),
            ],
          ),
        ),
      ),
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
}
