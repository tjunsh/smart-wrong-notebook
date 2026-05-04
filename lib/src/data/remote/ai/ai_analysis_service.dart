import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';
import 'package:smart_wrong_notebook/src/shared/utils/composite_worksheet_detector.dart';

enum _ExerciseTopic {
  generic,
  linearEquation,
  quadraticRoot,
  equationSystem,
  triangleAngle,
  solidVolume,
  functionEvaluation,
  proportionalRelation,
}

enum _TopicProfileSource { sourceQuestion, exercise }

class _ExerciseTopicProfile {
  const _ExerciseTopicProfile(this.topic, this.hasStrongSignal);

  final _ExerciseTopic topic;
  final bool hasStrongSignal;
}

class AiQuestionExtractionResult {
  const AiQuestionExtractionResult({
    required this.extractedQuestionText,
    required this.normalizedQuestionText,
    this.subject,
    this.splitResult,
  });

  final String extractedQuestionText;
  final String normalizedQuestionText;
  final Subject? subject;
  final QuestionSplitResult? splitResult;
}

class AiAnalysisService {
  AiAnalysisService({required this.settingsRepository});

  final SettingsRepository settingsRepository;

  static const _maxRetries = 2; // 最多重试2次（总共3次请求）
  static const _baseDelayMs = 1000; // 基础延迟1秒

  /// 带重试的 POST 请求（指数退避）
  Future<Response<T>> _retryPost<T>(
    Dio dio,
    String path, {
    required Map<String, dynamic> data,
    int attempt = 1,
  }) async {
    try {
      return await dio.post<T>(path, data: data);
    } on DioException catch (e) {
      // 只对网络错误和超时进行重试，不重试 HTTP 错误（如401、403）
      final shouldRetry = e.type == DioExceptionType.connectionTimeout ||
          e.type == DioExceptionType.receiveTimeout ||
          e.type == DioExceptionType.sendTimeout ||
          e.type == DioExceptionType.connectionError;

      if (shouldRetry && attempt <= _maxRetries) {
        final delayMs = _baseDelayMs * attempt;
        debugPrint(
            '[AiAnalysisService] 请求失败，${delayMs}ms 后重试 (第 $attempt 次)...');
        await Future.delayed(Duration(milliseconds: delayMs));
        return _retryPost(dio, path, data: data, attempt: attempt + 1);
      }
      rethrow;
    }
  }

  factory AiAnalysisService.fake() => _FakeAiAnalysisService();

