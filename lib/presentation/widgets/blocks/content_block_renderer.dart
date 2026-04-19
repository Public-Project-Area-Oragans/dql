import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/content_block.dart';
import 'flowchart_widget.dart';
import 'mindmap_widget.dart';
import 'sequence_widget.dart';
import 'table_block_widget.dart';

/// Phase 3 "다이어그램 위젯 이주" — 구조화 ContentBlock을 타입별 네이티브
/// Flutter 위젯으로 디스패치한다. 이미지 에셋은 전혀 사용하지 않는다.
///
/// PR #1~5 완료 후 모든 variant가 네이티브 위젯으로 렌더된다:
/// - Prose → MarkdownBody
/// - Table → TableBlockWidget (내장 Table)
/// - AsciiDiagram / Raw → monospace 가로 스크롤
/// - Flowchart → FlowchartWidget (graphview Sugiyama)
/// - Sequence → SequenceWidget (CustomPaint)
/// - Mindmap → MindmapWidget (재귀 Column)
class ContentBlockRenderer extends StatelessWidget {
  final ContentBlock block;
  final MarkdownStyleSheet? proseStyle;
  final Map<String, MarkdownElementBuilder>? proseBuilders;

  const ContentBlockRenderer({
    super.key,
    required this.block,
    this.proseStyle,
    this.proseBuilders,
  });

  @override
  Widget build(BuildContext context) {
    return switch (block) {
      ProseBlock(:final markdown) => MarkdownBody(
          data: markdown,
          selectable: true,
          styleSheet: proseStyle,
          builders: proseBuilders ?? const {},
        ),
      RawBlock(:final source) => _MonospaceScroll(source: source),
      final TableBlock t => TableBlockWidget(block: t),
      AsciiDiagramBlock(:final source) => _MonospaceScroll(source: source),
      final FlowchartBlock f => FlowchartWidget(block: f),
      final SequenceBlock s => SequenceWidget(block: s),
      final MindmapBlock m => MindmapWidget(block: m),
    };
  }
}

class _MonospaceScroll extends StatelessWidget {
  final String source;
  const _MonospaceScroll({required this.source});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkWalnut,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(10),
        child: SelectableText(
          source,
          style: const TextStyle(
            color: AppColors.steamGreen,
            fontFamily: 'Courier New',
            // Flutter Web CanvasKit 는 generic 'monospace' 패밀리를 항상 실제
            // monospace 로 매핑하지 않는다. ASCII 박스 드로잉의 열 정렬을
            // 유지하려면 실 폰트 이름을 순서대로 폴백 지정해야 한다.
            fontFamilyFallback: kMonospaceFallback,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

/// 프로젝트 공통 monospace 폰트 폴백 체인. ASCII 박스 드로잉 정렬이 필요한
/// 모든 텍스트 위젯에서 재사용한다. 플랫폼별로 가장 먼저 발견되는 실제
/// monospace 폰트가 적용된다.
const List<String> kMonospaceFallback = <String>[
  'Consolas', // Windows (Chrome/Edge)
  'Menlo', // macOS (Safari/Chrome)
  'DejaVu Sans Mono', // Linux 배포판 공통
  'Liberation Mono', // Linux 대체
  'Noto Sans Mono CJK KR', // 한글·CJK 정렬
  'monospace', // generic 폴백
];

