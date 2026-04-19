import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../tools/content_builder.dart';

/// fix-10b — `substituteFencesWithDescriptions` 가 content/diagram-descriptions
/// 캐시를 조회해 펜스 자리를 설명 prose 로 치환하는지 검증.
void main() {
  late Directory tempDir;
  late String originalCwd;

  setUp(() {
    originalCwd = Directory.current.path;
    tempDir = Directory.systemTemp.createTempSync('dol_fence_sub_');
    Directory.current = tempDir.path;
  });

  tearDown(() {
    Directory.current = originalCwd;
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  void writeCache(
    String categoryId,
    String chapterId,
    Map<String, Map<String, String>> entries,
  ) {
    final dir = Directory('content/diagram-descriptions/$categoryId');
    dir.createSync(recursive: true);
    final file = File('${dir.path}/$chapterId.json');
    file.writeAsStringSync(jsonEncode({
      'chapterId': chapterId,
      'entries': entries,
    }));
  }

  /// content_builder 의 fenceBuf.writeln + trimRight 와 동일하게 정규화한 뒤
  /// sha256 계산. 캐시 hit 테스트에서 key 를 일치시키기 위한 헬퍼.
  String normalizedHash(String fenceBody) {
    final buf = StringBuffer();
    for (final l in fenceBody.split('\n')) {
      buf.writeln(l);
    }
    final normalized = buf.toString().trimRight();
    return sha256.convert(utf8.encode(normalized)).toString();
  }

  group('substituteFencesWithDescriptions', () {
    test('캐시 없음 → 모든 펜스가 placeholder 로 치환', () {
      const md = '''
# 샘플

## 구조

설명 전.

```
┌──┐
│A │
└──┘
```

설명 후.
''';
      final result =
          substituteFencesWithDescriptions(md, 'cat', 'ch1');

      expect(result, contains('설명 전.'));
      expect(result, contains('설명 후.'));
      expect(result, contains('[설명 생성 대기'));
      expect(result, isNot(contains('┌──┐')));
    });

    test('캐시 hit → 설명 prose 삽입, placeholder/원본 모두 없음', () {
      const body = '┌──┐\n│A │\n└──┘';
      const md = '''
# 샘플

## 구조

```
$body
```
''';

      writeCache('cat', 'ch2', {
        normalizedHash(body): {
          'language': '',
          'description': '이것은 단일 박스 구조다.',
        },
      });

      final result =
          substituteFencesWithDescriptions(md, 'cat', 'ch2');
      expect(result, contains('이것은 단일 박스 구조다.'));
      expect(result, isNot(contains('[설명 생성 대기')));
      expect(result, isNot(contains('┌──┐')));
    });

    test('같은 body 해시가 여러 펜스에 재사용되면 모두 치환', () {
      const body = 'class Foo {}';
      const md = '''
# 샘플

## A

```java
$body
```

## B

```java
$body
```
''';

      writeCache('cat', 'ch3', {
        normalizedHash(body): {
          'language': 'java',
          'description': '빈 클래스 선언 예제다.',
        },
      });

      final result =
          substituteFencesWithDescriptions(md, 'cat', 'ch3');
      final occurrences = '빈 클래스 선언 예제다.'.allMatches(result).length;
      expect(occurrences, 2);
      expect(result, isNot(contains('[설명 생성 대기')));
    });

    test('깨진 캐시 JSON → graceful fallback (placeholder)', () {
      final dir = Directory('content/diagram-descriptions/cat');
      dir.createSync(recursive: true);
      File('${dir.path}/ch4.json').writeAsStringSync('not-json');

      const md = '```\ndata\n```';
      final result =
          substituteFencesWithDescriptions(md, 'cat', 'ch4');
      expect(result, contains('[설명 생성 대기'));
    });

    test('entries 빈 캐시 → 모든 펜스 miss', () {
      writeCache('cat', 'ch5', const {});
      const md = '```\nfoo\n```';
      final result =
          substituteFencesWithDescriptions(md, 'cat', 'ch5');
      expect(result, contains('[설명 생성 대기'));
    });

    test('prose 는 보존', () {
      const md = '''
# 제목

## 섹션

이것은 prose 문단이다. 유지되어야 한다.

```
code
```
''';
      final result =
          substituteFencesWithDescriptions(md, 'cat', 'ch6');
      expect(result, contains('이것은 prose 문단이다. 유지되어야 한다.'));
    });
  });
}

