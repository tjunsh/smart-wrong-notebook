import 'package:flutter/material.dart';

class SubjectManagementScreen extends StatelessWidget {
  const SubjectManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppBar(title: Text('科目管理')),
      body: Center(child: Text('内置科目 + 自定义科目')),
    );
  }
}
