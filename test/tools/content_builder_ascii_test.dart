import 'package:flutter_test/flutter_test.dart';

import '../../tools/content_builder.dart';

/// Phase 3 PR #3 — `_extractBlocks`의 ASCII 박스 다이어그램 분기 검증.
///
/// ```text / ```ascii / ```diagram / ``` 펜스 + 박스 드로잉 문자 → AsciiDiagramBlock.
/// 그 외 펜스(java, bash 등) 또는 박스 드로잉 없는 asciiLike 펜스는 prose에
/// 유지돼 flutter_markdown이 일반 코드블록으로 렌더.
void main() {
  Map<String, dynamic> parseSingleSection(String sectionBody) {
    const wrapper = '# Doc\n\n## Sec\n\n';
    final result = parseMdToChapter(wrapper + sectionBody, 'x-01', 1);
    final sections = result['theory']['sections'] as List;
    return sections.first as Map<String, dynamic>;
  }

  group('_extractBlocks — ASCII 박스 다이어그램', () {
    test('빈 언어 펜스 + 박스 드로잉 → AsciiDiagramBlock (fence 마커 제거)', () {
      final section = parseSingleSection('''
설명.

```
┌─────┐
│ Box │
└─────┘
```

끝.
''');
      final blocks = section['blocks'] as List;
      final ascii = blocks.firstWhere((b) => b['type'] == 'asciiDiagram');
      expect(ascii['source'], contains('┌─────┐'));
      expect(ascii['source'], contains('│ Box │'));
      expect(ascii['source'].contains('```'), isFalse,
          reason: 'source에는 fence 마커가 포함되면 안 됨');
    });

    test('text 언어 펜스 + 박스 드로잉 → AsciiDiagramBlock', () {
      final section = parseSingleSection('''
```text
트리
├── a
├── b
└── c
```
''');
      final blocks = section['blocks'] as List;
      expect(
        blocks.where((b) => b['type'] == 'asciiDiagram').length,
        1,
      );
    });

    test('ascii 언어 펜스 + 박스 드로잉 → AsciiDiagramBlock', () {
      final section = parseSingleSection('''
```ascii
┌─┐
└─┘
```
''');
      final blocks = section['blocks'] as List;
      expect(blocks.single['type'], 'asciiDiagram');
    });

    test(
        '박스 드로잉 없는 text 펜스는 codeExamples로 빠져 섹션 blocks에 AsciiDiagramBlock 생성 없음',
        () {
      // 현재 parseMdToChapter fence-close 정책: asciiLike 언어 + 박스 드로잉
      // 이어야 섹션 안에 유지. 박스 드로잉이 없는 text 펜스는 codeExamples로.
      final md = '''# Doc

## Sec

```text
그냥 일반 텍스트입니다
추가 라인
```
''';
      final result = parseMdToChapter(md, 'x-01', 1);
      final sections = result['theory']['sections'] as List;
      final blocks =
          (sections.first as Map<String, dynamic>)['blocks'] as List;
      expect(
        blocks.where((b) => b['type'] == 'asciiDiagram'),
        isEmpty,
        reason: '박스 드로잉 없는 text 펜스는 AsciiDiagramBlock이 아니어야 함',
      );
      final codeExamples = result['theory']['codeExamples'] as List;
      expect(
        codeExamples.any(
            (c) => c['language'] == 'text' && (c['code'] as String).contains('그냥 일반')),
        isTrue,
        reason: '대신 codeExamples로 라우팅되어야 함',
      );
    });

    test('자동 래핑된 인라인 박스 드로잉도 AsciiDiagramBlock으로 분리됨 (Task 12 연동)',
        () {
      // _wrapAsciiBlocks가 연속 ≥3 박스 드로잉 줄을 ```text 펜스로 감쌈.
      // 이어서 _extractBlocks가 그 펜스를 AsciiDiagramBlock으로 추출.
      final section = parseSingleSection('''
서론 문단.
┌──── A ────┐
│ body      │
└───────────┘
결론 문단.
''');
      final blocks = section['blocks'] as List;
      final types = blocks.map((b) => b['type']).toList();
      expect(types, contains('asciiDiagram'));
      expect(types, contains('prose'));
    });

    test('연속된 두 ASCII 다이어그램 펜스 → 각각 AsciiDiagramBlock', () {
      final section = parseSingleSection('''
```
┌─┐
└─┘
```

```text
├─a
└─b
```
''');
      final blocks = section['blocks'] as List;
      final diagrams =
          blocks.where((b) => b['type'] == 'asciiDiagram').toList();
      expect(diagrams, hasLength(2));
    });
  });
}
