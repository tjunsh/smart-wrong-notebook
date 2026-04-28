# Progress — AI错题本

## Done
- LaTeX 渲染两大 bug 已修复并通过测试验证（v43 已打包）：
  - **方程组**：根因是 `_supportedLatexCommands` 缺少 `begin`/`end`，导致 `_normalizeMathExpression` 把 `\begin{cases}` 的反斜杠剥掉。已修复。
  - **三角形**：根因是 `_normalizeDisplayText` 中 raw string `r'\\triangle'` 产生双反斜杠，以及 `tri∠` 替换只 lookahead 不消费 `∠`。已修复。
  - 方程组正则已放宽，支持带系数方程（`2x + 3y = 8`）和换行分隔。
  - 拆题预览 MathContentView 已加 `contentFormat: latexMixed`。
  - 新增 4 个 widget test 覆盖上述场景。
- 多题分析性能优化已完成：
  - `analyzeSplitCandidates` 从串行改为 `Future.wait` 并行，3 道题分析时间从 ~45-90s 降到 ~15-30s。
  - 删除 `extractQuestionStructure` 中冗余的 `_normalizeExtractedQuestionText` 二次调用和废弃的 `_normalizeSplitResult` 方法。
  - Loading 页面多题场景显示 "正在并行分析 N 道题..." / "已完成 X/N 题分析..." 实时进度。
- 全量 118 个测试通过。
- 已产出 APK：`ai-wrong-notebook-v43-20260428-2033.apk`。

## Blockers
- v43 真机测试时 AI 解析连续失败（"AI 服务请求失败"），API 端点 `vbcode.io/v1` 可达但返回错误。用户确认之前偶尔也会失败，本次连续失败可能是服务端问题。需要真机重试确认是否恢复。
- LaTeX 修复和并行优化的代码改动尚未 commit（工作区有 26 个文件改动）。

## Next First Step
- 真机安装 v43 重试 AI 解析，确认 API 是否恢复正常。
- 如果 API 恢复，验证方程组和三角形的 LaTeX 渲染是否正确。
- 确认无误后做 WIP commit，文件范围需用户确认。
