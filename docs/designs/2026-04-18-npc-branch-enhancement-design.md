# DOL — 분관별 NPC 기능 보강 설계 (P0-5)

> Phase 1 설계 `docs/phases/2026-04-17-dev-quest-library-design.md` §3~§5 구조를 전제로 한
> NPC·책장·퀘스트 3축 보강. 핵심은 **Claude API 기반 NPC Q&A** 도입.

- **작성일**: 2026-04-18
- **상태**: DRAFT (승인 대기)
- **Phase**: P0-5 (개인 사용용 완성 단계의 잔여 태스크)
- **전제 문서**:
  - `docs/phases/2026-04-17-dev-quest-library-design.md` §3 세계관·씬, §5 NPC 설계
  - `docs/phases/2026-04-18-roadmap-pivot-personal-first.md` (현 단계 P0)
  - `docs/phases/2026-04-18-phase-plan.md` §1.3 P0-5

---

## 1. 현재 상태 (2026-04-18 코드 기준)

실제 코드를 확인한 결과:

### 1.1 분관 · NPC · 카테고리 매핑

`lib/game/scenes/wing_scene.dart`의 `_wingNpcConfig`:

| wingId | npcId | npcName | categories (현재) |
|---|---|---|---|
| `backend` | `wizard` | 아르카누스 | `['java']` ← **버그: 실제 book.json 카테고리 ID는 `java-spring`** |
| `frontend` | `mechanic` | 코그윈 | `['dart', 'flutter']` ✓ |
| `database` | `alchemist` | 메르쿠리아 | `['mysql']` ✓ |
| `architecture` | `architect` | 모뉴멘타 | `['msa']` ✓ |

분관별로 각 category마다 별도 `BookshelfComponent`가 생성됨. 이미 **분관 단위로 카테고리는 격리됨** — Phase 1 설계와 일치.

### 1.2 "모든 언어가 한 책장에" 증상의 진짜 원인

`lib/presentation/screens/game_screen.dart:37`:

```dart
..onShelfTappedCallback = (_, _) {
  ref.read(questBoardOpenProvider.notifier).open();
};
```

**책장 클릭 시 `shelfId`·`category` 인자를 무시하고** 퀘스트 보드를 연다. `QuestBoardOverlay`는 모든 책·챕터를 통합 노출 → 사용자가 "모든 언어가 섞여 보임"으로 인식. 게임 배치는 괜찮지만 클릭 후 UX가 잘못됨.

### 1.3 NPC 대화

`_placeholderTreeFor(npcId)`가 NPC별 공통 텍스트만 반환 (대사 "아직 퀘스트가 없다..."). Task 7이 "대화 시스템 골격"만 구현하고 **실 콘텐츠/Q&A는 P0-5에서 완성** 예정이었던 상태.

### 1.4 퀘스트

`quest_board_overlay.dart`가 존재하지만 모든 카테고리 챕터를 혼재 노출. 분관 필터 없음.

---

## 2. 목표

### G1 — 책장 카테고리 필터링 (최저 비용 · 최고 명확성)

책장 클릭 시 **그 shelf의 category**에 해당하는 book의 챕터 목록만 노출. 다른 카테고리는 노출 X.

### G2 — NPC 프로필 확장 + 담당 카테고리 표출

각 NPC의 "담당" 카테고리를 데이터 모델에 정착. 대화 UI에서 "이 NPC는 Java/Spring 전문가" 같은 정체성 부여.

### G3 — Claude API 기반 NPC Q&A

NPC 대화 오버레이에 "질문하기" 입력 필드 추가. 담당 카테고리 콘텐츠 범위 안에서 Claude API가 답변 생성. 프롬프트 캐싱 + RAG-lite(카테고리 book.json의 관련 섹션만 컨텍스트에 주입)로 비용 제어.

### G4 — 분관 퀘스트 정리

퀘스트가 발생 분관의 담당 카테고리 챕터를 요구하도록 구성. 학습 진도(`PlayerProgress.completedChapters`)와 연동해 완료 판정.

