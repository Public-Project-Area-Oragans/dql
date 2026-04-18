import 'dart:convert';
import 'dart:io';

/// MD 문서를 JSON 콘텐츠로 변환하는 빌드 스크립트
///
/// 사용법: dart run tools/content_builder.dart [docs-source-path]
void main(List<String> args) {
  final docsPath = args.isNotEmpty ? args[0] : 'docs-source';
  const outputPath = 'content/books';

  final categories = {
    'java-spring': 'Java & Spring',
    'dart': 'Dart Programing',
    'flutter': 'Flutter Programing',
    'mysql': 'Mysql Study',
    'msa': 'MSA',
  };

  for (final entry in categories.entries) {
    final categoryId = entry.key;
    final folderName = entry.value;
    final sourceDir = Directory('$docsPath/$folderName');

    if (!sourceDir.existsSync()) {
      print('⚠ 폴더 없음: ${sourceDir.path}');
      continue;
    }

    final outDir = Directory('$outputPath/$categoryId');
    outDir.createSync(recursive: true);

    final mdFiles = sourceDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    final chapters = <Map<String, dynamic>>[];

    for (var i = 0; i < mdFiles.length; i++) {
      final file = mdFiles[i];
      final fileName = file.uri.pathSegments.last.replaceAll('.md', '');
      final id = '$categoryId-$fileName';
      final content = file.readAsStringSync();

      final chapter = parseMdToChapter(content, id, i + 1);
      chapters.add(applyOverride(chapter, categoryId, id));
    }

    final book = {
      'id': categoryId,
      'title': folderName,
      'category': categoryId,
      'chapters': chapters,
    };

    final outFile = File('${outDir.path}/book.json');
    outFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(book),
    );

    print('✓ $categoryId: ${chapters.length}개 챕터 → ${outFile.path}');
  }
}

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
      final body = codeBuffer.toString().trimRight();
      // Task 12 option D: language가 ascii/diagram/text/'' 이면서 박스
      // 드로잉 문자가 포함된 블록은 codeExamples로 분리하지 않고 섹션
      // 본문 안에 코드펜스로 유지한다. (코드 예제 섹션에서 문맥을 잃지 않음)
      final asciiLike = {'ascii', 'diagram', 'text'};
      final lang = (codeLanguage ?? 'text');
      final keepInSection =
          asciiLike.contains(lang.toLowerCase()) && _hasBoxDrawing(body);
      if (keepInSection) {
        currentContent.writeln('```$lang');
        currentContent.writeln(body);
        currentContent.writeln('```');
      } else {
        codeExamples.add({
          'language': codeLanguage ?? 'text',
          'code': body,
          'description': currentSection ?? '',
        });
      }
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
          'content': _wrapAsciiBlocks(currentContent.toString().trim()),
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
      'content': _wrapAsciiBlocks(currentContent.toString().trim()),
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

/// `content/overrides/<categoryId>/<chapterId>.json` 파일이 있으면
/// 해당 챕터의 simulator 필드를 override로 교체한다.
///
/// - 파일 없음 → 기본값 유지 (경고 로그 없음, 대부분 챕터는 default).
/// - JSON 파싱 실패 → 예외 throw, 빌드 중단.
/// - override에 `simulator` 필드 없으면 무시.
Map<String, dynamic> applyOverride(
  Map<String, dynamic> chapter,
  String categoryId,
  String chapterId,
) {
  final overrideFile = File('content/overrides/$categoryId/$chapterId.json');
  if (!overrideFile.existsSync()) {
    return chapter;
  }

  Map<String, dynamic> overrideJson;
  try {
    overrideJson =
        jsonDecode(overrideFile.readAsStringSync()) as Map<String, dynamic>;
  } catch (e) {
    throw Exception('override JSON 파싱 실패 ${overrideFile.path}: $e');
  }

  final simulatorOverride = overrideJson['simulator'];
  if (simulatorOverride is Map<String, dynamic>) {
    chapter['simulator'] = simulatorOverride;
    print('  ↗ override 적용: $chapterId');
  }

  return chapter;
}

/// Unicode 박스 드로잉(U+2500–U+259F) 문자가 하나라도 포함되어 있는지.
/// Task 12: 이 범위가 존재하면 ASCII 다이어그램 후보로 간주한다.
bool _hasBoxDrawing(String text) {
  for (final rune in text.runes) {
    if (rune >= 0x2500 && rune <= 0x259F) return true;
  }
  return false;
}

/// 섹션 본문 안의 연속된 박스 드로잉 줄(≥3)을 ```text``` 코드펜스로 감싸
/// MarkdownBody가 monospace로 정렬을 보존하도록 한다. (Task 12 option B)
///
/// 주의: 이미 코드펜스 내부에 있는 줄은 감싸지 않는다. 원문이 `순수 다이어그램`
/// 구간만 대상.
String _wrapAsciiBlocks(String content) {
  final lines = content.split('\n');
  final out = <String>[];
  var i = 0;
  var insideFence = false;
  while (i < lines.length) {
    final line = lines[i];
    if (line.startsWith('```')) {
      insideFence = !insideFence;
      out.add(line);
      i++;
      continue;
    }
    if (insideFence) {
      out.add(line);
      i++;
      continue;
    }
    if (_hasBoxDrawing(line)) {
      var j = i;
      while (j < lines.length &&
          !lines[j].startsWith('```') &&
          _hasBoxDrawing(lines[j])) {
        j++;
      }
      if (j - i >= 3) {
        out.add('```text');
        for (var k = i; k < j; k++) out.add(lines[k]);
        out.add('```');
        i = j;
        continue;
      }
    }
    out.add(line);
    i++;
  }
  return out.join('\n');
}
