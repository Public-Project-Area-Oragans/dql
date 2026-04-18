# DOL — Phase 계획 (P0 → P3)

> `docs/2026-04-18-roadmap-pivot-personal-first.md`에서 확정된 4단계 로드맵을
> 단계별로 세분화. 각 Phase는 **착수 조건 · 산출물 · 전환 기준 · 현재 잔여**를 명시.
> Task 세분화는 `docs/2026-04-18-task-workflow.md`의 표준 플로우를 따른다.

- **최초 작성**: 2026-04-18
- **현재 단계**: **P0 (개인 사용용 전체 기능 완성)** — 진행 중

---

## 0. 단계 개요

```
P0 개인 완성 (현재) → P1 전 언어 실사용 → P2 팀 버전 → P3 공개 버전
```

| Phase | 범위 | 예상 규모 | 현재 |
|---|---|---|---|
| P0 | 본인 일상 사용 가능한 결함 없는 완성 | 2~6주 | 진행 중 |
| P1 | 5개 카테고리 실사용 + 피드백 축적 | 4주 ± | 대기 |
| P2 | 팀/회사 버전 설계·개발 | TBD | 대기 |
| P3 | 불특정 다수 공개 버전 | TBD | 대기 |

---

## 1. P0 — 개인 사용용 전체 기능 완성

### 1.1 착수 조건

