import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/domain/models/mastery_level.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/features/capture/presentation/capture_entry_sheet.dart';

class NotebookScreen extends ConsumerStatefulWidget {
  const NotebookScreen({super.key});

  @override
  ConsumerState<NotebookScreen> createState() => _NotebookScreenState();
}

class _NotebookScreenState extends ConsumerState<NotebookScreen> {
  bool _showSearch = false;

  @override
  Widget build(BuildContext context) {
    final questionsAsync = ref.watch(filteredQuestionListProvider);
    final activeFilters = ref.watch(selectedSubjectFilterProvider) != null ||
        ref.watch(selectedMasteryFilterProvider) != null ||
        ref.watch(searchQueryProvider).isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: _showSearch ? _buildSearchField() : const Text('错题本'),
        actions: <Widget>[
          if (_showSearch)
            IconButton(
              onPressed: () {
                ref.read(searchQueryProvider.notifier).state = '';
                setState(() => _showSearch = false);
              },
              icon: const Icon(Icons.close),
            )
          else ...<Widget>[
            IconButton(
              onPressed: () => _showFilterSheet(context),
              icon: Icon(
                Icons.filter_list,
                color: activeFilters ? Theme.of(context).colorScheme.primary : null,
              ),
            ),
            IconButton(
              onPressed: () => setState(() => _showSearch = true),
              icon: const Icon(Icons.search),
            ),
          ],
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => showModalBottomSheet<void>(
          context: context,
          builder: (_) => const CaptureEntrySheet(),
        ),
        child: const Icon(Icons.add),
      ),
      body: questionsAsync.when(
        data: (questions) {
          if (activeFilters && questions.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const Icon(Icons.search_off, size: 48, color: Colors.grey),
                  const SizedBox(height: 12),
                  const Text('没有匹配的错题', style: TextStyle(color: Colors.grey)),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      ref.read(selectedSubjectFilterProvider.notifier).state = null;
                      ref.read(selectedMasteryFilterProvider.notifier).state = null;
                      ref.read(searchQueryProvider.notifier).state = '';
                    },
                    child: const Text('清除筛选'),
                  ),
                ],
              ),
            );
          }
          if (questions.isEmpty) {
            return const Center(child: Text('暂无错题，点击 + 添加'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: questions.length,
            itemBuilder: (context, index) {
              final q = questions[index];
              final hasImage = File(q.imagePath).existsSync();
              return Card(
                child: ListTile(
                  leading: hasImage
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: Image.file(File(q.imagePath), width: 48, height: 48, fit: BoxFit.cover),
                        )
                      : null,
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
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('加载失败: $e')),
      ),
    );
  }

  Widget _buildSearchField() {
    return TextField(
      autofocus: true,
      decoration: const InputDecoration(
        hintText: '搜索错题...',
        border: InputBorder.none,
      ),
      onChanged: (value) {
        ref.read(searchQueryProvider.notifier).state = value;
      },
    );
  }

  void _showFilterSheet(BuildContext context) {
    final selectedSubject = ref.read(selectedSubjectFilterProvider);
    final selectedMastery = ref.read(selectedMasteryFilterProvider);

    showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('按科目筛选', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _filterChip(
                      label: '全部',
                      selected: selectedSubject == null,
                      onSelected: () {
                        ref.read(selectedSubjectFilterProvider.notifier).state = null;
                        setSheetState(() {});
                      },
                    ),
                    ...Subject.values.map((s) => _filterChip(
                      label: s.label,
                      selected: selectedSubject == s,
                      onSelected: () {
                        ref.read(selectedSubjectFilterProvider.notifier).state = s;
                        setSheetState(() {});
                      },
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                Text('按掌握状态筛选', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _filterChip(
                      label: '全部',
                      selected: selectedMastery == null,
                      onSelected: () {
                        ref.read(selectedMasteryFilterProvider.notifier).state = null;
                        setSheetState(() {});
                      },
                    ),
                    ...MasteryLevel.values.map((m) => _filterChip(
                      label: _masteryLabel(m),
                      selected: selectedMastery == m,
                      onSelected: () {
                        ref.read(selectedMasteryFilterProvider.notifier).state = m;
                        setSheetState(() {});
                      },
                    )),
                  ],
                ),
                const SizedBox(height: 16),
                Center(
                  child: FilledButton.tonal(
                    onPressed: () {
                      ref.read(selectedSubjectFilterProvider.notifier).state = null;
                      ref.read(selectedMasteryFilterProvider.notifier).state = null;
                      setSheetState(() {});
                    },
                    child: const Text('重置筛选'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _filterChip({required String label, required bool selected, required VoidCallback onSelected}) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
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
}
