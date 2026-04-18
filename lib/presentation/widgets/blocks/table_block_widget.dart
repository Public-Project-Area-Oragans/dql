import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import '../../../data/models/content_block.dart';

/// GFM 표를 Flutter 내장 `Table` 위젯으로 렌더한다.
///
/// - 이미지 사용 없음. 모든 셀은 `Text` 기반.
/// - 넓은 표는 `SingleChildScrollView(Axis.horizontal)`로 감싸 뷰포트 초과
///   시 가로 스크롤 허용.
/// - 셀 정렬은 ContentBlock.table.alignments (left / center / right / "")
///   에 매핑.
class TableBlockWidget extends StatelessWidget {
  final TableBlock block;
  const TableBlockWidget({super.key, required this.block});

  @override
  Widget build(BuildContext context) {
    final columnCount = block.headers.length;
    // IntrinsicColumnWidth는 가장 긴 셀 기준으로 넓이를 잡음 → 가로 스크롤 효과.
    final columnWidths = <int, TableColumnWidth>{
      for (var i = 0; i < columnCount; i++) i: const IntrinsicColumnWidth(),
    };

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Table(
          columnWidths: columnWidths,
          defaultVerticalAlignment: TableCellVerticalAlignment.middle,
          border: TableBorder(
            horizontalInside: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.3),
              width: 0.5,
            ),
            verticalInside: BorderSide(
              color: AppColors.gold.withValues(alpha: 0.3),
              width: 0.5,
            ),
          ),
          children: [
            TableRow(
              decoration: const BoxDecoration(color: AppColors.deepPurple),
              children: [
                for (var i = 0; i < columnCount; i++)
                  _Cell(
                    text: block.headers[i],
                    alignment: _alignmentAt(i),
                    header: true,
                  ),
              ],
            ),
            for (final row in block.rows)
              TableRow(
                children: [
                  for (var i = 0; i < columnCount; i++)
                    _Cell(
                      text: i < row.length ? row[i] : '',
                      alignment: _alignmentAt(i),
                      header: false,
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  TextAlign _alignmentAt(int i) {
    if (i >= block.alignments.length) return TextAlign.left;
    switch (block.alignments[i]) {
      case 'center':
        return TextAlign.center;
      case 'right':
        return TextAlign.right;
      default:
        return TextAlign.left;
    }
  }
}

class _Cell extends StatelessWidget {
  final String text;
  final TextAlign alignment;
  final bool header;
  const _Cell({
    required this.text,
    required this.alignment,
    required this.header,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      child: Text(
        text,
        textAlign: alignment,
        style: TextStyle(
          color: header ? AppColors.brightGold : AppColors.parchment,
          fontSize: 13,
          fontWeight: header ? FontWeight.bold : FontWeight.normal,
          height: 1.4,
        ),
      ),
    );
  }
}
