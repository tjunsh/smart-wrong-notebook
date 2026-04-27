import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:smart_wrong_notebook/src/data/repositories/settings_repository.dart';
import 'package:smart_wrong_notebook/src/domain/models/ai_provider_config.dart';
import 'package:smart_wrong_notebook/src/domain/models/analysis_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/generated_exercise.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_split_result.dart';
import 'package:smart_wrong_notebook/src/domain/models/subject.dart';

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
        debugPrint('[AiAnalysisService] 请求失败，${delayMs}ms 后重试 (第 $attempt 次)...');
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
        if (config.apiKey.isNotEmpty) 'Authorization': 'Bearer ${config.apiKey}',
      },
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 180),
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
              {'parts': [{'text': 'Hi'}]},
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
      debugPrint('[AiAnalysisService] testConnection DioException: type=${e.type}, message=${e.message}');
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
    debugPrint('[AiAnalysisService] - correctedText: ${correctedText.isNotEmpty ? "provided (${correctedText.length} chars)" : "empty"}');
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
    QuestionSplitResult Function(String text)? fallbackSplit,
  }) async {
    final splitter = fallbackSplit ?? _defaultSplitQuestionCandidates;
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
    final content = await _requestAiContentWithImage(
      config: config,
      systemPrompt: await _loadExtractionSystemPrompt(),
      prompt: _buildExtractionPrompt(subjectName: subjectName, textHint: textHint),
      imageBytes: imageBytes,
    );

    final extraction = _parseExtractionResponse(content);
    final splitSeed = extraction.normalizedQuestionText.isNotEmpty
        ? extraction.normalizedQuestionText
        : extraction.extractedQuestionText;
    final splitResult = await splitQuestionCandidates(text: splitSeed);

    return AiQuestionExtractionResult(
      extractedQuestionText: extraction.extractedQuestionText,
      normalizedQuestionText: extraction.normalizedQuestionText,
      subject: extraction.subject,
      splitResult: splitResult,
    );
  }

  Future<List<CandidateAnalysisPayload>> analyzeSplitCandidates({
    required String questionId,
    required String subjectName,
    required QuestionSplitResult splitResult,
    String? imagePath,
  }) async {
    final payloads = <CandidateAnalysisPayload>[];
    for (final candidate in splitResult.candidates) {
      final analysis = await analyzeExtractedQuestion(
        correctedText: candidate.text,
        subjectName: subjectName,
        imagePath: imagePath,
      );
      final exercises = analysis is ParsedAnalysisResult
          ? extractGeneratedExercisesFromContent(
              analysis.rawContent,
              questionId: '$questionId-${candidate.order}',
            )
          : extractGeneratedExercises(
              analysis,
              questionId: '$questionId-${candidate.order}',
            );
      payloads.add(CandidateAnalysisPayload(
        candidateId: candidate.id,
        order: candidate.order,
        questionText: candidate.text,
        analysisResult: analysis,
        savedExercises: exercises,
        subject: analysis.subject,
        aiTags: analysis.aiTags,
        aiKnowledgePoints: analysis.knowledgePoints,
      ));
    }
    return payloads;
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
      if (imagePath != null && File(imagePath).existsSync()) {
        final imageBytes = await File(imagePath).readAsBytes();
        final content = await _requestAiContentWithImage(
          config: config,
          systemPrompt: systemPrompt,
          prompt: prompt,
          imageBytes: imageBytes,
        );
        return _parseAnalysisResponse(content);
      }

      final content = await _requestAiContent(
        config: config,
        systemPrompt: systemPrompt,
        prompt: prompt,
      );
      return _parseAnalysisResponse(content);
    } on DioException catch (e) {
      debugPrint('[AiAnalysisService] DioException: type=${e.type}, message=${e.message}, status=${e.response?.statusCode}');
      throw AiAnalysisException(_dioErrorMessage(e));
    } catch (e) {
      debugPrint('[AiAnalysisService] Exception: $e');
      throw AiAnalysisException('AI 解析失败: $e');
    }
  }

  Future<AiProviderConfig> _requireConfig() async {
    final config = await settingsRepository.getAiProviderConfig();

    debugPrint('[AiAnalysisService] config: ${config != null ? "loaded" : "null"}');
    if (config != null) {
      debugPrint('[AiAnalysisService] - baseUrl: ${config.baseUrl}');
      debugPrint('[AiAnalysisService] - model: ${config.model}');
      debugPrint('[AiAnalysisService] - apiKey length: ${config.apiKey.length}');
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
          buffer.write(': ${body.length > 100 ? '${body.substring(0, 100)}...' : body}');
        }
      } else if (e.message != null) {
        buffer.write(': ${e.message}');
      }
    } else if (e.message != null) {
      buffer.write(': ${e.message}');
    }
    return buffer.toString();
  }

  QuestionSplitResult _defaultSplitQuestionCandidates(String text) {
    final normalized = text.replaceAll('\r\n', '\n').trim();
    if (normalized.isEmpty) {
      return const QuestionSplitResult(
        sourceText: '',
        candidates: <QuestionSplitCandidate>[],
        strategy: QuestionSplitStrategy.fallback,
      );
    }

    final numberedSegments = _splitByNumberedQuestions(normalized);
    if (numberedSegments.length >= 2) {
      return QuestionSplitResult(
        sourceText: normalized,
        candidates: _buildSplitCandidates(numberedSegments, QuestionSplitStrategy.numbered),
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
        candidates: _buildSplitCandidates(paragraphSegments, QuestionSplitStrategy.paragraph),
        strategy: QuestionSplitStrategy.paragraph,
      );
    }

    return QuestionSplitResult(
      sourceText: normalized,
      candidates: _buildSplitCandidates(<String>[normalized], QuestionSplitStrategy.fallback),
      strategy: QuestionSplitStrategy.fallback,
    );
  }

  List<QuestionSplitCandidate> _buildSplitCandidates(List<String> segments, QuestionSplitStrategy strategy) {
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
    final matches = RegExp(r'(^|\n)\s*(?:第\s*\d+\s*题|\d+[\.、．)])\s*', multiLine: true).allMatches(text).toList();
    if (matches.length < 2) return const <String>[];

    final segments = <String>[];
    for (var index = 0; index < matches.length; index++) {
      final current = matches[index];
      final start = current.start + (current.group(1)?.length ?? 0);
      final end = index + 1 < matches.length ? matches[index + 1].start : text.length;
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
  }) async {
    final dio = _createClient(config);
    final response = await _retryPost(dio, '/chat/completions', data: <String, dynamic>{
      'model': config.model,
      'messages': <Map<String, String>>[
        <String, String>{'role': 'system', 'content': systemPrompt},
        <String, String>{'role': 'user', 'content': prompt},
      ],
      'temperature': 0.7,
      'max_tokens': 2000,
    });

    return response.data['choices'][0]['message']['content'] as String;
  }

  Future<String> _requestAiContentWithImage({
    required AiProviderConfig config,
    required String systemPrompt,
    required String prompt,
    required Uint8List imageBytes,
  }) async {
    final dio = _createClient(config);
    final base64Image = base64Encode(imageBytes);
    const mimeType = 'image/jpeg';
    final baseUrl = config.baseUrl.toLowerCase();
    final model = config.model.toLowerCase();

    if (baseUrl.contains('openrouter') ||
        model.contains('gpt') ||
        model.contains('4o') ||
        model.contains('4-turbo')) {
      final response = await _retryPost(dio, '/chat/completions', data: <String, dynamic>{
        'model': config.model,
        'messages': <Map<String, dynamic>>[
          {'role': 'system', 'content': systemPrompt},
          {
            'role': 'user',
            'content': [
              {
                'type': 'image_url',
                'image_url': {'url': 'data:$mimeType;base64,$base64Image', 'detail': 'high'},
              },
              {'type': 'text', 'text': prompt},
            ],
          },
        ],
        'temperature': 0.7,
        'max_tokens': 2000,
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
                {'inlineData': {'mimeType': mimeType, 'data': base64Image}},
              ],
            },
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 2000,
          },
        },
      );
      return response.data['candidates'][0]['content']['parts'][0]['text'] as String;
    }

    final response = await _retryPost(dio, '/chat/completions', data: <String, dynamic>{
      'model': config.model,
      'messages': <Map<String, dynamic>>[
        {'role': 'system', 'content': systemPrompt},
        {
          'role': 'user',
          'content': [
            {
              'type': 'image_url',
              'image_url': {'url': 'data:$mimeType;base64,$base64Image', 'detail': 'high'},
            },
            {'type': 'text', 'text': prompt},
          ],
        },
      ],
      'temperature': 0.7,
      'max_tokens': 2000,
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
- 练习题必须是选择题格式，包含 A/B/C/D 四个选项，其中一个是正确答案
- 答案字段填写正确选项的字母（如 "A"）
- aiTags 要求简短精炼（2-8个字），数量 2-4 个，如 ["压强", "力学", "公式"]
- knowledgePoints 可以详细描述，长度不限，如 ["压强公式p=f/s，压强与压力的关系", "受力面积相同时，压力越大压强越大"]

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

  static const _defaultExtractionSystemPrompt = '''你是一个专业的教辅录入员，负责把题目图片整理成可存储、可检索的结构化文本。

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
    final custom = await settingsRepository.getString('extraction_system_prompt');
    return custom?.isNotEmpty == true ? custom! : _defaultExtractionSystemPrompt;
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
    buffer.writeln('请输出 subject、extractedQuestionText、normalizedQuestionText。');
    return buffer.toString();
  }

  String _buildAnalysisPrompt(String correctedText, String subjectName) {
    final buffer = StringBuffer();
    buffer.writeln('请分析以下$subjectName科目的错题：');
    buffer.writeln();
    buffer.writeln('已确认题目文本：');
    buffer.writeln(correctedText);
    buffer.writeln();
    buffer.writeln('请以 JSON 格式返回完整的分析结果，包含 subject、finalAnswer、steps、aiTags、knowledgePoints、mistakeReason、studyAdvice、generatedExercises 字段。');
    return buffer.toString();
  }


  Map<String, dynamic> _parseResponseJson(String content) {
    debugPrint('[AiAnalysisService] Raw AI response: $content');

    String jsonStr = content.trim();
    if (jsonStr.startsWith('```')) {
      jsonStr = jsonStr
          .replaceFirst(RegExp(r'^```\w*\n?'), '')
          .replaceFirst(RegExp(r'\n?```$'), '');
    }

    try {
      final map = jsonDecode(jsonStr) as Map<String, dynamic>;
      debugPrint('[AiAnalysisService] Parsed JSON keys: ${map.keys.toList()}');
      return map;
    } catch (e) {
      debugPrint('[AiAnalysisService] Parse error: $e');
      throw AiAnalysisException('解析 AI 响应失败: $e');
    }
  }

  AiQuestionExtractionResult _parseExtractionResponse(String content) {
    final map = _parseResponseJson(content);
    final subject = _parseSubject((map['subject'] as String?) ?? '');
    final extractedQuestionText = (map['extractedQuestionText'] as String?)?.trim() ?? '';
    final normalizedQuestionText = (map['normalizedQuestionText'] as String?)?.trim() ?? '';
    final splitSeed = normalizedQuestionText.isNotEmpty ? normalizedQuestionText : extractedQuestionText;

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
      finalAnswer: map['finalAnswer'] as String? ?? '',
      steps: List<String>.from(map['steps'] as List? ?? <String>[]),
      aiTags: List<String>.from(map['aiTags'] as List? ?? <String>[]),
      knowledgePoints: List<String>.from(map['knowledgePoints'] as List? ?? <String>[]),
      mistakeReason: map['mistakeReason'] as String? ?? '',
      studyAdvice: map['studyAdvice'] as String? ?? '',
    );
  }

  @visibleForTesting
  AiQuestionExtractionResult parseExtractionResultForTest(String content) {
    return _parseExtractionResponse(content);
  }

  List<GeneratedExercise> extractGeneratedExercisesFromContent(
    String content, {
    required String questionId,
  }) {
    final map = _parseResponseJson(content);
    return _parseGeneratedExercises(map, questionId: questionId);
  }

  List<GeneratedExercise> extractGeneratedExercises(
    AnalysisResult analysis, {
    required String questionId,
  }) {
    return _defaultGeneratedExercises(questionId);
  }

  List<GeneratedExercise> _parseGeneratedExercises(
    Map<String, dynamic> map, {
    required String questionId,
  }) {
    final rawExercises = map['generatedExercises'];
    if (rawExercises is! List || rawExercises.isEmpty) {
      return _defaultGeneratedExercises(questionId);
    }

    final now = DateTime.now();
    final parsed = <GeneratedExercise>[];

    for (var index = 0; index < rawExercises.length; index++) {
      final item = rawExercises[index];
      if (item is! Map) continue;
      final exerciseMap = Map<String, dynamic>.from(item);
      final id = (exerciseMap['id'] as String?)?.trim();
      final question = (exerciseMap['question'] as String?)?.trim() ?? '';
      if (question.isEmpty) continue;

      List<String>? options;
      final rawOptions = exerciseMap['options'];
      if (rawOptions is List) {
        final normalizedOptions = rawOptions
            .map((option) => option?.toString().trim() ?? '')
            .where((option) => option.isNotEmpty)
            .toList();
        if (normalizedOptions.isNotEmpty) {
          options = normalizedOptions;
        }
      }

      parsed.add(GeneratedExercise(
        id: id != null && id.isNotEmpty ? id : 'gen_${questionId}_${index + 1}',
        questionId: questionId,
        generationMode: ExerciseGenerationMode.practice,
        difficulty: (exerciseMap['difficulty'] as String?)?.trim() ?? '同级',
        question: question,
        answer: (exerciseMap['answer'] as String?)?.trim() ?? '',
        explanation: (exerciseMap['explanation'] as String?)?.trim() ?? '',
        createdAt: now,
        order: index,
        options: options,
      ));
    }

    if (parsed.isEmpty) {
      return _defaultGeneratedExercises(questionId);
    }

    return parsed;
  }

  Subject? _parseSubject(String input) {
    final lower = input.toLowerCase();

    for (final subject in Subject.values) {
      if (subject.label == input || subject.name == input) {
        return subject;
      }
    }

    if (lower.contains('物理') || lower == 'wuli' || lower == 'physics') return Subject.physics;
    if (lower.contains('语文') || lower == 'chinese') return Subject.chinese;
    if (lower.contains('英语') || lower.contains('english')) return Subject.english;
    if (lower.contains('化学') || lower == 'chemistry') return Subject.chemistry;
    if (lower.contains('生物') || lower == 'biology') return Subject.biology;
    if (lower.contains('历史') || lower == 'history') return Subject.history;
    if (lower.contains('地理') || lower == 'geography') return Subject.geography;
    if (lower.contains('政治') || lower == 'politics') return Subject.politics;
    if (lower.contains('科学') || lower == 'science') return Subject.science;
    if (lower.contains('数学') || lower == 'math' || lower.contains('mathematics')) return Subject.math;
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
    final prompt = _buildJudgePrompt(question, userAnswer, correctAnswer, options);

    try {
      final response = await _retryPost(dio, '/chat/completions', data: <String, dynamic>{
      'model': config.model,
      'messages': <Map<String, String>>[
        <String, String>{'role': 'system', 'content': '你是一个判断答案是否正确的助手。请仔细分析题目和答案，给出判断结果。'},
        <String, String>{'role': 'user', 'content': prompt},
      ],
      'temperature': 0.1,
      'max_tokens': 50,
    });

      final content = response.data['choices'][0]['message']['content'] as String;
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

  String _buildJudgePrompt(String question, String userAnswer, String correctAnswer, List<String>? options) {
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

  List<GeneratedExercise> _defaultGeneratedExercises(String questionId) {
    final now = DateTime.now();
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
  });

  final String candidateId;
  final int order;
  final String questionText;
  final AnalysisResult analysisResult;
  final List<GeneratedExercise> savedExercises;
  final Subject? subject;
  final List<String> aiTags;
  final List<String> aiKnowledgePoints;
}

class _FakeAiAnalysisService extends AiAnalysisService {
  _FakeAiAnalysisService() : super(settingsRepository: InMemorySettingsRepository());

  @override
  Future<AiQuestionExtractionResult> extractQuestionStructure({
    required String subjectName,
    required String imagePath,
    String textHint = '',
  }) async {
    final normalized = textHint.isNotEmpty ? textHint : '示例题目文本';
    final splitResult = await splitQuestionCandidates(text: normalized);
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
    if (candidateAnalysisResults != null && analysisCallCount <= candidateAnalysisResults!.length) {
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