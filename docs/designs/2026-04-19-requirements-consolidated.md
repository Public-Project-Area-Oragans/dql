# DOL — 재작업 요구사항 정리 (2026-04-19)

> 2026-04-19 실사용 체크 중 사용자가 보고한 결함 5건 + 2 메타 요구사항.
> fix-1/2/3/4a 가 develop/master 에 반영된 뒤 실행된 사용자 검증에서 드러남.
> 본 문서는 **원점 재정리 + 재작업 승인 게이트** 역할.

- **작성일**: 2026-04-19
- **작성자**: Claude (세션 핸드오프 기준)
- **현재 master**: `af212e8` (PR #61, 배포 시각 `02:03:26 GMT`)
- **상태**: DRAFT — 사용자 승인 필요

---

## 0. 결정 원칙 (사용자 지시 반영)

### 0.1 배포 검증 프로토콜 (이번 세션부터 강제)

**내가 직접 수행하지 않는 배포 검증은 인정하지 않는다.** 사용자에게 브라우저 체크를 위임하는 구조는 결함 누락으로 이어졌음.

각 PR 배포 후 수행할 항목:

| # | 항목 | 도구 | 내가 가능 |
|---|---|---|---|
| 1 | master tip / gh-pages tip 매칭 | `git log`, `gh run list` | ✅ |
| 2 | 프로덕션 `Last-Modified` 갱신 | `curl -sI` | ✅ |
| 3 | 주요 자산(`main.dart.js` / `FontManifest.json` / `*.ttf` / `book.json`) HTTP 200 | `curl -sI` | ✅ |
| 4 | FontManifest 에 선언된 family 및 자산 실재 | `curl` 로 JSON + TTF 확인 | ✅ |
| 5 | 브라우저에서 Flame 캔버스 실 렌더 확인 | `gstack-browse` 헤드리스 | ⚠ **제한** (아래) |
| 6 | 각 분관/책장/NPC 상호작용 검증 | `gstack-browse` 클릭·스크린샷 | ⚠ **제한** |

### 0.2 헤드리스 브라우저 제한 (실측)

본 세션에서 `gstack-browse` 로 실 접속 시:

- Flutter bootstrap/main.dart.js/폰트 모두 정상 로드 확인.
- **CanvasKit WASM 이 `www.gstatic.com` 에서 `ERR_CONNECTION_FAILED`** → Flame 씬이 render되지 못함.
- 결과: `flt-glass-pane` 미생성, 스크린샷 화이트아웃.

→ UI-레벨 검증은 **헤드 모드 브라우저** (`$B connect`) 또는 **사용자 브라우저** 중 선택해야 함. 당분간은 두 가지 병행:
- 내가: 인프라·자산·FontManifest·책장 JSON 블록 구조 검증 (완전 자동)
- 사용자: 시각적 UI 결함 확인 (스크린샷 첨부로 되먹임)

### 0.3 재작업 방식

- **요구사항 문서 승인 전에는 코드 수정 금지**.
- 본 문서가 승인되면 각 결함별 PR 설계 → 구현 → 배포 → 내가 재검증 → 사용자 재확인.
- 사용자가 "문서 승인" 표시 전까지는 다음 PR 시작하지 않음.

---

## 1. 2026-04-19 사용자 실사용 체크 결과

### 1.1 결함 R0 — 각 분관별 서적 분리 안 됨

**사용자 보고**: "각 분관별 서적이 나눠지지 않음"

**재현 단계 (사용자 보고 4번과 결합)**:
1. 프로덕션 전체 새로고침
2. 중앙 홀 → 분관 입장
3. 분관 책장 클릭
4. **관찰**: 해당 분관 외 카테고리 책까지 전체 노출됨

**코드 관찰**:
- `lib/game/scenes/wing_scene.dart`: 분관 내 shelf 는 category 별로 생성됨 (frontend=2, 나머지=1).
- `lib/presentation/screens/game_screen.dart:40-44`: shelf 탭 → `questBoardFilterCategoryProvider.set(category)` 후 board open.
- `lib/presentation/overlays/quest_board_overlay.dart`: `filterCategory != null` 이면 해당 카테고리 책만 필터.

**의심 원인**:
- 중앙 홀에서 board 를 미리 연 상태가 닫히지 않은 채 분관 진입 시 잔존 상태?
- `.set(category)` 후 `.open()` 사이에 race condition?
- 또는 첫 렌더 시 `filterCategory` 가 아직 null 상태에서 ListView 구성이 먼저 실행됨?

**정리**: 코드 의도는 필터링 수행. 실관찰이 전체 노출. **런타임 검증 필요**.

---

### 1.2 결함 R1 — NPC 질문 탭 사라짐

**사용자 보고**: "NPC로부터 퀘스트 받는 대화와 질문 대화가 나눠져 있었으나 질문이 없어짐"

**재현 단계 (추정)**:
1. 분관 진입
2. NPC 클릭 → 대화 오버레이 열림
3. **관찰**: 💬 대화 탭만 존재, ❓ 질문 탭 없음

**코드 관찰**:
- `lib/presentation/overlays/dialogue_overlay.dart:47`: `if (npcId != null) _tabBar()` — tab bar 는 `activeNpcIdProvider` 값이 있을 때만 렌더.
- `lib/presentation/screens/game_screen.dart:35`: NPC 탭 시 `activeNpcIdProvider.set(npcId)` 호출.

**의심 원인**:
- `activeNpcId` 가 `@riverpod` 로 재빌드 시 초기화?
- NPC 탭 시 `onNpcTappedCallback` 이 실행되기 전 overlay 가 열림?
- 프로덕션 번들에 해당 코드가 실제 포함됐는지 재검증 필요.

**정리**: P0-5 의 NPC-4 로 탭 2개가 구현됐음. 그런데 사라졌다면 **회귀**. PR #51 이후 어느 시점에 깨졌는지 git diff 필요.

---

### 1.3 결함 R2 — ASCII 박스 전혀 변화 없음

**사용자 보고**: "ASCII 박스 전혀 변화 없음" (fix-4a 배포 직후)

**확인된 인프라 사실 (내 실측)**:
- `FontManifest.json`: `{"family":"JetBrainsMono","fonts":[{"asset":"assets/fonts/JetBrainsMono-Regular.ttf"}]}` 등록 완료
- TTF URL: `/dol/assets/assets/fonts/JetBrainsMono-Regular.ttf` → HTTP 200, 270224 bytes (원본과 동일)
- Flame 로드 시 동일 URL 요청 → 200 응답

**의심 원인 (가설 3종)**:
1. 브라우저/CDN 캐시가 구버전 HTML/main.dart.js 를 서빙.
2. JetBrainsMono 는 로드되나 사용자가 **이전에 보던 ASCII 박스 정렬 문제 그대로** 남음 → 폰트 문제가 아니라 **렌더 파이프라인(line height, letter spacing, 한글-ASCII wide char 혼재)** 문제.
3. 구조 자체가 깨짐 (박스 drawing 이 AsciiDiagramBlock 경로가 아니라 다른 path 로 감).

**정리**: 폰트만으로는 부족. 가설 2 가 가장 유력 — **한글 전각 + ASCII 반각** 문자는 같은 monospace 패밀리여도 셀 폭이 2:1 비율로 안 맞으면 정렬 깨짐. JetBrainsMono 는 한글 글리프가 없어 Fallback 으로 Noto/시스템 CJK 폰트가 render → 두 폰트 metric 충돌.

→ **근본 해결은 설계 문서(2026-04-19-ascii-to-widget-migration-design.md) 의 fix-4b 이후 파서+위젯 이주**. fix-4a 는 단독으로 불충분함이 실측됨.

---

### 1.4 결함 R3 — 책 제목 이모지 불일치

**사용자 보고**: "각 책의 제목에 이모지가 있는것과 없는것이 있는데 확인 필요 하나로 통일하기"

**코드 관찰**:
- `_FlatBookSection` (filterCategory != null 경로): `'📖 ${book.title}'` 으로 이모지 prefix.
- `ExpansionTile` (filterCategory == null 경로): `book.title` 만 (이모지 없음).
- `book.title` 자체는 `tools/content_builder.dart` 에서 `folderName` ("Java & Spring", "Dart Programing" 등) 사용.

**요구사항**:
- 하나로 통일. 후보:
  - A) 양쪽 경로 모두 `📖 {title}` 로 통일.
  - B) 양쪽 모두 이모지 제거.
