#2026-05-04 Park / 工作进度

## Done

###1. 举一反三题型漂移修复
- 修复二次方程/平方根题被兜底成一元一次题的问题。
- 增加主干题型锚点，举一反三生成、校验、兜底都复用同一个主干题型判断。
- 增加函数求值、立体几何体积、方程组、三角形角度等强题型校验，避免被 `x^2`、`r^2` 等弱符号误判成平方根题。
- 新增分式/比例关系题型锚点，修复 `\(\frac{a}{b}=2\)` + 和差条件漂移到平方根/方程组的问题。
- 修复三角形兜底练习角度 LaTeX：改成 `\(\angle A=50^\circ\)`这种 inline math，未修改 LaTeX 渲染引擎。

###2. 多题保存交互完成
- 多题确认页已简化为：勾选题目 + 全选 / 清空 + `保存已勾选题目 (N)`。
-0题勾选时保存按钮禁用，并显示“请至少勾选一道题后再保存”。
- 保存后保留子题独立数据：解析、AI 标签、知识点、举一反三、父题/根题/拆题顺序。

###3. 多轮举一反三 + 保存分流完成
- 举一反三完成一轮后展示完成页，不再直接跳走。
- 完成页动作按来源区分：
 - AI解析未保存题：`保存这道题`
 - 错题本已保存题：`返回错题详情`
 - 两者都支持 `继续练习`
- `继续练习` 会开启下一轮，并保留上一轮答题结果。
- 已保存题从错题本练习时，轮次结果写回题目记录。
- AI解析未保存题练习时，轮次结果先留在当前分析会话；保存时再进入多题保存确认页。
- 多题场景下，`保存这道题` 默认只勾选当前子题，用户仍可全选或调整勾选。
- `GeneratedExercise` 增加轻量轮次字段：`roundIndex`、`roundTotal`、`roundGroupId`、`sourceExerciseId`。
- Drift 数据库升级到 schemaVersion4，新增练习轮次字段迁移。

###4. 多题解析串题修复
- 修复多题保存时子题缺少独立 `CandidateAnalysisSnapshot` 会继承父题/第1题 `analysisResult`、AI 标签、知识点的问题。
- 修复多题 AI解析结果页显示兜底：多题模式下当前子题没有独立解析时显示“暂无解析结果”，不再展示父题/第1题答案和练习。
- 增加回归测试覆盖：保存链路不串题、解析页缺失快照不串题、六题样例第4/6题独立解析不串题。
- 已按要求未修改 LaTeX 渲染引擎文件：`math_content_view.dart`、`katex_math_view.dart`、`assets/katex/*`。

###5. 多题部分解析失败补丁
- 针对真机 JSON里第2/4/5/6题出现 `analysisResult: null`、空标签、空知识点的问题，补齐 AI 多题分析失败处理。
- `analyzeSplitCandidates()` 从无限并发 `Future.wait` 改为并发上限2。
- 每道子题解析失败后自动重试1 次。
- 如果仍有任意子题失败，直接抛出明确错误：第几题解析失败，请重试；不会进入可保存的半成品结果态。
- 不再用父题/第1题兜底，也不允许空解析子题被保存进题库。
- 新增测试模拟第2题解析失败，确认不会进入结果页、不会产生 partial `candidateAnalyses`、不会写入空解析。

###6. 下一阶段 AI 链路方案已写入记忆
- 已新增 memory：`ai_capture_provider_next_phase.md`。
- `MEMORY.md` 已加索引：`AI错题本下一阶段 AI 链路`。
-记忆内容覆盖：拍照/框选/拆题/分析提效、并发上限、失败重试、provider 模板、单 active provider、多 provider 后续演进。
-该方案暂不硬塞进当前 v60，回来后再决定是否做低感知重构或完整 P1 改造。

###7. APK 打包
- 最新补丁 APK：
 - `build/app/outputs/flutter-apk/ai-wrong-notebook-v60-20260504-1610.apk`
- 上一个 APK：
 - `build/app/outputs/flutter-apk/ai-wrong-notebook-v60-20260504-1530.apk`
- 不再建议验证旧 APK：
 - `build/app/outputs/flutter-apk/ai-wrong-notebook-v60-20260504-1443.apk`
- 小改动未递增小版本号，只更新时间戳。

## Verification

- `dart format lib/src/app/providers.dart lib/src/features/analysis/presentation/analysis_result_screen.dart test/app/providers_test.dart test/features/analysis/analysis_result_screen_test.dart`：通过，已格式化。
- `dart format lib/src/data/remote/ai/ai_analysis_service.dart test/features/analysis/analysis_loading_screen_test.dart`：通过，已格式化。
- `flutter pub run build_runner build --delete-conflicting-outputs`：通过，已重新生成 Drift代码。
- `flutter test test/data/remote/ai_analysis_service_test.dart`：通过，22/22。
- `flutter test test/features/analysis/exercise_practice_test.dart`：通过，4/4。
- `flutter test test/features/ocr/question_split_confirmation_screen_test.dart test/app/providers_test.dart`：通过，12/12。
- `flutter test test/features/analysis/exercise_practice_test.dart test/features/ocr/question_split_confirmation_screen_test.dart test/app/providers_test.dart`：通过，16/16。
- `flutter test test/features/analysis/analysis_loading_screen_test.dart`：通过，11/11。
- `flutter test test/app/providers_test.dart test/features/analysis/analysis_loading_screen_test.dart test/features/analysis/analysis_result_screen_test.dart test/features/ocr/question_split_confirmation_screen_test.dart test/features/analysis/exercise_practice_test.dart`：通过，33/33。
- `flutter analyze --no-fatal-infos`：完成，无 warning/error；仅剩既有 info级 lint，集中在 AI prompt 字符串多余转义、LaTeX 测试 const 建议等。
- `flutter build apk --release`：通过，生成 release APK，并复制为 `ai-wrong-notebook-v60-20260504-1610.apk`。
- 构建/测试过程中仍有已知 pub.dev advisory decode 噪声：`advisoriesUpdated must be a String`，不影响产物生成。