---

## 3. 비목표 (P0-5 범위 밖)

- NPC 스프라이트 아트 교체 (Phase 2 이후 이미 합의된 Approach B 시각 투자 시점에 재검토).
- 서버 측 API 키 보관 / 백엔드 프록시 — 개인 P0 단계엔 local-only 수용.
- Claude API 대체 엔진 (OpenAI 등) — 단일 공급자 가정.
- 음성 입력 / 멀티모달 질문.
- 다른 NPC 간 대화, NPC 간 이동.

---

## 4. 접근법 비교

### Approach A — 최소 MVP (카테고리 필터 + 정적 대사만)

- G1, G2, G4만 구현. G3(Claude API)는 제외.
- 장점: 작업 1~2주, 외부 의존 없음.
- 단점: "마크다운 대비 차별화" 핵심인 대화 학습이 빠짐.

### Approach B — 단계별 (권장)

Phase 순으로 PR 분할:

1. **G1 책장 필터** (1~2 PR, 독립적)
2. **G2 NPC 프로필 확장** (1 PR, 데이터 모델)
3. **G3-a Claude API 통합 레이어** (1 PR, 서비스 계층)
4. **G3-b NPC Q&A UI** (1~2 PR, 대화 오버레이 확장)
5. **G4 퀘스트 시스템 보강** (1~2 PR)

각 단계별로 배포·실사용 가능. 실측 기반으로 다음 단계 조정.

### Approach C — Claude API 먼저 (뒤집기)

G3를 먼저 구현 → NPC 외 어디든 "아무나에게 질문" 기능을 먼저 배포 → 분관 구조 개선은 나중. 장점: 즉각적 학습 효과. 단점: 분관 세계관 강화가 뒤로 밀림.

### 추천: **Approach B**

