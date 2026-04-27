import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:smart_wrong_notebook/src/app/providers.dart';
import 'package:smart_wrong_notebook/src/data/remote/ai/ai_analysis_service.dart';
import 'package:smart_wrong_notebook/src/domain/models/content_status.dart';
import 'package:smart_wrong_notebook/src/domain/models/question_record.dart';

class AnalysisLoadingScreen extends ConsumerStatefulWidget {
  const AnalysisLoadingScreen({super.key});

  @override
  ConsumerState<AnalysisLoadingScreen> createState() => _AnalysisLoadingScreenState();
}

class _AnalysisLoadingScreenState extends ConsumerState<AnalysisLoadingScreen> {
  String? _errorMessage;
  String? _debugInfo;
  int _step = 0;
  Timer? _stepTimer;

  final _steps = const ['正在提取题目...', '正在确认内容...', '正在学习分析...', '即将完成...'];

  @override
  void initState() {
    super.initState();
    _runAnalysis();
    _animateSteps();
  }

  void _animateSteps() {
    _stepTimer?.cancel();
    _stepTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_step < _steps.length - 1) {
        setState(() => _step++);
      } else {
        timer.cancel();
      }
    });
  }

  @override
  void dispose() {
    _stepTimer?.cancel();
    super.dispose();
  }

  Future<void> _runAnalysis() async {
    final current = ref.read(currentQuestionProvider);
    if (current == null) {
      if (mounted) context.go('/');
      return;
    }

    // 检查配置并显示调试信息
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final config = await settingsRepo.getAiProviderConfig();

    String debugInfo = '配置状态:\n';
    debugInfo += '- 配置对象: ${config != null ? "存在" : "为空"}\n';
    if (config != null) {
      debugInfo += '- baseUrl: ${config.baseUrl.isNotEmpty ? config.baseUrl : "(空)"}\n';
      debugInfo += '- model: ${config.model.isNotEmpty ? config.model : "(空)"}\n';
      debugInfo += '- apiKey: ${config.apiKey.isNotEmpty ? "[已设置(${config.apiKey.length}字符)]" : "(空)"}\n';
    } else {
      debugInfo += '\n请到设置中配置 AI 服务';
    }

    setState(() => _debugInfo = debugInfo);

    try {
      final service = ref.read(aiAnalysisServiceProvider);

      var working = current;
      if (working.normalizedQuestionText.isEmpty) {
        final extraction = await service.extractQuestionStructure(
          subjectName: working.subject.name,
          imagePath: working.imagePath,
          textHint: working.extractedQuestionText,
        );
        working = working.copyWith(
          extractedQuestionText: extraction.extractedQuestionText,
          normalizedQuestionText: extraction.normalizedQuestionText.isNotEmpty
              ? extraction.normalizedQuestionText
              : extraction.extractedQuestionText,
          subject: extraction.subject ?? working.subject,
          splitResult: extraction.splitResult,
        );
        ref.read(currentQuestionProvider.notifier).state = working;
      }

      final candidateSnapshots = working.splitResult != null && working.splitResult!.hasMultipleCandidates
          ? await service.analyzeSplitCandidates(
              questionId: working.id,
              subjectName: working.subject.name,
              splitResult: working.splitResult!,
              imagePath: working.imagePath,
            )
          : const <CandidateAnalysisPayload>[];

      final analysis = candidateSnapshots.isNotEmpty
          ? candidateSnapshots.first.analysisResult
          : await service.analyzeExtractedQuestion(
              correctedText: working.correctedText,
              subjectName: working.subject.name,
              imagePath: working.imagePath,
            );

      final generatedExercises = candidateSnapshots.isNotEmpty
          ? candidateSnapshots.first.savedExercises
          : analysis is ParsedAnalysisResult
              ? service.extractGeneratedExercisesFromContent(
                  analysis.rawContent,
                  questionId: working.id,
                )
              : service.extractGeneratedExercises(
                  analysis,
                  questionId: working.id,
                );

      final updated = working.copyWith(
        contentStatus: ContentStatus.ready,
        analysisResult: analysis,
        savedExercises: generatedExercises,
        subject: analysis.subject ?? working.subject,
        aiTags: analysis.aiTags,
        aiKnowledgePoints: analysis.knowledgePoints,
        candidateAnalyses: candidateSnapshots.map((payload) {
          return CandidateAnalysisSnapshot(
            candidateId: payload.candidateId,
            order: payload.order,
            questionText: payload.questionText,
            analysisResult: payload.analysisResult,
            savedExercises: payload.savedExercises,
            subject: payload.subject,
            aiTags: payload.aiTags,
            aiKnowledgePoints: payload.aiKnowledgePoints,
          );
        }).toList(),
      );
      ref.read(currentQuestionProvider.notifier).state = updated;

      if (mounted) {
        _stepTimer?.cancel();
        context.go('/analysis/result');
      }
    } on AiAnalysisException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _debugInfo = debugInfo;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('AI 解析'),
        leading: IconButton(
          icon: const Icon(CupertinoIcons.chevron_left),
          onPressed: () => context.go('/capture/ocr-confirmation'),
        ),
      ),
      body: _errorMessage != null
          ? _buildErrorView()
          : _LoadingView(step: _step, steps: _steps),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 64, height: 64,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF7ED),
                borderRadius: BorderRadius.circular(32),
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_circle,
                color: Color(0xFFEA580C),
                size: 32,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Color(0xFF9A3412)),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text('调试信息:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                  const SizedBox(height: 8),
                  Text(_debugInfo ?? '', style: const TextStyle(fontSize: 11, fontFamily: 'monospace')),
                ],
              ),
            ),
            const SizedBox(height: 20),
            FilledButton(
              onPressed: () {
                setState(() {
                  _errorMessage = null;
                  _step = 0;
                });
                _runAnalysis();
                _animateSteps();
              },
              style: FilledButton.styleFrom(minimumSize: const Size(120, 40)),
              child: const Text('重试'),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadingView extends StatefulWidget {
  const _LoadingView({required this.step, required this.steps});

  final int step;
  final List<String> steps;

  @override
  State<_LoadingView> createState() => _LoadingViewState();
}

class _LoadingViewState extends State<_LoadingView> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              width: 88, height: 88,
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(44),
              ),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (_, __) => Transform.rotate(
                  angle: _controller.value * 2 * 3.14159,
                  child: const Icon(CupertinoIcons.smiley, size: 44, color: Color(0xFF6366F1)),
                ),
              ),
            ),
            const SizedBox(height: 28),
            const CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF6366F1),
            ),
            const SizedBox(height: 28),
            Text(
              widget.steps[widget.step],
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 8),
            Text(
              'AI 正在生成学习分析，请稍候...',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
