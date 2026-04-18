import 'package:dol/data/models/book_model.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 2 Task 2-6: SimulatorConfig sealed union의 fromJson 디스패치 검증.
/// book_model_regression_test는 실제 book.json을 로드해 characterize하지만,
/// 이 테스트는 handcrafted JSON으로 **분기 단위**를 직접 검증한다.
void main() {
  group('SimulatorConfig.fromJson 디스패치', () {
    test('type:codeStep → CodeStepConfig로 파싱 (Phase 1 하위호환)', () {
      final json = <String, dynamic>{
        'type': 'codeStep',
        'steps': <Map<String, dynamic>>[
          {
            'instruction': '변수를 선언',
            'code': 'int x = 10;',
            'expectedState': {'x': 10},
          }
        ],
        'completionCriteria': {'minStepsCompleted': 1},
      };

      final config = SimulatorConfig.fromJson(json);

      expect(config, isA<CodeStepConfig>());
      final codeStep = config as CodeStepConfig;
      expect(codeStep.steps, hasLength(1));
      expect(codeStep.steps.first.instruction, '변수를 선언');
      expect(codeStep.completionCriteria.minStepsCompleted, 1);
    });

    test('type:structureAssembly → StructureAssemblyConfig로 파싱', () {
      final json = <String, dynamic>{
        'type': 'structureAssembly',
        'gridSize': {'cols': 5, 'rows': 5},
        'palette': [
          {'id': 'gateway', 'label': 'API Gateway', 'spriteKey': 'gateway'},
          {'id': 'service', 'label': 'Service', 'spriteKey': 'service'},
        ],
        'solution': {
          'nodes': [
            {
              'id': 'gateway',
              'pos': {'col': 2, 'row': 0}
            },
            {
              'id': 'service',
              'pos': {'col': 2, 'row': 2}
            },
          ],
          'edges': [
            {'from': 'gateway', 'to': 'service', 'directed': true},
          ],
        },
        'partialFeedback': {
          'missingNodes': 'missing: {names}',
          'missingEdges': 'missing edges: {pairs}',
          'extraEdges': 'extra edges: {pairs}',
        },
      };

      final config = SimulatorConfig.fromJson(json);

      expect(config, isA<StructureAssemblyConfig>());
      final assembly = config as StructureAssemblyConfig;
      expect(assembly.gridSize.cols, 5);
      expect(assembly.gridSize.rows, 5);
      expect(assembly.palette, hasLength(2));
      expect(assembly.solution.nodes, hasLength(2));
      expect(assembly.solution.edges, hasLength(1));
      expect(assembly.solution.edges.first.from, 'gateway');
      expect(assembly.solution.edges.first.directed, isTrue);
      expect(assembly.partialFeedback.missingNodes, 'missing: {names}');
    });

    test('type 필드 누락 시 FromJson 예외 throw', () {
      // unionKey가 없으면 freezed fromJson이 판별 불가 → 예외.
      // 이 contract는 builder의 override JSON 작성 실수를 빌드 시점에서 잡아주는
      // 안전망으로 기능한다. 향후 fallback이 생기면 이 테스트가 빨갛게 떠
      // "의도한 behavior change"를 명확히 한다.
      final json = <String, dynamic>{
        'steps': <Map<String, dynamic>>[],
        'completionCriteria': {'minStepsCompleted': 0},
      };

      expect(() => SimulatorConfig.fromJson(json), throwsA(isA<Object>()));
    });
  });

  group('AssemblyEdge.fromJson', () {
    test('directed 필드 생략 시 기본값 true', () {
      final edge = AssemblyEdge.fromJson({'from': 'a', 'to': 'b'});
      expect(edge.from, 'a');
      expect(edge.to, 'b');
      expect(edge.directed, isTrue);
    });
  });
}
