# Progress — AI错题本

## Done
- 多题保存前拆分链路已经完整打通：结构化拆题模型、拆题确认页、路由接入、保存多条题级记录与对应回归测试都已落地。
- 提取阶段已接入 `splitResult`，`AnalysisLoadingScreen` 会在 extraction 后把结构化拆题结果写回 `currentQuestionProvider`，保存链路优先复用，不再重复拆分。
- 分析结果页已升级为多题结果态，并进一步接入逐题独立解析：支持候选题切换，且优先展示当前候选题自己的 `analysisResult / aiTags / aiKnowledgePoints / savedExercises`。
- 保存链路已完成 candidate-aware 收尾：`buildSplitQuestionRecord(...)` 会优先继承对应 `CandidateAnalysisSnapshot` 的解析结果、练习、标签、知识点和科目，不再默认复用整题结果。
- 保存后的下游题级闭环已补齐验证：notebook 列表、错题详情、练习页都已用真实拆分后单题记录回归验证。
- 新增了完整导航与状态回流测试：已验证 notebook → detail → practice 的题级路由流，以及练习完成后 `savedExercises.isCorrect` 会回写到仓储与 `currentQuestionProvider`，返回详情页后已答计数会同步更新。
- 已清理练习回流测试中的外部 AI 判题噪音：相关测试显式使用 `AiAnalysisService.fake()`，不再触发远程 fallback。
- 轻量 batch/child lineage 数据模型已落地：`QuestionRecord` 新增 `parentQuestionId / rootQuestionId / splitOrder`，拆分保存的子题会写入父题、根题和 1-based 顺序。
- lineage 字段已贯通 JSON、SharedPrefs、Drift 表与仓储映射；Drift schema 已升到 v3，新增 nullable columns，并完成 `app_database.g.dart` 生成。
- 数据导入导出已改为复用 `QuestionRecord.toJson/fromJson()`，避免 `splitResult / candidateAnalyses / lineage / savedExercises` 等字段遗漏。
- 已补充 Drift 持久化直测：`AppDatabase.memory()` 支持测试内存库，`drift_question_repository_test.dart` 覆盖 lineage、保存练习、options/userAnswer/isCorrect、AI 标签和自定义标签 round-trip。
- 已上线轻量批次提示 UI：notebook 列表显示“来自同一拍照批次 · 第 N 题”，错题详情标签区显示“拍照批次 · 第 N 题”；普通单题不显示额外提示。
- 复习页已补齐批次上下文：同一拍照批次的待复习卡片显示“来自同一拍照批次 · 第 N 题”，普通单题不显示批次提示。
- 复习卡片已加入快捷操作与掌握状态：支持在列表中直接标记“仍需复习/继续巩固”和“已掌握”，并即时刷新待复习列表。
- 复习页与错题详情页的复习动作已统一写入 `ReviewLogRepository`，复习历史可追踪列表页和详情页产生的记录。
- 数据管理已纳入复习记录生命周期：页面显示“复习记录总量”，清空所有数据时会同步清空错题与复习记录，文案也已明确不可恢复范围。
- 已清理保存确认流程语义：`OcrConfirmationScreen` 重命名为 `QuestionSaveConfirmationScreen`，路由改为 `/capture/save-confirmation`，明确当前流程是拍照后直接 AI 识别/解题，保存时再确认题目文本。
- AI 解析 loading 文案已调整为“正在识别题目 / 正在理解题意 / 正在生成解析 / 即将完成”，返回路径也回到题目预览页，避免误导为解题前 OCR 确认。
- 本轮关键验证已通过：`flutter analyze`、`flutter test`；此前 targeted 验证包括 `flutter test test/features/settings/data_management_screen_test.dart`、`flutter test test/features/review/review_controller_test.dart`、`flutter test test/features/review/review_screen_test.dart`、`flutter test test/features/review/review_history_screen_test.dart`、`flutter test test/features/analysis/analysis_result_screen_test.dart`、`flutter test test/features/notebook/question_level_flow_test.dart`、`flutter test test/smoke/app_smoke_test.dart`。

## Blockers
- 当前没有新的代码阻塞；多题保存、题级闭环、lineage、批次提示、复习快捷动作、复习记录写入、数据清理和保存确认流程语义清理都已跑通。
- 工作区仍包含较多未提交改动和未跟踪文件；如果要做 WIP commit，必须先确认精确文件范围，不能直接批量 stage。

## Next First Step
- 下一步建议做 WIP commit：提交范围限定为本轮多题保存/批次 lineage/LaTeX 展示/复习流程/数据管理/保存确认语义清理及对应测试文件，提交前继续使用显式文件列表 stage。
