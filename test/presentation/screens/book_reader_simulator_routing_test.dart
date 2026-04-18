import 'package:dol/data/models/book_model.dart';
import 'package:dol/domain/providers/content_providers.dart';
import 'package:dol/presentation/screens/book_reader_screen.dart';
import 'package:dol/presentation/simulators/code_step_simulator.dart';
import 'package:dol/presentation/simulators/structure_assembly_simulator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 2 Task 2-6 IRON RULE: sealed union 리팩터가 기존 CodeStep 라우팅을
/// 깨뜨리지 않는지 검증. CodeStep / StructureAssembly / 알 수 없는 type 세 분기
/// 모두 기대한 위젯으로 라우팅되어야 한다.
void main() {
  group('BookReaderScreen simulator 라우팅 (CRITICAL 회귀)', () {
    const bookId = 'test-category';

    TheoryContent _emptyTheory() {
      return const TheoryContent(
        sections: [],
        codeExamples: [],
        diagrams: [],
      );
    }

    Book _bookWith(Chapter chapter) {
      return Book(
        id: bookId,
        title: 'Test Book',
        category: bookId,
        chapters: [chapter],
      );
    }

    Future<void> _pump(WidgetTester tester, Book book, String chapterId) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            bookByIdProvider(bookId).overrideWith((ref) => book),
          ],
          child: MaterialApp(
            home: BookReaderScreen(
              bookId: bookId,
              chapterId: chapterId,
            ),
          ),
        ),
      );
      await tester.pump();
      // TabBarView의 두번째 탭(시뮬레이터) 활성화
      await tester.tap(find.text('⚡ 시뮬레이터'));
      await tester.pumpAndSettle();
    }

    testWidgets(
        'CodeStepConfig(steps 있음) → CodeStepSimulator 렌더 (Phase 1 하위호환)',
        (tester) async {
      final chapter = Chapter(
        id: 'ch-codestep',
        title: 'CodeStep 챕터',
        order: 1,
        theory: _emptyTheory(),
        simulator: const SimulatorConfig.codeStep(
          steps: [
            SimStep(
              instruction: '변수를 선언',
              code: 'int x = 10;',
              expectedState: {'x': 10},
            ),
          ],
          completionCriteria: CompletionRule(minStepsCompleted: 1),
        ),
      );

      await _pump(tester, _bookWith(chapter), 'ch-codestep');

      expect(find.byType(CodeStepSimulator), findsOneWidget);
      expect(find.byType(StructureAssemblySimulator), findsNothing);
    });

    testWidgets(
        'StructureAssemblyConfig → StructureAssemblySimulator 렌더 (Phase 2)',
        (tester) async {
      final chapter = Chapter(
        id: 'ch-assembly',
        title: 'Assembly 챕터',
        order: 1,
        theory: _emptyTheory(),
        simulator: const SimulatorConfig.structureAssembly(
          gridSize: GridSize(cols: 5, rows: 5),
          palette: [
            PaletteItem(id: 'a', label: 'A', spriteKey: 'a'),
          ],
          solution: AssemblySolution(
            nodes: [AssemblyNode(id: 'a', pos: GridPos(col: 0, row: 0))],
            edges: [],
          ),
          partialFeedback: PartialFeedback(
            missingNodes: 'm',
            missingEdges: 'm',
            extraEdges: 'e',
          ),
        ),
      );

      await _pump(tester, _bookWith(chapter), 'ch-assembly');

      expect(find.byType(StructureAssemblySimulator), findsOneWidget);
      expect(find.byType(CodeStepSimulator), findsNothing);
    });

    testWidgets(
        'CodeStepConfig(steps 빈 상태) → "준비 중" fallback (대조군 케이스)',
        (tester) async {
      // Phase 2 Task 2-1의 대조군(msa-phase4-step1-api-gateway)이 해당 경로.
      // content_builder의 default simulator는 steps=[]이므로 fallback으로 떨어져야 한다.
      final chapter = Chapter(
        id: 'ch-control',
        title: '대조군 챕터',
        order: 1,
        theory: _emptyTheory(),
        simulator: const SimulatorConfig.codeStep(
          steps: [],
          completionCriteria: CompletionRule(minStepsCompleted: 0),
        ),
      );

      await _pump(tester, _bookWith(chapter), 'ch-control');

      expect(find.textContaining('준비 중'), findsOneWidget);
      expect(find.byType(CodeStepSimulator), findsNothing);
      expect(find.byType(StructureAssemblySimulator), findsNothing);
    });
  });
}
