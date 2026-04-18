import 'package:flutter_test/flutter_test.dart';

import '../../tools/content_builder.dart';

/// Phase 3 PR #7 — flowchart 파서 보강 케이스.
/// MSA 실측에서 drop 됐던 주요 패턴을 회복.
void main() {
  Map<String, dynamic> parseFlowchartSingle(String mermaidBody) {
    const wrapper = '# Doc\n\n## Sec\n\n';
    final result =
        parseMdToChapter('$wrapper```mermaid\n$mermaidBody\n```\n',
            'x-01', 1);
    final sections = result['theory']['sections'] as List;
    final blocks =
        (sections.first as Map<String, dynamic>)['blocks'] as List;
    return blocks.firstWhere((b) => b['type'] == 'flowchart')
        as Map<String, dynamic>;
  }

  group('flowchart parser — PR #7 확장', () {
    test(':::className suffix 스트립 (노드 선언 + 엣지 라인)', () {
      final block = parseFlowchartSingle('''
flowchart TD
    A[Client]:::primary --> B[Server]:::service
    C((End)):::success
''');
      final ids = (block['nodes'] as List).map((n) => n['id']).toSet();
      expect(ids, {'A', 'B', 'C'});
      final edge = (block['edges'] as List).single;
      expect(edge['from'], 'A');
      expect(edge['to'], 'B');
    });

    test('Stadium `([text])` 노드 → shape round', () {
      final block = parseFlowchartSingle('''
flowchart TD
    A([Browser])
    B[Server]
    A --> B
''');
      final nodeA = (block['nodes'] as List)
          .firstWhere((n) => n['id'] == 'A') as Map<String, dynamic>;
      expect(nodeA['shape'], 'round');
      expect(nodeA['label'], 'Browser');
    });

    test('Cylinder `[(text)]` 노드 → shape rect', () {
      final block = parseFlowchartSingle('''
flowchart TD
    DB[(Database)]
    APP[App]
    APP --> DB
''');
      final nodeDB = (block['nodes'] as List)
          .firstWhere((n) => n['id'] == 'DB') as Map<String, dynamic>;
      expect(nodeDB['shape'], 'rect');
      expect(nodeDB['label'], 'Database');
    });

    test('~~~ invisible link은 엣지 emit 없이 양쪽 id 등록만', () {
      final block = parseFlowchartSingle('''
flowchart TD
    A ~~~ B ~~~ C
    A --> D
''');
      final ids = (block['nodes'] as List).map((n) => n['id']).toSet();
      expect(ids, containsAll(['A', 'B', 'C', 'D']));
      final edges = block['edges'] as List;
      expect(edges, hasLength(1),
          reason: 'invisible link은 엣지로 emit되지 않음');
      expect(edges.single['from'], 'A');
      expect(edges.single['to'], 'D');
    });

    test('양방향 엣지 `A <--> B` 파싱', () {
      final block = parseFlowchartSingle('''
flowchart LR
    A[Client]
    B[Server]
    A <--> B
''');
      final edge = (block['edges'] as List).single;
      expect(edge['from'], 'A');
      expect(edge['to'], 'B');
    });

    test('엣지 end marker `--o`, `--x` 파싱', () {
      final block = parseFlowchartSingle('''
flowchart TD
    A --o B
    C --x D
''');
      final edges = block['edges'] as List;
      expect(edges, hasLength(2));
      expect(edges[0]['from'], 'A');
      expect(edges[0]['to'], 'B');
      expect(edges[1]['from'], 'C');
      expect(edges[1]['to'], 'D');
    });

    test('멀티웨이 `A & B --> C` 전개', () {
      final block = parseFlowchartSingle('''
flowchart TD
    A[Src1]
    B[Src2]
    C[Dest]
    A & B --> C
''');
      final edges = block['edges'] as List;
      expect(edges, hasLength(2));
      final pairs = edges.map((e) => '${e["from"]}→${e["to"]}').toSet();
      expect(pairs, {'A→C', 'B→C'});
    });

    test('멀티웨이 `A --> B & C` (오른쪽 전개)', () {
      final block = parseFlowchartSingle('''
flowchart TD
    A --> B & C
''');
      final pairs = (block['edges'] as List)
          .map((e) => '${e["from"]}→${e["to"]}')
          .toSet();
      expect(pairs, {'A→B', 'A→C'});
    });

    test('멀티웨이 + label `A & B -->|req| C`', () {
      final block = parseFlowchartSingle('''
flowchart TD
    A & B -->|"요청"| C
''');
      final edges = block['edges'] as List;
      expect(edges, hasLength(2));
      for (final e in edges) {
        expect(e['label'], '요청');
      }
    });

    test('class 지정 줄 `class A primary` 무시', () {
      final block = parseFlowchartSingle('''
flowchart TD
    A[Label] --> B[X]
    class A,B primary
''');
      // class 라인이 무시되고 flowchart 파싱은 성공해야 함.
      expect(block['edges'], hasLength(1));
    });

    test('click 지시자 `click A "url"` 무시', () {
      final block = parseFlowchartSingle('''
flowchart TD
    A[Link] --> B[Target]
    click A "https://example.com" "설명"
''');
      expect(block['edges'], hasLength(1));
    });

    test('`-->>` 시퀀스 변종 커넥터 (flowchart 안에서 오용된 케이스) 파싱', () {
      final block = parseFlowchartSingle('''
flowchart TD
    A --> B
    A -->> C
    A -->>> D
''');
      final edges = block['edges'] as List;
      expect(edges, hasLength(3));
      for (final e in edges) {
        expect(e['style'], 'solid');
      }
    });

    test('`==>>`, `==>>>` 두꺼운 시퀀스 변종도 thick으로 분류', () {
      final block = parseFlowchartSingle('''
flowchart TD
    A ==>> B
''');
      expect((block['edges'] as List).single['style'], 'thick');
    });
  });
}
