class AiProviderConfig {
  const AiProviderConfig({
    required this.id,
    required this.displayName,
    required this.baseUrl,
    required this.model,
    required this.apiKey,
  });

  final String id;
  final String displayName;
  final String baseUrl;
  final String model;
  final String apiKey;
}