  Dio _createClient(AiProviderConfig config) {
    return Dio(BaseOptions(
      baseUrl: config.baseUrl.endsWith('/')
          ? config.baseUrl.substring(0, config.baseUrl.length - 1)
          : config.baseUrl,
      headers: <String, String>{
        'Content-Type': 'application/json',
        if (config.apiKey.isNotEmpty)
          'Authorization': 'Bearer ${config.apiKey}',
      },
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 240),
    ));
  }

  /// 测试 API 连接
  Future<void> testConnection(AiProviderConfig config) async {
    debugPrint('[AiAnalysisService] testConnection called');
    debugPrint('[AiAnalysisService] baseUrl: ${config.baseUrl}');
    debugPrint('[AiAnalysisService] model: ${config.model}');

    final dio = _createClient(config);
    final baseUrl = config.baseUrl.toLowerCase();

    try {
      // 只检查 HTTP 200 状态码，不检查返回内容
      if (baseUrl.contains('openrouter')) {
        debugPrint('[AiAnalysisService] Testing OpenRouter endpoint');
        await dio.post('/chat/completions', data: <String, dynamic>{
          'model': config.model,
          'messages': [
            {'role': 'user', 'content': 'Hi'},
          ],
          'max_tokens': 1,
        });
      } else if (config.model.toLowerCase().contains('gemini')) {
        debugPrint('[AiAnalysisService] Testing Gemini endpoint');
        await dio.post(
          '/v1beta/models/${config.model}:generateContent',
          data: <String, dynamic>{
            'contents': [
              {
                'parts': [
                  {'text': 'Hi'}
                ]
              },
            ],
            'generationConfig': {'maxOutputTokens': 1},
          },
        );
      } else {
        debugPrint('[AiAnalysisService] Testing default OpenAI endpoint');
        await dio.post('/chat/completions', data: <String, dynamic>{
          'model': config.model,
          'messages': [
            {'role': 'user', 'content': 'Hi'},
          ],
          'max_tokens': 1,
        });
      }

      debugPrint('[AiAnalysisService] Connection test passed (HTTP 200)');
    } on DioException catch (e) {
      debugPrint(
          '[AiAnalysisService] testConnection DioException: type=${e.type}, message=${e.message}');
      throw AiAnalysisException(_dioErrorMessage(e));
    } catch (e) {
      debugPrint('[AiAnalysisService] Exception: $e');
      throw AiAnalysisException('测试失败: $e');
    }
  }

  /// 分析题目 - 兼容入口：先提取结构，再做学习分析
  Future<AnalysisResult> analyzeQuestion({
    required String correctedText,
    required String subjectName,
    String? imagePath, // 可选：图片路径
  }) async {
    debugPrint('[AiAnalysisService] analyzeQuestion called');
    debugPrint(
        '[AiAnalysisService] - correctedText: ${correctedText.isNotEmpty ? "provided (${correctedText.length} chars)" : "empty"}');
    debugPrint('[AiAnalysisService] - subjectName: $subjectName');
    debugPrint('[AiAnalysisService] - imagePath: $imagePath');

    var textForAnalysis = correctedText;
    var resolvedSubject = _parseSubject(subjectName);

    if (imagePath != null && File(imagePath).existsSync()) {
      final extraction = await extractQuestionStructure(
        subjectName: subjectName,
        imagePath: imagePath,
        textHint: correctedText,
      );
      if (extraction.normalizedQuestionText.isNotEmpty) {
        textForAnalysis = extraction.normalizedQuestionText;
      }
      resolvedSubject ??= extraction.subject;
    }

    return analyzeExtractedQuestion(
      correctedText: textForAnalysis,
      subjectName: resolvedSubject?.name ?? subjectName,
      imagePath: imagePath,
    );
  }

  Future<QuestionSplitResult> splitQuestionCandidates({
    required String text,
    String? subjectName,
    QuestionSplitResult Function(String text)? fallbackSplit,
  }) async {
    final subject = subjectName != null ? _parseSubject(subjectName) : null;
    final splitter = fallbackSplit ??
        (String t) => _defaultSplitQuestionCandidates(t, subject: subject);
    return splitter(text);
  }

  Future<AiQuestionExtractionResult> extractQuestionStructure({
    required String subjectName,
    required String imagePath,
    String textHint = '',
  }) async {
    debugPrint('[AiAnalysisService] extractQuestionStructure called');

    final config = await _requireConfig();
    final imageBytes = await File(imagePath).readAsBytes();
    try {
      final extractionContent = await _requestAiContentWithImage(
        config: config,
        systemPrompt: await _loadExtractionSystemPrompt(),
        prompt: _buildExtractionPrompt(
            subjectName: subjectName, textHint: textHint),
        imageBytes: imageBytes,
        maxTokens: 1600,
        imageDetail: 'auto',
      );
      final extraction = _parseExtractionResponse(extractionContent);

      return AiQuestionExtractionResult(
        extractedQuestionText: extraction.extractedQuestionText,
        normalizedQuestionText: extraction.normalizedQuestionText,
        subject: extraction.subject,
        splitResult: extraction.splitResult,
      );
    } on DioException catch (e) {
      debugPrint(
          '[AiAnalysisService] extract DioException: type=${e.type}, message=${e.message}, status=${e.response?.statusCode}, body=${e.response?.data}');
      throw AiAnalysisException(_dioErrorMessage(e));
    } catch (e) {
      debugPrint('[AiAnalysisService] extract Exception: $e');
      if (e is AiAnalysisException) rethrow;
      throw AiAnalysisException('AI 识别题目失败: $e');
    }
  }

  Future<List<CandidateAnalysisPayload>> analyzeSplitCandidates({
    required String questionId,
    required String subjectName,
    required QuestionSplitResult splitResult,
    String? imagePath,
    void Function(int completed, int total, {int failed})? onProgress,
  }) async {
    final candidates = splitResult.candidates;
    final total = candidates.length;
    var completed = 0;
    var failed = 0;
    final payloads = <CandidateAnalysisPayload>[];

    debugPrint(
        '[AiAnalysisService] analyzeSplitCandidates: $total candidates, concurrency=2');

    for (var start = 0; start < candidates.length; start += 2) {
      final batch = candidates.skip(start).take(2).map((candidate) async {
        try {
          final payload = await _analyzeSplitCandidateWithRetry(
            questionId: questionId,
            subjectName: subjectName,
            candidate: candidate,
          );
          completed++;
          onProgress?.call(completed, total, failed: failed);
          return payload;
        } catch (e) {
          debugPrint(
              '[AiAnalysisService] candidate ${candidate.order} failed after retry: $e');
          failed++;
          completed++;
          onProgress?.call(completed, total, failed: failed);
          return CandidateAnalysisPayload.failed(
            candidateId: candidate.id,
            order: candidate.order,
            questionText: candidate.text,
            errorMessage: e.toString(),
          );
        }
      }).toList();

      payloads.addAll(await Future.wait(batch));
    }

    payloads.sort((a, b) => a.order.compareTo(b.order));
    return payloads;
  }

  Future<CandidateAnalysisPayload> _analyzeSplitCandidateWithRetry({
    required String questionId,
    required String subjectName,
    required QuestionSplitCandidate candidate,
  }) async {
    Object? lastError;
    for (var attempt = 1; attempt <= 2; attempt++) {
      try {
        final candidateText = candidate.text;
        final analysis = await analyzeExtractedQuestion(
          correctedText: candidateText,
          subjectName: subjectName,
        );
        final exercises = analysis is ParsedAnalysisResult
            ? extractGeneratedExercisesFromContent(
                analysis.rawContent,
                questionId: '$questionId-${candidate.order}',
                analysis: analysis,
                sourceQuestionText: candidateText,
              )
            : extractGeneratedExercises(
                analysis,
                questionId: '$questionId-${candidate.order}',
                sourceQuestionText: candidateText,
              );

        return CandidateAnalysisPayload(
          candidateId: candidate.id,
          order: candidate.order,
          questionText: candidateText,
          analysisResult: analysis,
          savedExercises: exercises,
          subject: analysis.subject,
          aiTags: analysis.aiTags,
          aiKnowledgePoints: analysis.knowledgePoints,
        );
      } catch (e) {
        lastError = e;
        debugPrint(
            '[AiAnalysisService] candidate ${candidate.order} attempt $attempt failed: $e');
      }
    }
    throw lastError ?? AiAnalysisException('解析失败');
  }

  Future<AnalysisResult> analyzeExtractedQuestion({
    required String correctedText,
    required String subjectName,
    String? imagePath,
  }) async {
    debugPrint('[AiAnalysisService] analyzeExtractedQuestion called');

    final config = await _requireConfig();
    final prompt = _buildAnalysisPrompt(correctedText, subjectName);
    final systemPrompt = await _loadAnalysisSystemPrompt();

    try {
      final isCompositeLanguageAnalysis =
          _isCompositeLanguageAnalysis(correctedText, subjectName);
      if (imagePath != null && File(imagePath).existsSync()) {
        final imageBytes = await File(imagePath).readAsBytes();
        final imagePrompt = isCompositeLanguageAnalysis
            ? '$prompt\n\n请按一整道复合题分析，不要拆成多道独立题；英语按空号逐项解析，语文按文常、字词、翻译/释义模块解析。'
            : prompt;
        try {
          final content = await _requestAiContentWithImage(
            config: config,
            systemPrompt: systemPrompt,
            prompt: imagePrompt,
            imageBytes: imageBytes,
            maxTokens: isCompositeLanguageAnalysis ? 3000 : 2000,
            imageDetail: isCompositeLanguageAnalysis ? 'high' : 'auto',
          );
          return _parseAnalysisResponse(content);
        } on DioException catch (e) {
          if (!_shouldRetryWithCompactImage(e) ||
              !isCompositeLanguageAnalysis) {
            rethrow;
          }
          debugPrint(
              '[AiAnalysisService] High detail image analysis failed, retrying compact image request: ${e.type}, status=${e.response?.statusCode}');
          final content = await _requestAiContentWithImage(
            config: config,
            systemPrompt: systemPrompt,
            prompt: prompt,
            imageBytes: imageBytes,
            maxTokens: 2200,
            imageDetail: 'auto',
          );
          return _parseAnalysisResponse(content);
        }
      }

      final content = await _requestAiContent(
        config: config,
        systemPrompt: systemPrompt,
        prompt: prompt,
        maxTokens: isCompositeLanguageAnalysis ? 3000 : 2000,
      );
      return _parseAnalysisResponse(content);
    } on DioException catch (e) {
      debugPrint(
          '[AiAnalysisService] DioException: type=${e.type}, message=${e.message}, status=${e.response?.statusCode}, body=${e.response?.data}');
      throw AiAnalysisException(_dioErrorMessage(e));
    } catch (e) {
      debugPrint('[AiAnalysisService] Exception: $e');
      if (e is FormatException) {
        throw AiAnalysisException('AI 返回内容格式异常，请重试或换一张更清晰的图片');
      }
      throw AiAnalysisException('AI 解析失败: $e');
    }
  }

  Future<AiProviderConfig> _requireConfig() async {
    final config = await settingsRepository.getAiProviderConfig();

    debugPrint(
        '[AiAnalysisService] config: ${config != null ? "loaded" : "null"}');
    if (config != null) {
      debugPrint('[AiAnalysisService] - baseUrl: ${config.baseUrl}');
      debugPrint('[AiAnalysisService] - model: ${config.model}');
      debugPrint(
          '[AiAnalysisService] - apiKey length: ${config.apiKey.length}');
    }

    if (config == null ||
        config.baseUrl.isEmpty ||
        config.apiKey.isEmpty ||
        config.model.isEmpty) {
      debugPrint('[AiAnalysisService] No config - throwing error');
      throw AiAnalysisException('AI 未配置，请在设置中配置 API 地址、API Key 和模型');
    }

    return config;
  }

  bool _shouldRetryWithCompactImage(DioException e) {
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout ||
        e.type == DioExceptionType.connectionError) {
      return true;
    }
    final status = e.response?.statusCode;
    return status == 408 ||
        status == 429 ||
        status == 500 ||
        status == 502 ||
        status == 503 ||
        status == 504;
  }

  String _dioErrorMessage(DioException e) {
    final buffer = StringBuffer('AI 服务请求失败');
    if (e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout ||
        e.type == DioExceptionType.sendTimeout) {
      buffer.write(': 请求超时，请检查网络后重试');
    } else if (e.type == DioExceptionType.connectionError) {
      buffer.write(': 网络连接失败，请检查网络');
    } else if (e.response != null) {
      final status = e.response!.statusCode;
      final body = e.response!.data;
      if (status != null) {
        buffer.write(' (HTTP $status)');
        if (body != null && body is Map && body['error'] != null) {
          final errMsg = body['error'];
          if (errMsg is Map) {
            buffer.write(': ${errMsg['message'] ?? errMsg}');
          } else {
            buffer.write(': $errMsg');
          }
        } else if (body is String && body.isNotEmpty) {
          buffer.write(
              ': ${body.length > 100 ? '${body.substring(0, 100)}...' : body}');
        }
      } else if (e.message != null) {
        buffer.write(': ${e.message}');
      }
    } else if (e.message != null) {
      buffer.write(': ${e.message}');
    }
    return buffer.toString();
  }

  QuestionSplitResult _defaultSplitQuestionCandidates(String text,
      {Subject? subject}) {
    final normalized = _normalizeExtractedQuestionText(
      text.replaceAll('\r\n', '\n').trim(),
    );
    if (normalized.isEmpty) {
      return const QuestionSplitResult(
        sourceText: '',
        candidates: <QuestionSplitCandidate>[],
        strategy: QuestionSplitStrategy.fallback,
      );
    }

    if (isCompositeLanguageWorksheet(normalized, subject: subject)) {
      return QuestionSplitResult(
        sourceText: normalized,
        candidates: _buildSplitCandidates(
            <String>[normalized], QuestionSplitStrategy.fallback),
        strategy: QuestionSplitStrategy.fallback,
      );
    }

    final numberedSegments = _splitByNumberedQuestions(normalized);
    if (numberedSegments.length >= 2) {
      return QuestionSplitResult(
        sourceText: normalized,
        candidates: _buildSplitCandidates(
            numberedSegments, QuestionSplitStrategy.numbered),
        strategy: QuestionSplitStrategy.numbered,
      );
    }

    final paragraphSegments = normalized
        .split(RegExp(r'\n\s*\n+'))
        .map((segment) => segment.trim())
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (paragraphSegments.length >= 2) {
      return QuestionSplitResult(
        sourceText: normalized,
        candidates: _buildSplitCandidates(
            paragraphSegments, QuestionSplitStrategy.paragraph),
        strategy: QuestionSplitStrategy.paragraph,
      );
    }

    return QuestionSplitResult(
      sourceText: normalized,
      candidates: _buildSplitCandidates(
          <String>[normalized], QuestionSplitStrategy.fallback),
      strategy: QuestionSplitStrategy.fallback,
    );
  }

  String _normalizeExtractedQuestionText(String text) {
    final normalized = text
        .replaceAllMapped(
          RegExp(r'begin\{(cases|aligned)\}([\s\S]*?)end\{(?:cases|aligned)\}'),
          (match) {
            final body = match.group(2)!.trim().replaceAllMapped(
                  RegExp(r'(?<=[0-9A-Za-z一-龥])\s+(?=[A-Za-z])'),
                  (_) => r' \\ ',
                );
            return '\\begin{${match.group(1)}} $body \\end{${match.group(1)}}';
          },
        )
        .replaceAllMapped(RegExp(r'\\+tri\\+angle\s*'), (_) => r'\triangle ')
        .replaceAllMapped(RegExp(r'\\?tri\\?angle\s*|\\?tri∠|tri(?=\\angle)'),
            (_) => r'\triangle ')
        .replaceAllMapped(RegExp(r'(?<!\\)angle\b'), (_) => r'\angle')
        .replaceAllMapped(RegExp(r'(?<!\\)circ\b'), (_) => r'\circ')
        .replaceAllMapped(RegExp(r'(?<!\\)pm(?=[A-Za-z0-9])'), (_) => r'\pm ')
        .replaceAllMapped(RegExp(r'(?<!\\)pm\b'), (_) => r'\pm');

    return normalized
        .replaceAll(RegExp(r'\\+tri\\+angle\s*'), r'\triangle ')
        .replaceAll(RegExp(r'tri\\+angle\s*'), r'\triangle ')
        .replaceAll(RegExp(r'(?<![A-Za-z\\])tri∠'), r'\triangle ')
        .replaceAll(RegExp(r'(?<![A-Za-z\\])tri(?=\\angle|/)'), r'\triangle ')
        .replaceAll(
          RegExp(r'(?<![A-Za-z\\])text(?=kg|m|cm|g|s|N|Pa|J|W|V|A|Ω)'),
          r'\mathrm',
        )
        .replaceAllMapped(
          RegExp(r'\\?mathrm([A-Za-zΩ]+)(\^-?\d+)?'),
          (match) => '\\mathrm{${match.group(1)}}${match.group(2) ?? ''}',
        );
  }

  bool _isCompositeLanguageAnalysis(String text, String subjectName) {
    final subject = _parseSubject(subjectName);
    if ((subject == Subject.english || subject == Subject.chinese) &&
        text.trim().isEmpty) {
      return true;
    }
    return isCompositeLanguageWorksheet(text, subject: subject);
  }

  List<QuestionSplitCandidate> _buildSplitCandidates(
      List<String> segments, QuestionSplitStrategy strategy) {
    return segments.asMap().entries.map((entry) {
      return QuestionSplitCandidate(
        id: 'candidate-${entry.key}',
        order: entry.key + 1,
        text: entry.value,
        strategy: strategy,
      );
    }).toList();
  }

  List<String> _splitByNumberedQuestions(String text) {
    final matches =
        RegExp(r'(^|\n)\s*(?:第\s*\d+\s*题|\d+[\.、．)])\s*', multiLine: true)
            .allMatches(text)
            .toList();
    if (matches.length < 2) return const <String>[];

    final segments = <String>[];
    for (var index = 0; index < matches.length; index++) {
      final current = matches[index];
      final start = current.start + (current.group(1)?.length ?? 0);
      final end =
          index + 1 < matches.length ? matches[index + 1].start : text.length;
      final segment = text.substring(start, end).trim();
      if (segment.isNotEmpty) {
        segments.add(segment);
      }
    }
    return segments;
  }

  Future<String> _requestAiContent({
    required AiProviderConfig config,
    required String systemPrompt,
    required String prompt,
    int maxTokens = 2000,
  }) async {
    final dio = _createClient(config);
    final response =
        await _retryPost(dio, '/chat/completions', data: <String, dynamic>{
      'model': config.model,
      'messages': <Map<String, String>>[
        <String, String>{'role': 'system', 'content': systemPrompt},
        <String, String>{'role': 'user', 'content': prompt},
      ],
      'temperature': 0.7,
      'max_tokens': maxTokens,
    });

    return response.data['choices'][0]['message']['content'] as String;
  }

  bool _usesOpenAiCompatibleChat(AiProviderConfig config) {
    final baseUrl = config.baseUrl.toLowerCase();
    final model = config.model.toLowerCase();
    return baseUrl.contains('/v1') ||
        baseUrl.contains('openrouter') ||
        model.contains('gpt') ||
        model.contains('4o') ||
        model.contains('4-turbo');
  }

  Future<String> _requestAiContentWithImage({
    required AiProviderConfig config,
    required String systemPrompt,
    required String prompt,
    required Uint8List imageBytes,
    int maxTokens = 2000,
    String imageDetail = 'auto',
  }) async {
    final dio = _createClient(config);
    final base64Image = base64Encode(imageBytes);
    const mimeType = 'image/jpeg';
    final baseUrl = config.baseUrl.toLowerCase();
    final model = config.model.toLowerCase();

    if (_usesOpenAiCompatibleChat(config)) {
      final response =
          await _retryPost(dio, '/chat/completions', data: <String, dynamic>{
        'model': config.model,
        'messages': <Map<String, dynamic>>[
          {'role': 'system', 'content': systemPrompt},
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:$mimeType;base64,$base64Image',
                  'detail': imageDetail
                },
              },
              {'type': 'text', 'text': prompt},
            ],
          },
        ],
        'temperature': 0.7,
        'max_tokens': maxTokens,
      });
      return response.data['choices'][0]['message']['content'] as String;
    }

    if (model.contains('gemini') && !baseUrl.contains('openrouter')) {
      final response = await dio.post(
        '/v1beta/models/${config.model}:generateContent',
        data: <String, dynamic>{
          'contents': [
            {
              'parts': [
                {'text': '$systemPrompt\n\n$prompt'},
                {
                  'inlineData': {'mimeType': mimeType, 'data': base64Image}
                },
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': maxTokens,
          },
        },
      );
      return response.data['candidates'][0]['content']['parts'][0]['text']
          as String;
    }

    final response =
        await _retryPost(dio, '/chat/completions', data: <String, dynamic>{
      'model': config.model,
      'messages': <Map<String, dynamic>>[
        {'role': 'system', 'content': systemPrompt},
        {
          'role': 'user',
          'content': [
            {
              'type': 'image_url',
              'image_url': {
                'url': 'data:$mimeType;base64,$base64Image',
                'detail': imageDetail
              },
            },
            {'type': 'text', 'text': prompt},
          ],
        },
      ],
      'temperature': 0.7,
      'max_tokens': maxTokens,
    });
    return response.data['choices'][0]['message']['content'] as String;
  }

  static const _defaultAnalysisSystemPrompt = '''你是一个专业的错题分析助手，专门帮助学生分析和理解错题。

你的任务是：
1. 基于已经确认的题目文本进行学习分析
2. 根据题目内容判断所属科目（数学、语文、英语、物理、化学、生物、历史、地理、政治等）
3. 提供正确的解题思路和答案
4. 分析学生可能犯错误的原因
5. 提供学习建议和相关的知识点
6. 生成举一反三的练习题（选择题格式，带 A/B/C/D 选项）

重要规则：
- 优先使用用户已确认的题目文本，不要虚构题目
- 仅在文本明显缺失时，才参考图片补充细节
- 答案必须准确、有条理
- 生成的练习题应该难度适中、与原题相关
- generatedExercises 必须围绕本题同一个知识点、同一题型、同一种核心解法生成，禁止退化成无关的简单加减法或一元一次方程
- 如果原题含有平方项、平方根、一元二次或 \(x^2=a\) 结构，练习题也必须包含平方项/开平方/正负根相关解法，不能生成 \(x+1=4\)、\(2x=8\) 这类一元一次题
- 如果原题是三角形内角/外角/等腰三角形，练习题也必须是三角形角度关系题
- 如果原题是方程组，练习题也必须是方程组题
- 练习题必须是选择题格式，包含 A/B/C/D 四个选项，其中一个是正确答案
- 答案字段填写正确选项的字母（如 "A"）
- aiTags 要求简短精炼（2-8个字），数量 2-4 个，如 ["压强", "力学", "公式"]
- knowledgePoints 可以详细描述，长度不限，如 ["压强公式p=f/s，压强与压力的关系", "受力面积相同时，压力越大压强越大"]
- 如果内容包含 LaTeX，必须先生成合法 JSON：所有 LaTeX 反斜杠都写成 JSON 转义形式，例如 \\frac、\\times、\\(x\\)、\\[x\\]
- 方程组或多行公式必须使用 KaTeX 兼容的 aligned 或 cases 环境，例如 \\begin{cases} x+y=5 \\\\ x-y=1 \\end{cases}，不要使用 \\newline
- 不要在 JSON 字符串内部直接换行；换行必须写成 \\n
- 【LaTeX 格式强制规范——必须严格遵守】
  1. 所有数学公式必须使用标准 LaTeX 定界符包裹：行内公式用 \(公式\)，独立公式用 \[公式\]。禁止使用方括号 [(...) 或 [...] 作为 LaTeX 定界符。
  2. LaTeX 命令必须使用完整的反斜杠前缀，禁止省略反斜杠：
     - 正确命令：\frac、\angle、\triangle、\circ、\times、\cdot、\pm、\sqrt、\pi、\rho、\alpha、\beta、\gamma、\theta、\Delta、\lambda、\mu、\sigma、\omega、\leq、\geq、\neq、\approx、\sin、\cos、\tan、\log、\ln、\mathrm、\rightarrow、\leftarrow
     - 错误写法：frac、angle、triangle、circ、times、cdot、pm、sqrt、pi、rho、alpha
     - 注意：乘号用 \times，除法用 \frac，分数用 \frac{a}{b}，圆周率用 \pi，密度用 \rho
  3. 角度/度数统一用 ^\circ，圆周率统一用 \pi
  4. 上标用 ^{n} 格式，禁止裸 ^n
  5. 物理单位用 \mathrm{}：\mathrm{kg}、\mathrm{m}、\mathrm{N}、\mathrm{Pa}、\mathrm{J}、\mathrm{W}、\mathrm{V}、\mathrm{A}、\mathrm{\Omega}
  6. generatedExercises 中的 question、options、explanation 字段同样必须遵守上述所有 LaTeX 格式规则
  7. JSON 转义规则：反斜杠双写，\ → \\，\\ → \\\\。换行用 \\n。cases 环境行分隔符 \\ → \\\\
     - 示例：\\(x^2=4\)\\n  所以 x=\\pm 2  // JSON 中 \\n = 换行，\\pi = \pi，\\pm = \pm
     - 示例：\[\\begin{cases} x+y=5 \\\\ x-y=1 \\end{cases}\]  // \\\\ 在 JSON 中表示 LaTeX 换行符 \\
返回格式必须严格如下（不要包含 markdown 代码块标记，使用纯 JSON）：
{
  "subject": "自动判断的科目名称",
  "finalAnswer": "正确答案或解题要点",
  "steps": ["解题步骤1", "解题步骤2"],
  "aiTags": ["短标签1", "短标签2", "短标签3"],
  "knowledgePoints": ["知识点1详细描述", "知识点2详细描述"],
  "mistakeReason": "错误原因分析",
  "studyAdvice": "学习建议",
  "generatedExercises": [
    {"id": "e1", "difficulty": "简单", "question": "练习题目", "options": ["A. 选项1", "B. 选项2", "C. 选项3", "D. 选项4"], "answer": "A", "explanation": "解析"}
  ]
}''';

  static const _defaultExtractionSystemPrompt =
      '''你是一个专业的教辅录入员，负责把题目图片整理成可存储、可检索的结构化文本。

你的任务是：
1. 识别图片中的原始题目内容
2. 忽略无关的手写批改痕迹、圈画、红叉等内容
3. 输出适合存入题库的规范化题目文本
4. 判断题目所属科目
5. 数学公式使用 LaTeX 或 Markdown 友好的表达，保持题意完整

重要规则：
- 必须以图片内容为准，不要虚构缺失内容
- extractedQuestionText 保留尽量忠实的识别结果
- normalizedQuestionText 输出更适合展示、搜索和后续 AI 分析的规范文本
- 如果图片无法识别出有效题目，两个文本字段都返回空字符串
- 如果内容包含 LaTeX，必须先生成合法 JSON：所有 LaTeX 反斜杠都写成 JSON 转义形式，例如 \\frac、\\times、\\(x\\)、\\[x\\]
- 方程组或多行公式必须使用 KaTeX 兼容的 aligned 或 cases 环境，例如 \\begin{cases} x+y=5 \\\\ x-y=1 \\end{cases}，不要使用 \\newline
- 不要在 JSON 字符串内部直接换行；换行必须写成 \\n
- 【LaTeX 格式强制规范——必须严格遵守】
  1. 所有数学公式必须使用标准 LaTeX 定界符包裹：行内公式用 \(公式\)，独立公式用 \[公式\]。禁止使用方括号 [(...) 或 [...] 作为 LaTeX 定界符。
  2. LaTeX 命令必须使用完整的反斜杠前缀，禁止省略反斜杠：
     - 正确命令：\frac、\angle、\triangle、\circ、\times、\cdot、\pm、\sqrt、\pi、\rho、\alpha、\beta、\gamma、\theta、\Delta、\lambda、\mu、\sigma、\omega、\leq、\geq、\neq、\approx、\sin、\cos、\tan、\log、\ln、\mathrm、\rightarrow、\leftarrow
     - 错误写法：frac、angle、triangle、circ、times、cdot、pm、sqrt、pi、rho、alpha
     - 注意：乘号用 \times，除法用 \frac，分数用 \frac{a}{b}，圆周率用 \pi，密度用 \rho
  3. 角度/度数统一用 ^\circ，圆周率统一用 \pi
  4. 上标用 ^{n} 格式，禁止裸 ^n
  5. 物理单位用 \mathrm{}：\mathrm{kg}、\mathrm{m}、\mathrm{N}、\mathrm{Pa}、\mathrm{J}、\mathrm{W}、\mathrm{V}、\mathrm{A}、\mathrm{\Omega}
  6. JSON 转义规则：反斜杠双写，\ → \\，\\ → \\\\。换行用 \\n。cases 环境行分隔符 \\ → \\\\
     - 示例：\\(x^2=4\)\\n  所以 x=\\pm 2  // JSON 中 \\n = 换行，\\pi = \pi，\\pm = \pm
     - 示例：\[\\begin{cases} x+y=5 \\\\ x-y=1 \\end{cases}\]  // \\\\ 在 JSON 中表示 LaTeX 换行符 \\
返回格式必须严格如下（不要包含 markdown 代码块标记，使用纯 JSON）：
{
  "subject": "自动判断的科目名称",
  "extractedQuestionText": "从图片提取的原始题目文本",
  "normalizedQuestionText": "整理后的标准题目文本"
}''';

  Future<String> _loadAnalysisSystemPrompt() async {
    final custom = await settingsRepository.getString('system_prompt');
    return custom?.isNotEmpty == true ? custom! : _defaultAnalysisSystemPrompt;
  }

  Future<String> _loadExtractionSystemPrompt() async {
    final custom =
        await settingsRepository.getString('extraction_system_prompt');
    return custom?.isNotEmpty == true
        ? custom!
        : _defaultExtractionSystemPrompt;
  }

  String _buildExtractionPrompt({
    required String subjectName,
    required String textHint,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('请先做题目结构化提取。');
    buffer.writeln('用户当前选择的科目提示：$subjectName');
    if (textHint.isNotEmpty) {
      buffer.writeln();
      buffer.writeln('用户已有文本提示：');
      buffer.writeln(textHint);
    }
    buffer.writeln();
    buffer.writeln(
        '请输出 subject、extractedQuestionText、normalizedQuestionText。方程组或多行公式请使用 aligned/cases 环境，不要使用 \\newline。');
    return buffer.toString();
  }

  String _buildAnalysisPrompt(String correctedText, String subjectName) {
    final buffer = StringBuffer();
    buffer.writeln('请分析以下$subjectName科目的错题：');
    buffer.writeln();
    buffer.writeln('已确认题目文本：');
    buffer.writeln(correctedText);
    buffer.writeln();
    final topicAnchor = _buildExerciseTopicAnchor(correctedText);
    if (topicAnchor.isNotEmpty) {
      buffer.writeln('举一反三题型锚点：$topicAnchor');
      buffer.writeln('generatedExercises 必须保持这个题型和解题方法，不得降级成更简单的无关题。');
      buffer.writeln();
    }
    buffer.writeln(
        '请以 JSON 格式返回完整的分析结果，包含 subject、finalAnswer、steps、aiTags、knowledgePoints、mistakeReason、studyAdvice、generatedExercises 字段。方程组或多行公式请使用 aligned/cases 环境，不要使用 \\newline。');
    return buffer.toString();
  }

  String _buildExerciseTopicAnchor(String correctedText) {
    final profile =
        _buildExerciseTopicProfile(sourceQuestionText: correctedText);
    switch (profile.topic) {
      case _ExerciseTopic.quadraticRoot:
        return '含平方项/平方根/一元二次方程，练习必须继续考查把方程整理为 x^2=a、开平方、正负根、代入检验；禁止改成一元一次、函数求值、方程组或几何体积题';
      case _ExerciseTopic.equationSystem:
        return '二元一次方程组，练习必须继续考查代入消元或加减消元；题目必须保持方程组结构，禁止改成单个一元一次方程、平方根方程、函数求值或几何题';
      case _ExerciseTopic.triangleAngle:
        return '三角形角度关系，练习必须继续考查内角和、外角或等腰三角形角度；禁止改成代数方程、函数求值或几何体积题';
      case _ExerciseTopic.solidVolume:
        return '立体几何公式代入，练习必须继续考查圆锥/圆柱/体积公式和代入计算；公式中的 r^2 只是半径平方，禁止改成开平方求正负根、函数求值或方程组';
      case _ExerciseTopic.functionEvaluation:
        return '函数解析式代入求值，练习必须继续考查把自变量代入函数表达式并按运算顺序计算函数值；表达式中的 x^2 只是函数项，禁止改成开平方求正负根、方程组或几何题';
      case _ExerciseTopic.proportionalRelation:
        return '分式/比例关系与和差条件，练习必须继续考查把比值关系转化为倍数关系，再代入和或差条件求两个量；禁止改成方程组消元、平方根方程、函数求值或几何题';
      case _ExerciseTopic.linearEquation:
        return '一元一次方程，练习应继续考查移项、合并同类项、求未知数；禁止改成平方根方程、方程组、函数求值或几何题';
      case _ExerciseTopic.generic:
        return '';
    }
  }

  Map<String, dynamic> _parseResponseJson(String content) {
    debugPrint('[AiAnalysisService] Raw AI response: $content');

    final jsonStr = _stripJsonFence(content);

    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      debugPrint('[AiAnalysisService] Parsed JSON keys: ${map.keys.toList()}');
      return _normalizeParsedJsonStrings(map);
    } catch (e) {
      final repairedJson = _repairInvalidJsonStringEscapes(jsonStr);
      if (repairedJson != jsonStr) {
        try {
          final map = jsonDecode(repairedJson) as Map<String, dynamic>;
          debugPrint(
              '[AiAnalysisService] Parsed repaired JSON keys: ${map.keys.toList()}');
          return _normalizeParsedJsonStrings(map);
        } catch (repairedError) {
          debugPrint(
              '[AiAnalysisService] Repaired parse error: $repairedError');
          final recoveredMap = _recoverFlatJsonFields(repairedJson);
          if (recoveredMap.isNotEmpty) {
            debugPrint(
                '[AiAnalysisService] Recovered JSON keys: ${recoveredMap.keys.toList()}');
            return _normalizeParsedJsonStrings(recoveredMap);
          }
        }
      }

      debugPrint('[AiAnalysisService] Parse error: $e');
      throw AiAnalysisException('解析 AI 响应失败: $e');
    }
  }

  String _stripJsonFence(String content) {
    var jsonStr = content.trim();
    if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr
          .replaceFirst(RegExp(r'^```\w*\n?'), '')
          .replaceFirst(RegExp(r'\n?```$'), '');
    }
    return jsonStr;
  }

  Map<String, dynamic> _recoverFlatJsonFields(String jsonStr) {
    final result = <String, dynamic>{};
    final keyPattern = RegExp(r'"([^"\\]+)"\s*:');
    final matches = keyPattern.allMatches(jsonStr).toList();

    for (var i = 0; i < matches.length; i++) {
      final key = matches[i].group(1)!;
      final valueStart = matches[i].end;
      final valueEnd = i + 1 < matches.length
          ? matches[i + 1].start
          : jsonStr.lastIndexOf('}');
      if (valueEnd <= valueStart) continue;

      final rawValue = jsonStr
          .substring(valueStart, valueEnd)
          .trim()
          .replaceFirst(RegExp(r',$'), '')
          .trim();
      if (rawValue.startsWith('"')) {
        result[key] = _recoverJsonStringValue(rawValue);
      } else if (rawValue.startsWith('[')) {
        result[key] = _recoverJsonStringArray(rawValue);
      }
    }

    return result;
  }

  String _recoverJsonStringValue(String rawValue) {
    final start = rawValue.indexOf('"');
    final end = rawValue.lastIndexOf('"');
    if (start < 0 || end <= start) return '';
    return rawValue
        .substring(start + 1, end)
        .replaceAll(r'\n', '\n')
        .replaceAll(r'\r', '\r');
  }

  List<String> _recoverJsonStringArray(String rawValue) {
    final items = <String>[];
    final pattern = RegExp(r'"((?:\\.|[^"\\])*)"', dotAll: true);
    for (final match in pattern.allMatches(rawValue)) {
      items
          .add(match.group(1)!.replaceAll(r'\n', '\n').replaceAll(r'\r', '\r'));
    }
    return items;
  }

  Map<String, dynamic> _normalizeParsedJsonStrings(Map<String, dynamic> map) {
    return map
        .map((key, value) => MapEntry(key, _normalizeParsedJsonValue(value)));
  }

  dynamic _normalizeParsedJsonValue(dynamic value) {
    if (value is String) return _normalizeLatexControlEscapes(value);
    if (value is List) return value.map(_normalizeParsedJsonValue).toList();
    if (value is Map) {
      return value
          .map((key, item) => MapEntry(key, _normalizeParsedJsonValue(item)));
    }
    return value;
  }

  String _normalizeLatexControlEscapes(String value) {
    return value
        .replaceAll(r'\\', r'\')
        .replaceAll('\b', r'\b')
        .replaceAll('\f', r'\f')
        .replaceAll('\t', r'\t');
  }

  String _repairInvalidJsonStringEscapes(String jsonStr) {
    final buffer = StringBuffer();
    var inString = false;
    var escapeRun = 0;

    for (var index = 0; index < jsonStr.length; index++) {
      final char = jsonStr[index];
      final escaped = escapeRun.isOdd;

      if (char == '"' && !escaped) {
        inString = !inString;
        buffer.write(char);
        escapeRun = 0;
        continue;
      }

      if (inString && (char == '\n' || char == '\r')) {
        buffer.write(char == '\n' ? r'\n' : r'\r');
        escapeRun = 0;
        continue;
      }

      if (char == r'\') {
        if (inString) {
          final next = index + 1 < jsonStr.length ? jsonStr[index + 1] : '';
          final nextNext = index + 2 < jsonStr.length ? jsonStr[index + 2] : '';
          if (next.isEmpty || !_isValidJsonEscape(next, nextNext)) {
            buffer.write(r'\\');
            escapeRun = 0;
            continue;
          }
        }

        buffer.write(char);
        escapeRun++;
        continue;
      }

      buffer.write(char);
      escapeRun = 0;
    }

    return buffer.toString();
  }

  bool _isValidJsonEscape(String next, String nextNext) {
    if ('"\\/u'.contains(next)) return true;
    return 'bfnrt'.contains(next) && !_isAsciiLetter(nextNext);
  }

  bool _isAsciiLetter(String value) {
    if (value.isEmpty) return false;
    final code = value.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  AiQuestionExtractionResult _parseExtractionResponse(String content) {
    final map = _parseResponseJson(content);
    final subject = _parseSubject((map['subject'] as String?) ?? '');
    final extractedQuestionText = _normalizeExtractedQuestionText(
      (map['extractedQuestionText'] as String?)?.trim() ?? '',
    );
    final normalizedQuestionText = _normalizeExtractedQuestionText(
      (map['normalizedQuestionText'] as String?)?.trim() ?? '',
    );
    final splitSeed = normalizedQuestionText.isNotEmpty
        ? normalizedQuestionText
        : extractedQuestionText;

    return AiQuestionExtractionResult(
      subject: subject,
      extractedQuestionText: extractedQuestionText,
      normalizedQuestionText: normalizedQuestionText,
      splitResult: _defaultSplitQuestionCandidates(splitSeed),
    );
  }

  AnalysisResult _parseAnalysisResponse(String content) {
    final map = _parseResponseJson(content);

    Subject? subject;
    final subjectStr = map['subject'] as String?;
    if (subjectStr != null && subjectStr.isNotEmpty) {
      debugPrint('[AiAnalysisService] AI returned subject: $subjectStr');
      subject = _parseSubject(subjectStr);
      debugPrint('[AiAnalysisService] Parsed subject: $subject');
    }

    return ParsedAnalysisResult(
      rawContent: content,
      subject: subject,
      finalAnswer: _normalizeExtractedQuestionText(
        map['finalAnswer'] as String? ?? '',
      ),
      steps: List<String>.from(map['steps'] as List? ?? <String>[])
          .map(_normalizeExtractedQuestionText)
          .toList(),
      aiTags: List<String>.from(map['aiTags'] as List? ?? <String>[]),
      knowledgePoints:
          List<String>.from(map['knowledgePoints'] as List? ?? <String>[])
              .map(_normalizeExtractedQuestionText)
              .toList(),
      mistakeReason: _normalizeExtractedQuestionText(
        map['mistakeReason'] as String? ?? '',
      ),
      studyAdvice: _normalizeExtractedQuestionText(
        map['studyAdvice'] as String? ?? '',
      ),
    );
  }

  @visibleForTesting
  AiQuestionExtractionResult parseExtractionResultForTest(String content) {
    return _parseExtractionResponse(content);
  }

  List<GeneratedExercise> extractGeneratedExercisesFromContent(
    String content, {
    required String questionId,
    AnalysisResult? analysis,
    String? sourceQuestionText,
  }) {
    final map = _parseResponseJson(content);
    return _parseGeneratedExercises(
      map,
      questionId: questionId,
      analysis: analysis,
      sourceQuestionText: sourceQuestionText,
    );
  }

  List<GeneratedExercise> extractGeneratedExercises(
    AnalysisResult analysis, {
    required String questionId,
    String? sourceQuestionText,
  }) {
    return _defaultGeneratedExercises(
      questionId,
      analysis: analysis,
      sourceQuestionText: sourceQuestionText,
    );
  }

  List<GeneratedExercise> _parseGeneratedExercises(
    Map<String, dynamic> map, {
    required String questionId,
    AnalysisResult? analysis,
    String? sourceQuestionText,
  }) {
    final rawExercises = map['generatedExercises'];
    if (rawExercises is! List || rawExercises.isEmpty) {
      return _defaultGeneratedExercises(
        questionId,
        analysis: analysis,
        sourceQuestionText: sourceQuestionText,
      );
    }

    final parsedAnalysis = analysis ?? _analysisFromParsedMap(map);
    final sourceProfile = _buildExerciseTopicProfile(
      sourceQuestionText: sourceQuestionText,
      analysis: parsedAnalysis,
    );
    final now = DateTime.now();
    final parsed = <GeneratedExercise>[];

    for (var index = 0; index < rawExercises.length; index++) {
      final item = rawExercises[index];
      if (item is! Map) continue;
      final exerciseMap = Map<String, dynamic>.from(item);
      final id = (exerciseMap['id'] as String?)?.trim();
      final question = _normalizeExtractedQuestionText(
        (exerciseMap['question'] as String?)?.trim() ?? '',
      );
      if (question.isEmpty) continue;

      List<String>? options;
      final rawOptions = exerciseMap['options'];
      if (rawOptions is List) {
        final normalizedOptions = rawOptions
            .map((option) => option?.toString().trim() ?? '')
            .where((option) => option.isNotEmpty)
            .map(_normalizeExtractedQuestionText)
            .toList();
        if (normalizedOptions.isNotEmpty) {
          options = normalizedOptions;
        }
      }

      final exercise = GeneratedExercise(
        id: id != null && id.isNotEmpty ? id : 'gen_${questionId}_${index + 1}',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: (exerciseMap['difficulty'] as String?)?.trim() ?? '同级',
        question: question,
        answer: _normalizeExtractedQuestionText(
          (exerciseMap['answer'] as String?)?.trim() ?? '',
        ),
        explanation: _normalizeExtractedQuestionText(
          (exerciseMap['explanation'] as String?)?.trim() ?? '',
        ),
        createdAt: now,
        order: index,
        options: options,
      );

      if (_isGeneratedExerciseAcceptable(exercise, sourceProfile)) {
        parsed.add(GeneratedExercise(
          id: exercise.id,
          questionId: exercise.questionId,
          generationMode: exercise.generationMode,
          difficulty: exercise.difficulty,
          question: exercise.question,
          answer: exercise.answer,
          explanation: exercise.explanation,
          createdAt: exercise.createdAt,
          order: parsed.length,
          options: exercise.options,
        ));
      }
    }

    final expectedCount = rawExercises.length >= 3 ? 3 : rawExercises.length;
    if (parsed.length < expectedCount) {
      return _defaultGeneratedExercises(
        questionId,
        analysis: parsedAnalysis,
        sourceQuestionText: sourceQuestionText,
      );
    }

    return parsed;
  }

  AnalysisResult _analysisFromParsedMap(Map<String, dynamic> map) {
    List<String> listField(String key) {
      final value = map[key];
      if (value is! List) return const <String>[];
      return value
          .map((item) => item?.toString().trim() ?? '')
          .where((item) => item.isNotEmpty)
          .toList();
    }

    return AnalysisResult(
      subject: _parseSubject(map['subject']?.toString() ?? ''),
      finalAnswer: map['finalAnswer']?.toString() ?? '',
      steps: listField('steps'),
      aiTags: listField('aiTags'),
      knowledgePoints: listField('knowledgePoints'),
      mistakeReason: map['mistakeReason']?.toString() ?? '',
      studyAdvice: map['studyAdvice']?.toString() ?? '',
    );
  }

  bool _isGeneratedExerciseAcceptable(
    GeneratedExercise exercise,
    _ExerciseTopicProfile sourceProfile,
  ) {
    if (exercise.question.trim().isEmpty ||
        exercise.answer.trim().isEmpty ||
        exercise.explanation.trim().isEmpty) {
      return false;
    }

    final normalizedAnswer = exercise.answer.trim().toUpperCase();
    if (!RegExp(r'^[A-D]$').hasMatch(normalizedAnswer)) return false;

    final options = exercise.options;
    if (options == null || options.length != 4) return false;
    final optionLetters = options
        .map((option) =>
            option.trim().isEmpty ? '' : option.trim()[0].toUpperCase())
        .toSet();
    if (!optionLetters.containsAll(const <String>{'A', 'B', 'C', 'D'})) {
      return false;
    }

    if (!sourceProfile.hasStrongSignal) return true;

    final exerciseText =
        '${exercise.question} ${exercise.explanation} ${options.join(' ')}';
    if (!_exerciseMatchesTopicAnchor(exerciseText, sourceProfile.topic)) {
      return false;
    }

    final exerciseProfile = _buildExerciseTopicProfile(
      sourceQuestionText: exerciseText,
      profileSource: _TopicProfileSource.exercise,
    );
    return exerciseProfile.topic == sourceProfile.topic;
  }

  bool _exerciseMatchesTopicAnchor(String text, _ExerciseTopic topic) {
    final normalized = text.toLowerCase();
    bool hasAny(Iterable<String> needles) => needles.any(normalized.contains);
    switch (topic) {
      case _ExerciseTopic.functionEvaluation:
        return _hasFunctionSignal(normalized) &&
            hasAny(
                <String>['求', '代入', '函数值', 'f(', 'g(', 'h(', 'f（', 'g（', 'h（']);
      case _ExerciseTopic.proportionalRelation:
        return _hasProportionalRelationSignal(normalized);
      case _ExerciseTopic.solidVolume:
        return _hasVolumeSignal(normalized);
      case _ExerciseTopic.equationSystem:
        return _hasEquationSystemSignal(normalized);
      case _ExerciseTopic.triangleAngle:
        return _hasTriangleSignal(normalized);
      case _ExerciseTopic.quadraticRoot:
        return _hasQuadraticRootSignal(normalized);
      case _ExerciseTopic.linearEquation:
        return _hasLinearEquationSignal(normalized);
      case _ExerciseTopic.generic:
        return true;
    }
  }

  _ExerciseTopicProfile _buildExerciseTopicProfile({
    String? sourceQuestionText,
    AnalysisResult? analysis,
    _TopicProfileSource profileSource = _TopicProfileSource.sourceQuestion,
  }) {
    final text = <String>[
      sourceQuestionText ?? '',
      ...?analysis?.aiTags,
      ...?analysis?.knowledgePoints,
      analysis?.finalAnswer ?? '',
      ...?analysis?.steps,
      analysis?.mistakeReason ?? '',
      analysis?.studyAdvice ?? '',
    ].join(' ').toLowerCase();

    final hasVolume = _hasVolumeSignal(text);
    final hasFunctionEvaluation = _hasFunctionEvaluationSignal(text);
    final hasProportionalRelation = _hasProportionalRelationSignal(text);
    final hasEquationSystem =
        !hasProportionalRelation && _hasEquationSystemSignal(text);
    final hasTriangle = _hasTriangleSignal(text);
    final hasQuadraticRoot = !hasVolume &&
        !hasFunctionEvaluation &&
        !hasProportionalRelation &&
        _hasQuadraticRootSignal(text, allowBareSquareSymbol: true);
    final hasLinearEquation = !hasQuadraticRoot &&
        !hasEquationSystem &&
        !hasFunctionEvaluation &&
        !hasProportionalRelation &&
        _hasLinearEquationSignal(text);

    if (hasVolume) {
      return const _ExerciseTopicProfile(_ExerciseTopic.solidVolume, true);
    }
    if (hasFunctionEvaluation) {
      return const _ExerciseTopicProfile(
          _ExerciseTopic.functionEvaluation, true);
    }
    if (hasProportionalRelation) {
      return const _ExerciseTopicProfile(
          _ExerciseTopic.proportionalRelation, true);
    }
    if (hasEquationSystem) {
      return const _ExerciseTopicProfile(_ExerciseTopic.equationSystem, true);
    }
    if (hasTriangle) {
      return const _ExerciseTopicProfile(_ExerciseTopic.triangleAngle, true);
    }
    if (hasQuadraticRoot) {
      return const _ExerciseTopicProfile(_ExerciseTopic.quadraticRoot, true);
    }
    if (hasLinearEquation) {
      final isStrong = profileSource == _TopicProfileSource.exercise;
      return _ExerciseTopicProfile(_ExerciseTopic.linearEquation, isStrong);
    }
    return const _ExerciseTopicProfile(_ExerciseTopic.generic, false);
  }

  bool _hasAnySignal(String text, Iterable<String> needles) {
    return needles.any(text.contains);
  }

  bool _hasSquareSymbol(String text) {
    return RegExp(r'(x|a|b|m|n|p|q|r|y)\s*(\^\{?2\}?|²)').hasMatch(text);
  }

  bool _hasEquationSystemSignal(String text) {
    return _hasAnySignal(
        text, <String>['方程组', '消元', 'begin{cases}', 'cases', '二元一次方程组']);
  }

  bool _hasProportionalRelationSignal(String text) {
    final hasRatioSignal = _hasAnySignal(text, <String>[
      '比例',
      '比值',
      '分式关系',
      '分数关系',
      '倍数关系',
      '成比例',
      'a:b',
      'm:n',
      'x:y',
      r'\frac',
    ]);
    if (!hasRatioSignal) return false;
    return _hasAnySignal(text, <String>[
      '和式',
      '差式',
      '和差',
      'a+b',
      'x+y',
      'm+n',
      'a-b',
      'x-y',
      'm-n',
      '求 a',
      '求a',
      '求 x',
      '求x',
      '求两个量',
      '代入法',
      '转化为',
    ]);
  }

  bool _hasTriangleSignal(String text) {
    return _hasAnySignal(
        text, <String>['三角', '等腰', '内角', '外角', '角形', r'\triangle', '△']);
  }

  bool _hasVolumeSignal(String text) {
    return _hasAnySignal(text, <String>[
      '体积',
      '立体几何',
      '圆柱',
      '圆锥',
      '底面半径',
      '高为',
      r'\frac{1}{3}\pi',
      'πr^2h',
      'π r^2 h'
    ]);
  }

  bool _hasFunctionSignal(String text) {
    return _hasAnySignal(text, <String>[
      'f(',
      'g(',
      'h(',
      'f（',
      'g（',
      'h（',
      r'f\left',
      r'g\left',
      r'h\left'
    ]);
  }

  bool _hasFunctionEvaluationSignal(String text) {
    return _hasAnySignal(text, <String>['函数值', '函数解析式', '代入函数', '自变量']) ||
        (_hasFunctionSignal(text) && _hasAnySignal(text, <String>['代入', '求']));
  }

  bool _hasQuadraticRootSignal(String text,
      {bool allowBareSquareSymbol = false}) {
    final hasRootLanguage = _hasAnySignal(
        text, <String>['平方根', '开平方', '一元二次', '二次方程', '正负根', r'\sqrt', r'\pm']);
    if (hasRootLanguage) return true;
    return allowBareSquareSymbol &&
        _hasSquareSymbol(text) &&
        _hasAnySignal(text, <String>['解方程', '求 x', '求x', 'x 的值', 'x的值']);
  }

  bool _hasLinearEquationSignal(String text) {
    return _hasAnySignal(text, <String>['一元一次', '移项', '解方程']);
  }

  Subject? _parseSubject(String input) {
    final lower = input.toLowerCase();

    for (final subject in Subject.values) {
      if (subject.label == input || subject.name == input) {
        return subject;
      }
    }

    if (lower.contains('物理') || lower == 'wuli' || lower == 'physics') {
      return Subject.physics;
    }
    if (lower.contains('语文') || lower == 'chinese') return Subject.chinese;
    if (lower.contains('英语') || lower.contains('english')) {
      return Subject.english;
    }
    if (lower.contains('化学') || lower == 'chemistry') return Subject.chemistry;
    if (lower.contains('生物') || lower == 'biology') return Subject.biology;
    if (lower.contains('历史') || lower == 'history') return Subject.history;
    if (lower.contains('地理') || lower == 'geography') return Subject.geography;
    if (lower.contains('政治') || lower == 'politics') return Subject.politics;
    if (lower.contains('科学') || lower == 'science') return Subject.science;
    if (lower.contains('数学') ||
        lower == 'math' ||
        lower.contains('mathematics')) {
      return Subject.math;
    }
    return null;
  }

  /// AI 判断用户答案是否正确
  Future<bool> judgeAnswer({
    required String question,
    required String userAnswer,
    required String correctAnswer,
    List<String>? options,
  }) async {
    debugPrint('[AiAnalysisService] judgeAnswer called');
    debugPrint('[AiAnalysisService] - question: $question');
    debugPrint('[AiAnalysisService] - userAnswer: $userAnswer');
    debugPrint('[AiAnalysisService] - correctAnswer: $correctAnswer');

    final config = await settingsRepository.getAiProviderConfig();

    if (config == null ||
        config.baseUrl.isEmpty ||
        config.apiKey.isEmpty ||
        config.model.isEmpty) {
      debugPrint('[AiAnalysisService] No config - using direct compare');
      return userAnswer == correctAnswer;
    }

    final dio = _createClient(config);
    final prompt =
        _buildJudgePrompt(question, userAnswer, correctAnswer, options);

    try {
      final response =
          await _retryPost(dio, '/chat/completions', data: <String, dynamic>{
        'model': config.model,
        'messages': <Map<String, String>>[
          <String, String>{
            'role': 'system',
            'content': '你是一个判断答案是否正确的助手。请仔细分析题目和答案，给出判断结果。'
          },
          <String, String>{'role': 'user', 'content': prompt},
        ],
        'temperature': 0.1,
        'max_tokens': 50,
      });

      final content =
          response.data['choices'][0]['message']['content'] as String;
      debugPrint('[AiAnalysisService] judgeAnswer response: $content');

      // 解析 AI 判断结果
      final lower = content.toLowerCase();
      if (lower.contains('正确') && !lower.contains('不正')) {
        return true;
      } else if (lower.contains('错误') || lower.contains('不对')) {
        return false;
      }

      // 默认回退到直接比较
      return userAnswer == correctAnswer;
    } catch (e) {
      debugPrint('[AiAnalysisService] judgeAnswer error: $e');
      // 回退到直接比较
      return userAnswer == correctAnswer;
    }
  }

  String _buildJudgePrompt(String question, String userAnswer,
      String correctAnswer, List<String>? options) {
    final buffer = StringBuffer();
    buffer.writeln('请判断以下答案是否正确：');
    buffer.writeln();
    buffer.writeln('题目：$question');
    if (options != null && options.isNotEmpty) {
      buffer.writeln('选项：');
      for (final option in options) {
        buffer.writeln(option);
      }
    }
    buffer.writeln();
    buffer.writeln('正确答案：$correctAnswer');
    buffer.writeln('用户答案：$userAnswer');
    buffer.writeln();
    buffer.writeln('请只回答"正确"或"错误"，不需要其他解释。');

    return buffer.toString();
  }

  List<GeneratedExercise> _defaultGeneratedExercises(
    String questionId, {
    AnalysisResult? analysis,
    String? sourceQuestionText,
  }) {
    final now = DateTime.now();
    final profile = _buildExerciseTopicProfile(
      sourceQuestionText: sourceQuestionText,
      analysis: analysis,
    );

    if (profile.topic == _ExerciseTopic.quadraticRoot) {
      return <GeneratedExercise>[
        GeneratedExercise(
          id: 'e1',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '简单',
          question: r'已知 \(x^2=9\)，求 \(x\) 的值。',
          options: const [
            r'A. \(x=3\)',
            r'B. \(x=-3\)',
            r'C. \(x=\pm 3\)',
            r'D. \(x=9\)',
          ],
          answer: 'C',
          explanation: r'一个数的平方等于 9，这个数可能是 3 或 -3，所以 \(x=\pm 3\)。',
          createdAt: now,
          order: 0,
        ),
        GeneratedExercise(
          id: 'e2',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '同级',
          question: r'已知 \(x^2+4=20\)，求 \(x\) 的值。',
          options: const [
            r'A. \(x=4\)',
            r'B. \(x=\pm 4\)',
            r'C. \(x=8\)',
            r'D. \(x=\pm 8\)',
          ],
          answer: 'B',
          explanation: r'两边同时减去 4，得 \(x^2=16\)，所以 \(x=\pm 4\)。',
          createdAt: now,
          order: 1,
        ),
        GeneratedExercise(
          id: 'e3',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '提高',
          question: r'已知 \((x-1)^2=25\)，求 \(x\) 的值。',
          options: const [
            r'A. \(x=6\) 或 \(x=-4\)',
            r'B. \(x=5\) 或 \(x=-5\)',
            r'C. \(x=4\) 或 \(x=-6\)',
            r'D. \(x=6\)',
          ],
          answer: 'A',
          explanation:
              r'由 \((x-1)^2=25\) 得 \(x-1=\pm 5\)，所以 \(x=6\) 或 \(x=-4\)。',
          createdAt: now,
          order: 2,
        ),
      ];
    }

    if (profile.topic == _ExerciseTopic.triangleAngle) {
      return <GeneratedExercise>[
        GeneratedExercise(
          id: 'e1',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '简单',
          question:
              r'在 \(\triangle ABC\) 中，若 \(\angle A=50^\circ\)，\(\angle B=60^\circ\)，则 \(\angle C\) 是多少？',
          options: const ['A. 60°', 'B. 70°', 'C. 80°', 'D. 90°'],
          answer: 'B',
          explanation:
              r'三角形内角和为 \(180^\circ\)，所以 \(\angle C=180^\circ-50^\circ-60^\circ=70^\circ\)。',
          createdAt: now,
          order: 0,
        ),
        GeneratedExercise(
          id: 'e2',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '同级',
          question:
              r'在等腰 \(\triangle ABC\) 中，\(AB=AC\)，若 \(\angle A=36^\circ\)，则 \(\angle B\) 是多少？',
          options: const ['A. 36°', 'B. 54°', 'C. 72°', 'D. 108°'],
          answer: 'C',
          explanation:
              r'\(AB=AC\)，所以底角 \(\angle B=\angle C\)；两个底角和为 \(144^\circ\)，所以 \(\angle B=72^\circ\)。',
          createdAt: now,
          order: 1,
        ),
        GeneratedExercise(
          id: 'e3',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '提高',
          question:
              r'\(\triangle ABC\) 的一个外角为 \(120^\circ\)，与它不相邻的一个内角为 \(45^\circ\)，则另一个不相邻内角是多少？',
          options: const ['A. 45°', 'B. 60°', 'C. 75°', 'D. 120°'],
          answer: 'C',
          explanation:
              r'三角形外角等于两个不相邻内角之和，所以另一个内角为 \(120^\circ-45^\circ=75^\circ\)。',
          createdAt: now,
          order: 2,
        ),
      ];
    }

    if (profile.topic == _ExerciseTopic.proportionalRelation) {
      return <GeneratedExercise>[
        GeneratedExercise(
          id: 'e1',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '简单',
          question: r'若 \(\frac{a}{b}=2\)，且 \(a+b=12\)，求 \(a\) 的值。',
          options: const ['A. 4', 'B. 6', 'C. 8', 'D. 10'],
          answer: 'C',
          explanation:
              r'由 \(\frac{a}{b}=2\) 得 \(a=2b\)，代入 \(a+b=12\) 得 \(3b=12\)，所以 \(b=4\)，\(a=8\)。',
          createdAt: now,
          order: 0,
        ),
        GeneratedExercise(
          id: 'e2',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '同级',
          question: r'若 \(m:n=3:2\)，且 \(m+n=25\)，求 \(m\) 的值。',
          options: const ['A. 10', 'B. 12', 'C. 15', 'D. 18'],
          answer: 'C',
          explanation:
              r'由 \(m:n=3:2\) 可设 \(m=3k\)，\(n=2k\)，代入 \(m+n=25\) 得 \(5k=25\)，所以 \(m=15\)。',
          createdAt: now,
          order: 1,
        ),
        GeneratedExercise(
          id: 'e3',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '提高',
          question: r'若 \(\frac{x}{y}=\frac{4}{3}\)，且 \(x-y=5\)，求 \(x\) 的值。',
          options: const ['A. 10', 'B. 15', 'C. 20', 'D. 25'],
          answer: 'C',
          explanation:
              r'由 \(\frac{x}{y}=\frac{4}{3}\) 可设 \(x=4k\)，\(y=3k\)，代入 \(x-y=5\) 得 \(k=5\)，所以 \(x=20\)。',
          createdAt: now,
          order: 2,
        ),
      ];
    }

    if (profile.topic == _ExerciseTopic.equationSystem) {
      return <GeneratedExercise>[
        GeneratedExercise(
          id: 'e1',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '简单',
          question: r'解方程组：\\begin{cases} x+y=7 \\ x-y=1 \\end{cases}，x 的值是多少？',
          options: const ['A. 2', 'B. 3', 'C. 4', 'D. 5'],
          answer: 'C',
          explanation: r'两式相加得 2x=8，所以 x=4。',
          createdAt: now,
          order: 0,
        ),
        GeneratedExercise(
          id: 'e2',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '同级',
          question:
              r'解方程组：\\begin{cases} 2x+y=8 \\ x+y=5 \\end{cases}，y 的值是多少？',
          options: const ['A. 1', 'B. 2', 'C. 3', 'D. 4'],
          answer: 'B',
          explanation: r'两式相减得 x=3，代入 x+y=5 得 y=2。',
          createdAt: now,
          order: 1,
        ),
        GeneratedExercise(
          id: 'e3',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '提高',
          question:
              r'解方程组：\\begin{cases} x+2y=11 \\ 3x-y=4 \\end{cases}，x+y 的值是多少？',
          options: const ['A. 6', 'B. 7', 'C. 8', 'D. 9'],
          answer: 'C',
          explanation: r'由 3x-y=4 得 y=3x-4，代入 x+2y=11 得 x=3，y=5，所以 x+y=8。',
          createdAt: now,
          order: 2,
        ),
      ];
    }

    if (profile.topic == _ExerciseTopic.solidVolume) {
      return <GeneratedExercise>[
        GeneratedExercise(
          id: 'e1',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '简单',
          question: r'圆锥底面半径为 \(r=2\)，高为 \(h=3\)，则体积 \(V\) 为',
          options: const [
            r'A. \(4\pi\)',
            r'B. \(8\pi\)',
            r'C. \(12\pi\)',
            r'D. \(6\pi\)',
          ],
          answer: 'A',
          explanation:
              r'\(V=\frac{1}{3}\pi r^2 h=\frac{1}{3}\pi \times 4 \times 3=4\pi\)',
          createdAt: now,
          order: 0,
        ),
        GeneratedExercise(
          id: 'e2',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '同级',
          question: r'圆柱底面半径为 \(r=3\)，高为 \(h=5\)，则圆柱体积为',
          options: const [
            r'A. \(15\pi\)',
            r'B. \(30\pi\)',
            r'C. \(45\pi\)',
            r'D. \(20\pi\)',
          ],
          answer: 'C',
          explanation: r'\(V=\pi r^2 h=\pi \times 9 \times 5=45\pi\)',
          createdAt: now,
          order: 1,
        ),
        GeneratedExercise(
          id: 'e3',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '提高',
          question: r'同底等高的圆锥和圆柱，圆柱体积是圆锥体积的几倍？',
          options: const ['A. 2倍', 'B. 3倍', 'C. 4倍', 'D. 1倍'],
          answer: 'B',
          explanation:
              r'圆锥体积 \(V_1=\frac{1}{3}\pi r^2 h\)，圆柱体积 \(V_2=\pi r^2 h\)，所以 \(V_2/V_1=3\)',
          createdAt: now,
          order: 2,
        ),
      ];
    }

    if (profile.topic == _ExerciseTopic.functionEvaluation) {
      return <GeneratedExercise>[
        GeneratedExercise(
          id: 'e1',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '简单',
          question: r'已知函数 \(f(x)=2x+1\)，求 \(f(3)\) 的值。',
          options: const ['A. 5', 'B. 6', 'C. 7', 'D. 8'],
          answer: 'C',
          explanation: r'把 \(x=3\) 代入，得 \(f(3)=2\times3+1=7\)。',
          createdAt: now,
          order: 0,
        ),
        GeneratedExercise(
          id: 'e2',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '同级',
          question: r'已知函数 \(g(x)=x^2-2x\)，求 \(g(4)\) 的值。',
          options: const ['A. 6', 'B. 8', 'C. 10', 'D. 12'],
          answer: 'B',
          explanation: r'把 \(x=4\) 代入，得 \(g(4)=4^2-2\times4=16-8=8\)。',
          createdAt: now,
          order: 1,
        ),
        GeneratedExercise(
          id: 'e3',
          questionId: questionId,
          generationMode: ExerciseGenerationMode.practice,
          difficulty: '提高',
          question: r'已知函数 \(h(x)=-x^2+3x+2\)，求 \(h(2)\) 的值。',
          options: const ['A. 2', 'B. 4', 'C. 6', 'D. 8'],
          answer: 'B',
          explanation: r'把 \(x=2\) 代入，得 \(h(2)=-4+6+2=4\)。',
          createdAt: now,
          order: 2,
        ),
      ];
    }

    return <GeneratedExercise>[
      GeneratedExercise(
        id: 'e1',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '简单',
        question: 'x+1=4，求 x 的值',
        options: const ['A. 2', 'B. 3', 'C. 4', 'D. 5'],
        answer: 'B',
        explanation: '移项得 x=4-1=3',
        createdAt: now,
        order: 0,
      ),
      GeneratedExercise(
        id: 'e2',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '同级',
        question: '2x=8，求 x 的值',
        options: const ['A. 2', 'B. 3', 'C. 4', 'D. 6'],
        answer: 'C',
        explanation: '两边同时除以 2 得 x=4',
        createdAt: now,
        order: 1,
      ),
      GeneratedExercise(
        id: 'e3',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: '提高',
        question: '3x+2=11，求 x 的值',
        options: const ['A. 2', 'B. 3', 'C. 4', 'D. 5'],
        answer: 'B',
        explanation: '先减 2 再除以 3: 3x=9, x=3',
        createdAt: now,
        order: 2,
      ),
    ];
  }

  AnalysisResult _fakeResult() {
    return const AnalysisResult(
      subject: Subject.math,
      finalAnswer: 'x = 3',
      steps: <String>['移项得到 x = 5 - 2', '计算得到 x = 3'],
      aiTags: <String>['一元一次方程', '移项', '方程'],
      knowledgePoints: <String>['一元一次方程的基本概念', '移项规则：将项从等式一边移到另一边时需要变号'],
      mistakeReason: '对移项规则不熟悉',
      studyAdvice: '先用简单方程练熟移项，再做文字题。',
    );
  }
}

class ParsedAnalysisResult extends AnalysisResult {
  const ParsedAnalysisResult({
    required super.finalAnswer,
    required super.steps,
    required super.aiTags,
    required super.knowledgePoints,
    required super.mistakeReason,
    required super.studyAdvice,
    required this.rawContent,
    super.subject,
  });

  final String rawContent;
}

class CandidateAnalysisPayload {
  const CandidateAnalysisPayload({
    required this.candidateId,
    required this.order,
    required this.questionText,
    required this.analysisResult,
    required this.savedExercises,
    this.subject,
    this.aiTags = const [],
    this.aiKnowledgePoints = const [],
    this.status = CandidateAnalysisStatus.success,
    this.errorMessage,
  });

  const CandidateAnalysisPayload.failed({
    required this.candidateId,
    required this.order,
    required this.questionText,
    required this.errorMessage,
  })  : analysisResult = null,
        savedExercises = const [],
        subject = null,
        aiTags = const [],
        aiKnowledgePoints = const [],
        status = CandidateAnalysisStatus.failed;

  final String candidateId;
  final int order;
  final String questionText;
  final AnalysisResult? analysisResult;
  final List<GeneratedExercise> savedExercises;
  final Subject? subject;
  final List<String> aiTags;
  final List<String> aiKnowledgePoints;
  final CandidateAnalysisStatus status;
  final String? errorMessage;

  bool get isSuccessful =>
      status == CandidateAnalysisStatus.success && analysisResult != null;
}

class _FakeAiAnalysisService extends AiAnalysisService {
  _FakeAiAnalysisService()
      : super(settingsRepository: InMemorySettingsRepository());

  @override
  Future<AiQuestionExtractionResult> extractQuestionStructure({
    required String subjectName,
    required String imagePath,
    String textHint = '',
  }) async {
    final normalized = textHint.isNotEmpty ? textHint : '示例题目文本';
    final splitResult = await splitQuestionCandidates(
        text: normalized, subjectName: subjectName);
    return AiQuestionExtractionResult(
      extractedQuestionText: normalized,
      normalizedQuestionText: normalized,
      subject: _parseSubject(subjectName) ?? Subject.math,
      splitResult: splitResult,
    );
  }

  @override
  Future<AnalysisResult> analyzeExtractedQuestion({
    required String correctedText,
    required String subjectName,
    String? imagePath,
  }) async {
    return _fakeResult();
  }

  @override
  Future<AnalysisResult> analyzeQuestion({
    required String correctedText,
    required String subjectName,
    String? imagePath,
  }) async {
    return _fakeResult();
  }

  @override
  Future<bool> judgeAnswer({
    required String question,
    required String userAnswer,
    required String correctAnswer,
    List<String>? options,
  }) async {
    return userAnswer == correctAnswer;
  }
}

class TestAiAnalysisService extends AiAnalysisService {
  TestAiAnalysisService({
    required super.settingsRepository,
    required this.extractionResult,
    required this.analysisResultValue,
    this.candidateAnalysisResults,
  });

  final AiQuestionExtractionResult extractionResult;
  final AnalysisResult analysisResultValue;
  final List<AnalysisResult>? candidateAnalysisResults;
  int extractionCallCount = 0;
  int analysisCallCount = 0;
  int analysisImageCallCount = 0;

  @override
  Future<AiQuestionExtractionResult> extractQuestionStructure({
    required String subjectName,
    required String imagePath,
    String textHint = '',
  }) async {
    extractionCallCount++;
    return extractionResult;
  }

  @override
  Future<AnalysisResult> analyzeExtractedQuestion({
    required String correctedText,
    required String subjectName,
    String? imagePath,
  }) async {
    analysisCallCount++;
    if (imagePath != null) analysisImageCallCount++;
    if (candidateAnalysisResults != null &&
        analysisCallCount <= candidateAnalysisResults!.length) {
      return candidateAnalysisResults![analysisCallCount - 1];
    }
    return analysisResultValue;
  }
}

class AiAnalysisException implements Exception {
  AiAnalysisException(this.message);
  final String message;
  @override
  String toString() => message;
}
