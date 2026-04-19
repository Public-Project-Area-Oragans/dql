import 'package:flutter_test/flutter_test.dart';

// 원본 parseMdToChapter를 상대 경로로 import해서 단일 소스로 검증한다.
import '../../tools/content_builder.dart';

/// fix-10a (R7) 반영 — 이론 파트는 prose 전용.
/// 모든 코드/다이어그램 펜스 블록은 drop.
/// codeExamples 필드는 항상 빈 리스트.
void main() {
  group('parseMdToChapter — R7 prose-only', () {
    test('extracts title + order from first heading, code fence 는 drop', () {
      const md = '''
# Step 01 — Java란 무엇인가

## JVM 개요

JVM(Java Virtual Machine)은 자바 프로그램을 실행하는 가상 머신이다.

## 기본 문법

```java
public class Main {
    public static void main(String[] args) {
        System.out.println("Hello");
    }
}
```
''';

      final result = parseMdToChapter(md, 'java-step01', 1);

      expect(result['id'], 'java-step01');
      expect(result['title'], 'Step 01 — Java란 무엇인가');
      expect(result['order'], 1);
      expect(result['theory']['sections'], isNotEmpty);
      // fix-10a (R7): codeExamples 는 항상 빈 리스트.
      expect(result['theory']['codeExamples'], isEmpty);

      // 코드 펜스 내용이 sections[].content 에도 남지 않는다.
      final sections = result['theory']['sections'] as List;
      final allContent =
          sections.map((s) => s['content']).join('\n');
      expect(allContent, isNot(contains('System.out.println')));
    });

    test('no code blocks 의 경우에도 sections 정상 + codeExamples 빈 상태', () {
      const md = '''
# Step 02 — 개발환경 세팅

## IDE 설치

IntelliJ IDEA를 설치한다.

## SDK 설정

JDK 21을 다운로드한다.
''';

      final result = parseMdToChapter(md, 'java-step02', 2);

      expect(result['theory']['sections'].length, 2);
      expect(result['theory']['codeExamples'], isEmpty);
    });

    test('섹션 blocks 는 prose 타입만 담긴다', () {
      const md = '''
# 혼합 샘플

## 설명

설명 한 문단.

| 헤더A | 헤더B |
| --- | --- |
| r1 | r2 |

더 많은 설명.
''';

      final result = parseMdToChapter(md, 'x-blocks', 1);
      final sections = result['theory']['sections'] as List;
      final blocks = sections.first['blocks'] as List;

      // table 블록은 파서에 의해 감지되지만 prose-only 필터로 drop 됨.
      final types = blocks.map((b) => b['type'] as String).toSet();
      expect(types, {'prose'},
          reason: 'R7: blocks 에는 prose 만 남는다');
    });
  });

  group('parseMdToChapter — R7 에서 코드/다이어그램 펜스 drop', () {
    test('fence language 가 java 이면 codeExamples 에도, content 에도 안 남음',
        () {
      const md = '''
# 샘플

## 예제

```java
class Foo {
  int a = 1;
}
```
''';

      final result = parseMdToChapter(md, 'x-drop-java', 1);
      final codeExamples = result['theory']['codeExamples'] as List;
      expect(codeExamples, isEmpty);

      final sections = result['theory']['sections'] as List;
      final allContent =
          sections.map((s) => s['content']).join('\n');
      expect(allContent, isNot(contains('class Foo')));
    });

    test('fence language 빈 + 박스 드로잉 블록도 drop', () {
      const md = '''
# 샘플

## 구조도

위에 설명. 아래는 구조도:

```
단일 애플리케이션
├── 사용자 관리
├── 상품 관리
└── 알림
```

아래에 부연.
''';

      final result = parseMdToChapter(md, 'x-drop-ascii-fence', 1);
      final sections = result['theory']['sections'] as List;
      final content = sections.first['content'] as String;

      // 펜스 + 박스 drawing 이 전부 drop.
      expect(content, isNot(contains('```')));
      expect(content, isNot(contains('├── 사용자 관리')));
      // 주변 prose 는 유지.
      expect(content, contains('위에 설명'));
      expect(content, contains('아래에 부연'));
    });

    test('네이키드 박스 드로잉 연속 ≥3 줄 (fence 없이) 도 blocks 에서 prose 만 남김',
        () {
      // _wrapAsciiBlocks 가 ```text``` 로 자동 감싸면 blocks 파서가
      // asciiDiagram 으로 분류 → fix-10a 필터로 제거 → blocks 에는 prose 만.
      const md = '''
# 샘플

## 트리

트리 구조:
┌── root
├── a
└── b
끝.
''';

      final result = parseMdToChapter(md, 'x-wrap-ascii', 1);
      final sections = result['theory']['sections'] as List;
      final blocks = sections.first['blocks'] as List;

      final types = blocks.map((b) => b['type'] as String).toSet();
      expect(types, {'prose'});
    });
  });
}