## Important Root Cause Notes

-旧保存链路里，子题缺少独立 `CandidateAnalysisSnapshot` 时会兜底使用父题 `analysisResult`，而父题在多题场景通常是第1题解析。
-这个兜底掩盖了“子题缺少 snapshot / 部分分析失败”的真实问题，表现为第2/4/5/6题拿到第1题解析。
- 切掉父题兜底后，串题消失，但缺少 snapshot 的子题会暴露为空解析。
-现在的补丁做法是：不串题、不空存；如果任意子题解析失败，明确失败并阻止进入保存态。
- 用户反馈“之前很少出现多题部分失败”，所以后续需要判断是真实 API 偶发、并发限流，还是当前 prompt/解析格式导致某些题解析失败。

## Blockers / Watch Items

-需要用最新 APK 真机验证：
 - 多题样例6题解析是否能全部成功。
 - 如果某一题失败，是否明确提示第几题失败，而不是保存空解析或串题。
 - 多题拆分保存后，第2/4/5/6题的 `analysisResult`、AI 标签、知识点不再继承第1题。
 - 多题保存默认勾选当前子题是否符合预期。
 - 举一反三完成页：AI解析题显示 `保存这道题`，错题本已保存题显示 `返回错题详情`。
 - 已保存题继续练习后轮次是否保留。
 - 分式/比例、三角形角度、函数、立体几何、方程组没有回归。
- PDF 导出优先级 P2，暂不进入 v60；后续需要先明确范围、中文字体、分页、题目卷/答案卷、分享/打印入口。
- 拍照框选/AI provider 两个下一阶段需求已定方案并写入记忆，但不塞进当前 v60 APK。
- 用户正在思考是否做 AI 分析链路低感知重构：保持当前体验，但底层拆清楚 splitResult、candidateAnalyses、失败重试、保存资格。

## Current Git Status Snapshot

当前分支：`main`

已修改文件：
- `lib/src/app/providers.dart`
- `lib/src/data/local/app_database.dart`
- `lib/src/data/local/app_database.g.dart`
- `lib/src/data/local/tables/generated_exercises.dart`
- `lib/src/data/remote/ai/ai_analysis_service.dart`
- `lib/src/data/repositories/drift_question_repository.dart`
- `lib/src/domain/models/generated_exercise.dart`
- `lib/src/features/analysis/presentation/analysis_loading_screen.dart`
- `lib/src/features/analysis/presentation/analysis_result_screen.dart`
- `lib/src/features/analysis/presentation/exercise_practice_screen.dart`
- `lib/src/features/ocr/presentation/question_split_confirmation_screen.dart`
- `progress-current.md`
- `test/app/providers_test.dart`
- `test/data/remote/ai_analysis_service_test.dart`
- `test/features/analysis/analysis_loading_screen_test.dart`
- `test/features/analysis/analysis_result_screen_test.dart`
- `test/features/analysis/exercise_practice_test.dart`
- `test/features/ocr/question_split_confirmation_screen_test.dart`

未跟踪文件：
- `docs/ai-analysis-layout-proposal.html`
- `docs/current-layout-home-review-proposal.html`
- `docs/home-review-ux-proposal.html`
- `docs/icon-style-comparison.html`
- `docs/jilu.txt`
- `docs/layout-preview.html`
- `docs/review-flow-stats-proposal.html`
- `docs/review-top-stats-proposal.html`
- `docs/theme-palette-analysis-result-preview.html`
- `progress-2026-04-29.md`

## Next First Step

回来后先安装并验证：

`build/app/outputs/flutter-apk/ai-wrong-notebook-v60-20260504-1610.apk`

真机重点验证链路：
1. 多题6题样例是否全部解析成功。
2. 如果有子题解析失败，是否明确报错并阻止保存半成品。
3. 多题拆分保存后，第2/4/5/6题解析、AI 标签、知识点不再继承第1题。
4. 多轮举一反三继续练习是否保留历史轮次。
5. 已保存题练习完成是否显示 `返回错题详情`。
6. AI解析未保存题练习完成是否显示 `保存这道题`。
7. 分式/比例、方程组、圆锥体积、等腰三角形角度题型不回归。

## Resume Prompt

下次继续时可以直接说：

“继续 AI 错题本 v60 真机验证收尾。先读 `progress-current.md`，重点验证最新 APK `build/app/outputs/flutter-apk/ai-wrong-notebook-v60-20260504-1610.apk`。检查多题6题样例是否全部解析成功；如果失败，是否明确提示第几题失败且不保存半成品。不要动 LaTeX 渲染引擎。验证通过后再准备提交/发布；如果仍不稳，再讨论低感知重构 AI 分析链路。”
