import 'package:flutter_test/flutter_test.dart';
import 'package:smart_wrong_notebook/src/app/router.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';

class _TestSettingsRepository implements SettingsRepository {
  @override
  Future<AiProviderConfig?> getAiProviderConfig() async => null;

  @override
  Future<void> saveAiProviderConfig(AiProviderConfig config) async {}

  @override
  Future<String?> getString(String key) async => null;

  @override
  Future<void> setString(String key, String value) async {}
}

void main() {
  test('router includes capture split confirmation route', () {
    final router = buildRouter(_TestSettingsRepository());
    addTearDown(router.dispose);

    expect(
      () => router.configuration.findMatch(Uri.parse('/capture/split-confirmation')),
      returnsNormally,
    );
  });
}
