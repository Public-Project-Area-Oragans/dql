import 'package:flutter/material.dart';

import '../../../core/constants/app_colors.dart';
import 'content_block_renderer.dart' show kMonospaceFamily, kMonospaceFallback;

/// fix-4c/fix-4d — ASCII 박스 다이어그램을 Flutter 네이티브 `CustomPaint` 로
/// 그리드 정렬해 그린다.
///
/// 배경: `SelectableText + fontFamily: monospace` 경로는 한글 전각 + ASCII
/// 반각 혼재 시 글리프 metric 충돌로 박스 문자(`┌─┐│└┘`) 정렬이 깨짐.
/// 본 위젯은 각 문자를 (col × cellW, row × lineH) 에 `TextPainter` 로 찍기
/// 때문에 폰트 advance metric 과 무관하게 **컬럼 정렬을 Flutter 그리기
/// 단계에서 강제**한다. ASCII = 1 셀, CJK/전각 = 2 셀.
class AsciiGridDiagram extends StatelessWidget {
  final String source;
  final double fontSize;

  const AsciiGridDiagram({
    super.key,
    required this.source,
    this.fontSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = TextStyle(
      color: AppColors.steamGreen,
      fontFamily: kMonospaceFamily,
      fontFamilyFallback: kMonospaceFallback,
      fontSize: fontSize,
      height: 1.0,
    );

    // JetBrainsMono 기준 'M' 의 advance 를 실측해 cellWidth 로 사용한다.
    // 이렇게 얻은 단일 cellWidth 로 모든 ASCII 반각을 정확히 같은 간격으로
    // 찍는다. CJK 전각은 2배.
    final probe = TextPainter(
      text: TextSpan(text: 'M', style: textStyle),
      textDirection: TextDirection.ltr,
    )..layout();
    final cellWidth = probe.width;
    final lineHeight = probe.height;

    final lines = source.split('\n');
    final maxCols = lines.fold<int>(0, (acc, line) {
      var col = 0;
      for (final rune in line.runes) {
        col += _isWide(rune) ? 2 : 1;
      }
      return col > acc ? col : acc;
    });

    final canvasWidth = maxCols * cellWidth;
    final canvasHeight = lines.length * lineHeight;

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
        child: SizedBox(
          width: canvasWidth,
          height: canvasHeight,
          child: CustomPaint(
            size: Size(canvasWidth, canvasHeight),
            painter: _AsciiGridPainter(
              source: source,
              style: textStyle,
              cellWidth: cellWidth,
              lineHeight: lineHeight,
            ),
          ),
        ),
      ),
    );
  }
}

class _AsciiGridPainter extends CustomPainter {
  final String source;
  final TextStyle style;
  final double cellWidth;
  final double lineHeight;

  _AsciiGridPainter({
    required this.source,
    required this.style,
    required this.cellWidth,
    required this.lineHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final lines = source.split('\n');
    for (var r = 0; r < lines.length; r++) {
      final line = lines[r];
      var col = 0;
      for (final rune in line.runes) {
        final ch = String.fromCharCode(rune);
        final wide = _isWide(rune);
        final tp = TextPainter(
          text: TextSpan(text: ch, style: style),
          textDirection: TextDirection.ltr,
        )..layout();
        final widthCells = wide ? 2 : 1;
        // 문자 실 너비가 (widthCells × cellWidth) 보다 좁으면 중앙 정렬,
        // 더 넓으면 그대로 찍는다 (아주 드문 엣지 케이스).
        final slotWidth = widthCells * cellWidth;
        final x = col * cellWidth + (slotWidth - tp.width) / 2;
        final y = r * lineHeight;
        tp.paint(canvas, Offset(x, y));
        col += widthCells;
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AsciiGridPainter old) =>
      old.source != source ||
      old.cellWidth != cellWidth ||
      old.lineHeight != lineHeight;
}

/// East Asian Wide 여부 판정. 완전 정확한 유니코드 EAW 테이블 대신 프로젝트
/// 콘텐츠(docs-source) 가 실제 사용하는 범위만 커버하는 최소 필터.
bool _isWide(int rune) {
  // Hangul Syllables
  if (rune >= 0xAC00 && rune <= 0xD7A3) return true;
  // Hangul Jamo / Extended
  if (rune >= 0x1100 && rune <= 0x11FF) return true;
  if (rune >= 0x3130 && rune <= 0x318F) return true;
  // Hiragana / Katakana
  if (rune >= 0x3040 && rune <= 0x309F) return true;
  if (rune >= 0x30A0 && rune <= 0x30FF) return true;
  // CJK Unified Ideographs (기본 + 확장 A)
  if (rune >= 0x3400 && rune <= 0x4DBF) return true;
  if (rune >= 0x4E00 && rune <= 0x9FFF) return true;
  // CJK Symbols & Punctuation — `·` (U+00B7) 는 반각, 그 외 일부 전각
  if (rune >= 0x3000 && rune <= 0x303F) return true;
  // Fullwidth ASCII 변형
  if (rune >= 0xFF00 && rune <= 0xFF60) return true;
  return false;
}
