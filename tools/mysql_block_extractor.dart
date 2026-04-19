import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

/// fix-10b-mysql subagent — 블록 메타 덤프 유틸리티.
///
/// `docs-source/Mysql Study/*.md` 의 펜스 블록을 추출하여 하나의 JSON 배열로
/// stdout 에 출력. 필드는 chapterId / hash / language / kind / section /
/// context / body.
///
/// 설명(prose) 생성은 이 스크립트가 담당하지 않는다 — 외부에서 해시→설명
/// 매핑을 작성한 뒤 별도 merge 단계에서 JSON 캐시에 병합한다.
Future<void> main(List<String> args) async {
  final docsPath = args.isNotEmpty ? args[0] : 'docs-source';
  final sourceDir = Directory('$docsPath/Mysql Study');
  if (!sourceDir.existsSync()) {
    stderr.writeln('ERROR: ${sourceDir.path} 가 존재하지 않음');
    exit(1);
  }

  final mdFiles = sourceDir
      .listSync()
      .whereType<File>()
      .where((f) => f.path.endsWith('.md'))
      .toList()
    ..sort((a, b) => _compareNatural(a.path, b.path));

  final all = <Map<String, dynamic>>[];
  for (final file in mdFiles) {
    final fileName = file.uri.pathSegments.last.replaceAll('.md', '');
    final chapterId = 'mysql-$fileName';
    final content = file.readAsStringSync();
    final blocks = _extractFencedBlocks(content);
    for (final block in blocks) {
      final hash = sha256.convert(utf8.encode(block.body)).toString();
      all.add({
        'chapterId': chapterId,
        'hash': hash,
        'language': block.language,
        'kind': _classifyKind(block.language, block.body),
        'section': block.section,
        'context': block.context,
        'body': block.body,
      });
    }
  }

  stdout.writeln(const JsonEncoder.withIndent('  ').convert(all));
  stderr.writeln('extracted ${all.length} blocks from ${mdFiles.length} files');
}

class _FencedBlock {
  final String language;
  final String body;
  final String section;
  final String context;
  _FencedBlock(this.language, this.body, this.section, this.context);
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
    if (line.startsWith('```')) {
      inFence = false;
      blocks.add(_FencedBlock(
        fenceLang,
        fenceBuf.toString().trimRight(),
        sectionTitle,
        'Section: $sectionTitle\n\n${proseBuf.toString().trim()}',
      ));
      continue;
    }
    fenceBuf.writeln(line);
  }
  return blocks;
}

String _classifyKind(String language, String body) {
  final lang = language.toLowerCase();
  if (lang == 'mermaid') return '다이어그램';
  if (lang.isEmpty || lang == 'text' || lang == 'ascii' || lang == 'diagram') {
    return _hasBoxDrawing(body) ? '다이어그램' : '코드';
  }
  return '예제 코드';
}

bool _hasBoxDrawing(String body) =>
    body.contains(RegExp(r'[\u2500-\u257F]'));

int _compareNatural(String a, String b) {
  final regex = RegExp(r'(\d+)|(\D+)');
  final aParts = regex.allMatches(a).toList();
  final bParts = regex.allMatches(b).toList();
  final len = aParts.length < bParts.length ? aParts.length : bParts.length;
  for (var i = 0; i < len; i++) {
    final ap = aParts[i].group(0)!;
    final bp = bParts[i].group(0)!;
    final aIsNum = RegExp(r'^\d+$').hasMatch(ap);
    final bIsNum = RegExp(r'^\d+$').hasMatch(bp);
    if (aIsNum && bIsNum) {
      final cmp = int.parse(ap).compareTo(int.parse(bp));
      if (cmp != 0) return cmp;
    } else {
      final cmp = ap.compareTo(bp);
      if (cmp != 0) return cmp;
    }
  }
  return aParts.length.compareTo(bParts.length);
}
