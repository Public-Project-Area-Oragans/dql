import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/content_block.dart';
import 'flowchart_widget.dart';
import 'table_block_widget.dart';

/// Phase 3 "다이어그램 위젯 이주" — 구조화 ContentBlock을 타입별 네이티브
/// Flutter 위젯으로 디스패치한다. 이미지 에셋은 전혀 사용하지 않는다.
///
/// PR #1 스켈레톤: ProseBlock + RawBlock만 실질 렌더. 나머지 variant는
/// 후속 PR에서 네이티브 위젯으로 교체될 때까지 `_PlaceholderBlock` 표시.
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
      SequenceBlock() =>
        const _PlaceholderBlock(kind: 'Mermaid sequence (PR #5에서 구현 예정)'),
      MindmapBlock() =>
        const _PlaceholderBlock(kind: 'Mermaid mindmap (PR #5에서 구현 예정)'),
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
            fontFamily: 'monospace',
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

class _PlaceholderBlock extends StatelessWidget {
  final String kind;
  const _PlaceholderBlock({required this.kind});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.deepPurple,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        '⚙ $kind',
        style: const TextStyle(
          color: AppColors.gold,
          fontFamily: 'monospace',
          fontSize: 12,
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
