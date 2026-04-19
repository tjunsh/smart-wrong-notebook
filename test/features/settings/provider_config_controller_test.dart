import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/features/settings/presentation/provider_config_controller.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';

void main() {
  test('controller saves and retrieves provider config', () {
    final controller = ProviderConfigController();
    const config = AiProviderConfig(
      id: 'openai',
      displayName: 'OpenAI',
      baseUrl: 'https://api.openai.com/v1',
      model: 'gpt-4o',
      apiKey: 'sk-test',
    );

    controller.save(config);
    expect(controller.current?.id, 'openai');
    expect(controller.current?.model, 'gpt-4o');
  });
}
