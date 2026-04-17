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

      chapters.add(parseMdToChapter(content, id, i + 1));
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
