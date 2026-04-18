import 'package:flutter/material.dart';

class PromptSettingsScreen extends StatelessWidget {
  const PromptSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('提示词设置')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: <Widget>[
            const Text('题目解析提示词', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: '请分析以下错题...',
              ),
            ),
            SizedBox(height: 24),
            Text('举一反三提示词', style: TextStyle(fontWeight: FontWeight.w600)),
            SizedBox(height: 8),
            TextField(
              maxLines: 4,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                hintText: '根据以上题目生成3道类似题目...',
              ),
            ),
            SizedBox(height: 24),
            FilledButton(onPressed: null, child: Text('保存提示词')),
          ],
        ),
      ),
    );
  }
}
