import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/content_block.dart';

/// Mermaid mindmap을 순수 Flutter 재귀 트리(`Column` + 들여쓰기)로 렌더.
/// 이미지 미사용.
class MindmapWidget extends StatelessWidget {
  final MindmapBlock block;
  const MindmapWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkWalnut,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: _MindmapNodeView(node: block.root, depth: 0),
      ),
    );
  }
}

class _MindmapNodeView extends StatelessWidget {
  final MindmapNode node;
  final int depth;
  const _MindmapNodeView({required this.node, required this.depth});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: EdgeInsets.only(left: depth * 18.0, bottom: 4),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: depth == 0
                ? AppColors.magicPurple.withValues(alpha: 0.3)
                : AppColors.deepPurple,
            border: Border.all(
              color: depth == 0 ? AppColors.brightGold : AppColors.gold,
              width: depth == 0 ? 1.5 : 1,
            ),
            borderRadius:
                BorderRadius.circular(depth == 0 ? 12 : 4),
          ),
          child: Text(
            node.label,
            style: TextStyle(
              color: depth == 0
                  ? AppColors.brightGold
                  : AppColors.parchment,
              fontSize: depth == 0 ? 14 : 12,
              fontWeight:
                  depth == 0 ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
        for (final child in node.children)
          _MindmapNodeView(node: child, depth: depth + 1),
      ],
    );
  }
}
