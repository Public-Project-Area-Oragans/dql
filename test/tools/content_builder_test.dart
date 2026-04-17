import 'package:flutter_test/flutter_test.dart';

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
}

/// MD 파일을 챕터 JSON으로 변환하는 핵심 로직
Map<String, dynamic> parseMdToChapter(String markdown, String id, int order) {
  final lines = markdown.split('\n');

  var title = id;
  for (final line in lines) {
    if (line.startsWith('# ') && !line.startsWith('## ')) {
      title = line.substring(2).trim();
      break;
    }
  }

  final sections = <Map<String, String>>[];
  final codeExamples = <Map<String, String>>[];
  String? currentSection;
  final currentContent = StringBuffer();
  var inCodeBlock = false;
  String? codeLanguage;
  final codeBuffer = StringBuffer();

  for (final line in lines) {
    if (line.startsWith('```') && !inCodeBlock) {
      inCodeBlock = true;
      codeLanguage = line.substring(3).trim();
      if (codeLanguage.isEmpty) codeLanguage = 'text';
      codeBuffer.clear();
      continue;
    }

    if (line.startsWith('```') && inCodeBlock) {
      inCodeBlock = false;
      codeExamples.add({
        'language': codeLanguage ?? 'text',
        'code': codeBuffer.toString().trimRight(),
        'description': currentSection ?? '',
      });
      continue;
    }

    if (inCodeBlock) {
      codeBuffer.writeln(line);
      continue;
    }

    if (line.startsWith('## ')) {
      if (currentSection != null) {
        sections.add({
          'title': currentSection,
          'content': currentContent.toString().trim(),
        });
      }
      currentSection = line.substring(3).trim();
      currentContent.clear();
      continue;
    }

    if (line.startsWith('# ') && !line.startsWith('## ')) continue;

    currentContent.writeln(line);
  }

  if (currentSection != null) {
    sections.add({
      'title': currentSection,
      'content': currentContent.toString().trim(),
    });
  }

  return {
    'id': id,
    'title': title,
    'order': order,
    'theory': {
      'sections': sections,
      'codeExamples': codeExamples,
      'diagrams': <Map<String, String>>[],
    },
    'simulator': {
      'type': 'codeStep',
      'steps': <Map<String, dynamic>>[],
      'completionCriteria': {'minStepsCompleted': 0},
    },
    'isCompleted': false,
  };
}
