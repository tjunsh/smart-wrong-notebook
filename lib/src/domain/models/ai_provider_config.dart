class AiProviderConfig {
  const AiProviderConfig({
    required this.providerName,
    required this.baseUrl,
    required this.apiKey,
    required this.modelId,
  });

  final String providerName;
  final String baseUrl;
  final String apiKey;
  final String modelId;
}
