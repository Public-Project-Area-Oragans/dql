# DOL — 작업 이력 (Work History)

> 2026-04-17 프로젝트 시작부터 2026-04-18 Phase 3 + 로드맵 피벗까지의 전 PR 타임라인.
> 새 이력이 추가될 때 상단 "최신" 섹션에 append 한다.

- **최초 작성**: 2026-04-18
- **대상 저장소**: `Public-Project-Area-Oragans/dol`
- **범위**: PR #1 ~ #45

---

## 1. 한눈에 보기

| Phase | 기간 | PR 범위 | 상태 |
|---|---|---|---|
| Phase 0 (문서/스캐폴딩) | 2026-04-17 | #1 ~ #3 | ✅ 완료 |
| Phase 1 (MVP) | 2026-04-17 | #4 ~ #15 | ✅ 완료 |
| Phase 1 잔여 (Task 12) | 2026-04-18 | #25 | ✅ 완료 |
| Phase 2 (MSA 시뮬레이터) | 2026-04-18 | #17 ~ #24, #26 | ✅ 완료 |
| Phase 3 (다이어그램 위젯 이주) | 2026-04-18 | #27 ~ #32, #35, #38, #40, #42 ~ #45 | ✅ 구조화 97% 달성 |
| 로드맵 재정립 | 2026-04-18 | #37 | ✅ 완료 |

**배포 릴리즈 (develop → master)**: #33, #36, #39, #41, #45 (총 5차).

---

## 2. Phase 0 — 문서/스캐폴딩 (2026-04-17)

| PR | 내용 |
|---|---|
| #1 | chore: 프로젝트 초기 세팅 |
| #2 | feat: freezed 데이터 모델 (Book, Quest, NPC, Library, PlayerProgress) |
| #3 | docs: README.md + CLAUDE.md 프로젝트 문서 작성 |

**산출물**: 설계 문서 (`docs/2026-04-17-dev-quest-library-design.md`), 구현 계획서 (`docs/2026-04-17-dev-quest-library-plan.md`), freezed 모델 4종.

---

## 3. Phase 1 — MVP (2026-04-17)

| PR | 내용 |
|---|---|
| #4 | feat(task-03): MD → JSON 콘텐츠 빌더 + 테스트 |
| #5 | feat(task-04): Flame 게임 셸 + 씬 관리 + 중앙 홀/분관 전환 |
| #6 | feat(task-05): NPC, 책장, 정령 컴포넌트 + 분관 씬 배치 |
| #7 | feat(task-06): NPC 대화 시스템 오버레이 + 대화 분기 상태 관리 |
| #8 | feat(task-07): 퀘스트 게시판 + 혼합 퀴즈 + HUD 오버레이 |
| #9 | feat(task-08): 책 열람 화면 (이론 뷰 + 코드 스텝 시뮬레이터) |
| #10 | feat(task-09): GitHub Gist 진행 저장 + Hive 로컬 캐시 + ProgressRepository |
| #11 | ci(task-10): GitHub Actions 배포 + docs-source submodule |
| #12 | feat(task-11): 이론 카드에 flutter_markdown 적용 (품질 개선) |
| #15 | fix(ci): flutter build web에서 제거된 `--web-renderer` 플래그 삭제 |

**산출물**: Flutter Web 배포 완료 (`https://public-project-area-oragans.github.io/dol/`). 게임 셸, NPC/퀘스트/책 열람, 콘텐츠 파이프라인 완성.

---

## 4. Phase 2 — MSA 구조 조립 시뮬레이터 (2026-04-18)

| PR | 내용 |
|---|---|
| #17 | feat(task-2-0): SimulatorConfig sealed union + override JSON merge |
| #18 | feat(task-2-3): GraphValidator pure Dart + unit test 8 cases |
| #19 | feat(task-2-2): StructureAssemblySimulator UI + book_reader routing |
| #20 | feat(task-2-1): MSA 2챕터 override JSON + 대조군(step1) 설정 |
| #21 | feat(task-2-6a): CRITICAL 회귀 + override/Model unit 테스트 |
| #22 | feat(task-2-6b): StructureAssemblySimulator 인터랙션 회귀 10 케이스 |
| #23 | feat(task-2-6c): integration_test + ChromeDriver CI 스텝 |
| #24 | chore(task-2-6c): integration 잡 진단 강화 + CLI 플래그 교정 |
| #26 | feat(task-2-5): 계측 이벤트 로컬 Hive 저장 + /debug/telemetry 뷰어 |

