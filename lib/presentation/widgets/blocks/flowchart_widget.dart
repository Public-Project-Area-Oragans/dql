import 'package:flutter/material.dart';
import 'package:graphview/GraphView.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/content_block.dart';

/// Mermaid flowchart를 `graphview` Sugiyama 레이아웃으로 렌더한다.
///
/// `graphview`는 순수 Dart + `CustomPaint` 기반으로, 내부적으로 이미지
/// 에셋을 전혀 사용하지 않는다. 노드 위젯과 엣지 렌더는 모두 Flutter 기본
/// 프리미티브로 구성.
class FlowchartWidget extends StatefulWidget {
  final FlowchartBlock block;
  const FlowchartWidget({super.key, required this.block});

  @override
  State<FlowchartWidget> createState() => _FlowchartWidgetState();
}

class _FlowchartWidgetState extends State<FlowchartWidget> {
  late final Graph _graph;
  late final SugiyamaConfiguration _config;

  @override
  void initState() {
    super.initState();
    _graph = Graph()..isTree = false;

    final nodesById = <String, Node>{};
    for (final n in widget.block.nodes) {
      final node = Node.Id(n.id);
      nodesById[n.id] = node;
      _graph.addNode(node);
    }

    for (final e in widget.block.edges) {
      final from = nodesById[e.from];
      final to = nodesById[e.to];
      if (from == null || to == null) continue;
      _graph.addEdge(
        from,
        to,
        paint: Paint()
          ..color = _edgeColor(e.style)
          ..strokeWidth = e.style == 'thick' ? 2.5 : 1.5
          ..style = PaintingStyle.stroke,
      );
    }

    _config = SugiyamaConfiguration()
      ..nodeSeparation = 24
      ..levelSeparation = 40
      ..orientation = _orientationFor(widget.block.direction);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.block.nodes.isEmpty) {
      return const _EmptyFlowchart();
    }
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkWalnut,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      padding: const EdgeInsets.all(12),
      // InteractiveViewer로 큰 그래프 스크롤/줌 허용. constrained=false로
      // 레이아웃 결과 크기만큼 child 허용.
      child: SizedBox(
        height: _heightEstimate(),
        child: InteractiveViewer(
          constrained: false,
          boundaryMargin: const EdgeInsets.all(40),
          minScale: 0.3,
          maxScale: 2.5,
          child: GraphView(
            graph: _graph,
            algorithm: SugiyamaAlgorithm(_config),
            paint: Paint()
              ..color = AppColors.gold.withValues(alpha: 0.6)
              ..strokeWidth = 1.2
              ..style = PaintingStyle.stroke,
            builder: (Node node) {
              final id = node.key?.value as String?;
              if (id == null) return const SizedBox.shrink();
              final data = _lookupNode(id);
              return _NodeWidget(
                label: data?.label ?? id,
                shape: data?.shape ?? 'rect',
              );
            },
          ),
        ),
      ),
    );
  }

  double _heightEstimate() {
    // 노드 수에 비례한 간단 휴리스틱. InteractiveViewer로 보완되므로 엄격
    // 하지 않아도 됨.
    final n = widget.block.nodes.length;
    final horizontal = widget.block.direction == 'LR' ||
        widget.block.direction == 'RL';
    return horizontal ? 240 : (120 + n * 40).clamp(160, 800).toDouble();
  }

  FlowchartNode? _lookupNode(String id) {
    for (final n in widget.block.nodes) {
      if (n.id == id) return n;
    }
    return null;
  }

  Color _edgeColor(String style) {
    switch (style) {
      case 'dashed':
        return AppColors.magicPurple.withValues(alpha: 0.7);
      case 'thick':
        return AppColors.brightGold;
      default:
        return AppColors.gold.withValues(alpha: 0.7);
    }
  }

  int _orientationFor(String direction) {
    switch (direction) {
      case 'LR':
        return SugiyamaConfiguration.ORIENTATION_LEFT_RIGHT;
      case 'RL':
        return SugiyamaConfiguration.ORIENTATION_RIGHT_LEFT;
      case 'BT':
        return SugiyamaConfiguration.ORIENTATION_BOTTOM_TOP;
      case 'TB':
      case 'TD':
      default:
        return SugiyamaConfiguration.ORIENTATION_TOP_BOTTOM;
    }
  }
}

class _NodeWidget extends StatelessWidget {
  final String label;
  final String shape;
  const _NodeWidget({required this.label, required this.shape});

  @override
  Widget build(BuildContext context) {
    final decoration = switch (shape) {
      'diamond' => BoxDecoration(
          color: AppColors.magicPurple.withValues(alpha: 0.25),
          border: Border.all(color: AppColors.brightGold, width: 1.2),
        ),
      'circle' => BoxDecoration(
          color: AppColors.steamGreen.withValues(alpha: 0.25),
          border: Border.all(color: AppColors.brightGold, width: 1.2),
          shape: BoxShape.circle,
        ),
      'round' => BoxDecoration(
          color: AppColors.deepPurple,
          border: Border.all(color: AppColors.gold, width: 1),
          borderRadius: BorderRadius.circular(16),
        ),
      _ => BoxDecoration(
          color: AppColors.deepPurple,
          border: Border.all(color: AppColors.gold, width: 1),
          borderRadius: BorderRadius.circular(4),
        ),
    };

    return ConstrainedBox(
      constraints: const BoxConstraints(
        minWidth: 80,
        maxWidth: 180,
        minHeight: 36,
      ),
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: decoration,
        child: Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: AppColors.parchment,
            fontSize: 11,
            height: 1.2,
          ),
        ),
      ),
    );
  }
}

class _EmptyFlowchart extends StatelessWidget {
  const _EmptyFlowchart();
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Text(
        '(빈 flowchart)',
        style: TextStyle(
          color: AppColors.parchment.withValues(alpha: 0.5),
          fontStyle: FontStyle.italic,
        ),
      ),
    );
  }
}
