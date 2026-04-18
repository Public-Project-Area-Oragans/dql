import 'package:dol/data/models/content_block.dart';
import 'package:dol/presentation/widgets/blocks/table_block_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 3 PR #2 — TableBlockWidget 렌더 회귀 가드.
void main() {
  Widget harness(TableBlock block) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: TableBlockWidget(block: block),
        ),
      ),
    );
  }

  group('TableBlockWidget', () {
    testWidgets('헤더와 모든 데이터 셀이 렌더된다', (tester) async {
      await tester.pumpWidget(harness(const TableBlock(
        headers: ['이름', '나이'],
        rows: [
          ['Alice', '30'],
          ['Bob', '25']
        ],
        alignments: ['', 'right'],
      )));

      expect(find.text('이름'), findsOneWidget);
      expect(find.text('나이'), findsOneWidget);
      expect(find.text('Alice'), findsOneWidget);
      expect(find.text('30'), findsOneWidget);
      expect(find.text('Bob'), findsOneWidget);
      expect(find.text('25'), findsOneWidget);
    });

    testWidgets('Table 위젯이 존재한다 (이미지 X, 네이티브 Flutter Table)',
        (tester) async {
      await tester.pumpWidget(harness(const TableBlock(
        headers: ['A'],
        rows: [
          ['1']
        ],
        alignments: [''],
      )));
      expect(find.byType(Table), findsOneWidget);
      expect(find.byType(Image), findsNothing);
    });

    testWidgets('SingleChildScrollView(horizontal)로 감싸져 있음', (tester) async {
      await tester.pumpWidget(harness(const TableBlock(
        headers: ['A'],
        rows: [
          ['1']
        ],
        alignments: [''],
      )));
      final scroll = tester.widget<SingleChildScrollView>(
        find
            .ancestor(
              of: find.byType(Table),
              matching: find.byType(SingleChildScrollView),
            )
            .first,
      );
      expect(scroll.scrollDirection, Axis.horizontal);
    });

    testWidgets('정렬: center/right/left 매핑 확인', (tester) async {
      await tester.pumpWidget(harness(const TableBlock(
        headers: ['L', 'C', 'R'],
        rows: [
          ['a', 'b', 'c']
        ],
        alignments: ['left', 'center', 'right'],
      )));

      final lText = tester.widget<Text>(find.text('a'));
      final cText = tester.widget<Text>(find.text('b'));
      final rText = tester.widget<Text>(find.text('c'));
      expect(lText.textAlign, TextAlign.left);
      expect(cText.textAlign, TextAlign.center);
      expect(rText.textAlign, TextAlign.right);
    });

    testWidgets('행이 열보다 짧으면 빈 문자열로 채움 (크래시 없음)', (tester) async {
      await tester.pumpWidget(harness(const TableBlock(
        headers: ['A', 'B', 'C'],
        rows: [
          ['1', '2'] // 2개만
        ],
        alignments: ['', '', ''],
      )));
      expect(tester.takeException(), isNull);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('헤더만 있고 rows가 비어도 렌더된다', (tester) async {
      await tester.pumpWidget(harness(const TableBlock(
        headers: ['A', 'B'],
        rows: [],
        alignments: ['', ''],
      )));
      expect(find.text('A'), findsOneWidget);
      expect(find.text('B'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
