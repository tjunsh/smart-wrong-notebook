import 'package:flutter/material.dart';

class PromptSettingsScreen extends StatelessWidget {
  const PromptSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      appBar: AppBar(title: Text('提示词设置')),
      body: Center(child: Text('分析题目 / 举一反三')),
    );
  }
}
