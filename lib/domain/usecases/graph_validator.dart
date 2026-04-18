import '../../data/models/book_model.dart';

/// 구조 조립 시뮬레이터의 사용자 그래프를 정답과 비교한다.
///
/// 판정 축:
/// - 노드 ID 집합 일치 (위치는 시각 요소로만 쓰이고 판정 대상 아님 — Phase 2 범위)
/// - 엣지 집합 일치 (`directed=true`면 방향 고려, `false`면 정규화)
/// - 중복 엣지는 Set 변환으로 자동 제거
///
/// 결과는 sealed `ValidationResult`로 반환해 UI/오버레이가 패턴 매칭으로 분기.
abstract final class GraphValidator {
  const GraphValidator._();

  static ValidationResult validate({
    required List<AssemblyNode> userNodes,
    required List<AssemblyEdge> userEdges,
    required AssemblySolution expected,
  }) {
    if (userNodes.isEmpty && userEdges.isEmpty) {
      return const ValidationResult.empty();
    }

    final userNodeIds = userNodes.map((n) => n.id).toSet();
    final expectedNodeIds = expected.nodes.map((n) => n.id).toSet();

    final missingNodes = (expectedNodeIds.difference(userNodeIds).toList())
      ..sort();
    final extraNodes = (userNodeIds.difference(expectedNodeIds).toList())
      ..sort();

    final userEdgeKeys = userEdges.map(_edgeKey).toSet();
    final expectedEdgeKeys = expected.edges.map(_edgeKey).toSet();

    final missingEdges =
        expectedEdgeKeys.difference(userEdgeKeys).toList()..sort();
    final extraEdges =
        userEdgeKeys.difference(expectedEdgeKeys).toList()..sort();

    if (missingNodes.isEmpty &&
        extraNodes.isEmpty &&
        missingEdges.isEmpty &&
        extraEdges.isEmpty) {
      return const ValidationResult.correct();
    }

    return ValidationResult.partial(
      missingNodes: missingNodes,
      extraNodes: extraNodes,
      missingEdges: missingEdges,
      extraEdges: extraEdges,
    );
  }

  static EdgeKey _edgeKey(AssemblyEdge edge) {
    if (edge.directed) return EdgeKey(edge.from, edge.to);
    // undirected: 알파벳 순서로 정규화해 (A,B) == (B,A)
    final sorted = [edge.from, edge.to]..sort();
    return EdgeKey(sorted[0], sorted[1]);
  }
}

/// 엣지의 동등성 비교용 키. Set/difference 연산에서 사용.
class EdgeKey implements Comparable<EdgeKey> {
  final String from;
  final String to;

  const EdgeKey(this.from, this.to);

  @override
  bool operator ==(Object other) =>
      other is EdgeKey && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);

  @override
  int compareTo(EdgeKey other) {
    final byFrom = from.compareTo(other.from);
    return byFrom != 0 ? byFrom : to.compareTo(other.to);
  }

  @override
  String toString() => '$from → $to';
}

/// 판정 결과. sealed라 `switch (result) { case ValidationCorrect(): ... }` 매칭.
sealed class ValidationResult {
  const ValidationResult();

  const factory ValidationResult.correct() = ValidationCorrect;
  const factory ValidationResult.empty() = ValidationEmpty;
  const factory ValidationResult.partial({
    required List<String> missingNodes,
    required List<String> extraNodes,
    required List<EdgeKey> missingEdges,
    required List<EdgeKey> extraEdges,
  }) = ValidationPartial;
}

final class ValidationCorrect extends ValidationResult {
  const ValidationCorrect();
}

final class ValidationEmpty extends ValidationResult {
  const ValidationEmpty();
}

final class ValidationPartial extends ValidationResult {
  final List<String> missingNodes;
  final List<String> extraNodes;
  final List<EdgeKey> missingEdges;
  final List<EdgeKey> extraEdges;

  const ValidationPartial({
    required this.missingNodes,
    required this.extraNodes,
    required this.missingEdges,
    required this.extraEdges,
  });
}
