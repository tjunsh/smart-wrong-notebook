class AiPromptBuilder {
  String buildAnalysisPrompt({required String subjectName, required String correctedText}) {
    return '''请按 JSON 返回题目分析结果。
学科: $subjectName
题目: $correctedText
字段: finalAnswer, steps, knowledgePoints, mistakeReason, studyAdvice, generatedExercises
LaTeX 方程组或多行公式请使用 aligned/cases 环境，不要使用 \\newline。''';
  }
}
