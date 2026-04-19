import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import 'content_builder.dart' show compareNatural;

/// fix-10b (R7) — ASCII / Mermaid / 코드 펜스 블록을 Claude API 로 의도 설명
/// prose 로 변환해 `content/diagram-descriptions/<category>/<chapter>.json`
/// 해시→설명 캐시에 저장한다.
///
/// **오프라인 1회 실행 도구**. CI 빌드는 이 캐시만 조회 (content_builder).
///
/// 사용법:
///   ANTHROPIC_API_KEY=sk-ant-... dart run tools/ai_diagram_describer.dart [docs-source-path]
///
/// - 동일 body 해시는 중복 호출 없이 기존 캐시 재사용.
/// - 실패 블록은 해당 entry 생략 (다음 실행에서 재시도 가능).
Future<void> main(List<String> args) async {
  final apiKey = Platform.environment['ANTHROPIC_API_KEY'];
  if (apiKey == null || apiKey.isEmpty) {
    stderr.writeln('ERROR: ANTHROPIC_API_KEY 환경변수가 설정되지 않았다.');
    exit(1);
  }

  final docsPath = args.isNotEmpty ? args[0] : 'docs-source';
  const cacheRoot = 'content/diagram-descriptions';
  const model = 'claude-haiku-4-5-20251001';

  const categories = {
    'java-spring': 'Java & Spring',
    'dart': 'Dart Programing',
    'flutter': 'Flutter Programing',
    'mysql': 'Mysql Study',
    'msa': 'MSA',
  };

  final dio = Dio(BaseOptions(
    baseUrl: 'https://api.anthropic.com',
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 2),
  ));

  var totalBlocks = 0;
  var cachedHit = 0;
  var generated = 0;
  var failed = 0;

  for (final entry in categories.entries) {
    final categoryId = entry.key;
    final folderName = entry.value;
    final sourceDir = Directory('$docsPath/$folderName');
    if (!sourceDir.existsSync()) continue;

    final outDir = Directory('$cacheRoot/$categoryId');
    outDir.createSync(recursive: true);

    final mdFiles = sourceDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .toList()
      ..sort((a, b) => compareNatural(a.path, b.path));

    for (final file in mdFiles) {
      final fileName = file.uri.pathSegments.last.replaceAll('.md', '');
      final chapterId = '$categoryId-$fileName';
      final cacheFile = File('${outDir.path}/$chapterId.json');

      final cache = cacheFile.existsSync()
          ? (jsonDecode(cacheFile.readAsStringSync())
              as Map<String, dynamic>)
          : <String, dynamic>{
              'chapterId': chapterId,
              'entries': <String, dynamic>{},
            };
      final entries =
          (cache['entries'] as Map).cast<String, dynamic>();

      final content = file.readAsStringSync();
      final blocks = _extractFencedBlocks(content);

      for (final block in blocks) {
        totalBlocks++;
        final hash = _sha256(block.body);
        if (entries.containsKey(hash)) {
          cachedHit++;
          continue;
        }
        try {
          final description = await _generateDescription(
            dio: dio,
            apiKey: apiKey,
            model: model,
            language: block.language,
            body: block.body,
            context: block.context,
          );
          entries[hash] = <String, dynamic>{
            'language': block.language,
            'description': description,
          };
          generated++;
          stderr.writeln('  ✓ $chapterId / ${hash.substring(0, 8)}');
        } catch (e) {
          failed++;
          stderr.writeln('  ✗ $chapterId / ${hash.substring(0, 8)}: $e');
        }
      }

      cache['entries'] = entries;
      cacheFile.writeAsStringSync(
        const JsonEncoder.withIndent('  ').convert(cache),
      );
    }
  }

  stdout.writeln('\nDone. total=$totalBlocks, cached=$cachedHit, '
      'generated=$generated, failed=$failed');
  if (failed > 0) exit(2);
}

class _FencedBlock {
  final String language;
  final String body;
  final String context;
  _FencedBlock(this.language, this.body, this.context);
}

List<_FencedBlock> _extractFencedBlocks(String markdown) {
  final blocks = <_FencedBlock>[];
  final lines = markdown.split('\n');
  String sectionTitle = '';
  final proseBuf = StringBuffer();
  var inFence = false;
  String fenceLang = '';
  final fenceBuf = StringBuffer();

  for (final line in lines) {
    if (!inFence) {
      if (line.startsWith('## ')) {
        sectionTitle = line.substring(3).trim();
        proseBuf.clear();
        continue;
      }
      if (line.startsWith('```')) {
        inFence = true;
        fenceLang = line.substring(3).trim();
        fenceBuf.clear();
        continue;
      }
      proseBuf.writeln(line);
      continue;
    }
    // in fence
    if (line.startsWith('```')) {
      inFence = false;
      blocks.add(_FencedBlock(
        fenceLang,
        fenceBuf.toString().trimRight(),
        'Section: $sectionTitle\n\n${proseBuf.toString().trim()}',
      ));
      continue;
    }
    fenceBuf.writeln(line);
  }
  return blocks;
}

String _sha256(String body) =>
    sha256.convert(utf8.encode(body)).toString();

Future<String> _generateDescription({
  required Dio dio,
  required String apiKey,
  required String model,
  required String language,
  required String body,
  required String context,
}) async {
  final kind = _classifyKind(language, body);
  final prompt = '''
다음은 개발 학습 문서에 포함된 $kind 이다. 주변 맥락을 참고하여 이 $kind 이
**설명하고자 하는 개념·의도·흐름**을 한국어로 1~2 문단 (200~400자) 서술하라.

규칙:
- 구조 나열이나 기계적 번역이 아닌 **무엇을 가르치려 하는지** 서술한다.
- 코드의 경우, 코드 자체를 재현하지 않고 동작 목적과 사용 맥락을 요약한다.
- 독자가 다이어그램/코드를 보지 못한 채로 텍스트만 읽어도 같은 개념을
  이해할 수 있어야 한다.
- 서술체. 다른 부연(머리말·꼬리말) 없이 설명 본문만 출력.

[주변 맥락]
$context

[$kind 원본]
```$language
$body
```

[설명 (1~2 문단)]:
''';

  final resp = await dio.post(
    '/v1/messages',
    options: Options(
      headers: {
        'x-api-key': apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
    ),
    data: jsonEncode({
      'model': model,
      'max_tokens': 800,
      'messages': [
        {'role': 'user', 'content': prompt},
      ],
    }),
  );

  final data = resp.data;
  if (data is! Map) {
    throw StateError('Unexpected response shape: $data');
  }
  final content = data['content'] as List;
  if (content.isEmpty) {
    throw StateError('Empty content in response');
  }
  final text = (content.first as Map)['text'] as String;
  return text.trim();
}

String _classifyKind(String language, String body) {
  final lang = language.toLowerCase();
  if (lang == 'mermaid') return '다이어그램';
  if (lang.isEmpty || lang == 'text' || lang == 'ascii' ||
      lang == 'diagram') {
    return _hasBoxDrawing(body) ? '다이어그램' : '코드';
  }
  return '예제 코드';
}

bool _hasBoxDrawing(String body) =>
    body.contains(RegExp(r'[\u2500-\u257F]'));
