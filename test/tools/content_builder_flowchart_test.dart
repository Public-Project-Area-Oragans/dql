import 'package:flutter_test/flutter_test.dart';

import '../../tools/content_builder.dart';

/// Phase 3 PR #4 — Mermaid flowchart 파서 검증.
void main() {
  List parseSectionBlocks(String sectionBody) {
    const wrapper = '# Doc\n\n## Sec\n\n';
    final result = parseMdToChapter(wrapper + sectionBody, 'x-01', 1);
    final sections = result['theory']['sections'] as List;
    return (sections.first as Map<String, dynamic>)['blocks'] as List;
  }

  Map<String, dynamic> parseFlowchartSingle(String mermaidBody) {
    final blocks = parseSectionBlocks('```mermaid\n$mermaidBody\n```\n');
    return blocks.firstWhere((b) => b['type'] == 'flowchart')
        as Map<String, dynamic>;
  }

  group('_parseMermaid → flowchart', () {
    test('가장 단순: flowchart TD + 노드 2 + 엣지 1', () {
      final block = parseFlowchartSingle('''
flowchart TD
    A[Client] --> B[Gateway]
''');
      expect(block['direction'], 'TB');
      final nodes = block['nodes'] as List;
      expect(nodes.map((n) => n['id']), containsAll(['A', 'B']));
      final labels = {
        for (final n in nodes) n['id']: n['label'],
      };
      expect(labels['A'], 'Client');
      expect(labels['B'], 'Gateway');
      final edges = block['edges'] as List;
      expect(edges.single['from'], 'A');
      expect(edges.single['to'], 'B');
      expect(edges.single['style'], 'solid');
    });

    test('direction LR 매핑', () {
      final block = parseFlowchartSingle('flowchart LR\n  A --> B\n');
      expect(block['direction'], 'LR');
    });

    test('엣지 스타일: dashed, thick', () {
      final block = parseFlowchartSingle('''
flowchart TD
    A -.-> B
    B ==> C
''');
      final edges = block['edges'] as List;
      expect(edges[0]['style'], 'dashed');
      expect(edges[1]['style'], 'thick');
    });

    test('엣지 라벨 | 구문 보존', () {
      final block = parseFlowchartSingle('''
flowchart TD
    A -->|"요청"| B
''');
      final edge = (block['edges'] as List).single;
      expect(edge['label'], '요청');
    });

    test('노드 형상: rect / round / circle / diamond', () {
      final block = parseFlowchartSingle('''
flowchart TD
    A[Rect]
    B(Round)
    C((Circle))
    D{Diamond}
    A --> B
    B --> C
    C --> D
''');
      final shapes = {
        for (final n in block['nodes'] as List) n['id']: n['shape'],
      };
      expect(shapes['A'], 'rect');
      expect(shapes['B'], 'round');
      expect(shapes['C'], 'circle');
      expect(shapes['D'], 'diamond');
    });

    test('<br/> 라벨은 공백으로 치환', () {
      final block =
          parseFlowchartSingle('flowchart TD\n  A["Client<br/>Browser"] --> B[X]\n');
      final label = (block['nodes'] as List)
          .firstWhere((n) => n['id'] == 'A')['label'];
      expect(label, 'Client Browser');
    });

    test('subgraph + classDef + class는 무시되고 노드/엣지만 추출', () {
      final block = parseFlowchartSingle('''
flowchart LR
    subgraph G["그룹"]
        A[Client]
        B[Server]
    end
    A --> B
    classDef primary fill:#fff
    class A primary
''');
      final nodeIds = (block['nodes'] as List).map((n) => n['id']).toSet();
      expect(nodeIds, {'A', 'B'});
      final edges = block['edges'] as List;
      expect(edges.single['from'], 'A');
      expect(edges.single['to'], 'B');
    });

    test('테마 지시 %%{init: ...}%% 는 무시', () {
      final block = parseFlowchartSingle('''
%%{init: {'theme': 'dark'}}%%
flowchart TD
    A --> B
''');
      expect(block['direction'], 'TB');
    });

    test('알 수 없는 문법은 RawBlock으로 폴백 (flowchart 아님)', () {
      final blocks = parseSectionBlocks('''
```mermaid
gantt
    title 일정
    section A
    작업1 :a1, 2026-01-01, 30d
```
''');
      final mermaidBlocks =
          blocks.where((b) => b['type'] == 'flowchart').toList();
      expect(mermaidBlocks, isEmpty);
      final raw = blocks.firstWhere((b) => b['type'] == 'raw');
      expect(raw['language'], 'mermaid');
      expect(raw['source'], contains('gantt'));
    });
  });
}
