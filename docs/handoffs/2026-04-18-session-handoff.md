# DOL — 세션 핸드오프 (2026-04-18)

> 이 세션에서 끝낸 일과 다음 세션에서 이어갈 일을 한 문서에 정리.
> 다음 세션 진입 시 이 문서 먼저 읽고, `work-history.md` / `phase-plan.md` 순으로 맥락 확장.

- **작성일**: 2026-04-18
- **작성 시점 커밋**: master `a71cfbb` (PR #54 릴리즈), develop는 동일 tip
- **현재 단계**: P0 (개인 사용용 전체 기능 완성) — P0-5 완료, P0-1 검토 대기

---

## 1. 이 세션에서 완료한 것

### 1.1 P0-5 분관별 NPC 기능 보강 (PR #46 ~ #53)

| PR | 태그 | 요약 |
|---|---|---|
| #46 | docs | Phase 계획 / Task 워크플로 / 작업 이력 3종 문서 신설 + P0-5 NPC Task |
| #47 | docs | P0-5 NPC 분관 보강 설계 문서 |
| #48 | npc-1 | 책장 카테고리 필터링 + `java` → `java-spring` ID 교정 |
| #49 | npc-2 | `NpcModel.expertiseCategories` + `Quest.wingId/relatedCategories` + `NpcPersonas` 상수 |
| #50 | npc-3 | `ClaudeApiService` (SSE 스트리밍 + Hive 키 저장) + `/debug/settings` |
| #51 | npc-4 | DialogueOverlay 💬 대화 / ❓ 질문 탭 + `NpcQaSession` 스트리밍 |
| #52 | npc-5 | RAG-lite — category book.json 섹션 overlap 상위 N청크 system 주입 |
| #53 | npc-6 | 분관별 샘플 퀘스트 + `wingQuestsProvider` + QuestBoard 상단 섹션 |

### 1.2 릴리즈

- **PR #54** (develop → master): P0-5 전체 + 누적 diagram/phase 2 포함 master 승격. `a71cfbb` 머지, Sync & Deploy 자동 실행.
- 프로덕션: `https://public-project-area-oragans.github.io/dol/`

### 1.3 의존성 추가

- `dio ^5.9.2` — Claude Messages API 호출 (SSE 스트리밍 대응).
- 기존 `hive ^2.2.3` / `hive_flutter` — API 키 (`Box<String>('auth')`) + 텔레메트리 (`Box<String>('telemetry')`).

### 1.4 새 파일 경로 요약

**lib/**
- `lib/services/claude_api_service.dart` — Messages API + 예외 타입 5종.
- `lib/services/npc_personas.dart` — 4 NPC system prompt + 카테고리 매핑.
- `lib/services/category_context_service.dart` — RAG-lite (NPC-5).
- `lib/services/wing_quests.dart` — 4 wing 샘플 퀘스트 (NPC-6).
- `lib/data/models/qa_message.dart` — freezed QaMessage + QaRole.
- `lib/domain/providers/claude_api_providers.dart` — API 키 provider.
- `lib/domain/providers/npc_qa_providers.dart` — ActiveNpcId + NpcQaSession (family by npcId).
- `lib/domain/providers/category_context_providers.dart` — RAG provider.
- `lib/domain/providers/wing_quests_providers.dart` — progress 기반 상태 재계산.
- `lib/presentation/screens/debug_settings_screen.dart` — Claude 키 등록 UI.

**docs/**
- `docs/designs/2026-04-18-npc-branch-enhancement-design.md` — P0-5 설계.
- `docs/handoffs/2026-04-18-session-handoff.md` — (본 문서).

---

## 2. 현재 상태 스냅샷

### 2.1 브랜치

- `master`: `a71cfbb` (PR #54 머지 후 릴리즈 상태).
- `develop`: master와 동일 tip (release PR은 merge commit).
- 진행 중 브랜치: 없음 (본 핸드오프 문서 작업 제외).

### 2.2 검증 상태

- `flutter analyze lib/` — 0 issues.
- 단위 테스트 — 모든 NPC-3/4/5/6 추가 테스트 포함 green.
- integration CI — strict 머지 차단 조건 (PR #44 이후).

### 2.3 P0 잔여 (phase-plan.md §1.3 기준)

| Task | 상태 | 비고 |
|---|---|---|
| P0-1 타 카테고리 시뮬레이터 타입 설계 | ⏸ 대기 | **당위성 재검토 필요** — 단순 이론 탭+마크다운으로 충분한지 판단 |
| P0-2 flowchart residual 7건 | ⏸ 저 ROI | 잔여 raw 20건 중 일부 |
| P0-3 도메인 특화 diagram | ⏸ 보류 | gantt/er/state… 개별 위젯 비용 vs Raw 폴백 |
| P0-4 실사용 결함 backlog | ⏸ 상시 | 발견 시 GitHub Issues 또는 backlog 적재 |
| **P0-5 NPC 보강** | ✅ 완료 | 본 세션 |

---

## 3. 다음 세션에서 이어갈 일 (우선순위)

### 3.1 가장 먼저 — 프로덕션 검증 (머지 직후 당일 내)

배포 완료(약 3분 후) → `https://public-project-area-oragans.github.io/dol/` 접속하여:

1. **분관 책장 카테고리 필터링**
   - 백엔드 분관 책장 → `java-spring`만 노출
   - 프론트엔드 분관 책장 → `dart` / `flutter` 2개만 노출
   - DB 분관 → `mysql`만
   - 아키텍처 분관 → `msa`만
2. **NPC Q&A (Claude API 필요)**
   - `/debug/settings` 진입 → `sk-ant-*` 키 등록 (개인 Claude 콘솔에서 발급)
   - NPC 클릭 → 대화 오버레이 열림 → "❓ 질문" 탭 전환
   - 담당 분야 질문 입력 → 스트리밍 답변 (문자 단위 누적)
   - 담당 외 질문 → "해당 분관 NPC에게…" 안내 응답
3. **QuestBoard "이번 분관 퀘스트" 섹션**
   - 분관 입장 → 책장 탭 → 보드 상단에 Quest 카드 1개 노출
   - 필요 챕터 학습 완료 후 보드 재진입 → 카드 경계색 steamGreen + 완료 아이콘
4. **다이어그램/표**
   - MSA 카테고리 이론 탭에서 flowchart/sequence/table 렌더 정상
5. **회귀 확인**
   - 중앙 홀 → 분관 이동 → 복귀 정상
   - HUD XP/진행률 표시 정상

발견한 결함은 `docs/workflows/2026-04-18-troubleshooting-journal.md`에 증상+해결 축적 후 수정 PR.

### 3.2 선택 — P0-1 카테고리별 시뮬레이터 당위성 판단

- **지금 설계하지 말 것**: 검토부터.
- 실제 학습 경험에서 "MSA만 시뮬레이터, 타 카테고리는 읽기만"인 상태가 충분한가?
- 프론트엔드 Flutter 카테고리는 특히 후보 (Widget 트리 조립 가능)
- 판단 후 P0-1 착수하거나 Skip 결정.

### 3.3 선택 — 계측 기반 개선

- `/debug/telemetry`의 실제 사용 데이터 검토 (NPC-3 이후 claude_api_request 이벤트 포함 여부 확인)
- NPC Q&A 실제 질문 로그 축적 여부 결정 → 프라이버시 정책 필요

### 3.4 P0 종료 판정 → P1 전환 준비

`phase-plan.md §1.4` 기준:
- 결함 빈도 주 1건 이하 수렴
- 5 카테고리 책 열람 정상 (이미 충족)
- MSA 2챕터 시뮬레이터 + 대조군 유지
- 본인 정성 평가 "일상 학습에 쓰고 싶다"

P1은 4주 실사용 축적 단계 — 별도 설계 없음, 사용하며 backlog 누적.

---

## 4. 설계 의사결정 누락 없이 재확인할 포인트 (다음 세션 참고)

### 4.1 Claude API 키 보관

- 현재 평문 Hive 저장 (P0 개인 사용 한정).
- P2 팀 버전 시 **서버 프록시** 필수 재검토 — 설계 문서에 이미 기술됨.

### 4.2 RAG-lite 한계

- 토큰 overlap은 한국어 조사/영문 stemming 무시.
- 증상: "스프링 빈 생애주기"와 "Bean lifecycle" 매칭 실패 가능.
- 대안 후보: 임베딩 기반(sentence-transformers REST) — P1/P2 단계에서 사용 데이터 보고 결정.

### 4.3 NPC 퀘스트 규모

- 현재 분관당 1개. 확장 시 JSON 자산 외부화 (`content/quests/<wing>.json`) 고려.
- P0 단계는 코드 상수로 유지.

### 4.4 프롬프트 캐싱 히트율

- `cache_control: ephemeral` × system 블록 (persona + context chunks).
- 동일 카테고리 연속 질문 시 5분 TTL 내 재사용.
- 실측 방법: Claude 콘솔 대시보드 또는 응답 헤더의 `cache_read_input_tokens`.
- 후속 개선: RAG chunk 정렬 고정해 캐시 파편화 방지 (이미 구현됨 — category_context_service는 deterministic).

---

## 5. 참조 (빠른 재진입)

- **현재 상태**: `docs/workflows/2026-04-18-work-history.md` §8
- **Phase 계획**: `docs/phases/2026-04-18-phase-plan.md`
- **NPC 설계**: `docs/designs/2026-04-18-npc-branch-enhancement-design.md`
- **로드맵**: `docs/phases/2026-04-18-roadmap-pivot-personal-first.md`
- **트러블슈팅**: `docs/workflows/2026-04-18-troubleshooting-journal.md`
- **Task 워크플로**: `docs/workflows/2026-04-18-task-workflow.md`
- **CLAUDE.md**: 프로젝트 루트 — 아키텍처/생성/배포 규칙

---

## 6. 다음 세션 체크인 체크리스트

```
[ ] git checkout develop && git pull
[ ] git log --oneline master..develop (비어있어야 함 — 이 세션 종료 시 release 완료)
[ ] gh pr list --state open (오픈 PR 없어야 함)
[ ] docs/handoffs/2026-04-18-session-handoff.md 읽기
[ ] 프로덕션 URL 접속 → §3.1 체크리스트 수행
[ ] 결함 있으면 troubleshooting-journal 업데이트 + 수정 PR
[ ] 결함 없으면 P0-1 당위성 판단 or P1 실사용 전환
```
