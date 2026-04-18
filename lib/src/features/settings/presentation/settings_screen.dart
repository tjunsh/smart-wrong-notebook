import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('设置')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const <Widget>[
          ListTile(title: Text('AI 服务商配置')),
          ListTile(title: Text('科目管理')),
          ListTile(title: Text('提示词设置')),
          ListTile(title: Text('导出当前题库')),
        ],
      ),
    );
  }
}
