import 'package:flutter/material.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';

class ProviderConfigScreen extends StatelessWidget {
  const ProviderConfigScreen({super.key, required this.config});

  final AiProviderConfig? config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AI 服务配置')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: <Widget>[
            TextFormField(
              initialValue: config?.baseUrl ?? '',
              decoration: const InputDecoration(labelText: 'API 地址'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: config?.model ?? '',
              decoration: const InputDecoration(labelText: '模型'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: config?.apiKey ?? '',
              obscureText: true,
              decoration: const InputDecoration(labelText: 'API Key'),
            ),
            const SizedBox(height: 24),
            FilledButton(onPressed: null, child: const Text('保存')),
          ],
        ),
      ),
    );
  }
}
