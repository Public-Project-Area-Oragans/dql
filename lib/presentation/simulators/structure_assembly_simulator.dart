import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/book_model.dart';
import '../../domain/usecases/graph_validator.dart';
import '../widgets/steampunk_button.dart';
import '../widgets/steampunk_panel.dart';

/// 구조 조립 시뮬레이터.
///
/// Phase 2 Track B MVP. wireframe 기반 구현:
/// - 좌측 팔레트(서비스 블록) + 우측 그리드 캔버스
/// - Draggable/DragTarget 드래그&드롭
/// - 노드 탭으로 연결 모드 진입, 다른 노드 탭으로 엣지 생성
/// - 판정은 GraphValidator 주입, ValidationResult sealed 매칭
/// - 기본 접근성(Semantics, 포커스 링) 포함. 완전한 키보드 드래그 대체는 후속 증분.
class StructureAssemblySimulator extends StatefulWidget {
  final StructureAssemblyConfig config;
  final VoidCallback onComplete;

  const StructureAssemblySimulator({
    super.key,
    required this.config,
    required this.onComplete,
  });

  @override
  State<StructureAssemblySimulator> createState() =>
      _StructureAssemblySimulatorState();
}

class _StructureAssemblySimulatorState
    extends State<StructureAssemblySimulator> {
  final Map<GridPos, PaletteItem> _placed = {};
  final List<AssemblyEdge> _edges = [];
  String? _connectFrom;
  ValidationResult? _lastResult;

  GridSize get _grid => widget.config.gridSize;
  List<PaletteItem> get _palette => widget.config.palette;

  List<AssemblyNode> _userNodes() => _placed.entries
      .map((e) => AssemblyNode(id: e.value.id, pos: e.key))
      .toList();

  void _onDropNode(PaletteItem item, GridPos pos) {
    if (_placed.containsKey(pos)) return;
    setState(() {
      _placed[pos] = item;
      _lastResult = null;
    });
  }

  void _onTapNode(String nodeId) {
    setState(() {
      if (_connectFrom == null) {
        _connectFrom = nodeId;
      } else if (_connectFrom == nodeId) {
        _connectFrom = null;
      } else {
        final from = _connectFrom!;
        final duplicate = _edges.any((e) => e.from == from && e.to == nodeId);
        if (!duplicate) {
          _edges.add(AssemblyEdge(from: from, to: nodeId));
        }
        _connectFrom = null;
      }
      _lastResult = null;
    });
  }

  void _onRemoveNode(GridPos pos) {
    final item = _placed[pos];
    if (item == null) return;
    setState(() {
      _placed.remove(pos);
      _edges.removeWhere((e) => e.from == item.id || e.to == item.id);
      if (_connectFrom == item.id) _connectFrom = null;
      _lastResult = null;
    });
  }

  void _validate() {
    final result = GraphValidator.validate(
      userNodes: _userNodes(),
      userEdges: _edges,
      expected: widget.config.solution,
    );
    setState(() => _lastResult = result);
    if (result is ValidationCorrect) {
      Future.delayed(const Duration(seconds: 1), widget.onComplete);
    }
  }

  void _reset() {
    setState(() {
      _placed.clear();
      _edges.clear();
      _connectFrom = null;
      _lastResult = null;
    });
  }

  bool get _canValidate => _placed.isNotEmpty;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: 'MSA 구조 조립 시뮬레이터',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          const SizedBox(height: 12),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildPalette(),
                const SizedBox(width: 12),
                Expanded(child: _buildCanvas()),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildActions(),
          if (_lastResult != null) ...[
            const SizedBox(height: 12),
            _buildResult(_lastResult!),
          ],
        ],
      ),
    );
  }

  // ── Header ───────────────────────────────────────────────

  Widget _buildHeader() {
    return const SteampunkPanel(
      title: '🪙 조립 과제',
      child: Text(
        '팔레트에서 컴포넌트를 끌어와 캔버스에 배치하고, 노드를 탭해 연결 관계를 그린 뒤 판정을 누르세요.',
        style: TextStyle(color: AppColors.parchment, fontSize: 14),
      ),
    );
  }

  // ── Palette ──────────────────────────────────────────────

  Widget _buildPalette() {
    return SizedBox(
      width: 180,
      child: SteampunkPanel(
        title: '팔레트',
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_palette.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  '팔레트가 비어있습니다.\nTask 2-1에서 채움.',
                  style: TextStyle(
                    color: AppColors.parchment.withValues(alpha: 0.5),
                    fontSize: 12,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ..._palette.map((item) => _PaletteCard(item: item)),
            if (_connectFrom != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: AppColors.steamGreen,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: const Text(
                  '[연결 모드]',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.parchment,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ── Canvas ───────────────────────────────────────────────

  Widget _buildCanvas() {
    return SteampunkPanel(
      title: '캔버스 ${_grid.cols} × ${_grid.rows}',
      child: AspectRatio(
        aspectRatio: _grid.cols / _grid.rows,
        child: Container(
          color: AppColors.parchment,
          child: Stack(
            children: [
              Column(
                children: List.generate(_grid.rows, (row) {
                  return Expanded(
                    child: Row(
                      children: List.generate(_grid.cols, (col) {
                        return Expanded(
                          child: _buildCell(GridPos(col: col, row: row)),
                        );
                      }),
                    ),
                  );
                }),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _EdgePainter(
                        edges: _edges,
                        placed: _placed,
                        gridSize: _grid,
                      ),
                    ),
                  ),
                ),
              ),
              if (_placed.isEmpty)
                const Positioned.fill(
                  child: IgnorePointer(
                    child: Center(
                      child: Text(
                        '← 팔레트에서 블록을 끌어오세요',
                        style: TextStyle(
                          color: AppColors.inkBrown,
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCell(GridPos pos) {
    return DragTarget<PaletteItem>(
      onWillAcceptWithDetails: (_) => !_placed.containsKey(pos),
      onAcceptWithDetails: (details) => _onDropNode(details.data, pos),
      builder: (context, candidate, rejected) {
        final item = _placed[pos];
        final hover = candidate.isNotEmpty;
        return Container(
          margin: const EdgeInsets.all(1),
          decoration: BoxDecoration(
            color: hover
                ? AppColors.magicPurple.withValues(alpha: 0.2)
                : Colors.transparent,
            border: Border.all(
              color: AppColors.gold.withValues(alpha: 0.25),
              width: 0.5,
            ),
          ),
          child: item == null ? null : _buildPlacedNode(item, pos),
        );
      },
    );
  }

  Widget _buildPlacedNode(PaletteItem item, GridPos pos) {
    final isConnectSource = _connectFrom == item.id;
    return RepaintBoundary(
      child: Semantics(
        button: true,
        label: '${item.label} 노드, ${pos.row + 1}행 ${pos.col + 1}열'
            '${isConnectSource ? ", 연결 시작점 선택됨" : ""}',
        child: GestureDetector(
          onTap: () => _onTapNode(item.id),
          onLongPress: () => _onRemoveNode(pos),
          child: Container(
            margin: const EdgeInsets.all(2),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: isConnectSource
                  ? AppColors.magicPurple.withValues(alpha: 0.6)
                  : AppColors.deepPurple,
              border: Border.all(
                color: AppColors.brightGold,
                width: isConnectSource ? 3 : 2,
              ),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Padding(
              padding: const EdgeInsets.all(4),
              child: Text(
                item.label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                maxLines: 2,
                style: const TextStyle(
                  color: AppColors.parchment,
                  fontSize: 10,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Actions ──────────────────────────────────────────────

  Widget _buildActions() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '배치 ${_placed.length} / 연결 ${_edges.length}',
          style: const TextStyle(color: AppColors.gold, fontSize: 12),
        ),
        Row(
          children: [
            SteampunkButton(label: '🔄 리셋', onPressed: _reset, isSmall: true),
            const SizedBox(width: 8),
            SteampunkButton(
              label: '⚖ 판정',
              onPressed: _canValidate ? _validate : null,
            ),
          ],
        ),
      ],
    );
  }

  // ── Result ───────────────────────────────────────────────

  Widget _buildResult(ValidationResult r) {
    return switch (r) {
      ValidationCorrect() => _buildResultPanel(
          title: '✓ 통과!',
          color: AppColors.steamGreen,
          lines: const ['완벽합니다. 구조를 정확히 조립했습니다.'],
        ),
      ValidationEmpty() => _buildResultPanel(
          title: '⚠ 비어있음',
          color: AppColors.gold,
          lines: const ['먼저 팔레트에서 블록을 끌어와 배치하세요.'],
        ),
      ValidationPartial(
        missingNodes: final mn,
        extraNodes: final en,
        missingEdges: final me,
        extraEdges: final ee,
      ) =>
        _buildResultPanel(
          title: '⚡ 일부 틀림',
          color: AppColors.magicPurple,
          lines: [
            if (mn.isNotEmpty) '누락 노드: ${mn.join(", ")}',
            if (en.isNotEmpty) '불필요 노드: ${en.join(", ")}',
            if (me.isNotEmpty)
              '누락 연결: ${me.map((e) => e.toString()).join(", ")}',
            if (ee.isNotEmpty)
              '불필요 연결: ${ee.map((e) => e.toString()).join(", ")}',
          ],
        ),
    };
  }

  Widget _buildResultPanel({
    required String title,
    required Color color,
    required List<String> lines,
  }) {
    return Semantics(
      liveRegion: true,
      child: SteampunkPanel(
        title: title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: lines
              .map((l) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Text(
                      l,
                      style: TextStyle(color: color, fontSize: 13),
                    ),
                  ))
              .toList(),
        ),
      ),
    );
  }
}

// ── Palette card ─────────────────────────────────────────────

class _PaletteCard extends StatelessWidget {
  final PaletteItem item;
  const _PaletteCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Draggable<PaletteItem>(
        data: item,
        feedback: _PaletteVisual(item: item, opacity: 0.7),
        childWhenDragging: Opacity(
          opacity: 0.3,
          child: _PaletteVisual(item: item),
        ),
        child: Semantics(
          button: true,
          label: '팔레트: ${item.label}. 드래그해 캔버스에 배치.',
          child: _PaletteVisual(item: item),
        ),
      ),
    );
  }
}

class _PaletteVisual extends StatelessWidget {
  final PaletteItem item;
  final double opacity;
  const _PaletteVisual({required this.item, this.opacity = 1.0});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: 160,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.midPurple.withValues(alpha: opacity),
          border: Border.all(
            color: AppColors.gold.withValues(alpha: opacity),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          item.label,
          style: TextStyle(
            color: AppColors.parchment.withValues(alpha: opacity),
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}

// ── Edge painter ─────────────────────────────────────────────

class _EdgePainter extends CustomPainter {
  final List<AssemblyEdge> edges;
  final Map<GridPos, PaletteItem> placed;
  final GridSize gridSize;

  _EdgePainter({
    required this.edges,
    required this.placed,
    required this.gridSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (edges.isEmpty) return;

    final cellWidth = size.width / gridSize.cols;
    final cellHeight = size.height / gridSize.rows;

    final idToCenter = <String, Offset>{};
    placed.forEach((pos, item) {
      idToCenter[item.id] = Offset(
        (pos.col + 0.5) * cellWidth,
        (pos.row + 0.5) * cellHeight,
      );
    });

    final linePaint = Paint()
      ..color = AppColors.gold
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    for (final edge in edges) {
      final from = idToCenter[edge.from];
      final to = idToCenter[edge.to];
      if (from == null || to == null) continue;
      canvas.drawLine(from, to, linePaint);
      if (edge.directed) {
        _drawArrowHead(canvas, from, to, linePaint);
      }
    }
  }

  void _drawArrowHead(Canvas canvas, Offset from, Offset to, Paint paint) {
    const arrowSize = 10.0;
    const nodeRadius = 14.0;
    final direction = to - from;
    final length = direction.distance;
    if (length == 0) return;
    final unit = direction / length;
    final tip = to - unit * nodeRadius;
    final perpendicular = Offset(-unit.dy, unit.dx);
    final base = tip - unit * arrowSize;
    final p1 = base + perpendicular * arrowSize * 0.5;
    final p2 = base - perpendicular * arrowSize * 0.5;
    canvas.drawLine(tip, p1, paint);
    canvas.drawLine(tip, p2, paint);
  }

  @override
  bool shouldRepaint(covariant _EdgePainter old) =>
      old.edges.length != edges.length ||
      old.placed.length != placed.length ||
      old.edges.hashCode != edges.hashCode ||
      old.placed.hashCode != placed.hashCode;
}