이미 착수됨 (로드맵 피벗 PR #37 머지 시점).

### 1.2 산출물 (완료)

Phase 0~3 전체 + Task 12 + Task 2-5 완료.

- 게임 셸 / NPC / 퀘스트 / 책 열람 (Phase 1)
- MSA 구조 조립 시뮬레이터 2챕터 + 대조군 (Phase 2)
- Task 12 ASCII 다이어그램 정렬 보존
- Task 2-5 계측 로그(Hive + /debug/telemetry)
- 다이어그램/표 순수 Flutter 위젯 이주 (Phase 3) — **구조화 97%**

### 1.3 P0 잔여 태스크 (우선순위 순)

#### P0-1 (작업 대기): 타 카테고리 시뮬레이터 타입 설계

현재 시뮬레이터는 **MSA 2챕터**에만 적용. 다른 4개 카테고리(java-spring / dart / flutter / mysql)는 `CodeStepConfig(steps=[])` 폴백으로 이론 탭만 활성.

**필요한 설계**:
- **java-spring**: Bean 의존 그래프 조립? 레이어드 아키텍처 드래그 앤 드롭? 후보 논의 필요.
- **dart**: async/await 흐름 시각화? Future/Stream 상태 조립?
- **flutter**: Widget 트리 조립(Draggable + Column/Row)?
- **mysql**: SQL 실습(쿼리 입력 + 결과 검증)? ER 조립?

현행 `SimulatorConfig` sealed union에 신규 variant 추가 (`springBean`, `widgetTree`, `sqlPractice`) — freezed 3.x 패턴 따라 book_model 확장.

**결정 포인트**: 이 P0-1 진행 전 **카테고리별 시뮬레이터 당위성** 재검토 필요. 단순 이론 탭 + 마크다운만으로 충분할 수도.

#### P0-5 (2026-04-18 추가): 분관별 NPC 기능 보강

사용자 요청(2026-04-18)으로 추가. **별도 설계 문서 선행 필요** (`docs/YYYY-MM-DD-npc-branch-enhancement-design.md`).

**전제 (Phase 1 설계 §5 기준)**:
- 분관은 **4개**: 백엔드 / 프론트엔드 / DB / 아키텍처.
- 5개 카테고리 ↔ 4개 분관 매핑:
  - 백엔드 분관 → `java-spring`
  - 프론트엔드 분관 → `dart`, `flutter` (2 카테고리 묶음)
  - DB 분관 → `mysql`
  - 아키텍처 분관 → `msa`
- NPC 역할: **마법사**(백엔드), **연금술사**(DB), **기계공**(프론트), **건축가**(아키텍처).

**목표**:
1. **NPC별 담당 도메인 + Claude API 기반 Q&A**
   - 각 NPC가 담당 분관 카테고리 1~2개를 "전공" 프로필로 보유.
   - NPC 대화 오버레이에 "질문하기" 입력 → **Claude API(`claude-sonnet-4-6` 또는 `claude-haiku-4-5`)**로 답변 생성.
   - System prompt 고정: 역할 + 세계관 톤("도서관의 마법사 사서는 Spring Framework 심화 전문가" 등) + 담당 카테고리 book.json에서 관련 섹션 RAG-lite 주입 고려.
   - 프롬프트 캐싱으로 system prompt + 카테고리 색인 재활용 → 반복 질문 비용 절감.
2. **퀘스트 시스템 보강**
   - 현재 퀘스트는 Phase 1 기본 골격 + 플레이스홀더. 담당 분관 NPC가 해당 카테고리 챕터 학습을 요구하는 퀘스트 생성 → 완료 판정은 `PlayerProgress.completedChapters`와 연동.
   - 퀘스트 서사: Phase 1 설계 §5.3 "3단 구조(대화 → 학습 → 복귀 시 분기 테스트)" 재활용.
3. **분관 책장 카테고리 필터링**
   - **현재 문제**: 모든 분관 책장에 5개 카테고리 book이 혼재 노출됨 (분관 정체성 실종).
   - **목표**: 분관 ID → 해당 카테고리 리스트로 매핑. 프론트 분관만 2 카테고리, 나머지는 1 카테고리.
   - 수정 지점 후보: `lib/presentation/components/bookshelf_component.dart`, `lib/domain/providers/content_providers.dart`, `lib/data/models/library_model.dart`.

**예상 설계 항목 (NPC 설계 문서에서 확정)**:
- Claude API 통합 (`lib/services/claude_api_service.dart`): API 키 관리(local Hive 암호화 저장 후보), 프롬프트 캐싱(공통 system + per-category context), 모델 선택(비용/지연 트레이드오프), anthropic_sdk_dart 또는 dio 기반 REST.
- NPC 모델 확장: `NpcModel`에 `expertiseCategories: List<String>` + `systemPromptKey: String`.
- RAG-lite: 질문 입력 시 해당 카테고리 `book.json`에서 키워드 매칭 상위 섹션을 prompt에 포함 (전량 주입은 context 초과).
- Q&A UI: Phase 1 `dialogue_overlay`를 확장해 입력 필드 + "질문" 버튼 + 답변 카드 (스트리밍 응답 지원 고려).
- Fallback: API 실패 시 "현재 마법 회선이 불안정합니다" 같은 세계관 유지 메시지 + 재시도.
- 테스트: Claude API 레이어는 fake/mock (네트워크 격리), 책장 필터는 위젯 테스트, Q&A 흐름은 integration_test.

**선행 결정 필요**:
- **API 키 보관**: 개인 P0 단계 → local Hive 암호화 저장 허용. P2/팀에선 서버 프록시 재검토.
- **요청 비용 제어**: 질문당 토큰 한도 + rate limit (세션당 N회, 카테고리별 캐시).
- **콘텐츠 범위**: NPC 답변이 담당 카테고리 외로 벗어나지 않도록 system prompt 가드 ("다른 분야 질문은 해당 분관으로 안내").

**ROI 판단**: 높음. 개인 학습 도구로서 "즉석 질문 가능" 기능은 마크다운 대비 차별화의 핵심. Phase 1~3의 "읽기 중심"에서 "대화 중심"으로 전환 가능.

**후속 플로우**:
1. NPC enhancement 설계 문서 작성 (선행).
2. 책장 필터링 기능 선행 PR (단독 작업 가능).
3. Claude API 통합 레이어 PR.
4. NPC 프로필 확장 + Q&A UI PR.
5. 퀘스트 시스템 보강 PR.
6. develop → master 릴리즈.

#### P0-2 (수량화 가능): flowchart residual 7건 분석

잔여 raw 20건 중 flowchart-residual 7건 샘플 분석 → 필요 시 파서 추가 보강. ROI 낮음(7건), 후순위.

#### P0-3 (옵션): 도메인 특화 diagram 최소 지원

- `gantt` (4건): 시간축 간트차트 → 수평 막대 그래프 Flutter 위젯.
- `stateDiagram` (3건): 상태 다이어그램 → flowchart 위젯 재활용 가능.
- `erDiagram` / `classDiagram` / `quadrantChart` / `block-beta` (각 1): 구조 복잡, 개별 위젯 구현 부담.

**정책**: 최소 지원보다는 Raw monospace 폴백 유지가 비용 대비 합리적.

#### P0-4 (계측 기반 가드): 실사용 결함 발견 → backlog

P0 단계에서 실사용 중 발견한 결함을 `docs/backlog/` (미생성) 또는 GitHub Issues에 적재 → P0 내에서 처리.

### 1.4 P0 → P1 전환 기준

1. **결함 빈도가 주 1건 이하로 수렴** — 일상 사용이 망가지지 않는 상태.
2. 기능 기준:
   - 5개 카테고리 모두 `book_reader_screen` 진입 → 이론 탭 정상 렌더 (Phase 3 완성으로 충족).
   - MSA 2챕터 시뮬레이터 + 대조군 구조 유지.
   - (선택) 타 카테고리 시뮬레이터가 P0-1에서 결정된 경우 해당 구현 완료.
3. 정성 판정: "이 도구로 일상 학습을 해보고 싶다"는 본인 평가.

---

## 2. P1 — 전 언어 실사용 검증

### 2.1 착수 조건

P0 전환 기준 충족.

### 2.2 활동

- 5개 카테고리에서 각 N개 이상 챕터 학습 (N은 P0 종료 시 결정, 목표 10~20).
- `/debug/telemetry` + 주관 메모 축적.
- 개선 요청 / 결함 발견 시 backlog 적재 → 필요 시 **P0으로 재유입** (실사용이 새 P0 Task를 만들 수 있음).
- 기간 4주 ± (본인 학습 스케줄에 연동).

### 2.3 산출물

- 카테고리별 학습 완료 챕터 로그 (스크린샷 + 메모).
- DOL 사용 중 발견한 결함/개선 목록 (정성).
- 학습 효과 자기 평가: "마크다운/eBook 대비 체감이 있는가? 있다면 무엇이?"

### 2.4 P1 → P2 전환 기준

- 4주 누적 사용 지속.
- 자기 평가에서 "효과 있음" 또는 "중립" — **"효과 없음" 시 P2 보류 + 도메인 재검토**.
- 타인에게 소개하고 싶은 시나리오가 구체적으로 떠오름.

---

## 3. P2 — 팀/회사 버전

### 3.1 착수 조건

P1 전환 기준 충족.

### 3.2 선행 설계 (P2 진입 시 별도 문서)

**파일명 예시**: `docs/YYYY-MM-DD-team-version-design.md`

**고려 영역** (확정 아님 — 실사용 경험으로 조정):
- 멀티 유저 / 권한 / SSO
- 팀 네임스페이스 + 콘텐츠 저작 플로우
- 팀 계측 대시보드 (개인 `/debug/telemetry` → 팀 집계)
- 자가 호스팅 옵션 (GitHub Pages 대신 팀 서버)
- 백엔드 요구사항 (인증, 진행 동기화)

### 3.3 산출물 (예측)

- 팀 사용 가능한 배포 형태 (SaaS or 자가 호스팅 옵션).
- 팀 콘텐츠 저작 도구 (docs-source 대체 or 확장).
- 이해관계자 설득용 계측 리포트.

### 3.4 P2 → P3 전환 기준

- 팀 내부 사용 안정화 + 외부 수요 신호 (외부인 문의, 유사 니즈 발견).

---

## 4. P3 — 공개 버전

### 4.1 착수 조건

P2 전환 기준 충족.

### 4.2 선행 설계

**파일명 예시**: `docs/YYYY-MM-DD-public-version-design.md`

**고려 영역**:
- 인증 / 결제 / 운영 비용 / SLA
- 콘텐츠 기여 플로우 / 모더레이션
- 공개 지속가능성 모델 (오픈소스 vs SaaS vs 하이브리드)
- 성능/확장성

---

## 5. Phase 간 원칙

1. **한 단계 완성 후 다음 단계 설계** — 사전에 과도한 스펙 확정 금지.
2. **재유입 허용** — P1/P2 실사용 중 결함/요구가 P0으로 다시 올 수 있음.
3. **실측 우선** — 설계 추정보다 배포 후 실측 결과를 신뢰 (Phase 3 diagram에서 교훈).
4. **단일 문서로 단계 관리** — 현재 단계는 본 문서 최상단에 명시.

---

## 6. 참조

- 로드맵 피벗: `docs/2026-04-18-roadmap-pivot-personal-first.md`
- 작업 이력: `docs/2026-04-18-work-history.md`
- Task 워크플로: `docs/2026-04-18-task-workflow.md`
- 트러블슈팅: `docs/2026-04-18-troubleshooting-journal.md`
