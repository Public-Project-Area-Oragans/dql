import 'package:dol/data/models/book_model.dart';
import 'package:dol/domain/providers/content_providers.dart';
import 'package:dol/domain/providers/game_providers.dart';
import 'package:dol/presentation/overlays/quest_board_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase P0-5 / NPC-1 — QuestBoardOverlay가 `questBoardFilterCategoryProvider`
/// 값에 따라 책 목록을 필터링하는지 검증.
void main() {
  Book _book(String id, String category, String title, int chapters) {
    return Book(
      id: id,
      title: title,
      category: category,
      chapters: List.generate(
        chapters,
        (i) => Chapter(
          id: '$id-ch$i',
          title: '$title Ch $i',
          order: i + 1,
          theory: const TheoryContent(
            sections: [],
            codeExamples: [],
            diagrams: [],
          ),
          simulator: const SimulatorConfig.codeStep(
            steps: [],
            completionCriteria: CompletionRule(minStepsCompleted: 0),
          ),
        ),
      ),
    );
  }

  Widget harness({String? filterCategory}) {
    return ProviderScope(
      overrides: [
        allBooksProvider.overrideWith((ref) async => [
              _book('java-spring', 'java-spring', 'Java & Spring', 2),
              _book('mysql', 'mysql', 'MySQL', 2),
              _book('msa', 'msa', 'MSA', 2),
            ]),
        if (filterCategory != null)
          questBoardFilterCategoryProvider.overrideWith(
            () => _StubFilter(filterCategory),
          ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: QuestBoardOverlay(
            onClose: () {},
            onChapterSelected: (_, _) {},
          ),
        ),
      ),
    );
  }

  group('QuestBoardOverlay 카테고리 필터', () {
    testWidgets('filterCategory가 null이면 모든 책 노출', (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      expect(find.text('Java & Spring'), findsOneWidget);
      expect(find.text('MySQL'), findsOneWidget);
      expect(find.text('MSA'), findsOneWidget);
    });

    testWidgets('filterCategory=mysql 일 때 MySQL 책만 노출', (tester) async {
      await tester.pumpWidget(harness(filterCategory: 'mysql'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      expect(find.text('MySQL'), findsOneWidget);
      expect(find.text('Java & Spring'), findsNothing);
      expect(find.text('MSA'), findsNothing);
    });

    testWidgets('filterCategory=java-spring 일 때 Java & Spring만 노출',
        (tester) async {
      await tester.pumpWidget(harness(filterCategory: 'java-spring'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      expect(find.text('Java & Spring'), findsOneWidget);
      expect(find.text('MySQL'), findsNothing);
    });

    testWidgets('filterCategory가 어느 책에도 없는 카테고리면 empty 메시지',
        (tester) async {
      await tester.pumpWidget(harness(filterCategory: 'unknown-cat'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      expect(find.textContaining('책이 없습니다'), findsOneWidget);
    });
  });
}

/// 테스트에서 `questBoardFilterCategoryProvider.overrideWith` 문법이
/// generated Notifier를 구현해야 하므로 간단한 stub.
class _StubFilter extends QuestBoardFilterCategory {
  final String _value;
  _StubFilter(this._value);

  @override
  String? build() => _value;
}
