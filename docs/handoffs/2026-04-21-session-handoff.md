# DOL — 세션 핸드오프 (2026-04-21)

> 2026-04-20~21 세션. art-2 실사용 피드백 대응 (art-2b) + art-3 타이틀 씬 이주 + integration test 재정합 + 8/9차 릴리즈 2연속 배포. 픽셀아트 이주 누적 14/1000 call.
> 다음 세션 진입 시 이 문서 먼저 읽고 fix-10b 잔량 24 chapter + art-4 중앙 홀 우선순위 결정.

- **작성일**: 2026-04-21
- **작성 시점 develop HEAD**: `ec3477c` (PR #114 art-3b 머지 후, master 대비 1 commit ahead)
- **현재 단계**: P0 진행 + 픽셀아트 이주 art-3 완료 (art-4 착수 대기) + R7 fix-10b 잔량 24 chapter

---

## 1. 이번 세션 완료분

### 1.1 art-2b — UI 피드백 보강 (MERGED #110, 배포 완료)

art-2 배포 후 headed Chrome 검증에서 발견된 2가지 치명 이슈 해결.

| 문제 | 해결 |
|---|---|
| 이론 탭 텍스트가 `framePanel` 9-slice 중앙 텍스처에 겹쳐 가독성 치명 | `TheoryCard` 의 `SteampunkPanel` → `_TheorySectionPanel` (평평한 darkWalnut+gold border) 폴백. R7 fix-10 시리즈 콘텐츠 정착 후 재도입 예정 |
| 버튼·분관·NPC·책장 hover/pressed 시각 구분 미흡 | **Flutter**: `SteampunkButton` 에 `ColorFiltered` ±25% + 1px Y translate. **Flame**: `TappableComponent` 믹스인에 `HoverCallbacks` 제약 + `renderTree` `saveLayer(null, tint)` ColorFilter ±30%. `npc / bookshelf / wing_door` 3 컴포넌트 with 절에 `HoverCallbacks` 추가 |

**기술 노트**: `saveLayer` bounds 를 local `(0, 0, size.x, size.y)` 로 넣었더니 부모 좌표계 clip 으로 컴포넌트가 "보였다 안 보였다" 하는 증상. `null` 로 변경 (성능 hint 손실만, 안전).

### 1.2 art-3 — 타이틀 씬 (MERGED #112, 배포 완료)

Manifest §1.3 "타이틀 로고 Flutter 정적 이미지" 원칙 준수. 기존 `/` → `LoginScreen` 을 **TitleScreen → /game 탭 이동** 으로 교체.

| PR | 태그 | 내용 |
|---|---|---|
| #112 | art-3 | `TitleScreen` 신설, 배경 + 로고 + 깜빡이는 PRESS TO START. PixelLab 2 에셋 (256×256 배경 + 256×256 로고). GoRouter `/` → Title, `/login` → LoginScreen |
| #114 | art-3b | integration test `pumpAndSettle` → `pump` 로 변경. TitleScreen `AnimationController.repeat()` 이 무한 깜빡임으로 `pumpAndSettle` 이 영원히 끝나지 않는 CI regression 수정 |

**알려진 이슈**: `verify_palette.dart` fail (AA 엣지로 16색 외 100%). art-2 와 동일 패턴. CI 게이트 아님. **art-9 폴리시 단계에서 일괄 quantize 처리 예정**.

### 1.3 로컬 정리 (세션 시작 시)

- 직전 세션 중단 후 로컬 develop 이 `origin/develop` 과 78 ahead / 28 behind 상태였음. 로컬 78 commit 은 전부 원격에 있는 구 PR 머지 복사본으로 판명 → `git reset --hard origin/develop` 안전 적용
- `.claude/worktrees/agent-*` 54 worktree (locked) + `feature/describer-*` / `worktree-agent-*` 로컬 브랜치 105개 일괄 정리 (`-f -f` force remove + `-D`)
- 정리 후 로컬 브랜치 4개만 (`develop`, `master`, `docs/pixel-art-bible-manifest`, `feature/fix-10b-cache-partial-clean`)

### 1.4 배포 릴리즈

| 릴리즈 PR | 포함 | master commit |
|---|---|---|
| #111 | 8차 — art-2 + art-2b + Bible/Manifest + fix-10b 캐시 27개 PR ~1,387 entries | `1a08a1f` (squash) |
| #113 | 9차 — art-3 타이틀 씬 | `ec3477c` 직전 (merge commit) |

**squash merge 후유증**: 8차를 squash 로 머지했더니 develop ↔ master 간 history 단절 → 9차 PR 이 conflict. `git merge -s ours --allow-unrelated-histories origin/master` 로 develop 에 squash 내용 흡수 후 PR #113 을 **merge commit** 방식으로 승격.

**교훈**: 릴리즈 PR은 **merge commit 방식** 유지. squash 는 tracking history 손상.

### 1.5 외부 사용자 완료 항목

- ✅ **ANTHROPIC_API_KEY revoke + 재발급** 완료 (2026-04-20 세션 중 사용자 보고)
- ✅ worktree 일괄 정리 (이 세션에서 자동 처리)

---

## 2. 미처리 잔량 (다음 세션 최우선)

### 2.1 fix-10b describer 미완 **24 chapter** (2026-04-20 핸드오프에서 이월)

**mysql (13ch)**:
- `mysql-step-01` (2회 중단) · `step-04` (2회) · `step-06` (2회) · `step-09` (2회)
- `mysql-step-11` ~ `step-20` (10ch 미착수)

**msa (10ch)**:
- `phase3-step4-api-contract` (2회 중단) · `phase4-step2/3/4` · `phase5-step1/2/3` · `phase6-step1/2/3`

**flutter (1ch)**:
- `Step-30-CICD` (2회 중단)

**이 세션에서 사용자 지시**: "**메인에서 직접 처리**" — subagent 대신 이 Claude 가 직접 chapter 읽고 prose 작성. chapter 당 평균 ~30 entries × prose ≈ 15~30 분. 24 chapter = **한 세션 내 완주 비현실적** — 다음 세션부터 순차 착수.

**해결 경로 우선순위**:
1. **메인 직접 처리** (사용자 지시): chapter 단위로 읽고 `content/diagram-descriptions/<category>/<chapter>.json` 에 entries 추가. 1-2 chapter / 세션 단위 진척.
2. **API credit 있으면** `ai_diagram_describer.dart` 재실행 보조 — 해시 dedup 로 이미 생성된 ~3,126 entries skip, 잔량만 재호출. 반복 실패 chapter 에 유용.
3. **subagent batch** 는 이 세션에서 사용자가 제외 지시.

### 2.2 art-4 중앙 홀 + 분관 문 (픽셀아트 이주 다음 단계)

설계: `C:/Users/deepe/.claude/plans/optimized-yawning-rocket.md` art-4 블록.

- 에셋 ~12 (central hall bg 256×144 × 3 parallax + 4 분관 문 64×96 각 idle+glow frame + 토치 애니)
- 예산 ~18 call (잉여 986/1000 충분)
- `lib/game/scenes/central_hall_scene.dart` + `lib/game/components/wing_door_component.dart` → `SpriteAnimationComponent` 상속
- 분관별 지배색 (§1.3) PixelLab 프롬프트에 주입. Flutter `ColorFilter` 사용 금지 (팔레트 락 위반)
- art-2b 에서 이미 분관 문 hover/pressed 시각 피드백 선취됨 — art-4 는 스프라이트 교체만

### 2.3 10차 릴리즈 대기

현재 develop 이 master 보다 **1 commit ahead** (art-3b). 다음 세션에서 **fix-10b chapter 1~2 개 추가 + art-4 착수분** 이 쌓이면 함께 릴리즈하거나, art-3b 만으로도 선제 배포 가능 (CI 안정화 목적).

---

## 3. 진행 중 / 미착수 (장기)

### 3.1 fix-10 시리즈 (R7 후속, fix-10b 이후)

| PR | 상태 | 범위 |
|---|---|---|
| fix-10c | 미착수 | Chapter JSON `simulatorContent.codeSnippets` 스키마 + content_builder 코드 수집 |
| fix-10d | 미착수 | 시뮬레이터 UI 에 코드 팝업/side panel (인터랙션 유지) |
| fix-10e | 미착수 | docs-source submodule update + 전체 재빌드 + 배포 |

### 3.2 픽셀아트 이주 (art-5~9)

| PR | 범위 | 예산 (누적) |
|---|---|---|
| art-4 | UI 크롬 (중앙 홀 + 분관 문 + 토치) | ~18 call (~32) |
| art-5 | 분관 배경 + 타일셋 A (backend+database) | ~50 call (~82) |
| art-6 | 분관 배경 + 타일셋 B (frontend+architecture) | ~50 call (~132) |
| art-7 | NPC 4 분관 마스터 | ~40 call (~172) |
| art-8 | 책장 + 정령 + 데코 | ~50 call (~222) |
| art-9 | 전환 + 폴리시 + 팔레트 quantize + 최종 감사 | ~12 call (~234) |

**현재 누적**: 14 / 1000 call. **잉여**: 986 (매우 여유).

---

## 4. 기술 교훈 (다음 세션 참고)

### 4.1 Squash vs Merge commit (릴리즈 PR)

- 릴리즈 PR (`develop → master`) 은 **merge commit** 유지 — squash 하면 develop ↔ master history 단절로 다음 릴리즈 PR 이 conflict.
- 과거 릴리즈 #69, #71, #73 전부 merge commit 이었음. #111 (8차) 를 squash 한 것이 실수.
- 회복: `git merge -s ours --allow-unrelated-histories origin/master` 로 develop 에 흡수 후 merge commit PR 승격.

### 4.2 Flame hover 구현

- `HoverCallbacks` 제약을 믹스인 `on` 절에 추가하면 서브클래스는 with 절에 `HoverCallbacks` 도 명시 필요.
- `Canvas.saveLayer(bounds, paint)` 의 bounds 는 **부모 좌표계**. local `(0, 0, size.x, size.y)` 는 잘못된 위치로 clip 되어 "보였다 안 보였다" 증상. `null` 로 지정해 전체 canvas 대상 (성능 hint 만 잃음).
- `HoverCallbacks.isHovered` 는 기본 제공 — 직접 `_hovering` state 중복 관리하지 말 것 (override 경고).

### 4.3 PixelLab MCP

- `create_map_object` basic mode max 400×400 = 160,000 픽셀. 요청 해상도를 정사각으로 자동 조정 (256×144 → 256×256). `BoxFit.cover` + `Image.asset(width:)` 로 흡수.
- 매니페스트 §3.6 은 PixFlux 전용이지만 MCP 에 PixFlux 없음. `create_map_object` (BitForge) 로 대체 가능하지만 팔레트 락 fail 은 art-9 로 이월.
- 투명 배경 기본 — 풀샷 배경 이미지도 transparent 영역 나올 수 있음 (cover fit 으로 가려짐).

### 4.4 Integration test + 무한 애니메이션

- `TitleScreen.AnimationController.repeat()` 같은 무한 애니는 `tester.pumpAndSettle` 을 영원히 대기시킴 → timeout.
- 해결: 초기 진입만 `tester.pump(Duration)` 으로 고정 시간 pump. navigate 이후 해당 위젯 dispose 되면 `pumpAndSettle` 복귀 가능.

---

## 5. 체크인 체크리스트 (다음 세션 진입 시)

```
[ ] git fetch origin develop && git pull --ff-only
[ ] gh pr list --state open (현재 0 예상)
[ ] docs/handoffs/2026-04-21-session-handoff.md (본 문서) 읽기
[ ] docs/pixel-art/PIXEL_ART_PROGRESS.md 누적 14/1000 확인
[ ] fix-10b 잔량 chapter 리스트 (§2.1) vs content/diagram-descriptions/ 실제 파일 비교
[ ] 다음 작업 선택:
    (A) fix-10b chapter 1-2 개 메인 직접 처리
    (B) art-4 중앙 홀 + 분관 문 착수
    (C) (develop 1 commit ahead 이면) 10차 선제 릴리즈
[ ] CLAUDE.md 참조 최신 핸드오프 2026-04-21 로 갱신됐는지 확인
```

---

## 6. 참조

- `docs/handoffs/2026-04-20-session-handoff.md` — 직전 세션
- `docs/handoffs/2026-04-19-session-handoff.md` — 직직전 세션
- `docs/designs/2026-04-19-requirements-consolidated.md` — R0~R7 원점
- `docs/pixel-art/PIXEL_ART_ASSET_BIBLE.md` / `docs/pixel-art/PIXEL_ART_ASSET_MANIFEST.md` — 스타일 규격
- `docs/pixel-art/PIXEL_ART_PROGRESS.md` — art-* 누적 (14/1000 call)
- `C:/Users/deepe/.claude/plans/optimized-yawning-rocket.md` — 픽셀아트 9-PR 플랜
- `tools/ai_diagram_describer.dart` — describer API 파이프라인 (credit 재충전 후 재실행)