- 사용자 선호 확인 필요. 내 추천: **A (이모지 유지)** — 세계관 톤(증기·마법 도서관) 에 아이콘이 어울림.

---

### 1.5 결함 R4 — 분관 책장 UX: 첫 진입 전체 노출 + 언어별 묶음

**사용자 시나리오 (전문 재인용)**:
> "전체 새로고침 -> 분관 진입 -> 책장 -> 하나의 분관에 모든 과목이 보임 -> 도서 클릭 -> 다시 나오기 -> 해당 분관의 도서목록만 보이나 앞서 수정 요청한 언어에 묶여서 바로 전체가 보이지 않음"

**분석**:
- R0 과 같은 "첫 진입 시 전체 노출" 문제.
- **추가 요구사항**: 필터 걸렸어도 책 단위로 묶이지 않고 해당 분관의 **전체 챕터가 바로** 평탄 노출되어야 함.

**사용자 의도 재구성**:
- 프론트 분관 → Dart + Flutter 책 2개 → 두 책의 **모든 챕터가 하나의 흐름으로** 보여야 함. 책 헤더도 최소화.
- 그 외 분관 → 1 책 → 해당 책의 전체 챕터 바로 노출.

**fix-2 설계 재고 필요**:
- 현재 fix-2 의 `_FlatBookSection` 는 `📖 {title}` 헤더 + 챕터 리스트. 사용자는 "언어에 묶여서" 라고 느낌 → 헤더가 불필요한 분리 단위로 작용.
- 대안: 분관 내 모든 책의 챕터를 단일 flat list 로. 책 구분은 얇은 divider 정도만.

