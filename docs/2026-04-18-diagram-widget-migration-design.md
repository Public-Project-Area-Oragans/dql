# Dev Quest Library — 다이어그램/표 순수 Flutter 위젯 이주 설계

> ASCII 다이어그램, Markdown 표, Mermaid 다이어그램을 이미지(SVG/PNG) 사전 렌더링 없이 **순수 Flutter 위젯**만으로 모든 배포 카테고리에서 올바르게 표시.

- **작성일**: 2026-04-18
- **상태**: DRAFT (사용자 승인 대기)
- **범위**: `java-spring`, `dart`, `flutter`, `mysql`, `msa` 전 5개 배포 카테고리
- **제약**: 이미지 에셋 사전 렌더링 금지, 모든 렌더링은 Flutter 네이티브 위젯

---

## 1. 배경

Phase 1~2 과정에서 `flutter_markdown`으로 이론 뷰를 렌더링하도록 구성했으나, 배포 후 관찰 결과 세 종류의 콘텐츠가 의도대로 표시되지 않는다.

1. **ASCII 다이어그램** (박스 드로잉 `─│┌┘` 등): 비례 폰트로 정렬이 깨짐. Task 12(PR #25)에서 `_ScrollablePreBuilder`로 monospace + 가로 스크롤을 적용했으나 master 미릴리즈 상태.
2. **Markdown 표** (`|...|`): 넓은 셀이 뷰포트를 넘어 잘림. 가로 스크롤 없음.
3. **Mermaid 다이어그램** (` ```mermaid ... ``` `): flutter_markdown이 인식하지 못해 일반 코드블록으로 표시됨 (시각적 의미 상실).

---

## 2. 콘텐츠 분포 (측정치)

`tools/content_builder.dart`로 생성한 `content/books/<category>/book.json` 기준.

| 카테고리 | 챕터 | Mermaid | Markdown 표(행) | ASCII 박스 블록 |
|---|---|---|---|---|
| java-spring | 48 | 0 | 많음 | 109 |
| dart | 24 | 0 | 많음 | 51 |
| flutter | 32 | 0 | 많음 | 184 |
| mysql | 31 | 0 | 577×2열 + 402×3열 + 67×4열 + 27×5열 + 5×6열 | 159 |
| **msa** | 46 | **672** | 많음 + 4 구조 표 | 24 |

Mermaid 타입 분포(MSA 기준):

| 타입 | 개수 | 비중 |
|---|---|---|
| `flowchart TB/LR/TD/BT` | 557 | 82.9% |
| `sequenceDiagram` | 73 | 10.9% |
| `mindmap` | 31 | 4.6% |
| `gantt` | 4 | 0.6% |
| `stateDiagram-v2` | 3 | 0.4% |
| `quadrantChart` / `erDiagram` / `classDiagram` / `graph` | 각 1 | 0.6% |

**함의**: Mermaid의 93% 이상이 `flowchart + sequence + mindmap`. 이 3종만 커버하면 거의 전부.

---

## 3. 제약 (확정)

1. **이미지 사전 렌더링 금지**: `mermaid-cli → SVG` 같은 빌드 파이프라인 배제. 런타임 이미지 에셋 불가.
2. **순수 Flutter 위젯**: `Text`, `Table`, `CustomPaint`, `Row/Column`, `GraphView`(순수 Dart) 등만 허용. `webview_flutter` / `image` / `flutter_svg`(외부 SVG 파일 로드용) 배제.
3. **전 카테고리 적용**: 5개 배포 카테고리 모두에서 동일 동작.
4. **점진적 폴백**: 미지원 Mermaid 타입은 시각 저하되더라도 가독성 유지(monospace 코드블록).

---

## 4. 접근법 비교

### Approach A — 런타임 파서 (클라이언트 측)

- **개념**: 기존 `book.json`의 `codeExamples[language='mermaid']`과 섹션 본문의 `` ```text `` 블록을 Flutter 앱에서 런타임에 파싱, 위젯 트리로 변환.
- **파이프라인 변경 없음**: `tools/content_builder.dart` 그대로.
- **노력**: M (2~3주)
- **장점**: 콘텐츠 재빌드 없이 Flutter 앱 업그레이드만으로 적용.
- **단점**: 파싱 비용을 클라이언트가 전담. 대형 MSA 챕터 로드 시 프레임 드랍 가능.

### Approach B — 빌드 타임 구조화 (서버/빌드 측)

- **개념**: `content_builder`가 Mermaid·표·ASCII 박스를 **구조화된 JSON**으로 변환해 `book.json`에 저장. Flutter 앱은 해당 JSON을 읽어 네이티브 위젯으로 바로 렌더.
- 예시 출력:
  ```json
  {
    "type": "flowchart",
    "direction": "TB",
    "nodes": [{"id":"A","label":"Gateway","kind":"rect"},...],
    "edges": [{"from":"A","to":"B","label":"request","style":"solid"}]
  }
  ```
- **노력**: L (3~5주 — 파서 작성 + 위젯 + 테스트)
- **장점**:
  - 런타임 파싱 비용 0
  - 파서 오류는 CI 빌드 시점에 가시화 (배포 안전)
  - 캐시 친화적 (동일 JSON은 동일 위젯 트리)
- **단점**:
  - content_builder Dart 코드 복잡도 상승
  - docs-source 소스 변경 시마다 재빌드 필요 (이미 그런 파이프라인이긴 함)

### Approach C — 하이브리드

- 간단 블록(표, ASCII 박스)은 런타임 파싱, 복잡 블록(Mermaid)은 빌드 타임 구조화.
- 두 경로를 양쪽으로 유지하는 비용.
- 노력 M~L, 장기 유지보수 부담.

### 추천: **Approach B**

근거:
1. Mermaid 파서는 상태 기계라 Dart로 구현해도 100~300줄 정도. 빌드 시점에만 돌므로 `dart:io` 자유롭게 사용.
2. `book.json`은 이미 빌드 산출물(gitignore). 구조 확장은 자연스러움.
3. Flutter 위젯 계층이 "JSON → 위젯"의 단일 책임만 가지므로 테스트 용이.
4. 설계 문서(`dev-quest-library-design.md`)의 "`content/books/*.json` 단일 소스 원칙"과 정합.

---

## 5. 데이터 모델 (Approach B)

`lib/data/models/book_model.dart`에 새 freezed 타입 추가. 기존 섹션의 `content` 필드(문자열)는 유지하되, 새로 `blocks` 필드를 추가해 구조화 블록을 순서대로 나열.

```dart
@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.none)
sealed class ContentBlock with _$ContentBlock {
  // 단순 마크다운 prose (기존 content의 일반 단락)
  const factory ContentBlock.prose({required String markdown}) = ProseBlock;

  // 구조화된 표
  const factory ContentBlock.table({
    required List<String> headers,
    required List<List<String>> rows,
    List<String>? alignments, // left/center/right/null
  }) = TableBlock;

  // ASCII 박스 다이어그램 (monospace 유지)
  const factory ContentBlock.asciiDiagram({required String source}) = AsciiDiagramBlock;

  // Mermaid flowchart
  const factory ContentBlock.flowchart({
    required String direction, // TB/LR/TD/BT
    required List<GraphNode> nodes,
    required List<GraphEdge> edges,
  }) = FlowchartBlock;

  // Mermaid sequenceDiagram
  const factory ContentBlock.sequence({
    required List<String> participants,
    required List<SequenceStep> steps,
  }) = SequenceBlock;

  // Mermaid mindmap
  const factory ContentBlock.mindmap({required MindmapNode root}) = MindmapBlock;

  // 미지원 타입 폴백 (원본 코드블록 monospace 렌더)
  const factory ContentBlock.raw({
    required String language,
    required String source,
  }) = RawBlock;

  factory ContentBlock.fromJson(Map<String, dynamic> json) =>
      _$ContentBlockFromJson(json);
}
```

기존 `TheorySection.content`는 **유지하되** 새 `blocks: List<ContentBlock>`를 선택적 필드로 추가. Phase 1 하위호환을 깨지 않기 위해, `blocks`가 비어 있으면 기존 `content`(markdown) 파이프라인으로 폴백.

---

## 6. 빌드 타임 파서 스펙 (`tools/content_builder.dart`)

### 6.1 표 파서

Markdown GFM 표 검출 규칙: `| ... |` 형태의 행이 2개 이상 연속이며, 둘째 행이 `|---|---|` 형식. 각 열 정렬은 `|:---|`, `|:---:|`, `|---:|`로 판정.

출력:
```json
{"type":"table","headers":["전략","설명","적합성"],"rows":[["MSA","...","..."]],"alignments":["left","left","center"]}
```

### 6.2 ASCII 박스 다이어그램

Task 12에서 이미 연속 3줄 이상 박스 드로잉을 ` ```text `` 펜스로 감싸는 규칙이 있음. 이 경로를 재사용해 `AsciiDiagramBlock`으로 emit.

### 6.3 Mermaid 파서

각 지원 타입은 라인 기반 상태 머신:

**Flowchart** (예: `flowchart TB\n  A[Client] --> B[Gateway]`):
- 헤더 라인: `flowchart|graph <DIRECTION>`
- 노드 라인: `<id>[<label>]`, `<id>{<label>}`, `<id>((<label>))` 등
- 엣지 라인: `<from> -->|<label>| <to>`, `<from> --> <to>`, `<from> -.-> <to>`

**SequenceDiagram**:
- 헤더: `sequenceDiagram`
- 참가자: `participant <name>` 또는 첫 등장 순서 자동 추출
- 메시지: `<A>-><B>: label`, `<A>-->>-<B>: label` 등 동기/비동기/응답

**Mindmap**:
- 헤더: `mindmap`
- 들여쓰기 기반 트리 구조
- 노드 형식: `((text))`, `[text]`, `text`

**미지원 타입** (`gantt`, `erDiagram`, `classDiagram`, `quadrantChart`, `stateDiagram-v2`): `RawBlock`으로 emit. 시각은 monospace이지만 정보 유지.

### 6.4 파서 테스트

`test/tools/`에 각 타입별 파서 단위 테스트 추가 (각 5~8 케이스):
- `flowchart_parser_test.dart` — 방향, 노드 형상 6종, 엣지 스타일 4종, subgraph
- `sequence_parser_test.dart` — participant 추출, 메시지 타입 4종
- `mindmap_parser_test.dart` — 들여쓰기, 중첩 3단계
- `table_parser_test.dart` — 정렬, 셀 내부 markdown, escape

---

## 7. 위젯 구현 (`lib/presentation/widgets/blocks/`)

### 7.1 파일 구조

```
lib/presentation/widgets/blocks/
├── content_block_renderer.dart   ← switch(block) → 해당 위젯
├── prose_block.dart              ← MarkdownBody 래핑
├── table_block_widget.dart       ← Table (Flutter native)
├── ascii_diagram_widget.dart     ← Task 12 _ScrollablePreBuilder 재사용
├── flowchart_widget.dart         ← graphview 또는 CustomPaint
├── sequence_widget.dart          ← Column + CustomPaint (시간축)
├── mindmap_widget.dart           ← 재귀 Tree + Expanded
└── raw_block_widget.dart         ← monospace fallback
```

### 7.2 의존성 평가

| 위젯 | 접근법 | 필요 패키지 | 라이선스 | 번들 영향 |
|---|---|---|---|---|
| `TableBlock` | Flutter 내장 `Table` | 없음 | N/A | 0 |
| `AsciiDiagramBlock` | `SelectableText` + `SingleChildScrollView(Axis.horizontal)` | 없음 | N/A | 0 |
| `FlowchartWidget` | **`graphview: ^1.2.0`** — Sugiyama/Tree/FR 레이아웃, 순수 Dart, `CustomPaint` 기반 | MIT | ~50KB |
| `SequenceWidget` | 자체 `CustomPaint` + `Column` | 없음 | N/A | 0 |
| `MindmapWidget` | 재귀 `ExpansionTile` 또는 `Column` + 들여쓰기 | 없음 | N/A | 0 |
| `RawBlock` | `SelectableText` + 가로 스크롤 | 없음 | N/A | 0 |

`graphview`가 유일한 신규 외부 패키지. 이미지 로딩이 아니라 레이아웃 계산 엔진이므로 "이미지 금지" 제약에 저촉되지 않음. 라이선스도 문제 없음.

대안: `graphview` 도입 부담이 있다면 **Sugiyama 레이아웃 알고리즘을 직접 구현** (200~400줄). 1회성 투자로 외부 의존 제거.

### 7.3 스케치

**`FlowchartWidget`** — `graphview.GraphView` 기반:
```dart
class FlowchartWidget extends StatelessWidget {
  final FlowchartBlock block;
  @override
  Widget build(BuildContext context) {
    final graph = Graph();
    for (final n in block.nodes) graph.addNode(Node.Id(n.id));
    for (final e in block.edges) {
      graph.addEdge(Node.Id(e.from), Node.Id(e.to));
    }
    final config = SugiyamaConfiguration()
      ..nodeSeparation = 30
      ..levelSeparation = 40
      ..orientation = _orientationFrom(block.direction);
    return InteractiveViewer(
      constrained: false,
      boundaryMargin: const EdgeInsets.all(40),
      child: GraphView(
        graph: graph,
        algorithm: SugiyamaAlgorithm(config),
        builder: (Node node) => _NodeCard(label: _labelFor(node, block)),
      ),
    );
  }
}
```

**`SequenceWidget`** — Column + CustomPaint로 시간축 화살표:
- 상단: `Row` of participants (`Container`에 라벨)
- 본문: 각 step마다 `CustomPaint`로 source→target 화살표 + 라벨
- 세로 스크롤 자동

**`TableBlockWidget`** — Flutter 내장 `Table`:
```dart
Table(
  columnWidths: {
    for (var i = 0; i < block.headers.length; i++) i: const IntrinsicColumnWidth(),
  },
  border: TableBorder.all(color: AppColors.gold.withValues(alpha: 0.4)),
  children: [
    TableRow(decoration: BoxDecoration(color: AppColors.deepPurple),
      children: block.headers.map(_headerCell).toList()),
    for (final row in block.rows)
      TableRow(children: row.map(_bodyCell).toList()),
  ],
)
```
긴 셀 대응: `table` 전체를 `SingleChildScrollView(scrollDirection: Axis.horizontal)`로 감쌈.

---

## 8. 통합 (`theory_card.dart`)

기존 `MarkdownBody(data: section.content, builders: {...})`에서, `section.blocks`가 존재하면 해당 리스트를 순회하며 `ContentBlockRenderer`로 렌더. blocks 없으면 기존 markdown 경로(하위호환).

```dart
if (section.blocks.isNotEmpty) {
  for (final block in section.blocks) ContentBlockRenderer(block: block)
} else {
  MarkdownBody(data: section.content, ...)  // 기존
}
```

---

## 9. 접근성

| 위젯 | 대체 경로 |
|---|---|
| `FlowchartWidget` | `Semantics(label: '${block.nodes.length}개 노드, ${block.edges.length}개 연결을 가진 흐름도')` + 확장 시 노드/엣지 리스트 낭독 |
| `SequenceWidget` | 순서 리스트로 대체: "1. A가 B에게 label 요청", "2. B가 A에게 응답" |
| `TableBlockWidget` | `Table`이 기본적으로 스크린리더 친화적. 헤더는 `header` Semantics 플래그 |
| `AsciiDiagramBlock` | `Semantics(excludeSemantics: true, child: ..., label: '원본 소스: ${first 100 chars}...')` |

---

## 10. 점진적 롤아웃 (PR 분할)

| # | PR 제목 | 범위 | 의존 | 난이도 |
|---|---|---|---|---|
| 1 | `feat(diagram-1): ContentBlock sealed union + markdown→blocks 파이프라인 skeleton` | 데이터 모델 + 기존 content를 단일 `ProseBlock`으로 wrap. 동작 무변화. | 없음 | S |
| 2 | `feat(diagram-2): 표 파서 + TableBlockWidget` | 모든 카테고리 적용. 가장 흔하고 쉬운 대상. | #1 | M |
| 3 | `feat(diagram-3): ASCII 박스 → AsciiDiagramBlock` | Task 12 로직을 blocks로 편입. | #1 | S |
| 4 | `feat(diagram-4): Flowchart 파서 + FlowchartWidget (graphview)` | MSA 557개 커버. | #1 | L |
| 5 | `feat(diagram-5): Sequence/Mindmap/Raw fallback` | MSA 104개 커버. 나머지는 RawBlock. | #1 | M |
| 6 | `chore(diagram-6): develop→master 릴리즈` | 배포. | #1~5 | XS |

누적 커버리지 (MSA 기준):
- PR #2 이후: 표 100%
- PR #3 이후: 표 + ASCII 박스 100%
- PR #4 이후: + flowchart 82.9%
- PR #5 이후: + sequence 10.9% + mindmap 4.6% = **~98%** (미지원 gantt/er/class/quadrant는 Raw)

---

## 11. 위험 & 대응

1. **Mermaid 파서 엣지 케이스**: subgraph 중첩, 긴 label, 특수문자. → 단위 테스트에 실제 docs-source 샘플 5~10개 고정 입력으로 포함.
2. **레이아웃 성능**: MSA 한 챕터에 flowchart 10개 이상 있는 경우. → `InteractiveViewer`로 개별 다이어그램이 뷰포트를 초과하지 않도록 clip + `AutomaticKeepAliveClientMixin`으로 재계산 방지.
3. **오프스크린 렌더링**: TabBar 전환 시 flowchart 재계산. → 동일 `AutomaticKeepAlive` 전략.
4. **웹 빌드 번들 크기**: `graphview` 추가 ~50KB. 허용 범위.
5. **파서 회귀**: 기존 markdown이 이상하게 구조화될 가능성. → Characterization 테스트로 `content_builder` 전 카테고리 빌드 결과의 블록 개수 스냅샷 유지.

---

## 12. 성공 기준

1. `flutter test` 모든 기존 테스트 + 신규 파서/위젯 테스트 녹색.
2. `flutter analyze lib/` 신규 warning 0.
3. `flutter build web --release` 성공.
4. 배포 사이트에서 다음 샘플 챕터가 의도대로 표시:
   - `mysql/mysql-step-04` — 큰 표 (넓은 셀 가로 스크롤).
   - `msa/phase4-step1-api-gateway` — flowchart 5개+, sequenceDiagram 1개+.
   - `flutter/step-14-foundation` — ASCII 박스 다이어그램 3개+.
5. 기존 Phase 2 MSA 시뮬레이터 라우팅 테스트 (routing_test.dart) 회귀 없음.

---

## 13. 다음 단계

- [ ] 이 문서 사용자 리뷰 & 승인
- [ ] PR 1 skeleton부터 순차 실행 (위 롤아웃 표 순서대로)
- [ ] 배포 후 `/debug/telemetry`로 챕터 진입 성공률 기록

> **주**: 이 설계는 "이미지 사용 금지 + 전 카테고리 + 순수 Flutter 위젯"이라는 명시 제약을 충족하며, 현재 관찰된 세 종류 렌더 결함을 모두 대상으로 한다. Mermaid의 경우 93% 이상을 커버하고 잔여 7%는 monospace fallback으로 가독성을 유지한다.
