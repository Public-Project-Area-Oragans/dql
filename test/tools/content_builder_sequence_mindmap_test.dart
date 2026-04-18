import 'package:flutter_test/flutter_test.dart';

import '../../tools/content_builder.dart';

/// Phase 3 PR #5 — sequenceDiagram + mindmap 파서 검증.
void main() {
  List parseSectionBlocks(String sectionBody) {
    const wrapper = '# Doc\n\n## Sec\n\n';
    final result = parseMdToChapter(wrapper + sectionBody, 'x-01', 1);
    final sections = result['theory']['sections'] as List;
    return (sections.first as Map<String, dynamic>)['blocks'] as List;
  }

  Map<String, dynamic> parseMermaidSingle(String mermaidBody, String type) {
    final blocks = parseSectionBlocks('```mermaid\n$mermaidBody\n```\n');
    return blocks.firstWhere((b) => b['type'] == type)
        as Map<String, dynamic>;
  }

  group('_parseMermaid → sequence', () {
    test('기본 participant + 메시지', () {
      final block = parseMermaidSingle('''
sequenceDiagram
    participant A as Alice
    participant B as Bob
    A->>B: Hello
''', 'sequence');
      expect(block['participants'], ['Alice', 'Bob']);
      final steps = block['steps'] as List;
      expect(steps.single['from'], 'Alice');
      expect(steps.single['to'], 'Bob');
      expect(steps.single['label'], 'Hello');
      expect(steps.single['kind'], 'sync');
    });

    test('reply 메시지(-->>)는 kind=reply', () {
      final block = parseMermaidSingle('''
sequenceDiagram
    participant A
    participant B
    A-->>B: Reply
''', 'sequence');
      expect((block['steps'] as List).single['kind'], 'reply');
    });

    test('암시적 participant (첫 언급 순서대로 추가)', () {
      final block = parseMermaidSingle('''
sequenceDiagram
    Alice->>Bob: Hello
    Bob->>Alice: Hi back
''', 'sequence');
      expect(block['participants'], ['Alice', 'Bob']);
      expect((block['steps'] as List).length, 2);
    });

    test('Note / alt / loop 등 제어 구조는 무시되고 메시지만 추출', () {
      final block = parseMermaidSingle('''
sequenceDiagram
    participant A
    participant B
    A->>B: 요청
    Note right of B: 처리 중...
    alt 성공
        B-->>A: 200 OK
    else 실패
        B-->>A: 500 Error
    end
''', 'sequence');
      final steps = block['steps'] as List;
      expect(steps.length, 3);
      expect(steps.first['label'], '요청');
      expect(steps.last['label'], '500 Error');
    });

    test('<br/> 라벨은 공백 치환', () {
      final block = parseMermaidSingle('''
sequenceDiagram
    A->>B: POST /orders<br/>Authorization: Bearer x
''', 'sequence');
      final label = (block['steps'] as List).single['label'];
      expect(label, 'POST /orders Authorization: Bearer x');
    });

    test('lost message `--x` 커넥터 (reply kind)', () {
      final block = parseMermaidSingle('''
sequenceDiagram
    participant A
    participant B
    B--xA: Connection Refused
''', 'sequence');
      expect((block['steps'] as List).single['kind'], 'reply');
      expect((block['steps'] as List).single['label'], 'Connection Refused');
    });

    test('async `--)` 커넥터', () {
      final block = parseMermaidSingle('''
sequenceDiagram
    A--)B: fire-and-forget
''', 'sequence');
      expect((block['steps'] as List).single['kind'], 'reply',
          reason: 'dash 2개면 reply 계열로 분류');
    });

    test('sync `-x` (단일 dash + x)', () {
      final block = parseMermaidSingle('''
sequenceDiagram
    A-xB: timeout
''', 'sequence');
      expect((block['steps'] as List).single['kind'], 'sync');
    });
  });

  group('_parseMermaid → mindmap', () {
    test('기본 루트 + 2단계 자식', () {
      final block = parseMermaidSingle('''
mindmap
  root((Core))
    Child1
      Grandchild
    Child2
''', 'mindmap');
      final root = block['root'] as Map<String, dynamic>;
      expect(root['label'], 'Core');
      final children = root['children'] as List;
      expect(children, hasLength(2));
      expect(children[0]['label'], 'Child1');
      expect(children[0]['children'], hasLength(1));
      expect((children[0]['children'] as List).first['label'], 'Grandchild');
      expect(children[1]['label'], 'Child2');
      expect((children[1]['children'] as List), isEmpty);
    });

    test('<br/> 라벨 치환 (root)', () {
      final block = parseMermaidSingle('''
mindmap
  root((인증/인가<br/>심화))
    OAuth2
''', 'mindmap');
      expect(block['root']['label'], '인증/인가 심화');
    });

    test('형제 노드가 같은 들여쓰기로 연속될 때 모두 root의 자식', () {
      final block = parseMermaidSingle('''
mindmap
  root((Main))
    A
    B
    C
''', 'mindmap');
      final children = block['root']['children'] as List;
      expect(children.map((c) => c['label']), ['A', 'B', 'C']);
    });

    test('들여쓰기가 깊어지다가 얕아지면 스택 pop', () {
      final block = parseMermaidSingle('''
mindmap
  root((R))
    A
      A1
      A2
    B
      B1
''', 'mindmap');
      final root = block['root'];
      final childA = (root['children'] as List)[0];
      final childB = (root['children'] as List)[1];
      expect(childA['label'], 'A');
      expect((childA['children'] as List).map((c) => c['label']),
          ['A1', 'A2']);
      expect(childB['label'], 'B');
      expect((childB['children'] as List).first['label'], 'B1');
    });
  });
}
