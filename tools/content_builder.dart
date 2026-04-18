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

  final sections = <Map<String, dynamic>>[];
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
      // Phase 3 PR #4: mermaid도 섹션에 유지해 _extractBlocks가 구조화.
      final asciiLike = {'ascii', 'diagram', 'text'};
      final lang = (codeLanguage ?? 'text');
      final lower = lang.toLowerCase();
      final keepInSection =
          (asciiLike.contains(lower) && _hasBoxDrawing(body)) ||
              lower == 'mermaid';
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
        final wrapped = _wrapAsciiBlocks(currentContent.toString().trim());
        sections.add({
          'title': currentSection,
          'content': wrapped,
          'blocks': _extractBlocks(wrapped),
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
    final wrapped = _wrapAsciiBlocks(currentContent.toString().trim());
    sections.add({
      'title': currentSection,
      'content': wrapped,
      'blocks': _extractBlocks(wrapped),
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

/// Phase 3: 섹션 본문을 ContentBlock 리스트로 분해.
///
/// 인식 타입:
/// - GFM 표 → TableBlock (PR #2)
/// - ```text / ```ascii / ```diagram / ``` 펜스 + 박스 드로잉 → AsciiDiagramBlock (PR #3)
/// - 그 외 구간 → ProseBlock
/// 후속 PR에서 mermaid 분리 추가.
List<Map<String, dynamic>> _extractBlocks(String content) {
  const asciiLikeLangs = {'', 'text', 'ascii', 'diagram'};
  final lines = content.split('\n');
  final blocks = <Map<String, dynamic>>[];
  final proseBuf = StringBuffer();

  void flushProse() {
    final text = proseBuf.toString().trim();
    if (text.isEmpty) {
      proseBuf.clear();
      return;
    }
    blocks.add({'type': 'prose', 'markdown': text});
    proseBuf.clear();
  }

  var i = 0;
  while (i < lines.length) {
    final line = lines[i];

    // 1) 표 감지
    final tableEnd = _tryParseTable(lines, i);
    if (tableEnd != null) {
      flushProse();
      blocks.add(tableEnd.block);
      i = tableEnd.nextIndex;
      continue;
    }

    // 2) 코드 펜스 감지
    if (line.startsWith('```')) {
      final lang = line.substring(3).trim().toLowerCase();
      final fenceBody = StringBuffer();
      var j = i + 1;
      while (j < lines.length && !lines[j].startsWith('```')) {
        fenceBody.writeln(lines[j]);
        j++;
      }
      final closed = j < lines.length;
      final body = fenceBody.toString().trimRight();
      if (closed &&
          asciiLikeLangs.contains(lang) &&
          _hasBoxDrawing(body)) {
        // asciiLike 펜스 + 박스 드로잉 → AsciiDiagramBlock
        flushProse();
        blocks.add({'type': 'asciiDiagram', 'source': body});
        i = j + 1;
        continue;
      }
      if (closed && lang == 'mermaid') {
        // Mermaid → 타입별 구조화. 현재 지원: flowchart. 나머지는 RawBlock.
        flushProse();
        blocks.add(_parseMermaid(body));
        i = j + 1;
        continue;
      }
      // 그 외 펜스는 원본 그대로 prose에 유지 (flutter_markdown이 코드블록으로 렌더).
      proseBuf.writeln(line);
      for (var k = i + 1; k <= j && k < lines.length; k++) {
        proseBuf.writeln(lines[k]);
      }
      i = closed ? j + 1 : j;
      continue;
    }

    proseBuf.writeln(line);
    i++;
  }
  flushProse();
  // content가 완전히 비어있으면 단일 ProseBlock("")이라도 emit하지 않고 빈 리스트.
  return blocks;
}

/// Phase 3 PR #4: Mermaid 소스 → ContentBlock 디스패치.
/// 현재 flowchart만 구조화, 나머지는 RawBlock 폴백.
Map<String, dynamic> _parseMermaid(String source) {
  final rawLines = source.split('\n');
  final lines = <String>[];
  for (final line in rawLines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) continue;
    if (trimmed.startsWith('%%')) continue;
    lines.add(line);
  }
  if (lines.isEmpty) {
    return {'type': 'raw', 'language': 'mermaid', 'source': source};
  }
  final header = lines.first.trim();
  if (_flowchartHeaderPattern.hasMatch(header)) {
    final parsed = _parseFlowchart(lines);
    if (parsed != null) return parsed;
  }
  if (header == 'sequenceDiagram') {
    final parsed = _parseSequence(lines);
    if (parsed != null) return parsed;
  }
  if (header == 'mindmap') {
    final parsed = _parseMindmap(lines);
    if (parsed != null) return parsed;
  }
  return {'type': 'raw', 'language': 'mermaid', 'source': source};
}

final RegExp _flowchartHeaderPattern =
    RegExp(r'^(?:flowchart|graph)(?:\s+(TB|TD|LR|BT|RL))?\s*$');

// from + connector + optional "|label|" + to
// 지원 connector (느슨 — 소스에서 발견된 변종 포함):
//   --> / -->> / -->>>                   solid (dashes n>{1..3})
//   -.-> / -.->> / -.->>>                dashed
//   ==> / ==>> / ==>>>                   thick
//   --- / === / -.-                      open (no arrow, connection만)
//   <-->                                 bidirectional
//   --o / --x                            marker end
final RegExp _edgePattern = RegExp(
  r'^([A-Za-z_]\w*)'
  r'\s*(-->{1,3}|-\.->{1,3}|==>{1,3}|---|-\.\-|===|<-->|--[ox])'
  r'(?:\s*\|\s*"?([^"|]+?)"?\s*\|\s*)?'
  r'\s*([A-Za-z_]\w*)',
);

// `A --label--> B` 형태의 중간 라벨 엣지.
final RegExp _edgeDashLabelPattern = RegExp(
  r'^([A-Za-z_]\w*)\s*--\s*"?([^"-]+?)"?\s*-->\s*([A-Za-z_]\w*)',
);

// 노드 정의: 다양한 shape 지원. 라벨은 두 변종:
//   - `"라벨"` (쌍따옴표 래핑) → 내부에 `()[]{}` 허용
//   - 비인용 라벨 → `]`, `)`, `}`, `"` 제외한 문자열
// 비인용 라벨이 `()` 포함 시 `)` 에서 조기 종료하는 고질적 버그를 해결.
final RegExp _nodeShapePattern = RegExp(
  r'([A-Za-z_]\w*)\s*'
  r'(\[\[|\[\(|\(\[|\(\(|\{\{|\[|\(|\{)'
  r'(?:"([^"]+)"|([^\]\)\}"]+))'
  r'(\]\]|\)\]|\]\)|\)\)|\}\}|\]|\)|\})',
);

// Mermaid node class 지정 suffix (예: `A[Label]:::primary`). 매번 strip.
final RegExp _classSuffixPattern = RegExp(r':::[A-Za-z_][\w-]*');

// Invisible link `~~~` (정렬용, 시각적 엣지 아님).
final RegExp _invisibleLinkPattern = RegExp(r'~{3,}');

// Multiway: `A & B --> C` 형태에서 `&` 구분자 분해.
final RegExp _ampersandSplitPattern = RegExp(r'\s*&\s*');

/// lines는 `%%` 제거 + 빈 줄 제거 + 헤더 포함된 상태.
/// 실패 시 null 반환 → RawBlock 폴백.
Map<String, dynamic>? _parseFlowchart(List<String> lines) {
  final headerMatch = _flowchartHeaderPattern.firstMatch(lines.first.trim());
  if (headerMatch == null) return null;
  var direction = headerMatch.group(1) ?? 'TB';
  if (direction == 'TD') direction = 'TB';

  final nodes = <String, Map<String, String>>{};
  final edges = <Map<String, dynamic>>[];

  void ensureNode(String id, {String? label, String? shape}) {
    final existing = nodes[id];
    if (existing == null) {
      nodes[id] = {
        'label': label ?? id,
        'shape': shape ?? 'rect',
      };
    } else {
      if (label != null && existing['label'] == id) existing['label'] = label;
      if (shape != null && existing['shape'] == 'rect') {
        existing['shape'] = shape;
      }
    }
  }

  String edgeStyle(String connector) {
    // 점선: `-.` 포함 (dashed).
    if (connector.contains('.')) return 'dashed';
    // 두꺼운 선: `=` 포함 (thick).
    if (connector.contains('=')) return 'thick';
    // 그 외 (`-->`, `-->>`, `<-->`, `--o`, `--x`, `---`) → solid.
    return 'solid';
  }

  for (var idx = 1; idx < lines.length; idx++) {
    // PR #7: `:::className` suffix 스트립 (거의 모든 MSA flowchart에 존재).
    final raw = lines[idx].trim().replaceAll(_classSuffixPattern, '').trim();
    if (raw.isEmpty) continue;

    // 무시: subgraph/end/classDef/class/style/direction/linkStyle/click.
    if (raw.startsWith('subgraph') ||
        raw == 'end' ||
        raw.startsWith('classDef') ||
        raw.startsWith('class ') ||
        raw.startsWith('style ') ||
        raw.startsWith('direction ') ||
        raw.startsWith('linkStyle') ||
        raw.startsWith('click ')) {
      continue;
    }

    // 인라인 노드 선언 먼저 수집.
    for (final m in _nodeShapePattern.allMatches(raw)) {
      final id = m.group(1)!;
      final open = m.group(2)!;
      // group 3 = 인용 라벨(따옴표 제거), group 4 = 비인용 라벨.
      final label = m.group(3) ?? m.group(4)!;
      ensureNode(id,
          label: _stripLabel(label), shape: _shapeFromOpen(open));
    }

    // 노드 shape 선언을 id만 남기도록 치환해 edge 매칭 용이하게 함.
    final stripped =
        raw.replaceAllMapped(_nodeShapePattern, (m) => m.group(1)!);

    // PR #7: `~~~` invisible link. 엣지 emit 없이 양쪽 id만 등록.
    if (_invisibleLinkPattern.hasMatch(stripped)) {
      final parts = stripped.split(_invisibleLinkPattern);
      for (final p in parts) {
        final id = p.trim();
        if (RegExp(r'^[A-Za-z_]\w*$').hasMatch(id)) ensureNode(id);
      }
      continue;
    }

    // PR #7: Multiway `A & B --> C` 전개. edge regex 실패를 미리 방지.
    if (stripped.contains('&')) {
      final multiEdge = _tryParseMultiway(
        stripped,
        ensureNode,
        edges,
        edgeStyle,
      );
      if (multiEdge) continue;
    }

    final dashLabel = _edgeDashLabelPattern.firstMatch(stripped);
    if (dashLabel != null) {
      final from = dashLabel.group(1)!;
      final label = dashLabel.group(2)!.trim();
      final to = dashLabel.group(3)!;
      ensureNode(from);
      ensureNode(to);
      edges.add({
        'from': from,
        'to': to,
        'label': label,
        'style': 'solid',
      });
      continue;
    }

    final edgeMatch = _edgePattern.firstMatch(stripped);
    if (edgeMatch != null) {
      final from = edgeMatch.group(1)!;
      final connector = edgeMatch.group(2)!;
      final label = (edgeMatch.group(3) ?? '').trim();
      final to = edgeMatch.group(4)!;
      ensureNode(from);
      ensureNode(to);
      edges.add({
        'from': from,
        'to': to,
        'label': label,
        'style': edgeStyle(connector),
      });
      continue;
    }

    if (_nodeShapePattern.hasMatch(raw)) continue;
    // 인식 불가 — 전체를 raw로 폴백.
    return null;
  }

  if (nodes.isEmpty && edges.isEmpty) return null;

  final nodeList = nodes.entries
      .map((e) => {
            'id': e.key,
            'label': e.value['label'],
            'shape': e.value['shape'],
          })
      .toList();

  return {
    'type': 'flowchart',
    'direction': direction,
    'nodes': nodeList,
    'edges': edges,
  };
}

String _shapeFromOpen(String open) {
  switch (open) {
    case '((':
      return 'circle';
    case '(':
    case '([': // stadium → round
      return 'round';
    case '{{':
    case '{':
      return 'diamond';
    case '[(': // cylinder → rect(시각적 근사)
    case '[[':
    case '[':
    default:
      return 'rect';
  }
}

/// PR #7: `A & B --> C` 또는 `A --> B & C` 멀티웨이 엣지 전개.
/// stripped는 이미 노드 shape가 id만 남은 상태의 라인.
/// 성공 시 edges에 expanded pairs 추가하고 true 반환.
bool _tryParseMultiway(
  String stripped,
  void Function(String id, {String? label, String? shape}) ensureNode,
  List<Map<String, dynamic>> edges,
  String Function(String) edgeStyle,
) {
  // 엣지 커넥터를 먼저 탐색 (PR #7 feat 보강과 동일 세트).
  final connectorPattern =
      RegExp(r'(-->{1,3}|-\.->{1,3}|==>{1,3}|---|-\.\-|===|<-->|--[ox])');
  final m = connectorPattern.firstMatch(stripped);
  if (m == null) return false;
  final connector = m.group(1)!;

  // label: 커넥터 우측 바로 뒤 `|...|` 가능.
  String label = '';
  final afterConnector = stripped.substring(m.end).trimLeft();
  String toSection = afterConnector;
  final labelMatch =
      RegExp(r'^\|\s*"?([^"|]+?)"?\s*\|\s*(.+)$').firstMatch(afterConnector);
  if (labelMatch != null) {
    label = labelMatch.group(1)!.trim();
    toSection = labelMatch.group(2)!;
  }

  final fromSection = stripped.substring(0, m.start).trim();
  final fromIds = fromSection
      .split(_ampersandSplitPattern)
      .map((s) => s.trim())
      .where((s) => RegExp(r'^[A-Za-z_]\w*$').hasMatch(s))
      .toList();
  final toIds = toSection
      .trim()
      .split(_ampersandSplitPattern)
      .map((s) => s.trim())
      .where((s) => RegExp(r'^[A-Za-z_]\w*$').hasMatch(s))
      .toList();

  // 단일 x 단일이면 multiway가 아니므로 일반 edge 경로로 넘김.
  if (fromIds.length <= 1 && toIds.length <= 1) return false;
  if (fromIds.isEmpty || toIds.isEmpty) return false;

  for (final from in fromIds) {
    for (final to in toIds) {
      ensureNode(from);
      ensureNode(to);
      edges.add({
        'from': from,
        'to': to,
        'label': label,
        'style': edgeStyle(connector),
      });
    }
  }
  return true;
}

String _stripLabel(String label) {
  return label.replaceAll('<br/>', ' ').replaceAll('<br>', ' ').trim();
}

// ── sequenceDiagram ─────────────────────────────────────────

final RegExp _participantPattern =
    RegExp(r'^participant\s+([A-Za-z_][\w-]*)(?:\s+as\s+(.+))?$');
final RegExp _actorPattern =
    RegExp(r'^actor\s+([A-Za-z_][\w-]*)(?:\s+as\s+(.+))?$');

// 메시지 커넥터 (Mermaid sequence):
//   -> / ->>      (solid, 1 dash)
//   --> / -->>    (dashed, 2 dashes = reply)
//   -x / --x      (lost message, cross)
//   -) / --)      (async, open arrow)
// 2 dashes → reply/async, 1 dash → sync. `+`/`-` activation suffix 무시.
// id 패턴에서 `-`를 제외해야 greedy가 커넥터 대시를 먹지 않음.
final RegExp _sequenceMsgPattern = RegExp(
  r'^([A-Za-z_]\w*)\s*(-{1,2}(?:>>?|x|\)))\+?-?\s*([A-Za-z_]\w*)\s*:\s*(.+)$',
);

Map<String, dynamic>? _parseSequence(List<String> lines) {
  final participants = <String>[];
  final displayByRef = <String, String>{};
  final steps = <Map<String, dynamic>>[];

  void addParticipant(String id, [String? display]) {
    if (!participants.contains(id)) {
      participants.add(id);
      if (display != null) displayByRef[id] = display;
    } else if (display != null && !displayByRef.containsKey(id)) {
      displayByRef[id] = display;
    }
  }

  for (var idx = 1; idx < lines.length; idx++) {
    final raw = lines[idx].trim();
    if (raw.isEmpty) continue;

    // 명시적 participant / actor 선언.
    final pMatch = _participantPattern.firstMatch(raw) ??
        _actorPattern.firstMatch(raw);
    if (pMatch != null) {
      addParticipant(pMatch.group(1)!, pMatch.group(2)?.trim());
      continue;
    }

    // 지원 안 하는 제어 구조/노트는 무시.
    if (raw.startsWith('Note ') ||
        raw.startsWith('note ') ||
        raw == 'end' ||
        raw.startsWith('alt ') ||
        raw.startsWith('else') ||
        raw.startsWith('opt ') ||
        raw.startsWith('loop ') ||
        raw.startsWith('par ') ||
        raw.startsWith('and ') ||
        raw.startsWith('critical ') ||
        raw.startsWith('break ') ||
        raw.startsWith('rect ') ||
        raw.startsWith('activate ') ||
        raw.startsWith('deactivate ') ||
        raw.startsWith('autonumber')) {
      continue;
    }

    final msg = _sequenceMsgPattern.firstMatch(raw);
    if (msg != null) {
      final from = msg.group(1)!;
      final connector = msg.group(2)!;
      final to = msg.group(3)!;
      final label = _stripLabel(msg.group(4)!);
      addParticipant(from);
      addParticipant(to);
      // reply 구분: 이중 대시 포함 (--> 또는 -->>) → reply.
      final kind = connector.startsWith('--') ? 'reply' : 'sync';
      steps.add({
        'from': from,
        'to': to,
        'label': label,
        'kind': kind,
      });
      continue;
    }

    // 인식 불가 라인: 전체 폴백.
    return null;
  }

  if (participants.isEmpty && steps.isEmpty) return null;

  final participantLabels = participants
      .map((id) => displayByRef[id] ?? id)
      .toList(growable: false);

  return {
    'type': 'sequence',
    'participants': participantLabels,
    'steps': steps.map((s) {
      // step에는 ref id 대신 display 라벨을 저장해 위젯에서 1:1 매칭 가능.
      return {
        'from': displayByRef[s['from']] ?? s['from'],
        'to': displayByRef[s['to']] ?? s['to'],
        'label': s['label'],
        'kind': s['kind'],
      };
    }).toList(),
  };
}

// ── mindmap ────────────────────────────────────────────────

// 옵션 prefix (ex: root) + 도형 markers + 본문.
final RegExp _mindmapNodePattern =
    RegExp(r'^(?:[A-Za-z_]\w*\s*)?(\(\(|\[|\{\{|\{)(.+?)(\)\)|\]|\}\}|\})$');

Map<String, dynamic>? _parseMindmap(List<String> lines) {
  if (lines.length < 2) return null;
  // 인덴트 기반 트리. 각 라인의 leading whitespace 길이로 깊이 판정.
  // root는 `mindmap` 다음 첫 라인 (자식 X — 그 자체가 최상위).
  final content = <Map<String, dynamic>>[]; // {indent, label}
  for (var idx = 1; idx < lines.length; idx++) {
    final line = lines[idx];
    if (line.trim().isEmpty) continue;
    final indent = line.length - line.trimLeft().length;
    final label = _mindmapNodeLabel(line.trim());
    content.add({'indent': indent, 'label': label});
  }
  if (content.isEmpty) return null;

  // 최소 indent를 0으로 정규화.
  final baseIndent = content
      .map((e) => e['indent'] as int)
      .reduce((a, b) => a < b ? a : b);
  for (final e in content) {
    e['indent'] = (e['indent'] as int) - baseIndent;
  }

  // 스택 기반 트리 구축. 첫 요소가 root.
  final root = <String, dynamic>{
    'label': content.first['label'],
    'children': <Map<String, dynamic>>[],
  };
  final stack = <_MindmapStackFrame>[
    _MindmapStackFrame(indent: 0, node: root),
  ];
  for (var i = 1; i < content.length; i++) {
    final indent = content[i]['indent'] as int;
    final label = content[i]['label'] as String;
    // 현재 indent보다 깊거나 같은 프레임을 pop.
    while (stack.length > 1 && stack.last.indent >= indent) {
      stack.removeLast();
    }
    final child = <String, dynamic>{
      'label': label,
      'children': <Map<String, dynamic>>[],
    };
    (stack.last.node['children'] as List).add(child);
    stack.add(_MindmapStackFrame(indent: indent, node: child));
  }

  return {'type': 'mindmap', 'root': root};
}

class _MindmapStackFrame {
  final int indent;
  final Map<String, dynamic> node;
  _MindmapStackFrame({required this.indent, required this.node});
}

String _mindmapNodeLabel(String trimmed) {
  final m = _mindmapNodePattern.firstMatch(trimmed);
  if (m != null) {
    return _stripLabel(m.group(2)!);
  }
  return _stripLabel(trimmed);
}

/// GFM 표 감지 결과. 없으면 null.
class _TableParseResult {
  final Map<String, dynamic> block;
  final int nextIndex;
  _TableParseResult(this.block, this.nextIndex);
}

final RegExp _separatorCellPattern = RegExp(r'^\s*:?-{3,}:?\s*$');

_TableParseResult? _tryParseTable(List<String> lines, int start) {
  if (start + 1 >= lines.length) return null;
  final header = lines[start];
  final separator = lines[start + 1];
  if (!_isTableRow(header) || !_isTableSeparator(separator)) return null;

  final headers = _splitRow(header);
  final alignments = _splitRow(separator).map(_alignmentFor).toList();
  if (headers.length != alignments.length) return null;

  final rows = <List<String>>[];
  var j = start + 2;
  while (j < lines.length && _isTableRow(lines[j])) {
    final cells = _splitRow(lines[j]);
    // 열 수 불일치는 무시하지 않고 table 끝으로 간주 (Markdown 사양 모호).
    if (cells.length != headers.length) break;
    rows.add(cells);
    j++;
  }

  // 데이터 행 0개도 허용 (헤더만 있는 "빈 표"). content_builder 관점에선 희귀
  // 하지만 파서 무결성을 위해 허용.
  return _TableParseResult(
    {
      'type': 'table',
      'headers': headers,
      'rows': rows,
      'alignments': alignments,
    },
    j,
  );
}

bool _isTableRow(String line) {
  final t = line.trim();
  if (t.length < 3) return false;
  return t.startsWith('|') && t.endsWith('|') && t.contains('|', 1);
}

bool _isTableSeparator(String line) {
  final t = line.trim();
  if (!t.startsWith('|') || !t.endsWith('|')) return false;
  final cells = _splitRow(line);
  if (cells.length < 2) return false;
  return cells.every((c) => _separatorCellPattern.hasMatch(c));
}

List<String> _splitRow(String line) {
  var t = line.trim();
  if (t.startsWith('|')) t = t.substring(1);
  if (t.endsWith('|')) t = t.substring(0, t.length - 1);
  return t.split('|').map((c) => c.trim()).toList();
}

String _alignmentFor(String separatorCell) {
  final t = separatorCell.trim();
  final startsColon = t.startsWith(':');
  final endsColon = t.endsWith(':');
  if (startsColon && endsColon) return 'center';
  if (endsColon) return 'right';
  if (startsColon) return 'left';
  return '';
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