근거:
1. G1(책장 필터)은 실제로 10~20 라인 수정으로 끝남 — 즉시 잠금 해제.
2. G2(NpcModel 확장)는 G3·G4 전제 데이터. 선행 필요.
3. G3는 외부 API + 비용 · 보안 설계 선행 필수. 독립 PR로 분리해 위험 격리.
4. 단계별 검증 루프가 다이어그램 이주 경험(PR #35~#43)과 동일 패턴.

---

## 5. 데이터 모델 변경 (G2)

### 5.1 `NpcModel` 확장

`lib/data/models/npc_model.dart`:

```dart
@freezed
abstract class NpcModel with _$NpcModel {
  const factory NpcModel({
    required String id,
    required String name,
    required String role,
    required String spriteAsset,
    required List<Quest> quests,
    // P0-5 신규:
    @Default([]) List<String> expertiseCategories,  // ['java-spring'] 등
    @Default('') String personaPromptKey,           // 'wizard_backend' 등
  }) = _NpcModel;
  ...
}
```

`personaPromptKey`는 `AssetNpcPrompts`(상수 테이블, 아래)에서 실 system prompt를 참조하는 lookup key. JSON에 전체 프롬프트를 내리면 유지보수 난이도가 상승.

### 5.2 `wing_scene.dart`의 `_wingNpcConfig` 교정

- `backend.categories`: `['java']` → `['java-spring']`
- 함께 기존 `NpcModel.expertiseCategories`, `personaPromptKey`도 지정.

### 5.3 NPC 프롬프트 상수 테이블

`lib/services/npc_personas.dart` (신규):

```dart
const Map<String, String> kNpcSystemPrompts = {
  'wizard_backend': '너는 "아르카누스" — 백엔드 분관의 마법사 사서이다. '
      'Java / Spring Framework 심화를 가르치며, 세계관은 증기와 마법이 ...',
  'mechanic_frontend': '너는 "코그윈" — ...',
  'alchemist_database': ...,
  'architect_architecture': ...,
};
```

각 프롬프트는 **역할 고정 + 담당 카테고리 + 응답 톤(스팀펑크 세계관) + 제한사항(해당 분야 외 질문은 안내 후 사양)** 포함.

---

## 6. 책장 필터링 (G1)

### 6.1 현 구조 재활용

`onShelfTappedCallback(shelfId, category)` 인자가 이미 넘어오고 있음. `game_screen.dart`에서 이를 **버려** 버리는 것이 문제.

### 6.2 수정안

`questBoardOpenProvider`를 `QuestBoardState` (열림 여부 + 필터 카테고리)로 확장 또는 `QuestBoardOverlay`에 `filterCategory` prop 추가.

```dart
..onShelfTappedCallback = (shelfId, category) {
  ref.read(questBoardOpenProvider.notifier).openForCategory(category);
};
```

`QuestBoardOverlay`:

```dart
QuestBoardOverlay(
  filterCategory: state.filterCategory,  // null이면 전체
  onClose: ...,
  onChapterSelected: ...,
)
```

위젯 내부에서 `allBooksProvider.where((b) => b.category == filterCategory)`로 노출 범위 제한.

### 6.3 "중앙 홀" 또는 "NPC에서 연 퀘스트 보드"는 전체 노출 유지

분관 외부에서 접근 시 filter를 null로 두어 기존 동작 보존.

### 6.4 예외: `frontend` 분관

categories가 `['dart', 'flutter']` 두 개. shelfId 단위로 filter가 category 단일이므로 자연스럽게 별도 shelf로 분리됨. 문제 없음.

---

## 7. Claude API 통합 (G3-a)

### 7.1 의존성 선택

| 옵션 | 장점 | 단점 |
|---|---|---|
| `anthropic_sdk_dart` 공식 여부 확인 필요 | 공식이면 최선 | 2026-04 현재 Flutter-friendly 공식 SDK 존재 미확인 |
| `dio` + 수동 REST | 즉시 가능, 의존성 최소 | API 변경 추적 부담 |
| `http` + 수동 | 더 가벼움 | 같음 |

**권장**: 우선 `dio`(이미 PR #10 GistService에서 의존)로 구현. 공식 SDK가 안정화되면 교체.

### 7.2 파일 구조

```
lib/services/claude_api_service.dart     ← API 래퍼 (서비스 계층)
lib/services/npc_personas.dart           ← NPC 시스템 프롬프트 상수
lib/data/models/qa_message.dart          ← QA 메시지 freezed 모델 (user / assistant / system)
lib/domain/providers/
  ├─ claude_api_providers.dart           ← Riverpod (keepAlive)
  └─ npc_qa_providers.dart               ← NPC별 질문 상태 (히스토리, 로딩, 에러)
```

### 7.3 `ClaudeApiService` 스켈레톤

```dart
class ClaudeApiService {
  final Dio _dio;
  final String _apiKeyHiveKey = 'claude_api_key';

  ClaudeApiService({Dio? dio}) : _dio = dio ?? Dio();

  Future<String?> _loadApiKey() async {
    if (!Hive.isBoxOpen('auth')) await Hive.openBox<String>('auth');
    return Hive.box<String>('auth').get(_apiKeyHiveKey);
  }

  Future<Stream<String>> askStream({
    required String systemPrompt,
    required List<QaMessage> history,
    required String userQuestion,
    String model = 'claude-haiku-4-5-20251001',
    List<ContextChunk> ragChunks = const [],
  }) async {
    // 1) prompt caching: system prompt + ragChunks 를 cache_control 블록으로
    //    표시 → 동일 NPC 반복 질문 시 비용 대폭 절감.
    // 2) streaming 모드로 응답 받아 UI에 타이핑 효과.
    // 3) 실패 시 FallbackException throw → UI에서 세계관 메시지로 치환.
    ...
  }
}
```

### 7.4 API 키 보관

**P0 단계 (개인)**:
- `/debug/telemetry`와 유사한 방식으로 `/debug/settings` 화면 신설 (또는 기존 login/settings 화면 재활용).
- 사용자 수동 입력 → Hive `Box<String>('auth')` 저장 (암호화 없이 평문, 개인용 로컬 제한).
- 보안 주의: 배포되는 정적 자산에는 키를 포함시키지 않는다.

**P2 이후**: 서버 프록시로 이관, 이 문서에서 확정하지 않음.

### 7.5 RAG-lite: 카테고리 Book 컨텍스트 주입

질문 → 해당 NPC의 `expertiseCategories`의 book.json에서 **키워드 관련 섹션**을 뽑아 system 메시지에 덧붙인다.

1. 질문에서 한국어·영어 명사 토큰화 (간단 regex).
2. 카테고리 book.json 각 섹션의 `content`와 토큰 overlap 계산 (단순 substring count).
3. 상위 3~5개 섹션을 최대 N tokens (모델 context window의 20% 이하)으로 clipping.
4. Claude 프롬프트 캐싱 블록에 넣어 카테고리 1회 빌드 후 재활용.

정교한 벡터 임베딩은 **P2 팀 버전**에서 고려.

### 7.6 모델 선택 전략

- 기본: `claude-haiku-4-5-20251001` (비용·지연 최적).
- 사용자 옵션: `/debug/settings`에서 `claude-sonnet-4-6` 토글 (심화 답변 필요 시).
- Opus 사용 보류 (개인용 비용 이슈).

### 7.7 Fallback

API 실패 상황별 사용자 메시지 (세계관 유지):
- 키 미설정: "도서관의 외부 통신선이 연결되어 있지 않다. /debug/settings 에서 주문서를 등록하라."
- 네트워크 실패: "마법 회선이 불안정하다. 잠시 후 다시 시도하라."
- rate limit: "오늘 이 마법사의 힘이 한계에 달했다. 내일 다시 오라."
- 파싱 실패: "이 마법사의 답변이 흐릿하다. 질문을 다시 해보라."

---

## 8. NPC Q&A UI (G3-b)

### 8.1 기존 대화 오버레이 재활용

`DialogueOverlay`에 탭 두 개:
- **대화** (기존 `DialogueTree` 스크립트)
- **질문** (새 Q&A 모드)

### 8.2 Q&A 모드 UI 구조

```
┌──────────────────────────────────────┐
│ [대화] [질문]   ← 탭                 │
├──────────────────────────────────────┤
│ 아르카누스                            │
│  "백엔드의 수수께끼를 풀고자 한다면..." │
│                                      │
│ 사용자                                │
│  "Spring의 의존성 주입은 어떻게 ..."  │
│                                      │
│ 아르카누스                            │
│  "... (Claude 답변, 스트리밍 텍스트)" │
│ ─────                                 │
│ [입력창                         ] [전송] │
└──────────────────────────────────────┘
```

### 8.3 상태 관리

`npc_qa_providers.dart`:

```dart
@riverpod
class NpcQaSession extends _$NpcQaSession {
  @override
  NpcQaState build(String npcId) => NpcQaState(messages: [], loading: false);

  Future<void> ask(String question) async { ... }
  void clear() { ... }
}
```

세션은 NPC별 `AutoDispose` (분관 이탈 시 정리). 계측 이벤트(`/debug/telemetry`)에도 질문 1건 + 답변 토큰수 기록.

### 8.4 Streaming 렌더

Dart stream + Rive-style 타이핑 효과. UX 개선 요소.

---

## 9. 퀘스트 보강 (G4)

### 9.1 분관별 퀘스트 템플릿

- NPC가 `expertiseCategories`의 특정 챕터를 요구.
- 예: 백엔드 분관 아르카누스 → "Spring Bean Lifecycle 챕터 완료" 퀘스트.
- 퀘스트 완료 판정: `PlayerProgress.completedChapters` 교집합.

### 9.2 `QuestModel` 확장 (선택)

```dart
@freezed
abstract class Quest with _$Quest {
  const factory Quest({
    required String id,
    required String title,
    required String description,
    required String chapterId,       // 기존
    @Default('') String wingId,      // 신규 — 분관 필터링
    @Default([]) List<String> relatedCategories,  // 복수 카테고리 허용
  }) = _Quest;
  ...
}
```

### 9.3 QuestBoardOverlay 분관 필터 (G1에서 이미 처리)

`filterCategory` prop이 category 기반. quest의 `relatedCategories`와 교차 필터.

---

## 10. 테스트 전략

| 영역 | 테스트 | 수 | 비고 |
|---|---|---|---|
| 책장 필터 (G1) | Widget test: `QuestBoardOverlay(filterCategory: 'mysql')` 렌더 시 msa/java 챕터 숨김 | 3 | mock allBooks |
| NPC 모델 (G2) | `NpcModel.fromJson` 신규 필드 round-trip | 2 | freezed |
| Claude 서비스 (G3-a) | fake `Dio` interceptor로 request 검증 + fallback 케이스 | 5 | HttpMockAdapter |
| Q&A UI (G3-b) | 탭 전환, 질문 입력, 답변 누적 표시 | 4 | riverpod override |
| 퀘스트 확장 (G4) | 기존 regression + 새 필드 | 2 | |
| integration | "분관 진입 → NPC 클릭 → 질문하기 → 답변 수신"(mock API) | 1 | 기존 ChromeDriver |

---

## 11. 롤아웃 (PR 분할)

| # | 범위 | 난이도 | 의존 |
|---|---|---|---|
| PR NPC-1 | 책장 필터 (G1) + `java` → `java-spring` 카테고리 ID 교정 | S | 없음 |
| PR NPC-2 | `NpcModel` / `Quest` 필드 확장 + `npc_personas.dart` 상수 | S | PR NPC-1 |
| PR NPC-3 | `ClaudeApiService` + `QaMessage` 모델 + `/debug/settings` API 키 관리 | M | PR NPC-2 |
| PR NPC-4 | NPC Q&A UI (`DialogueOverlay` 탭 추가) + 스트리밍 | M | PR NPC-3 |
| PR NPC-5 | RAG-lite (카테고리 book.json 섹션 상위 추출 + 프롬프트 주입) | M | PR NPC-3/4 |
| PR NPC-6 | 분관별 퀘스트 샘플 + 완료 판정 | S | PR NPC-2 |
| PR NPC-7 | develop → master 릴리즈 | XS | 위 전체 |

---

## 12. 위험 & 대응

- **API 비용 폭주**: 세션당 N개, 카테고리 캐시, 경고 배너.
- **부정확 답변**: system prompt에 "확신 없음은 명시" + "공식 문서 링크 유도" 지시.
- **API 키 유출**: Hive 평문 저장은 개인 P0 한정. 배포 자산에 포함 금지 (env 사용 금지).
- **레이턴시**: Haiku 기본 + streaming으로 체감 완화. Opus 사용 시 경고.
- **세계관 이탈**: 답변이 "AI 어시스턴트"처럼 나오지 않게 persona prompt + 피드백 fine-tune (prompt-only).

---

## 13. 성공 기준

1. 분관 A 책장 클릭 시 A 카테고리 챕터만 노출.
2. NPC 대화에 "질문" 탭이 나타나고, 입력 → 1초 이내 첫 토큰 수신 시작.
3. 질문 10회 반복 테스트: 답변이 담당 카테고리 범위를 일관적으로 유지 (5% 미만 이탈).
4. fallback 메시지가 세계관 톤 유지.
5. 기존 테스트 회귀 없음. 신규 테스트 모두 녹색.
6. 배포 후 `/debug/telemetry`에 QA 이벤트가 축적됨.

---

## 14. 참조

- Phase 1 설계: `docs/phases/2026-04-17-dev-quest-library-design.md` §3 씬, §5 NPC
- Phase 계획: `docs/phases/2026-04-18-phase-plan.md` §1.3 P0-5
- 로드맵 피벗: `docs/phases/2026-04-18-roadmap-pivot-personal-first.md`
- 트러블슈팅: `docs/workflows/2026-04-18-troubleshooting-journal.md` (Claude API 관련 항목 추가 예정)
- Task 워크플로: `docs/workflows/2026-04-18-task-workflow.md`
