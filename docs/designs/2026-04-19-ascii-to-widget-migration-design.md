# DOL — ASCII 다이어그램 → 구조화 Flutter 위젯 이주 설계

> 5개 카테고리에 산재한 **527 asciiDiagram + 20 raw 블록** 전량을
> 텍스트 렌더(monospace) 에서 **파서 기반 구조화 블록 + 네이티브 Flutter 위젯**
> 으로 이주한다. 최종 목표: 프로덕션 UI 어디에도 ASCII 문자 아트가 보이지 않음.

- **작성일**: 2026-04-19
- **상태**: DRAFT (사용자 승인 대기)
- **전제**:
  - `docs/designs/2026-04-18-diagram-widget-migration-design.md` — Phase 3 기존 이주 (mermaid 대상, ASCII 제외)
  - fix-4a (JetBrains Mono 번들) — 본 이주 완료 전까지의 **안전 렌더 층**

---

## 1. 배경

Phase 3 "다이어그램 위젯 이주" 는 **Mermaid (flowchart/sequence/mindmap/table)** 만
구조화하고, ASCII 박스 드로잉(`─│┌┘` 등) 은 "손으로 그린 시각 자체가 source"
라는 근거로 `SelectableText` monospace 렌더 경로를 유지했다.

2026-04-19 실사용 체크 결과:
1. Flutter Web CanvasKit 가 generic `'monospace'` family 를 OS/브라우저별로 불안정하게 매핑.
2. 열 정렬이 깨진 ASCII 박스는 정보 가치가 크게 훼손됨.
3. fix-4a 의 JetBrains Mono 번들은 **근본 해결이 아닌 품질 보증 층** — 브라우저
   렌더링 변동성에 영구적으로 의존.

사용자 결정: **"모든 언어에 ASCII 구성은 하나도 존재하면 안 된다, 모두 변경 필요"** (2026-04-19).

---

## 2. 현재 분포 (2026-04-19 배포 기준)

`content/books/<category>/book.json` 의 `blocks` 배열 타입 카운트:

| 카테고리 | asciiDiagram | raw | 총 블록 |
|---|---:|---:|---:|
| java-spring | 109 | 0 | 944 |
| dart | 51 | 0 | 555 |
| flutter | 184 | 0 | 849 |
| mysql | 159 | 0 | 864 |
| msa | 24 | 20 | 2723 |
| **합계** | **527** | **20** | **5935** |

raw 20 은 mermaid 도메인 특화(gantt/er/class/quadrant/block-beta) + flowchart edge case → 본 이주 범위 밖. 본 설계는 **asciiDiagram 527 건** 대상.

---

## 3. ASCII 박스 드로잉의 유형 분석

샘플 50건 수기 분석한 결과 5개 패턴 군으로 분류 가능.

### 3.1 Pattern A — 단순 박스 (~35%)
```
┌─────────────────┐
│  단일 라벨        │
└─────────────────┘
```
- 한 개의 사각형 + 내부 텍스트.
- 파서 난이도: **낮음**.

### 3.2 Pattern B — 박스 + 표 구조 (~20%)
```
┌──────┬──────┬──────┐
│ H1   │ H2   │ H3   │
├──────┼──────┼──────┤
│ V1   │ V2   │ V3   │
└──────┴──────┴──────┘
```
- 내부에 `├┼┤` 행/열 구분자가 있는 표. **Markdown 표로 사전 변환해야 하는 후보**.
- 파서 난이도: 중 (열 경계 추출).

### 3.3 Pattern C — 플로우 (박스 + 화살표) (~25%)
```
┌─────┐    ┌─────┐    ┌─────┐
│  A  │───▶│  B  │───▶│  C  │
└─────┘    └─────┘    └─────┘
```
- 수평/수직 `─│` 라인 + `▶▼◀▲` 화살표로 박스 연결.
- 파서 난이도: 중-높음 (박스 bounding box 추출 + connector trace).