---

### 1.6 결함 R5 — 배포 정상 여부 재확인

**사용자 보고**: "배포가 정상적으로 이루어졌는지 다시 확인하기"

**내 실측 결과 (완료)**:

| 항목 | 결과 |
|---|---|
| master tip | `af212e8` (PR #61 merge) |
| gh-pages tip | `e9f3272` (deploy of af212e8) |
| Sync & Deploy 최근 run | success `01:59:56Z` |
| 프로덕션 index.html Last-Modified | `2026-04-19 02:03:26 GMT` |
| main.dart.js Last-Modified | `2026-04-19 02:03:26 GMT` (3.37 MB) |
| FontManifest.json | `MaterialIcons` + `JetBrainsMono` 등록됨 |
| JetBrainsMono TTF | HTTP 200, 270224 B (원본과 동일) |

**결론**: **인프라·자산 배포는 100% 정상**. 사용자가 본 결함은 코드 레벨 버그이거나 브라우저 캐시 영향.

**권고**:
- 브라우저 개발자도구 → Network 탭 → **Disable cache** 체크 후 하드 리프레시
- 또는 Application 탭 → Service Workers → Unregister → Storage 클리어 → 리프레시

---

### 1.8 요구 R7 — 이론 파트 콘텐츠 재구성 (2026-04-19 추가)

**사용자 지시 (2026-04-19)**:

- 원본 `docs-source/` 레포에서 각 문서를 다시 가져와 작업.
- ASCII 및 Mermaid 블록을 **일반 문장 텍스트로 대체**해 이론 파트를 완전히 교체.
- **이론 파트에는 소스코드가 존재하면 안 됨.**
- 소스코드는 **차후 추가될 시뮬레이터 파트**에서 시뮬레이터 인터랙션과 함께 팝업/보조 패널로 표기.

**영향 범위**:

- `tools/content_builder.dart` 출력 스키마 변경:
  - `theory.sections[].blocks` 에서 asciiDiagram / flowchart / sequence / mindmap / table / raw 제거. `prose` 만 남김.
  - `theory.codeExamples` 제거.
- Chapter JSON 에 신설 필드 `simulatorContent.codeSnippets: List<{language, code, description}>` — 시뮬레이터 인터랙션과 병행 표시용.
- 5 카테고리 전체 book.json 재빌드 필요 (181 챕터).
- `docs-source/` submodule 은 최신 revision 으로 업데이트 후 재빌드.

**시뮬레이터 파트 인터랙션 보존 (중요)**:

- 시뮬레이터 파트의 기존 인터랙션(CodeStep, StructureAssembly 등)은 **모두 유지**.
- 이론 파트에서 옮겨온 코드 스니펫은 시뮬레이터 화면 내 **팝업 다이얼로그** 또는 **보조 패널(side panel)** 로 표시.
- 시뮬레이터가 "읽기 전용"으로 격하되지 않음. 코드는 참고용 + 인터랙션은 주체.

**정책**:

- docs-source 원본 markdown 수정 금지. 변환은 빌드 파이프라인에서만.
- 다이어그램·코드 펜스 자리에는 **Claude API 로 의도 기반 설명 prose 생성** 후 삽입 (2026-04-19 사용자 결정).
  - 생성은 **오프라인 1회** (`tools/ai_diagram_describer.dart`).
  - 결과는 `content/diagram-descriptions/<category>/<chapter-id>.json` 에 해시 → 설명 매핑으로 캐시.
  - **빌드(CI) 는 캐시만 조회**. API 호출 안 함.
  - 설명 길이: 한국어 1~2 문단.
  - 모델: `claude-haiku-4-5` 기본 (비용·지연 최적).

**전제 조건**:

- R6 (fix-9) 해결 후 착수. UI 회귀 없이 데이터 파이프라인 + 시뮬레이터 코드 패널 변경.

---

### 1.7 결함 R6 — 분관 책장 첫 탭 시 전체 카테고리 노출 (filter autoDispose 회귀)

**사용자 재확인 (2026-04-19)**: "msa 분관에 들어가서 책장을 열었더니 java, mysql, dart, flutter 가 다 보이는게 문제. msa 분관이면 오직 msa 의 책 목록만 나와야 한다."

**근본 진단**:

- `lib/domain/providers/game_providers.dart` 의 `@riverpod class QuestBoardFilterCategory` 는 **autoDispose 기본값**.
- `lib/presentation/screens/game_screen.dart:40-44` `onShelfTappedCallback` 은 `.set(category)` 직후 `.open()` 호출.
- `.set()` 시점에 이 provider 를 `ref.watch` 하는 위젯이 아직 렌더되지 않음 → listener 0 → autoDispose 가 state 재초기화 → 곧 이어 `QuestBoardOverlay` 가 렌더되며 `ref.watch(filterCategoryProvider)` 호출 시 **filterCategory == null** 관찰 → 전체 5 카테고리 노출.
- 재진입 시(이미 listener 상주) 는 정상 동작하기 때문에 사용자가 "첫 진입만 전체, 재진입 시 필터 적용" 로 관찰한 현상과 일치.

**해결 방향 (fix-9)**:

- `QuestBoardFilterCategory`, `QuestBoardOpen`, `CurrentWingId`, `CurrentScene` 을 `@Riverpod(keepAlive: true)` 로 전환. UI 세션 상태이므로 autoDispose 불필요.
- `dart run build_runner build --delete-conflicting-outputs` 로 `.g.dart` 재생성 (gitignored, CI 재생성).
- widget/integration test: shelf 탭 직후 **첫 render** 에서 filterCategory 가 즉시 해당 category 로 적용됨을 회귀 가드.

---

## 2. 요구사항 명세 (신규 UI 사양)

### 2.1 분관 책장 동작 (R0 + R4 + R6)

- 분관 입장 → 책장 클릭 → QuestBoard overlay 가 열림
- 해당 분관 담당 카테고리의 **모든 책의 모든 챕터**가 flat list 로 즉시 노출
- 책 단위 헤더 없음 (또는 1~2 px 구분선 수준)
- "이번 분관 퀘스트" 섹션은 유지 (NPC-6)
- 중앙 홀에서 board 를 연 경우(없다면 제거 검토) 에만 전체 5 카테고리 노출
- **첫 탭에서도 레이스 0, autoDispose 간섭 0** — 예: MSA 분관 → MSA 책장 탭 → MSA 챕터만. Java/Dart/Flutter/MySQL 혼재 금지. 재탭/재진입 동작과 일관되게 **1회 탭으로 확정**. (R6)

### 2.2 NPC 대화 오버레이 (R1)

- 분관 내 NPC 클릭 → 오버레이 열림
- **2 탭 고정 표시**: 💬 대화 / ❓ 질문
- 기본 선택 탭: 💬 대화
- ❓ 질문 탭은 `activeNpcId` 가 null 이어도 항상 보여야 하는가? → **YES, 고정 표시**. NPC 기본 컨텍스트로 해석.
- 대화 종료 시 overlay 닫히며 activeNpcId clear.

### 2.3 책 제목 이모지 규칙 (R3)

- 모든 경로에서 책 타이틀 앞에 **📖** prefix 통일.
- `content_builder.dart` 단계에서 처리 vs UI 단계에서 처리 → **UI 단계** 권장 (데이터는 pure, 표시 layer 에서 장식).

### 2.4 ASCII 다이어그램 렌더 (R2)

- **최종 목표**: ASCII 박스 0 개. 모두 구조화 Flutter 위젯으로 이주 (fix-4b 이후).
- **중간 단계**: JetBrainsMono 로드 확인됨. 한글 전각 충돌 시각 확인 필요. 폰트만으로 부족하면 fix-4b 부터 파서+위젯.
- 설계 문서: `docs/designs/2026-04-19-ascii-to-widget-migration-design.md` 참조.

### 2.5 배포 검증 (R5)

- 각 PR 머지 → master → gh-pages 배포 → 내가 `curl` + `gstack-browse` 로 인프라 검증 → 사용자에게 브라우저 체크리스트 전달.
- 다음 작업 착수 전에 검증 보고 공유.

---

## 3. 재작업 실행 계획

### 3.1 PR 분할 (2026-04-19 업데이트)

| PR | 범위 | 우선순위 | 난이도 | 상태 |
|---|---|---|---|---|
| fix-5 (R1) | DialogueOverlay ❓ 질문 탭 상시 노출 | 높음 | S | ✅ PR #62 merged |
| fix-6 (R0+R4+R3) | QuestBoard 책장 평탄화 + divider + 이모지 제거 | 높음 | M | ✅ PR #63 merged |
| fix-4a (R2 기반) | JetBrainsMono 번들 + fontFamily 교체 | 중간 | S | ✅ PR #60 merged |
| fix-4b (R2 모델) | `ContentBlock.boxDiagram` + BoxNode/BoxEdge + renderer 스켈레톤 | 낮음 | S | ✅ PR #65 merged |
| fix-4c (R2 렌더) | `AsciiGridDiagram` CustomPaint 그리드 드로잉 | 중간 | M | ✅ PR #66 merged — 테두리는 복구, 내부 한글 컬럼 정렬 미해결 |
| fix-9 (R6) | `QuestBoardFilterCategory` 등 UI 세션 state 를 `@Riverpod(keepAlive: true)` 로 전환 — autoDispose 로 인한 첫-탭 필터 소실 해결 | 최고 | S | ✅ PR #68/#69 merged — headed 브라우저 실측 완료, MSA 첫-탭 필터 정상 |
| fix-4-escalation (R2 조건부) | `tools/content_builder.dart` 의 `_extractBlocks` 에서 asciiDiagram / raw 블록을 emit 하지 않도록 strip | 조건부 | XS | **skip** — 사용자 2026-04-19 결정으로 R7 (fix-10) 로 대체 (§5.5 참조) |
| **fix-10 (R7)** | 이론 파트 prose-only 재구성 — asciiDiagram/flowchart/sequence/mindmap/table/raw/code 전부 strip + 코드는 simulator 팝업 | 높음 | L | ⏳ 진행 (세부 §3.4) |
| release | develop → master 묶음 | — | XS | — |

### 3.2 착수 순서 (2026-04-19 업데이트)

1. ✅ R1, R0, R3 해결 완료 (fix-5, fix-6)
2. ✅ R2 부분 완화 (fix-4a/4b/4c) — 테두리 복구, 내부 컬럼 미해결
3. ✅ R6 해결 (fix-9) — `@Riverpod(keepAlive: true)` 4 개 + headed 브라우저 실측 완료. MSA 분관 첫-탭 시 MSA 챕터만 즉시 노출 확인.
4. **지금: R7 착수 (fix-10a 부터)** — 이론 파트 prose-only 재구성.
5. 사용자 결정: fix-4-escalation **skip** (R7 에 포함됨, §5.5 참조).
6. fix-10 전 단계 완료 후 release → 배포 검증 → 최종 확인.

### 3.4 R7 실행 계획 (fix-10 ~ 10e, fix-9 이후)

| PR | 범위 | 의존 | 난이도 |
|---|---|---|---|
| fix-10a | content_builder `_extractBlocks` 를 prose-only 로 제한. asciiDiagram / flowchart / sequence / mindmap / table / raw 블록 strip. `theory.codeExamples` 필드 제거. 파싱 내부 테스트(ascii/flowchart/flowchart_boost/sequence_mindmap/table) 삭제 — emit 경로에서 parser 결과가 버려져 assertion 가치 상실 (Phase 3 의 위젯 자체는 코드 상 보존, 후속 정리 PR 에서 정리) | fix-9 머지 | M |
| fix-10b | **AI 기반 의도 설명 prose 삽입 파이프라인** — (1) `tools/ai_diagram_describer.dart` 신규 스크립트가 docs-source 각 MD 를 순회해 코드·다이어그램 펜스 블록을 Claude API (`claude-haiku-4-5`) 로 1~2 문단 한국어 설명 생성 → `content/diagram-descriptions/<category>/<chapter-id>.json` 해시→설명 캐시. (2) `tools/content_builder.dart` 는 펜스 drop 시 캐시에서 동일 해시 설명 조회 → currentContent 에 prose 삽입. 캐시 miss 시 "_[설명 생성 대기]_" placeholder. (3) CI 빌드는 캐시 조회만 (API 호출 없음). 로컬 오프라인으로만 `ANTHROPIC_API_KEY` env 로 생성 | fix-10a | M |
| fix-10c | Chapter JSON 스키마에 `simulatorContent.codeSnippets: List<{language, code, description}>` 추가 + content_builder 가 MD 의 코드 펜스를 해당 필드로 수집. freezed 모델 확장 + build_runner | fix-10a | M |
| fix-10d | 시뮬레이터 UI 에 **코드 스니펫 팝업/보조 패널** — CodeStep / StructureAssembly 등 기존 인터랙션 위에 "코드 보기" 토글 버튼 → 다이얼로그 또는 side panel 로 codeSnippets 표시 | fix-10c | M |
| fix-10e | docs-source submodule 최신 revision 으로 update + 전체 재빌드 + 5 카테고리 배포 검증 | fix-10a~d | S |

**검증 포인트**:

- 이론 탭 진입 시 `<pre>`, `<code>`, 다이어그램, 표 블록 0개 (prose 만).
- 시뮬레이터 탭에 codeSnippets 표시 UI (팝업 또는 side panel) 존재.
- **시뮬레이터 인터랙션 회귀 0** — CodeStep 재생, StructureAssembly 드래그 등 기존 동작 유지.
- content/books/<cat>/book.json 의 모든 chapter.theory.sections[].blocks type 이 "prose" 로만 채워짐.

**리스크 & 완화**:

- prose 만 남기면 학습 가치 급감 우려 → placeholder 링크 + 향후 prose 재작성 백로그 관리.
- 시뮬레이터 인터랙션은 **반드시 유지**. 코드는 부가 참고 요소로만 편입.

---

### 3.3 검증 프로토콜 재확인 (각 PR 후)

- [ ] `flutter test` 로컬 green
- [ ] `flutter analyze lib/` No issues
- [ ] PR CI (test + integration) green
- [ ] 머지 후 `gh run list` Sync & Deploy success
- [ ] `curl -sI` 로 프로덕션 Last-Modified 갱신 확인
- [ ] 변경 관련 자산(예: JSON, 폰트) 200 OK 응답 검증
- [ ] **내가 gstack-browse 로 최소 접근 가능 여부 확인 (인프라 레벨)**
- [ ] 사용자에게 3~5개 구체 체크포인트 전달 + 스크린샷 요청

---

## 4. 사용자 승인 사항 (2026-04-19 확정)

사용자 응답으로 확정된 결정:

1. **책장 UX (§2.1)** — 분관 내 모든 책의 챕터를 **flat 병합하되 얇은 divider 로 책 구분은 유지**. `📖 헤더` 는 제거하지만 책과 책 사이에 1px gold alpha divider 삽입.
2. **NPC ❓ 질문 탭 (§2.2)** — **상시 노출**. `activeNpcId` 가 null 이어도 탭바는 항상 표시. 탭 본문은 npcId null 분기에서 적절한 placeholder 메시지.
3. **책 제목 이모지 (§2.3)** — **📖 제거**. 양 경로 모두 text-only 로 통일.
4. **착수 순서** — **fix-5 (NPC) → fix-6 (책장) → fix-7 (이모지) → fix-8 (ASCII 재확인)**. ASCII 는 fix-4b 본 이주 전에 현 fix-4a 효과 실측 선행.

---

## 5. R2 ASCII 박스 에스컬레이션 결정 조건 (2026-04-19 확정)

### 5.1 현재 상태 (fix-4c 실측)

헤드 Chrome `gstack-browse connect` 로 MSA `msa-roadmap` "문서 구성 원칙" 박스 관찰 결과:

- ✅ 상단 `┌─...─┐` / 하단 `└─...─┘` / 좌/우 `│` **테두리 복구**.
- ❌ 내부 `│` 세로 구분자 컬럼 정렬 **여전히 깨짐**. 한글 글리프가 JetBrainsMono 에 없어 시스템 CJK 폰트(Malgun Gothic 등)로 fallback 되며 advance metric 이 `cellWidth × 2` 와 불일치 → 중앙 정렬 오프셋 누적.

### 5.2 사용자 지시 (2026-04-19 원문)

> "4b로 진입하여 작업하고 다시 확인하되 그래도 완전히 수정이 반영되지 않을시 이론파트에서 ascii를 사용하는 부분 또는 이를 변환한 부분을모두 문서에서 제거"

### 5.3 에스컬레이션 단계

1. **1차 (완료)**: fix-4a JetBrainsMono 번들 — 테두리 일부 복구.
2. **2차 (완료)**: fix-4c CustomPaint 그리드 드로잉 — 테두리 완전 복구, 내부 컬럼 미해결.
3. **3차 (대기, 사용자 승인 필요)**: fix-4-escalation — `tools/content_builder.dart` `_extractBlocks` 에서 `type == 'asciiDiagram'` / `type == 'raw'` 블록 emit 금지. 이론 탭에서 ASCII 박스 영역 자체가 사라짐 (5 카테고리 합계 527 + 20 = 547 블록 제거). Mermaid 파서 경로(flowchart/sequence/mindmap/table) 는 영향 없음.

### 5.4 결정 게이트

- fix-9 배포 후 R6 해결 확인 → 사용자에게 "R2 잔여 컬럼 정렬 문제로 fix-4-escalation 진행할지" 명시적 승인 요청.
- 승인 시에만 `_extractBlocks` 수정 + CI + 배포.
- docs-source 원본 markdown 은 **건드리지 않음** — 언제든 revert 가능.

### 5.5 R7 (§1.8) 과의 관계

R7 의 fix-10a 가 이론 섹션의 asciiDiagram / raw / flowchart / sequence / mindmap / table 블록까지 전부 strip 하므로, **fix-4-escalation 과 동일 효과를 더 넓은 범위에서 달성**한다. 따라서:

- fix-9 완료 → R7(fix-10) 진입 선택 시 fix-4-escalation 은 **중복 → skip**.
- R7 보류 상태에서는 fix-4-escalation 만 별도로 갈지도 유효한 선택지.
- R7 를 진행하기로 확정된 이후에는 fix-4-escalation 대기 항목 제거.

---

## 6. 참조

- `docs/handoffs/2026-04-18-session-handoff.md` — 직전 세션 핸드오프
- `docs/phases/2026-04-18-phase-plan.md` — P0 단계 정의
- `docs/designs/2026-04-19-ascii-to-widget-migration-design.md` — ASCII 이주 세부 설계
- `docs/workflows/2026-04-18-troubleshooting-journal.md` — 기존 결함/해결 축적
- `CLAUDE.md` — 프로젝트 전체 규칙
