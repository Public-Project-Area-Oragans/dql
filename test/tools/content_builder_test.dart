import 'package:flutter_test/flutter_test.dart';

// 원본 parseMdToChapter를 상대 경로로 import해서 단일 소스로 검증한다.
// (과거에는 테스트 파일 안에 같은 함수를 복제했으나 Task 12에서
//  ASCII 다이어그램 감지 로직이 추가되면서 drift 방지를 위해 제거.)
import '../../tools/content_builder.dart';

void main() {
  group('parseMdToChapter', () {
    test('extracts title from first heading', () {
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
      expect(result['theory']['codeExamples'], isNotEmpty);
      expect(result['theory']['codeExamples'][0]['language'], 'java');
    });

    test('handles markdown with no code blocks', () {
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
  });

  group('parseMdToChapter — Task 12 ASCII 다이어그램 보존', () {
    test(
        'fence language가 비어있고 박스 드로잉이 포함되면 섹션에 유지 (codeExamples로 이동하지 않음)',
        () {
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

      final result = parseMdToChapter(md, 'x-01', 1);
      final sections = result['theory']['sections'] as List;
      final codeExamples = result['theory']['codeExamples'] as List;

      expect(codeExamples, isEmpty,
          reason: '박스 드로잉 포함 + 언어 비어있음 → 섹션에 남아야 함');
      final content = sections.first['content'] as String;
      expect(content, contains('```text'),
          reason: '섹션 본문에 text 언어로 다시 감싼 코드펜스 존재');
      expect(content, contains('├── 사용자 관리'));
    });

    test('fence language가 java라면 박스 드로잉 여부와 관계없이 codeExamples로 이동',
        () {
      const md = '''
# 샘플

## 예제

```java
class Foo {
  // ├── 이건 주석 안의 박스 드로잉
}
```
''';

      final result = parseMdToChapter(md, 'x-02', 1);
      final codeExamples = result['theory']['codeExamples'] as List;

      expect(codeExamples, hasLength(1));
      expect(codeExamples.first['language'], 'java');
    });

    test(
        '섹션 본문 내 연속된 ≥3 박스 드로잉 줄은 자동으로 ```text``` 펜스로 감싸진다',
        () {
      const md = '''
# 샘플

## 트리

트리 구조:
┌── root
├── a
└── b
끝.
''';

      final result = parseMdToChapter(md, 'x-03', 1);
      final sections = result['theory']['sections'] as List;
      final content = sections.first['content'] as String;

      expect(content, contains('```text'));
      expect(content, contains('┌── root'));
      // 인덱스 순서: 설명 → fence open → 박스 3줄 → fence close → 끝.
      final fenceIndex = content.indexOf('```text');
      final endIndex = content.indexOf('끝.');
      expect(fenceIndex < endIndex, isTrue,
          reason: '펜스가 "끝." 이전에 위치해야 함');
    });

    test('연속 박스 드로잉 줄이 2줄 이하면 감싸지지 않는다', () {
      const md = '''
# 샘플

## 짧은 장식

├── 한 줄
설명 텍스트.
└── 또 한 줄
''';

      final result = parseMdToChapter(md, 'x-04', 1);
      final sections = result['theory']['sections'] as List;
      final content = sections.first['content'] as String;

      expect(content.contains('```text'), isFalse,
          reason: '3줄 미만인 경우 감싸지 않고 원문 유지');
    });
  });
}