### 3.4 Pattern D — 계층 (들여쓰기 기반 트리) (~15%)
```
Root
├── Child A
│   └── Grandchild A1
└── Child B
    └── Grandchild B1
```
- 프로그래머 친숙 트리 출력. Mindmap 과 의미론적 동일.
- 파서 난이도: **낮음** (기존 `MindmapWidget` 으로 변환 가능).

### 3.5 Pattern E — 혼합·자유 (~5%)
- 주석·수식·코드 실행 트레이스·메모리 맵 등 임의 구조.
- 파서 난이도: **매우 높음** → RawBlock 폴백.

---

## 4. 접근법 비교

### Approach A — 완전 수동 (콘텐츠 리라이트)
- 모든 ASCII 를 `docs-source/` 원본 마크다운에서 Mermaid 로 수기 교체.
- **노력**: 극단적 (527건 × 수 분).
- **장점**: 작성자 의도 완전 반영.
- **단점**: 자동화 불가 → 지속 가능성 0.

### Approach B — 파서 + 구조화 블록 + 네이티브 위젯 (권장)
- `tools/content_builder.dart` 에 ASCII 박스 파서 추가.
- 새 `ContentBlock.boxDiagram({List<BoxNode> nodes, List<BoxEdge> edges, GridSize grid})` variant.
- `BoxDiagramWidget`: `Container` + `CustomPaint` 로 박스·커넥터 드로잉.
- 파서 실패 시 `RawBlock` 으로 폴백 (JetBrainsMono 렌더).
- **노력**: 중-높음 (파서 500~800라인 + 위젯 200라인 + 테스트).
- **장점**: 자동화, 확장성, 뷰포트 반응형.

### Approach C — `CustomPaint` 그리드 드로잉 (얕은 위젯화)
- 파싱 없이 각 문자를 `(col × charW, row × lineH)` 에 `TextPainter` 로 찍음.
- `AsciiDiagramBlock` 은 유지, 렌더만 교체.
- **노력**: 낮음 (150라인).
- **장점**: 100% 시각 보존, 폰트 의존 0.
- **단점**: 여전히 "문자 아트" — 시맨틱 정보 없음, 접근성 낭패, 반응형 불가.

### 추천: **B (파서 + 구조화) + Pattern E 는 C 폴백**
- B 로 대다수(A/B/C/D = 95%) 처리.
- Pattern E (5%) 는 C 폴백 또는 RawBlock.

---

## 5. 새 데이터 모델

### 5.1 `ContentBlock` union 확장

`lib/data/models/content_block.dart`:

```dart
@Freezed(unionKey: 'type', unionValueCase: FreezedUnionCase.none)
sealed class ContentBlock with _$ContentBlock {
  // ... 기존 variant 유지 ...

  /// ASCII 박스 드로잉 파서가 구조화한 박스 다이어그램.
  /// - Pattern A: 단일 박스 → nodes=1, edges=[]
  /// - Pattern C: 플로우 → nodes=N, edges=M
  /// - Pattern B: 표 → (대안) TableBlock 로 재라우팅
  /// - Pattern D: 트리 → (대안) MindmapBlock 으로 재라우팅
  const factory ContentBlock.boxDiagram({
    required List<BoxNode> nodes,
    required List<BoxEdge> edges,
    required int cols,
    required int rows,
  }) = BoxDiagramBlock;
}

@freezed
abstract class BoxNode with _$BoxNode {
  const factory BoxNode({
    required String id,
    required String label,
    required int col,       // top-left 그리드 좌표
    required int row,
    required int widthCells,
    required int heightCells,
    @Default('rect') String shape, // rect | rounded | diamond
  }) = _BoxNode;
  factory BoxNode.fromJson(Map<String, dynamic> json) =>
      _$BoxNodeFromJson(json);
}

@freezed
abstract class BoxEdge with _$BoxEdge {
  const factory BoxEdge({
    required String from,
    required String to,
    @Default('→') String arrow, // → ← ↑ ↓ ↔
    @Default('') String label,
  }) = _BoxEdge;
  factory BoxEdge.fromJson(Map<String, dynamic> json) =>
      _$BoxEdgeFromJson(json);
}
```

### 5.2 파서 출력 예시

