import 'package:dol/data/models/content_block.dart';
import 'package:dol/presentation/widgets/blocks/content_block_renderer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// fix-3 — Flutter Web CanvasKit 에서 generic `'monospace'` 가 실제 monospace
/// 로 매핑되지 않아 ASCII 박스 드로잉 정렬이 깨지는 문제 회귀 가드.
///
/// `AsciiDiagramBlock` / `RawBlock` 은 모두 `_MonospaceScroll` 을 통해 렌더되며,
/// 그 내부 `SelectableText` 의 `TextStyle.fontFamilyFallback` 가
/// `kMonospaceFallback` 과 동일해야 한다.
void main() {
  group('monospace 상수', () {
    test('kMonospaceFamily 는 번들된 JetBrainsMono 패밀리', () {
      // fix-4a: pubspec.yaml 의 fonts: family 선언과 동일해야 한다.
      expect(kMonospaceFamily, 'JetBrainsMono');
    });

    test('kMonospaceFallback 은 플랫폼별 실 monospace 를 순서대로 나열', () {
      expect(kMonospaceFallback, contains('Consolas'));
      expect(kMonospaceFallback, contains('Menlo'));
      expect(kMonospaceFallback, contains('DejaVu Sans Mono'));
      expect(kMonospaceFallback.last, 'monospace');
    });
  });

  Future<TextStyle> _styleOf(
    WidgetTester tester,
    ContentBlock block,
  ) async {
    await tester.pumpWidget(MaterialApp(
      home: Scaffold(body: ContentBlockRenderer(block: block)),
    ));
    await tester.pumpAndSettle();
    final selectable = tester.widget<SelectableText>(
      find.byType(SelectableText),
    );
    return selectable.style!;
  }

  group('ContentBlockRenderer — monospace fallback 전파', () {
    testWidgets('AsciiDiagramBlock 은 JetBrainsMono + kMonospaceFallback',
        (tester) async {
      final style = await _styleOf(
        tester,
        const ContentBlock.asciiDiagram(
          source: '┌──┐\n│ A │\n└──┘',
        ),
      );
      expect(style.fontFamily, kMonospaceFamily);
      expect(style.fontFamilyFallback, kMonospaceFallback);
    });

    testWidgets('RawBlock 도 동일 fallback 적용', (tester) async {
      final style = await _styleOf(
        tester,
        const ContentBlock.raw(
          language: 'gantt',
          source: 'gantt\n  section Foo\n  task1: 2026-01-01, 5d',
        ),
      );
      expect(style.fontFamily, kMonospaceFamily);
      expect(style.fontFamilyFallback, kMonospaceFallback);
    });
  });
}
