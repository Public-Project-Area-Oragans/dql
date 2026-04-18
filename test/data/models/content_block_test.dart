import 'dart:convert';

import 'package:dol/data/models/content_block.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 3 "다이어그램 위젯 이주" PR #1 skeleton. sealed union 전체 variant의
/// fromJson/toJson 라운드트립 + discriminator 분기 검증.
void main() {
  group('ContentBlock.fromJson discriminator', () {
    test('type:prose → ProseBlock', () {
      final b = ContentBlock.fromJson({'type': 'prose', 'markdown': '## hi'});
      expect(b, isA<ProseBlock>());
      expect((b as ProseBlock).markdown, '## hi');
    });

    test('type:table → TableBlock', () {
      final b = ContentBlock.fromJson({
        'type': 'table',
        'headers': ['a', 'b'],
        'rows': [
          ['1', '2']
        ],
        'alignments': ['left', 'center'],
      });
      expect(b, isA<TableBlock>());
      final t = b as TableBlock;
      expect(t.headers, ['a', 'b']);
      expect(t.rows.first, ['1', '2']);
      expect(t.alignments, ['left', 'center']);
    });

    test('type:asciiDiagram → AsciiDiagramBlock', () {
      final b = ContentBlock.fromJson({
        'type': 'asciiDiagram',
        'source': '┌─┐\n└─┘',
      });
      expect(b, isA<AsciiDiagramBlock>());
      expect((b as AsciiDiagramBlock).source, '┌─┐\n└─┘');
    });

    test('type:flowchart → FlowchartBlock (nodes + edges 역직렬화)', () {
      final b = ContentBlock.fromJson({
        'type': 'flowchart',
        'direction': 'TB',
        'nodes': [
          {'id': 'a', 'label': 'A', 'shape': 'rect'}
        ],
        'edges': [
          {'from': 'a', 'to': 'a', 'label': 'loop', 'style': 'solid'}
        ],
      });
      expect(b, isA<FlowchartBlock>());
      final f = b as FlowchartBlock;
      expect(f.direction, 'TB');
      expect(f.nodes.single.id, 'a');
      expect(f.edges.single.label, 'loop');
    });

    test('type:sequence → SequenceBlock', () {
      final b = ContentBlock.fromJson({
        'type': 'sequence',
        'participants': ['X', 'Y'],
        'steps': [
          {'from': 'X', 'to': 'Y', 'label': 'req', 'kind': 'sync'}
        ],
      });
      expect(b, isA<SequenceBlock>());
      expect((b as SequenceBlock).steps.single.label, 'req');
    });

    test('type:mindmap → MindmapBlock (재귀 역직렬화)', () {
      final b = ContentBlock.fromJson({
        'type': 'mindmap',
        'root': {
          'label': 'root',
          'children': [
            {
              'label': 'child',
              'children': [
                {'label': 'leaf', 'children': <Map<String, dynamic>>[]}
              ]
            }
          ]
        }
      });
      expect(b, isA<MindmapBlock>());
      final root = (b as MindmapBlock).root;
      expect(root.label, 'root');
      expect(root.children.single.children.single.label, 'leaf');
    });

    test('type:raw → RawBlock', () {
      final b = ContentBlock.fromJson({
        'type': 'raw',
        'language': 'gantt',
        'source': 'gantt\n  title Foo',
      });
      expect(b, isA<RawBlock>());
      expect((b as RawBlock).language, 'gantt');
    });

    test('FlowchartEdge.style 기본값 solid / FlowchartEdge.label 기본값 ""',
        () {
      final e = FlowchartEdge.fromJson({'from': 'a', 'to': 'b'});
      expect(e.style, 'solid');
      expect(e.label, '');
    });

    test('SequenceStep.kind 기본값 sync', () {
      final s = SequenceStep.fromJson({
        'from': 'A',
        'to': 'B',
        'label': 'x',
      });
      expect(s.kind, 'sync');
    });

    test('MindmapNode.children 기본값 빈 리스트', () {
      final n = MindmapNode.fromJson({'label': 'leaf'});
      expect(n.children, isEmpty);
    });
  });

  group('ContentBlock.toJson 라운드트립', () {
    void checkRoundTrip(ContentBlock original) {
      final encoded = jsonEncode(original.toJson());
      final decoded = ContentBlock.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );
      expect(decoded.runtimeType, original.runtimeType);
      expect(decoded, original);
    }

    test('ProseBlock 라운드트립', () {
      checkRoundTrip(const ProseBlock(markdown: 'hello'));
    });

    test('FlowchartBlock 라운드트립 (nested 객체 포함)', () {
      checkRoundTrip(const FlowchartBlock(
        direction: 'LR',
        nodes: [FlowchartNode(id: 'x', label: 'X', shape: 'diamond')],
        edges: [
          FlowchartEdge(
              from: 'x', to: 'x', label: 'self', style: 'dashed')
        ],
      ));
    });

    test('MindmapBlock 라운드트립 (재귀 구조)', () {
      checkRoundTrip(const MindmapBlock(
        root: MindmapNode(
          label: 'a',
          children: [MindmapNode(label: 'b', children: [])],
        ),
      ));
    });
  });
}