입력:
```
┌─────┐    ┌─────┐
│  A  │───▶│  B  │
└─────┘    └─────┘
```

출력:
```json
{
  "type": "boxDiagram",
  "cols": 19,
  "rows": 3,
  "nodes": [
    {"id": "n1", "label": "A", "col": 0, "row": 0, "widthCells": 7, "heightCells": 3},
    {"id": "n2", "label": "B", "col": 11, "row": 0, "widthCells": 7, "heightCells": 3}
  ],
  "edges": [{"from": "n1", "to": "n2", "arrow": "→"}]
}
```

---

## 6. 파서 설계 (`tools/content_builder.dart`)

### 6.1 파싱 단계

1. **Tokenize**: 2D 격자 배열 `grid[row][col]` 로 적재.
2. **Box detection**: `┌` 발견 → 같은 row 에서 `─+` 추적 → `┐` → 열 따라 `│+` → `└┘` 닫힘 확인. 바운딩 박스 수집.
3. **Label extraction**: 각 박스 내부 문자를 행별 연결 → trim.
4. **Table detection**: 바운딩 박스 내부에 `├┼┤` 가 있으면 **TableBlock 으로 재라우팅** (기존 위젯 재사용).
5. **Tree detection**: `├──`/`└──` 들여쓰기 패턴 → **MindmapBlock 으로 재라우팅**.
6. **Edge detection**: 박스 외부 `─│▶◀▼▲` 를 path tracing → nearest-box 매칭 → edge emit.
7. **Unparseable**: 박스 0개 이상 연결 실패 → RawBlock 폴백.

### 6.2 유닛 테스트 (최소 15 케이스)

- `test/tools/content_builder_ascii_parser_test.dart`
  - Pattern A 단일 박스 (3 케이스: 숫자/한글/영어 label)
  - Pattern B 표 → TableBlock 재라우팅 (2)
  - Pattern C 수평 플로우 2-5 노드 (4)
  - Pattern C 수직 플로우 (1)
  - Pattern C 분기/병합 (2)
  - Pattern D 트리 2-3 level → MindmapBlock 재라우팅 (2)
  - Pattern E 파싱 실패 → RawBlock 폴백 (1)

### 6.3 회귀 가드

- 기존 `_extractBlocks` 를 건드리므로 **characterization test** 필수:
  - MSA book.json 의 block type 카운트 스냅샷을 테스트에 고정.
  - 파서 도입 후 `asciiDiagram` 이 `boxDiagram`/`tableBlock`/`mindmap`/`raw` 로 재분류되는 차이가 의도대로인지 확인.

---

## 7. 위젯 구현 (`lib/presentation/widgets/blocks/`)

### 7.1 `BoxDiagramWidget`

```dart
class BoxDiagramWidget extends StatelessWidget {
  final BoxDiagramBlock block;

  @override
  Widget build(BuildContext context) {
    final cellW = 10.0; // design token
    final cellH = 18.0;
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkWalnut,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SizedBox(
        width: block.cols * cellW,
        height: block.rows * cellH,
        child: CustomPaint(
          painter: _BoxDiagramPainter(block, cellW, cellH),
          child: Stack(
            children: [
              for (final n in block.nodes)
                Positioned(
                  left: n.col * cellW,
                  top: n.row * cellH,
                  width: n.widthCells * cellW,
                  height: n.heightCells * cellH,
                  child: Center(
                    child: Text(
                      n.label,
                      style: const TextStyle(
                        color: AppColors.parchment,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
```

- `_BoxDiagramPainter` 는 각 node 의 bounding box `drawRect`, edge 는 `drawLine` + 화살촉.
- 반응형: `InteractiveViewer` 로 래핑해 모바일·좁은 뷰포트 대응 예정(후속 PR).

### 7.2 접근성

- `Semantics(label: '${nodes.length}개 박스, ${edges.length}개 연결의 다이어그램')`.
- 확장 가능: 각 node 를 `Semantics(label: node.label)` 로 감싸 스크린리더가 읽도록.

---

## 8. 롤아웃 계획 (PR 분할)

