import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';

class NotebookScreen extends ConsumerWidget {
  const NotebookScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final questionsAsync = ref.watch(questionListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('错题本'),
        actions: <Widget>[
          IconButton(onPressed: () {}, icon: const Icon(Icons.filter_list)),
          IconButton(onPressed: () {}, icon: const Icon(Icons.search)),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.go('/capture/correction'),
        child: const Icon(Icons.add),
      ),
      body: questionsAsync.when(
        data: (questions) => questions.isEmpty
            ? const Center(child: Text('暂无错题，点击 + 添加'))
            : ListView.builder(
                padding: const EdgeInsets.all(8),
                itemCount: questions.length,
                itemBuilder: (context, index) {
                  final q = questions[index];
                  return Card(
                    child: ListTile(
                      title: Text(
                        q.correctedText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      subtitle: Text('${q.subject.label} · ${q.masteryLevel.name}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        ref.read(currentQuestionProvider.notifier).state = q;
                        context.go('/notebook/question/${q.id}');
                      },
                    ),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }
}
