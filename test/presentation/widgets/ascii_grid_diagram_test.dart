import 'package:dol/presentation/widgets/blocks/ascii_grid_diagram.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// fix-4c/4d — `AsciiGridDiagram` 이 ASCII 박스 소스를 CustomPaint 기반
/// 그리드로 렌더하는지 검증.
void main() {
  Widget _wrap(String source) => MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AsciiGridDiagram(source: source),
          ),
        ),
      );

  testWidgets('기본 ASCII 박스 소스를 CustomPaint 로 렌더', (tester) async {
    await tester.pumpWidget(_wrap('┌──┐\n│A │\n└──┘'));
    await tester.pumpAndSettle();
    expect(find.byType(AsciiGridDiagram), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    // SelectableText 경로를 쓰지 않는다.
    expect(find.byType(SelectableText), findsNothing);
  });

  testWidgets('한글+ASCII 혼재 박스도 렌더 (예외 발생 없음)', (tester) async {
    const src = '┌─────────┐\n'
        '│ 서론      │\n'
        '│ 본론      │\n'
        '└─────────┘';
    await tester.pumpWidget(_wrap(src));
    await tester.pumpAndSettle();
    expect(find.byType(AsciiGridDiagram), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('빈 소스에서도 크래시 없이 렌더', (tester) async {
    await tester.pumpWidget(_wrap(''));
    await tester.pumpAndSettle();
    expect(find.byType(AsciiGridDiagram), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('여러 행 매우 긴 라인도 SizedBox width 내에서 렌더 (가로 스크롤)',
      (tester) async {
    final src = List.generate(20, (i) => '─' * 100).join('\n');
    await tester.pumpWidget(_wrap(src));
    await tester.pumpAndSettle();
    expect(find.byType(AsciiGridDiagram), findsOneWidget);
    // SingleChildScrollView (horizontal) 가 래핑한다.
    expect(find.byType(SingleChildScrollView), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