| # | 범위 | 의존 | 난이도 |
|---|---|---|---|
| fix-4a ✅ | JetBrains Mono 번들 — 안전 렌더 층 | 없음 | S |
| fix-4b | `ContentBlock.boxDiagram` + `BoxNode/BoxEdge` freezed 모델 + build_runner | fix-4a | S |
| fix-4c | Pattern A (단일 박스) 파서 + 단위 테스트 | fix-4b | M |
| fix-4d | `BoxDiagramWidget` 렌더러 + 단위·위젯 테스트 | fix-4b | M |
| fix-4e | Pattern B (표) → TableBlock 재라우팅 | fix-4c | M |
| fix-4f | Pattern D (트리) → MindmapBlock 재라우팅 | fix-4c | M |
| fix-4g | Pattern C (플로우) 파서 — 수평 | fix-4c, d | L |
| fix-4h | Pattern C 분기·병합·수직 | fix-4g | M |
| fix-4i | 5 카테고리 실측 & 잔여 raw 분석 → 파서 미세 조정 | fix-4g, h | S-M |
| fix-4j | 접근성 보강 (`Semantics` 풀 커버) | fix-4d | S |
| fix-4k | characterization test snapshot 최종 고정 + release | 전부 | S |

**마일스톤**:
- fix-4a → 즉시 배포 (본 세션)
- fix-4b ~ 4d → 다음 세션 (1주 내)
- fix-4e ~ 4h → 2~3 주차
- fix-4i ~ 4k → 4 주차 릴리즈

---

## 9. 성공 기준

1. 5 카테고리 통합 `asciiDiagram` 블록 수 = **0**.
2. `raw` 블록 수가 **20 이하** 유지 (msa 도메인 특화 mermaid 폴백만).
3. `boxDiagram` + 재라우팅된 `table`/`mindmap` 합계 ≥ **500** (원 527 대비 95%+).
4. 프로덕션 브라우저 검증: MSA `msa-roadmap` 등 대표 챕터에서 박스가 Flutter 컨테이너로 렌더 (DOM 에 `<text>` 아트 없음 — `<canvas>` 또는 `<div>` border).
5. 접근성: 스크린리더가 각 박스 label 을 개별 낭독.
6. 기존 Phase 3 flowchart/sequence/mindmap/table 렌더 회귀 0.

---

## 10. 리스크 & 완화

| 리스크 | 완화 |
|---|---|
| 파서가 엣지 케이스(복잡 도형)에서 잘못된 그래프 생성 | characterization test 로 카테고리별 typecount 스냅샷 유지. 파서 승격 전 샘플 50건 수기 검수. |
| 박스 내 줄바꿈·특수문자 (수식·화살표 포함) | 파서는 순수 박스 구조만 인식, 내부는 그대로 `label` 에 넣음. 위젯에서 줄바꿈 처리. |
| `BoxDiagramWidget` 레이아웃 깨짐 (좁은 뷰포트) | `InteractiveViewer` + `FittedBox(fit: BoxFit.scaleDown)` 조합. 모바일 폴백 검토. |
| Approach B 가 Pattern E (5%) 를 커버 못함 | RawBlock 으로 폴백, JetBrainsMono 렌더로 허용. Success criteria 도 95%+ 로 설정. |
| Assignment 이탈 (특정 챕터의 ASCII 가 표/트리 일부 구조와 하이브리드) | 파서는 실패 시 전체 블록을 RawBlock 으로 폴백. 부분 파싱 시도 금지 (일관성 우선). |

---

## 11. 참조

- `docs/designs/2026-04-18-diagram-widget-migration-design.md` — Phase 3 mermaid 이주 (선행)
- `docs/phases/2026-04-18-phase-plan.md` §1.3 — P0 잔여 맥락
- `docs/workflows/2026-04-18-troubleshooting-journal.md` §4 — Mermaid 파서 교훈 (실측 주도 반복 패치)
- `lib/presentation/widgets/blocks/content_block_renderer.dart` — 디스패처
- `tools/content_builder.dart` `_extractBlocks` — 파서 편입 지점
