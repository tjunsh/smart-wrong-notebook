import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';

class ProviderConfigController {
  AiProviderConfig? current;

  void save(AiProviderConfig config) {
    current = config;
  }
}
