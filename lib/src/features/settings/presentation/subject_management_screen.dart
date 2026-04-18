import 'package:flutter/material.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

class SubjectManagementScreen extends StatelessWidget {
  const SubjectManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final subjects = Subject.values;

    return Scaffold(
      appBar: AppBar(title: const Text('科目管理')),
      body: ListView.separated(
        itemCount: subjects.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, index) {
          final subject = subjects[index];
          return ListTile(
            leading: const Icon(Icons.book_outlined),
            title: Text(subject.label),
            trailing: subject == Subject.custom
                ? const Icon(Icons.edit_outlined, size: 18)
                : null,
          );
        },
      ),
    );
  }
}