**산출물**:
- MSA `phase4-step2-service-discovery`, `phase4-step4-resilience-patterns` 2챕터에 StructureAssemblyConfig override.
- 대조군: `phase4-step1-api-gateway` (CodeStepConfig 유지, 마크다운 원문만).
- `GraphView`(Flame 없음) + `Draggable`/`DragTarget` 기반 구조 조립 UI.
- integration_test + ChromeDriver CI (`continue-on-error: true` 초기 적용 → 후속 PR #44에서 strict 승격).
- `/debug/telemetry` 이벤트 뷰어 (Hive 기반, graceful degrade).

---

## 5. Phase 1 잔여 — Task 12 (2026-04-18)

| PR | 내용 |
|---|---|
| #25 | feat(task-12): 이론 뷰 ASCII 다이어그램 정렬 보존 (Issue #13 close) |

**산출물**: `_wrapAsciiBlocks` 자동 래핑 + Task 12 `_ScrollablePreBuilder` 가로 스크롤 monospace. Issue #13 해결.

---

## 6. Phase 3 — 다이어그램/표 순수 Flutter 위젯 이주 (2026-04-18)

### 6.1 설계 & 스켈레톤

| PR | 내용 |
|---|---|
| #27 | docs: 다이어그램 위젯 이주 설계 문서 |
| #28 | feat(diagram-1): ContentBlock sealed union + renderer 스켈레톤 |
| #29 | feat(diagram-2): GFM 표 파서 + TableBlockWidget (Flutter 내장 Table) |
| #30 | feat(diagram-3): ASCII 박스 다이어그램을 blocks 파이프라인으로 이관 |
| #31 | feat(diagram-4): Mermaid flowchart 파서 + FlowchartWidget (graphview) |
| #32 | feat(diagram-5): Mermaid sequence + mindmap 파서 + 네이티브 위젯 |

**초기 배포 후 실측**: flowchart 321 / raw 263 → 구조화 **57%**.

### 6.2 실측 주도 파서 보강 (3회 이터레이션)

| PR | 내용 | 실측 복구 | 누적 구조화 |
|---|---|---|---|
| #35 | feat(diagram-7): `:::className` 스트립 + Stadium/Cylinder + ~~~/특수 엣지/multiway | +27 | 65% |
| #38 | feat(diagram-8): flowchart 커넥터 변종 `-->>`, `==>>` 지원 | +0 (의외로 주원인 아님) | 65% |
| **#40** | **feat(diagram-9): 인용 라벨 내 `()` 보존 (근본 원인)** | **+201** | **94%** |
| #43 | feat(diagram-10): sequence 커넥터 `--x`, `-x`, `--)`, `-)` 지원 | +14 | **97%** |

**최종 MSA 블록 분포 (2026-04-18 PR #45 배포 기준)**:
- prose 1446 / table 581 / asciiDiagram 24 / flowchart 550 / sequence 71 / mindmap 31 / raw 20
- 잔여 raw 20 = 도메인 특화(gantt/er/class/stateDiagram/quadrant/block-beta) + edge case.

### 6.3 운영 문서 & CI 강화

| PR | 내용 |
|---|---|
| #34 | docs: 트러블슈팅 저널 신설 + CLAUDE.md 참조 문서 갱신 |
| #37 | docs: 로드맵 피벗 — 개인 완성 → 전 언어 실사용 → 팀 → 공개 순차 |
| #42 | docs(troubleshooting): flowchart 94% 달성 타임라인 + 교훈 추가 |
| #44 | chore(ci): integration 잡 strict 승격 — continue-on-error 제거 |

---

## 7. 배포 릴리즈 (develop → master)

| 릴리즈 PR | 포함 | master commit |
|---|---|---|
| #33 | Phase 2 + Task 12 + Phase 3 (#17~#32 전체) | `64e1337` |
| #36 | Phase 3 파서 보강 + 로드맵 피벗 (#35, #37) | `2b00c7a` (근사) |
| #39 | 커넥터 변종 (#38) | (생략) |
| #41 | 인용 라벨 괄호 보존 (#40) | (생략) |
| #45 | sequence 커넥터 + strict CI (#42, #43, #44) | (생략) |

프로덕션 URL: `https://public-project-area-oragans.github.io/dol/`

---

## 8. 현재 상태 (2026-04-18 기준)

- **테스트**: `flutter test` 136/136 pass, `flutter analyze lib/` clean.
- **CI strict**: test + integration 양쪽 머지 차단 조건.
- **구조화 성공률**: MSA mermaid 97% (630/672). 표·ASCII 100%.
- **의존성**: `graphview ^1.2.0` (Sugiyama), `markdown ^7.0.0` (direct), `integration_test` (sdk), `flutter_markdown ^0.7.6`.
- **로드맵 단계**: **P0 (개인 사용용 전체 기능 완성)**. P1/P2/P3 별도 설계.

---

## 9. 참조

- 설계: `docs/2026-04-17-dev-quest-library-design.md` / `docs/2026-04-18-dev-quest-library-phase2-design.md` / `docs/2026-04-18-diagram-widget-migration-design.md`
- 로드맵: `docs/2026-04-18-roadmap-pivot-personal-first.md`
- 트러블슈팅: `docs/2026-04-18-troubleshooting-journal.md`
- Phase 계획: `docs/2026-04-18-phase-plan.md` (본 세션에서 신설)
- Task 워크플로: `docs/2026-04-18-task-workflow.md` (본 세션에서 신설)
