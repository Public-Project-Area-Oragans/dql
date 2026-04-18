import 'package:freezed_annotation/freezed_annotation.dart';

import 'content_block.dart';

part 'book_model.freezed.dart';
part 'book_model.g.dart';

// ── 이론 콘텐츠 ───────────────────────────────────────────

@freezed
abstract class TheorySection with _$TheorySection {
  const factory TheorySection({
    required String title,
    required String content,
    // Phase 3 "다이어그램 위젯 이주" skeleton. build-time parser가 채우며,
    // 비어있으면 `content`(markdown) 단일 ProseBlock으로 폴백.
    @Default([]) List<ContentBlock> blocks,
  }) = _TheorySection;

  factory TheorySection.fromJson(Map<String, dynamic> json) =>
      _$TheorySectionFromJson(json);
}

@freezed
abstract class CodeBlock with _$CodeBlock {
  const factory CodeBlock({
    required String language,
    required String code,
    required String description,
  }) = _CodeBlock;

  factory CodeBlock.fromJson(Map<String, dynamic> json) =>
      _$CodeBlockFromJson(json);
}

@freezed
abstract class DiagramData with _$DiagramData {
  const factory DiagramData({
    required String type,
    required String content,
  }) = _DiagramData;

  factory DiagramData.fromJson(Map<String, dynamic> json) =>
      _$DiagramDataFromJson(json);
}

@freezed
abstract class TheoryContent with _$TheoryContent {
  const factory TheoryContent({
    required List<TheorySection> sections,
    required List<CodeBlock> codeExamples,
    required List<DiagramData> diagrams,
  }) = _TheoryContent;

  factory TheoryContent.fromJson(Map<String, dynamic> json) =>
      _$TheoryContentFromJson(json);
}

// ── 시뮬레이터 공용 ──────────────────────────────────────

@freezed
abstract class SimStep with _$SimStep {
  const factory SimStep({
    required String instruction,
    required String code,
    required Map<String, dynamic> expectedState,
  }) = _SimStep;

  factory SimStep.fromJson(Map<String, dynamic> json) =>
      _$SimStepFromJson(json);
}

@freezed
abstract class CompletionRule with _$CompletionRule {
  const factory CompletionRule({
    required int minStepsCompleted,
  }) = _CompletionRule;

  factory CompletionRule.fromJson(Map<String, dynamic> json) =>
      _$CompletionRuleFromJson(json);
}

// ── 구조 조립 시뮬레이터 전용 ────────────────────────────

@freezed
abstract class GridSize with _$GridSize {
  const factory GridSize({
    required int cols,
    required int rows,
  }) = _GridSize;

  factory GridSize.fromJson(Map<String, dynamic> json) =>
      _$GridSizeFromJson(json);
}

@freezed
abstract class GridPos with _$GridPos {
  const factory GridPos({
    required int col,
    required int row,
  }) = _GridPos;

  factory GridPos.fromJson(Map<String, dynamic> json) =>
      _$GridPosFromJson(json);
}

@freezed
abstract class PaletteItem with _$PaletteItem {
  const factory PaletteItem({
    required String id,
    required String label,
    required String spriteKey,
  }) = _PaletteItem;

  factory PaletteItem.fromJson(Map<String, dynamic> json) =>
      _$PaletteItemFromJson(json);
}

@freezed
abstract class AssemblyNode with _$AssemblyNode {
  const factory AssemblyNode({
    required String id,
    required GridPos pos,
  }) = _AssemblyNode;

  factory AssemblyNode.fromJson(Map<String, dynamic> json) =>
      _$AssemblyNodeFromJson(json);
}

@freezed
abstract class AssemblyEdge with _$AssemblyEdge {
  const factory AssemblyEdge({
    required String from,
    required String to,
    @Default(true) bool directed,
  }) = _AssemblyEdge;

  factory AssemblyEdge.fromJson(Map<String, dynamic> json) =>
      _$AssemblyEdgeFromJson(json);
}

@freezed
abstract class AssemblySolution with _$AssemblySolution {
  const factory AssemblySolution({
    required List<AssemblyNode> nodes,
    required List<AssemblyEdge> edges,
  }) = _AssemblySolution;

  factory AssemblySolution.fromJson(Map<String, dynamic> json) =>
      _$AssemblySolutionFromJson(json);
}

@freezed
abstract class PartialFeedback with _$PartialFeedback {
  const factory PartialFeedback({
    required String missingNodes,
    required String missingEdges,
    required String extraEdges,
  }) = _PartialFeedback;

  factory PartialFeedback.fromJson(Map<String, dynamic> json) =>
      _$PartialFeedbackFromJson(json);
}

// ── SimulatorConfig sealed union ─────────────────────────
//
// 기존 book.json의 `"type": "codeStep"` 문자열과 하위호환 유지.
// 신규 `"type": "structureAssembly"` 서브타입 추가.
// SimulatorType enum은 제거 (sealed class 자체가 discriminator).

@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.none)
sealed class SimulatorConfig with _$SimulatorConfig {
  const factory SimulatorConfig.codeStep({
    required List<SimStep> steps,
    required CompletionRule completionCriteria,
  }) = CodeStepConfig;

  const factory SimulatorConfig.structureAssembly({
    required GridSize gridSize,
    required List<PaletteItem> palette,
    required AssemblySolution solution,
    required PartialFeedback partialFeedback,
  }) = StructureAssemblyConfig;

  factory SimulatorConfig.fromJson(Map<String, dynamic> json) =>
      _$SimulatorConfigFromJson(json);
}

// ── 챕터·책 ───────────────────────────────────────────────

@freezed
abstract class Chapter with _$Chapter {
  const factory Chapter({
    required String id,
    required String title,
    required int order,
    required TheoryContent theory,
    required SimulatorConfig simulator,
    @Default(false) bool isCompleted,
  }) = _Chapter;

  factory Chapter.fromJson(Map<String, dynamic> json) =>
      _$ChapterFromJson(json);
}

@freezed
abstract class Book with _$Book {
  const Book._();

  const factory Book({
    required String id,
    required String title,
    required String category,
    required List<Chapter> chapters,
  }) = _Book;

  double get totalProgress {
    if (chapters.isEmpty) return 0.0;
    final completed = chapters.where((c) => c.isCompleted).length;
    return completed / chapters.length;
  }

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
}
