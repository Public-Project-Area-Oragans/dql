import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/content_block.dart';

/// Mermaid sequenceDiagram의 순수 Flutter 렌더러.
///
/// 상단에 참가자 헤더(Row), 세로축을 따라 메시지를 차례로 렌더한다. 각
/// 메시지는 from/to 참가자 사이를 CustomPaint로 화살표로 연결.
///
/// 이미지 미사용. 모든 그래픽은 `CustomPaint`로 직접 그린다.
class SequenceWidget extends StatelessWidget {
  final SequenceBlock block;
  const SequenceWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    if (block.participants.isEmpty) {
      return const SizedBox.shrink();
    }
    final width = (block.participants.length * 140.0).clamp(280.0, 1600.0);
    const rowHeight = 56.0;
    final height = 60 + block.steps.length * rowHeight + 40;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkWalnut,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: SizedBox(
          width: width,
          height: height.toDouble(),
          child: CustomPaint(
            painter: _SequencePainter(block: block),
          ),
        ),
      ),
    );
  }
}

class _SequencePainter extends CustomPainter {
  final SequenceBlock block;
  _SequencePainter({required this.block});

  static const _headerHeight = 44.0;
  static const _rowHeight = 56.0;
  static const _laneTopPadding = 20.0;

  @override
  void paint(Canvas canvas, Size size) {
    final participantCount = block.participants.length;
    if (participantCount == 0) return;

    final laneX = <double>[];
    final laneWidth = size.width / participantCount;
    for (var i = 0; i < participantCount; i++) {
      laneX.add(laneWidth * (i + 0.5));
    }

    // 1) 각 참가자의 세로 lifeline.
    final lifePaint = Paint()
      ..color = AppColors.gold.withValues(alpha: 0.35)
      ..strokeWidth = 1.0;
    for (final x in laneX) {
      canvas.drawLine(
        Offset(x, _headerHeight),
        Offset(x, size.height - 10),
        lifePaint,
      );
    }

    // 2) 헤더 박스.
    for (var i = 0; i < participantCount; i++) {
      final rect = Rect.fromLTWH(
        laneWidth * i + 12,
        6,
        laneWidth - 24,
        _headerHeight - 12,
      );
      final boxPaint = Paint()..color = AppColors.deepPurple;
      final borderPaint = Paint()
        ..color = AppColors.gold
        ..strokeWidth = 1.2
        ..style = PaintingStyle.stroke;
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        boxPaint,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(4)),
        borderPaint,
      );
      _paintText(
        canvas,
        block.participants[i],
        rect,
        AppColors.brightGold,
        bold: true,
      );
    }

    // 3) 메시지 화살표 + 라벨.
    for (var step = 0; step < block.steps.length; step++) {
      final s = block.steps[step];
      final fromIdx = block.participants.indexOf(s.from);
      final toIdx = block.participants.indexOf(s.to);
      if (fromIdx < 0 || toIdx < 0) continue;

      final y = _headerHeight + _laneTopPadding + step * _rowHeight;
      final x1 = laneX[fromIdx];
      final x2 = laneX[toIdx];

      final arrowPaint = Paint()
        ..color = s.kind == 'reply'
            ? AppColors.magicPurple.withValues(alpha: 0.8)
            : AppColors.gold
        ..strokeWidth = 1.4
        ..style = PaintingStyle.stroke;

      if (s.kind == 'reply') {
        _drawDashedLine(canvas, Offset(x1, y), Offset(x2, y), arrowPaint);
      } else {
        canvas.drawLine(Offset(x1, y), Offset(x2, y), arrowPaint);
      }
      _drawArrowhead(canvas, Offset(x2, y), x2 >= x1, arrowPaint);

      // 라벨 (선 위 중앙).
      final midX = (x1 + x2) / 2;
      final labelRect = Rect.fromCenter(
        center: Offset(midX, y - 12),
        width: (x2 - x1).abs().clamp(80.0, 280.0),
        height: 18,
      );
      _paintText(canvas, s.label, labelRect, AppColors.parchment);
    }
  }

  void _paintText(Canvas canvas, String text, Rect rect, Color color,
      {bool bold = false}) {
    final tp = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: bold ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
      maxLines: 2,
      ellipsis: '…',
    );
    tp.layout(maxWidth: rect.width);
    tp.paint(
      canvas,
      Offset(
        rect.left + (rect.width - tp.width) / 2,
        rect.top + (rect.height - tp.height) / 2,
      ),
    );
  }

  void _drawArrowhead(Canvas canvas, Offset tip, bool pointingRight, Paint p) {
    const size = 5.0;
    final path = Path();
    if (pointingRight) {
      path.moveTo(tip.dx, tip.dy);
      path.lineTo(tip.dx - size, tip.dy - size);
      path.lineTo(tip.dx - size, tip.dy + size);
    } else {
      path.moveTo(tip.dx, tip.dy);
      path.lineTo(tip.dx + size, tip.dy - size);
      path.lineTo(tip.dx + size, tip.dy + size);
    }
    path.close();
    canvas.drawPath(path, Paint()..color = p.color);
  }

  void _drawDashedLine(Canvas canvas, Offset a, Offset b, Paint p) {
    const dashLen = 6.0;
    const gap = 4.0;
    final total = (b - a).distance;
    final unit = (b - a) / total;
    var traveled = 0.0;
    while (traveled < total) {
      final start = a + unit * traveled;
      final end = a + unit * (traveled + dashLen).clamp(0.0, total);
      canvas.drawLine(start, end, p);
      traveled += dashLen + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _SequencePainter oldDelegate) =>
      oldDelegate.block != block;
}
