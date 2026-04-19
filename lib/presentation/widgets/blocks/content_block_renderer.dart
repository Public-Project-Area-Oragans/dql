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
      final BoxDiagramBlock b => _BoxDiagramPlaceholder(block: b),
    };
  }
}

/// fix-4b 스켈레톤: 파서(fix-4c)가 `BoxDiagramBlock` 을 emit 할 때까지 사용되는
/// 임시 플레이스홀더. fix-4d 에서 실 `BoxDiagramWidget` (Container+CustomPaint)
/// 로 교체된다. 현재는 노드 수·엣지 수만 텍스트로 노출해 라우팅이 작동하는지
/// 확인.
class _BoxDiagramPlaceholder extends StatelessWidget {
  final BoxDiagramBlock block;
  const _BoxDiagramPlaceholder({required this.block});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkWalnut,
        border: Border.all(color: AppColors.magicPurple),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '[BoxDiagram placeholder] ${block.nodes.length}개 노드, '
        '${block.edges.length}개 연결, ${block.cols}x${block.rows} 그리드',
        style: const TextStyle(
          color: AppColors.parchment,
          fontSize: 12,
        ),
      ),
    );
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
            fontFamily: kMonospaceFamily,
            fontFamilyFallback: kMonospaceFallback,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

/// fix-4a: 번들된 JetBrains Mono 를 1차 패밀리로 사용한다. OS/브라우저에
/// 독립적으로 ASCII 박스 드로잉·코드 블록 열 정렬을 보장한다.
/// `pubspec.yaml` 의 `fonts:` 선언과 family 이름이 일치해야 한다.
const String kMonospaceFamily = 'JetBrainsMono';

/// 시스템에 JetBrains Mono 가 로드되지 않은 예외 상황(에셋 로딩 지연 등)을
/// 대비한 OS별 monospace 폴백 체인.
const List<String> kMonospaceFallback = <String>[
  'Consolas', // Windows (Chrome/Edge)
  'Menlo', // macOS (Safari/Chrome)
  'DejaVu Sans Mono', // Linux 배포판 공통
  'Liberation Mono', // Linux 대체
  'Noto Sans Mono CJK KR', // 한글·CJK 정렬
  'monospace', // generic 폴백
];

