import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';

abstract class SettingsRepository {
  Future<AiProviderConfig?> getAiProviderConfig();
  Future<void> saveAiProviderConfig(AiProviderConfig config);
}

class InMemorySettingsRepository implements SettingsRepository {
  AiProviderConfig? _config;

  @override
  Future<AiProviderConfig?> getAiProviderConfig() async => _config;

  @override
  Future<void> saveAiProviderConfig(AiProviderConfig config) async {
    _config = config;
  }
}
