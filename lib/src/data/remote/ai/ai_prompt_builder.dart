class AiPromptBuilder {
  String buildAnalysisPrompt({required String subjectName, required String correctedText}) {
    return '''请按 JSON 返回题目分析结果。
学科: $subjectName
题目: $correctedText
字段: finalAnswer, steps, knowledgePoints, mistakeReason, studyAdvice, generatedExercises''';
  }
}
