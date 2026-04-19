import 'package:freezed_annotation/freezed_annotation.dart';

part 'content_block.freezed.dart';
part 'content_block.g.dart';

/// 이론 섹션 안의 개별 블록. build-time parser가 markdown/mermaid/표를
/// 구조화해 이 union으로 배출하고, `ContentBlockRenderer`가 타입별 네이티브
/// Flutter 위젯으로 렌더한다. 이미지 에셋은 전혀 사용하지 않는다.
///
/// Phase 3 "다이어그램 위젯 이주" 스켈레톤 (PR #1).
/// 이 PR에서는 ProseBlock + RawBlock만 실질 구현하고 나머지 variant는 타입만
/// 정의한다. 실제 파싱·렌더링은 후속 PR에서 순차 추가:
/// - PR #2: TableBlock (파서 + 위젯)
/// - PR #3: AsciiDiagramBlock (Task 12 로직 편입)
/// - PR #4: FlowchartBlock (graphview)
/// - PR #5: SequenceBlock + MindmapBlock
@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.none)
sealed class ContentBlock with _$ContentBlock {
  /// 일반 마크다운 산문. 기존 `TheorySection.content`의 디폴트 이주 대상.
  const factory ContentBlock.prose({required String markdown}) = ProseBlock;

  /// GFM 표.
  const factory ContentBlock.table({
    required List<String> headers,
    required List<List<String>> rows,
    @Default([]) List<String> alignments, // left | center | right | ""
  }) = TableBlock;

  /// ASCII 박스 드로잉 다이어그램. Task 12의 `_ScrollablePreBuilder` 경로.
  const factory ContentBlock.asciiDiagram({required String source}) =
      AsciiDiagramBlock;

  /// Mermaid flowchart.
  const factory ContentBlock.flowchart({
    required String direction, // TB | LR | TD | BT
    required List<FlowchartNode> nodes,
    required List<FlowchartEdge> edges,
  }) = FlowchartBlock;

  /// Mermaid sequenceDiagram.
  const factory ContentBlock.sequence({
    required List<String> participants,
    required List<SequenceStep> steps,
  }) = SequenceBlock;

  /// Mermaid mindmap.
  const factory ContentBlock.mindmap({required MindmapNode root}) =
      MindmapBlock;

  /// fix-4b: ASCII 박스 드로잉을 파싱한 구조화 박스 다이어그램.
  ///
  /// `tools/content_builder.dart` 의 ASCII 박스 파서가 `┌─┐│└┘` 패턴을
  /// 인식해 bounding box 노드 + 방향성 엣지로 추출. 렌더는 `BoxDiagramWidget`
  /// 이 Flutter 네이티브 `Container` + `CustomPaint` 로 그린다.
  ///
  /// 파서 실패 시엔 여전히 `AsciiDiagramBlock` 이 폴백으로 남을 수 있다
  /// (fix-4a 의 JetBrainsMono 폰트가 보증).
  const factory ContentBlock.boxDiagram({
    required List<BoxNode> nodes,
    required List<BoxEdge> edges,
    required int cols,
    required int rows,
  }) = BoxDiagramBlock;

  /// 미지원/파서 실패 폴백. 원본 소스를 monospace로 렌더.
  const factory ContentBlock.raw({
    required String language,
    required String source,
  }) = RawBlock;

  factory ContentBlock.fromJson(Map<String, dynamic> json) =>
      _$ContentBlockFromJson(json);
}

@freezed
abstract class FlowchartNode with _$FlowchartNode {
  const factory FlowchartNode({
    required String id,
    required String label,
    @Default('rect') String shape, // rect | diamond | circle | round
  }) = _FlowchartNode;

  factory FlowchartNode.fromJson(Map<String, dynamic> json) =>
      _$FlowchartNodeFromJson(json);
}

@freezed
abstract class FlowchartEdge with _$FlowchartEdge {
  const factory FlowchartEdge({
    required String from,
    required String to,
    @Default('') String label,
    @Default('solid') String style, // solid | dashed | thick
  }) = _FlowchartEdge;

  factory FlowchartEdge.fromJson(Map<String, dynamic> json) =>
      _$FlowchartEdgeFromJson(json);
}

@freezed
abstract class SequenceStep with _$SequenceStep {
  const factory SequenceStep({
    required String from,
    required String to,
    required String label,
    @Default('sync') String kind, // sync | async | reply
  }) = _SequenceStep;

  factory SequenceStep.fromJson(Map<String, dynamic> json) =>
      _$SequenceStepFromJson(json);
}

@freezed
abstract class MindmapNode with _$MindmapNode {
  const factory MindmapNode({
    required String label,
    @Default([]) List<MindmapNode> children,
  }) = _MindmapNode;

  factory MindmapNode.fromJson(Map<String, dynamic> json) =>
      _$MindmapNodeFromJson(json);
}

/// fix-4b: BoxDiagramBlock 의 노드. 파서가 ASCII 박스의 bounding box 를
/// 문자 그리드 좌표 (col, row) + (widthCells, heightCells) 로 기록.
@freezed
abstract class BoxNode with _$BoxNode {
  const factory BoxNode({
    required String id,
    required String label,
    required int col,
    required int row,
    required int widthCells,
    required int heightCells,
    @Default('rect') String shape, // rect | rounded | diamond
  }) = _BoxNode;

  factory BoxNode.fromJson(Map<String, dynamic> json) =>
      _$BoxNodeFromJson(json);
}

/// fix-4b: BoxDiagramBlock 의 엣지. 파서가 `─│▶◀▼▲` 커넥터를 trace 해서
/// from / to 노드 id + 방향 화살표를 기록.
@freezed
abstract class BoxEdge with _$BoxEdge {
  const factory BoxEdge({
    required String from,
    required String to,
    @Default('→') String arrow, // → ← ↑ ↓ ↔
    @Default('') String label,
  }) = _BoxEdge;

  factory BoxEdge.fromJson(Map<String, dynamic> json) =>
      _$BoxEdgeFromJson(json);
}
