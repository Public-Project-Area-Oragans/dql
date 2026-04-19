import 'package:dol/data/models/book_model.dart';
import 'package:dol/presentation/simulators/structure_assembly_simulator.dart';
import 'package:dol/presentation/widgets/steampunk_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _gateway = AssemblyNode(id: 'gateway', pos: GridPos(col: 2, row: 0));
const _serviceA = AssemblyNode(id: 'serviceA', pos: GridPos(col: 1, row: 2));
const _serviceB = AssemblyNode(id: 'serviceB', pos: GridPos(col: 3, row: 2));

StructureAssemblyConfig _sampleConfig({
  List<PaletteItem> palette = const [
    PaletteItem(id: 'gateway', label: 'API Gateway', spriteKey: 'gateway'),
    PaletteItem(id: 'serviceA', label: 'Service A', spriteKey: 'service'),
    PaletteItem(id: 'serviceB', label: 'Service B', spriteKey: 'service'),
  ],
}) {
  return StructureAssemblyConfig(
    gridSize: const GridSize(cols: 5, rows: 5),
    palette: palette,
    solution: const AssemblySolution(
      nodes: [_gateway, _serviceA, _serviceB],
      edges: [
        AssemblyEdge(from: 'gateway', to: 'serviceA'),
        AssemblyEdge(from: 'gateway', to: 'serviceB'),
      ],
    ),
    partialFeedback: const PartialFeedback(
      missingNodes: 'missing: {names}',
      missingEdges: 'missing edges: {pairs}',
      extraEdges: 'extra edges: {pairs}',
    ),
  );
}

Widget _harness(StructureAssemblyConfig config, {VoidCallback? onComplete}) {
  return MaterialApp(
    home: Scaffold(
      body: SingleChildScrollView(
        child: StructureAssemblySimulator(
          config: config,
          onComplete: onComplete ?? () {},
        ),
      ),
    ),
  );
}

void main() {
  group('StructureAssemblySimulator smoke', () {
    testWidgets('헤더·팔레트·캔버스·판정 버튼이 렌더된다', (tester) async {
      await tester.pumpWidget(_harness(_sampleConfig()));
      expect(find.text('🪙 조립 과제'), findsOneWidget);
      expect(find.text('팔레트'), findsOneWidget);
      expect(find.text('캔버스 5 × 5'), findsOneWidget);
      expect(find.text('⚖ 판정'), findsOneWidget);
      expect(find.text('🔄 리셋'), findsOneWidget);
    });

    testWidgets('팔레트의 모든 블록이 렌더된다', (tester) async {
      await tester.pumpWidget(_harness(_sampleConfig()));
      expect(find.text('API Gateway'), findsOneWidget);
      expect(find.text('Service A'), findsOneWidget);
      expect(find.text('Service B'), findsOneWidget);
    });

    testWidgets('빈 팔레트 구성이면 안내 문구가 보인다', (tester) async {
      await tester.pumpWidget(_harness(_sampleConfig(palette: const [])));
      expect(find.textContaining('팔레트가 비어있습니다'), findsOneWidget);
    });

    testWidgets('배치 전에는 판정 버튼이 disabled (onPressed null)', (tester) async {
      await tester.pumpWidget(_harness(_sampleConfig()));
      // art-2: SteampunkButton 이 ElevatedButton 랩퍼에서 StatefulWidget
      // 스프라이트 버튼으로 이주 — 타입 매칭도 업데이트.
      final button = tester.widget<SteampunkButton>(
        find
            .ancestor(
              of: find.text('⚖ 판정'),
              matching: find.byType(SteampunkButton),
            )
            .first,
      );
      expect(button.onPressed, isNull,
          reason: '빈 캔버스에서는 판정 버튼 비활성');
    });

    testWidgets('빈 캔버스일 때 힌트 텍스트가 보인다', (tester) async {
      await tester.pumpWidget(_harness(_sampleConfig()));
      expect(find.textContaining('팔레트에서 블록을 끌어오세요'), findsOneWidget);
    });

    testWidgets('배치/연결 수 배지가 0/0로 시작한다', (tester) async {
      await tester.pumpWidget(_harness(_sampleConfig()));
      expect(find.text('배치 0 / 연결 0'), findsOneWidget);
    });

    testWidgets('리셋 버튼은 항상 활성', (tester) async {
      await tester.pumpWidget(_harness(_sampleConfig()));
      final button = tester.widget<SteampunkButton>(
        find
            .ancestor(
              of: find.text('🔄 리셋'),
              matching: find.byType(SteampunkButton),
            )
            .first,
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('Semantics 컨테이너 label이 존재 (a11y)', (tester) async {
      await tester.pumpWidget(_harness(_sampleConfig()));
      final semantics = tester.getSemantics(
        find.byType(StructureAssemblySimulator),
      );
      // Semantics 트리에 특정 label 노드 탐색
      expect(semantics, isNotNull);
    });

    testWidgets('Draggable 위젯이 팔레트 항목 수만큼 존재', (tester) async {
      await tester.pumpWidget(_harness(_sampleConfig()));
      expect(find.byType(Draggable<PaletteItem>), findsNWidgets(3));
    });

    testWidgets('DragTarget 셀이 gridSize (5×5 = 25) 만큼 존재', (tester) async {
      await tester.pumpWidget(_harness(_sampleConfig()));
      expect(find.byType(DragTarget<PaletteItem>), findsNWidgets(25));
    });
  });
}
