import 'package:flutter_test/flutter_test.dart';

import '../../tools/content_builder.dart';

/// Phase 3 PR #2 — GFM 표 파서 (_extractBlocks)의 분기 검증.
///
/// `_extractBlocks`는 private이라 `parseMdToChapter` 경유로 간접 검증.
void main() {
  Map<String, dynamic> parseSingleSection(String sectionBody) {
    // parseMdToChapter는 section heading이 필요하므로 최소한의 wrapper 추가.
    const wrapper = '# Doc\n\n## Sec\n\n';
    final result = parseMdToChapter(wrapper + sectionBody, 'x-01', 1);
    final sections = result['theory']['sections'] as List;
    return sections.first as Map<String, dynamic>;
  }

  group('_extractBlocks — GFM 표 검출', () {
    test('헤더 + 구분자 + 본문 2행 표 → TableBlock 1개 + 앞뒤 ProseBlock', () {
      final section = parseSingleSection('''
설명 문단입니다.

| 이름 | 나이 | 도시 |
|------|-----:|:----:|
| Alice | 30 | 서울 |
| Bob | 25 | 부산 |

뒤 단락입니다.
''');
      final blocks = section['blocks'] as List;

      expect(blocks, hasLength(3));
      expect(blocks[0]['type'], 'prose');
      expect(blocks[0]['markdown'], contains('설명 문단'));

      expect(blocks[1]['type'], 'table');
      expect(blocks[1]['headers'], ['이름', '나이', '도시']);
      expect(blocks[1]['rows'], [
        ['Alice', '30', '서울'],
        ['Bob', '25', '부산'],
      ]);
      expect(blocks[1]['alignments'], ['', 'right', 'center']);

      expect(blocks[2]['type'], 'prose');
      expect(blocks[2]['markdown'], contains('뒤 단락'));
    });

    test('헤더만 있고 본문 없는 표도 TableBlock으로 허용 (rows 빈 배열)', () {
      final section = parseSingleSection('''
| A | B |
|---|---|
''');
      final blocks = section['blocks'] as List;
      final table = blocks.firstWhere((b) => b['type'] == 'table');
      expect(table['headers'], ['A', 'B']);
      expect(table['rows'], isEmpty);
    });

    test('구분자 없는 pipe 라인은 표로 인식하지 않고 ProseBlock에 포함', () {
      final section = parseSingleSection('''
| 단순 | 텍스트 |
이어지는 내용.
''');
      final blocks = section['blocks'] as List;
      expect(blocks.every((b) => b['type'] == 'prose'), isTrue,
          reason: '구분자 없이는 GFM 표 아님 → 전체가 prose');
    });

    test('표 2개 연속 — 중간 공백 한 줄만 있어도 각각 분리된 TableBlock', () {
      final section = parseSingleSection('''
| H1 | H2 |
|----|----|
| a | b |

| X | Y |
|---|---|
| 1 | 2 |
''');
      final blocks = section['blocks'] as List;
      final tables = blocks.where((b) => b['type'] == 'table').toList();
      expect(tables, hasLength(2));
      expect(tables[0]['headers'], ['H1', 'H2']);
      expect(tables[1]['headers'], ['X', 'Y']);
    });

    test('표 밖 내용이 없으면 ProseBlock 없이 TableBlock 하나만', () {
      final section = parseSingleSection('''
| A | B |
|---|---|
| 1 | 2 |
''');
      final blocks = section['blocks'] as List;
      expect(blocks.where((b) => b['type'] == 'prose'), isEmpty);
      expect(blocks.where((b) => b['type'] == 'table'), hasLength(1));
    });

    test('열 수가 행마다 불일치하면 그 행부터 표 종료', () {
      final section = parseSingleSection('''
| A | B |
|---|---|
| 1 | 2 |
| 3 | 4 | 5 |
''');
      final blocks = section['blocks'] as List;
      final table = blocks.firstWhere((b) => b['type'] == 'table');
      expect(table['rows'], [
        ['1', '2']
      ], reason: '열 3개 행은 표에 포함되지 않고 prose로 밀려남');
      final prose = blocks.firstWhere((b) => b['type'] == 'prose');
      expect(prose['markdown'], contains('| 3 | 4 | 5 |'));
    });

    test('정렬 표기 4종 (left / right / center / default)', () {
      final section = parseSingleSection('''
| L | C | R | D |
|:---|:---:|---:|---|
| a | b | c | d |
''');
      final blocks = section['blocks'] as List;
      final table = blocks.firstWhere((b) => b['type'] == 'table');
      expect(table['alignments'], ['left', 'center', 'right', '']);
    });
  });
}
