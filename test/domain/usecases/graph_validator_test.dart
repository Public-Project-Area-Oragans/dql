import 'package:dol/data/models/book_model.dart';
import 'package:dol/domain/usecases/graph_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('GraphValidator', () {
    // 공용 정답 그래프 (API Gateway 패턴 축소판)
    const gateway = AssemblyNode(id: 'gateway', pos: GridPos(col: 2, row: 0));
    const serviceA = AssemblyNode(id: 'serviceA', pos: GridPos(col: 1, row: 2));
    const serviceB = AssemblyNode(id: 'serviceB', pos: GridPos(col: 3, row: 2));

    AssemblySolution buildExpected() => const AssemblySolution(
          nodes: [gateway, serviceA, serviceB],
          edges: [
            AssemblyEdge(from: 'gateway', to: 'serviceA'),
            AssemblyEdge(from: 'gateway', to: 'serviceB'),
          ],
        );

    test('1. 완전 일치 → ValidationCorrect', () {
      final result = GraphValidator.validate(
        userNodes: const [gateway, serviceA, serviceB],
        userEdges: const [
          AssemblyEdge(from: 'gateway', to: 'serviceA'),
          AssemblyEdge(from: 'gateway', to: 'serviceB'),
        ],
        expected: buildExpected(),
      );

      expect(result, isA<ValidationCorrect>());
    });

    test('2. 노드 개수 불일치 (extra) → ValidationPartial(extraNodes)', () {
      const rogue = AssemblyNode(id: 'rogue', pos: GridPos(col: 0, row: 0));
      final result = GraphValidator.validate(
        userNodes: const [gateway, serviceA, serviceB, rogue],
        userEdges: const [
          AssemblyEdge(from: 'gateway', to: 'serviceA'),
          AssemblyEdge(from: 'gateway', to: 'serviceB'),
        ],
        expected: buildExpected(),
      );

      expect(result, isA<ValidationPartial>());
      final partial = result as ValidationPartial;
      expect(partial.extraNodes, ['rogue']);
      expect(partial.missingNodes, isEmpty);
    });

    test('3. 노드 종류 불일치 (missing + extra) → ValidationPartial', () {
      const substitute =
          AssemblyNode(id: 'dbCache', pos: GridPos(col: 3, row: 2));
      final result = GraphValidator.validate(
        userNodes: const [gateway, serviceA, substitute], // serviceB 자리에 dbCache
        userEdges: const [
          AssemblyEdge(from: 'gateway', to: 'serviceA'),
          AssemblyEdge(from: 'gateway', to: 'dbCache'),
        ],
        expected: buildExpected(),
      );

      final partial = result as ValidationPartial;
      expect(partial.missingNodes, ['serviceB']);
      expect(partial.extraNodes, ['dbCache']);
    });

    test('4. 엣지 방향 뒤집힘 (directed) → missing + extra', () {
      final result = GraphValidator.validate(
        userNodes: const [gateway, serviceA, serviceB],
        userEdges: const [
          AssemblyEdge(from: 'serviceA', to: 'gateway'), // 역방향
          AssemblyEdge(from: 'gateway', to: 'serviceB'),
        ],
        expected: buildExpected(),
      );

      final partial = result as ValidationPartial;
      expect(partial.missingEdges, contains(const EdgeKey('gateway', 'serviceA')));
      expect(partial.extraEdges, contains(const EdgeKey('serviceA', 'gateway')));
    });

    test('5. 엣지 일부 누락 (missing only) → ValidationPartial', () {
      final result = GraphValidator.validate(
        userNodes: const [gateway, serviceA, serviceB],
        userEdges: const [
          AssemblyEdge(from: 'gateway', to: 'serviceA'),
          // gateway → serviceB 누락
        ],
        expected: buildExpected(),
      );

      final partial = result as ValidationPartial;
      expect(partial.missingEdges, [const EdgeKey('gateway', 'serviceB')]);
      expect(partial.extraEdges, isEmpty);
      expect(partial.missingNodes, isEmpty);
    });

    test('6. 빈 그래프 (아무것도 배치 안 함) → ValidationEmpty', () {
      final result = GraphValidator.validate(
        userNodes: const [],
        userEdges: const [],
        expected: buildExpected(),
      );

      expect(result, isA<ValidationEmpty>());
    });

    test('7. 중복 엣지 정규화 (undirected) → 같은 것으로 처리', () {
      const undirectedExpected = AssemblySolution(
        nodes: [gateway, serviceA],
        edges: [
          AssemblyEdge(from: 'gateway', to: 'serviceA', directed: false),
        ],
      );

      // 사용자가 (serviceA, gateway, directed=false)로 배치
      final result = GraphValidator.validate(
        userNodes: const [gateway, serviceA],
        userEdges: const [
          AssemblyEdge(from: 'serviceA', to: 'gateway', directed: false),
        ],
        expected: undirectedExpected,
      );

      expect(result, isA<ValidationCorrect>(),
          reason: 'undirected 엣지는 정렬 정규화로 동등해야 함');
    });

    test('보조: 사용자가 중복 엣지를 여러 번 배치해도 Set으로 1개 처리', () {
      final result = GraphValidator.validate(
        userNodes: const [gateway, serviceA, serviceB],
        userEdges: const [
          AssemblyEdge(from: 'gateway', to: 'serviceA'),
          AssemblyEdge(from: 'gateway', to: 'serviceA'), // 중복
          AssemblyEdge(from: 'gateway', to: 'serviceB'),
        ],
        expected: buildExpected(),
      );

      expect(result, isA<ValidationCorrect>(),
          reason: '중복 엣지는 Set 변환으로 자동 제거되어야 함');
    });
  });
}
