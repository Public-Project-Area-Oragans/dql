import 'package:dol/data/models/book_model.dart';
import 'package:dol/domain/providers/content_providers.dart';
import 'package:dol/domain/providers/game_providers.dart';
import 'package:dol/presentation/overlays/quest_board_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase P0-5 / NPC-1 — QuestBoardOverlay 가 `questBoardFilterCategoryProvider`
/// 값에 따라 책 목록을 필터링.
///
/// fix-6 (2026-04-19) — 분관 책장(filterCategory != null) 경로에서 책 타이틀
/// 헤더 제거, 챕터는 모든 책을 flat 병합해서 책 사이엔 얇은 divider 만 둔다.
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

  Widget harness({String? filterCategory, List<Book>? books}) {
    final effectiveBooks = books ??
        [
          _book('java-spring', 'java-spring', 'Java & Spring', 2),
          _book('mysql', 'mysql', 'MySQL', 2),
          _book('msa', 'msa', 'MSA', 2),
        ];
    return ProviderScope(
      overrides: [
        allBooksProvider.overrideWith((ref) async => effectiveBooks),
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
    testWidgets('filterCategory 가 null 이면 모든 책이 ExpansionTile 로 노출',
        (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      expect(find.text('Java & Spring'), findsOneWidget);
      expect(find.text('MySQL'), findsOneWidget);
      expect(find.text('MSA'), findsOneWidget);
    });

    testWidgets('filterCategory=mysql 일 때 MySQL 챕터만 노출, 타 책 숨김',
        (tester) async {
      await tester.pumpWidget(harness(filterCategory: 'mysql'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      // fix-6: 책 타이틀 텍스트는 더 이상 헤더로 렌더되지 않는다.
      expect(find.text('MySQL'), findsNothing);
      expect(find.text('📖 MySQL'), findsNothing);

      // MySQL 책의 챕터만 보여야 한다.
      expect(find.text('MySQL Ch 0'), findsOneWidget);
      expect(find.text('MySQL Ch 1'), findsOneWidget);
      expect(find.text('Java & Spring Ch 0'), findsNothing);
      expect(find.text('MSA Ch 0'), findsNothing);
    });

    testWidgets('filterCategory 가 어느 책에도 없으면 empty 메시지',
        (tester) async {
      await tester.pumpWidget(harness(filterCategory: 'unknown-cat'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      expect(find.textContaining('책이 없습니다'), findsOneWidget);
    });
  });

  group('QuestBoardOverlay 챕터 평탄화 (fix-6)', () {
    testWidgets(
        '분관 책장 필터 시 ExpansionTile 없이 챕터 즉시 노출, 이모지 없음',
        (tester) async {
      await tester.pumpWidget(harness(filterCategory: 'mysql'));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      expect(find.byType(ExpansionTile), findsNothing);
      expect(find.text('MySQL Ch 0'), findsOneWidget);
      expect(find.text('MySQL Ch 1'), findsOneWidget);
      // 이모지 헤더 제거 확인.
      expect(find.textContaining('📖'), findsNothing);
    });

    testWidgets(
        '중앙 홀(filterCategory null) 은 기존처럼 ExpansionTile 접혀있음',
        (tester) async {
      await tester.pumpWidget(harness());
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();
      expect(find.byType(ExpansionTile), findsNWidgets(3));
      expect(find.text('MySQL Ch 0'), findsNothing);
    });

    testWidgets(
        'frontend 분관 시나리오: 2책 모든 챕터 평탄 노출 + 책 사이 divider',
        (tester) async {
      // frontend 분관에서 dart + flutter 두 shelf 가 같은 filter 로
      // 묶인 상황 시뮬레이션. 실 앱은 shelf 별로 1 카테고리씩 필터하지만,
      // divider 로직은 books 목록에 2권 이상 있으면 동작해야 한다.
      final dartBook = _book('dart', 'frontend', 'Dart Programing', 2);
      final flutterBook =
          _book('flutter', 'frontend', 'Flutter Programing', 2);
      await tester.pumpWidget(harness(
        filterCategory: 'frontend',
        books: [dartBook, flutterBook],
      ));
      await tester.pump(const Duration(milliseconds: 50));
      await tester.pump();

      // 두 책의 모든 챕터가 한 번에 보인다.
      expect(find.text('Dart Programing Ch 0'), findsOneWidget);
      expect(find.text('Dart Programing Ch 1'), findsOneWidget);
      expect(find.text('Flutter Programing Ch 0'), findsOneWidget);
      expect(find.text('Flutter Programing Ch 1'), findsOneWidget);

      // 책 사이 divider 한 줄만 삽입.
      expect(find.byType(Divider), findsOneWidget);
    });
  });
}

/// 테스트에서 `questBoardFilterCategoryProvider.overrideWith` 문법이
/// generated Notifier 를 구현해야 하므로 간단한 stub.
class _StubFilter extends QuestBoardFilterCategory {
  final String _value;
  _StubFilter(this._value);

  @override
  String? build() => _value;
}
