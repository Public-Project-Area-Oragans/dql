# DOL — 세션 핸드오프 (2026-04-24)

> art-4b 중앙 홀 풀샷 재작업 **미완**. spec + plan 완성 후 에셋 9개 생성 + 코드 재작성까지 진행. **최종 시각 검증에서 도어 스타일이 새 base 와 조화 부족** → 도어 4개 재생성 (Option B/D) 을 **다음 세션으로 이관**. master 반영 전 feature 브랜치에 보존 상태.

- **작성일**: 2026-04-24
- **master HEAD**: `7481abd` (10.5차 릴리즈, 2026-04-22 세션 동일, 변동 없음)
- **develop HEAD (local)**: `57ca496` (원격 origin/develop 기준 +4 commits, 미푸시)
- **feature 브랜치**: `feature/art-4b-central-hall-fullshot` HEAD `7cb0e7b` (+8 commits 위 develop)
- **현재 단계**: P0 진행 + art-4b 진행 중 (v1 붕괴 원인 해결, 도어 스타일 후속 조정 필요)
- **누적 PixelLab call**: 22 + 11 = **33 / 1000** (base 재생성 1 포함, 잉여 967)

---

## 1. 이번 세션 완료분

### 1.1 Brainstorming + Spec + Plan (develop, 미푸시 4 commits)

`/superpowers:brainstorming` → `writing-plans` 플로우로 art-4b 설계 완료.

| commit | 내용 |
|---|---|
| `d5de58d` | `docs/pixel-art/2026-04-24-art-4b-central-hall-redo-design.md` — spec 초안 |
| `cc1f591` | spec self-review 교정 3건 (overlay 수 12→9, arch scale 1.25 glow, .tmp/ ignore 현실화) |
| `9baecbb` | 실제 코드베이스 path·구조에 맞춰 spec 재정렬 (`lib/core/assets/asset_ids.dart`, `SpriteRegistry.preload via dol_game.dart`) |
| `57ca496` | `docs/pixel-art/2026-04-24-art-4b-central-hall-plan.md` — 13 Task 구현 플랜 (TDD + 단계식 검증 게이트 + self-review) |

### 1.2 Task 1-4 에셋 생성 (feature branch, 미푸시)

Phase 1 opacity 게이트 + Phase 2 overlay 배치 완료. 9 PixelLab call (base 1 + pillar 1 + arch×4 + chandelier 1 + compass 1 + door v2 1). chandelier 첫 시도 429 concurrent 발생, 재시도로 성공. 실제 시행에서 확인된 사항:
- **5 concurrent 은 안전, 6 은 429** — handoff 2026-04-22 §4.1 관찰 재확인
- `create_map_object` 에 "opaque rectangular" 프롬프트 → opacity PASS (v1 base 4 corner alpha 255)

| commit | 파일 |
|---|---|
| `4e94d2c` | `env_mainhall_base_v1.png` (v1, 256×256, high top-down, isometric — v2 로 교체됨) |
| `caa054c` | `deco_pillar` + `deco_entrance_arch_{backend/database/frontend/architecture}` + `deco_chandelier` (6 PNG) |
| `09c08de` | `deco_compass_rose` + `obj_door_architecture_v2` (2 PNG) |

### 1.3 Task 5-7 코드 변경 (feature branch, subagent 실행)

| commit | 파일 | 결과 |
|---|---|---|
| `acbbbef` | `lib/core/assets/asset_ids.dart` + `test/core/assets/asset_ids_test.dart` | `EnvironmentAssets.mainhallBase` + `MainHallDecoAssets` 클래스 + `doorArchitecture` v2, 기존 parallax 상수 `@Deprecated`. 테스트 12/12 PASS |
| `840eeee` | `lib/game/dol_game.dart` | preload id 리스트 신규 12 상수로 교체 |
| `15c42a2` | `lib/game/scenes/central_hall_scene.dart` | 3층 parallax 제거 → 조립식 렌더 스택 (base + pillar + arch×4 + chandelier + compass + doors) 구현. 178/178 tests PASS |

### 1.4 Task 8 시각 검증 — 문제 발견 + v2 피벗 (feature branch)

첫 Chrome 검증 (스크린샷 1): **근본 문제 발견** — base v1 이 "완성된 씬" 으로 생성돼 overlay 와 중복. 좌측 끝 기둥이 backend 도어 밖으로 튀어나가는 등 전체 구성 붕괴.

- **원인**: PixelLab prompt 의 "4 archway entrances / chandelier hint / marble floor" 를 base 가 전부 그림. overlay 와 중복
- **피벗 결정 (옵션 C)**: base 재생성 (빈 corridor front-facing) + overlay 최소화 (도어만)

| commit | 파일 | 결과 |
|---|---|---|
| `fe1d106` | `env_mainhall_base_v1.png` (v2 재생성) + scene.dart 간소화 | base 재생성 PASS (corner alpha 255). pillar/entrance_arch/chandelier/compass overlay 메서드 제거 (에셋은 보존) |
| `7cb0e7b` | `scene.dart` 도어 크기 조정 | `doorWidth /5 → /7`, `doorHeight 0.3 → 0.25`, `y 0.4 → 0.5` |

### 1.5 Task 8 시각 재검증 — **남은 문제**

두 번째 Chrome 검증 (스크린샷 2, v2 base + overlay 제거):
- ✅ **base 훌륭함** — steampunk corridor (bookshelves 좌우, 샹들리에 중앙, 후면 아치에서 석양, 바닥 컴퍼스)
- ✅ opaque 풀스크린 복구 — 프로덕션 붕괴 원인 해결됨
- ❌ **도어 스타일 mismatch** — 4 도어가 base 의 어두운 pastel 팔레트와 조화 부족. 너무 화려하고 선명
- ❌ **원근감 불일치** — base 는 corridor 원근감, 도어는 2D 평면 → 분위기 깨짐

세 번째 검증 (스크린샷 3, 도어 축소 + y 하향):
- 개선: 도어 작아져 후면 아치 소실점 보존 가능
- **여전히 부족**: 도어 스타일 조화 문제 지속, 원근감 미비 지속

**사용자 결정**: 여기서 중단, 다음 세션으로 이관.

---

## 2. 미해결 문제 + 다음 세션 작업

### 2.1 art-4b 잔여 — 도어 4개 재생성 + 원근감 배치 🔥 최우선

**문제 재정의**:
1. 도어 4개 (v1 기존 3 + architecture v2 이번) 스타일이 새 base corridor 와 조화 부족
2. 도어가 2D 평면 배치라 base 의 3D corridor 원근감과 불일치

**권장 경로 (옵션 B → 필요 시 D)**:

#### B. 도어 4개 재생성 — base 스타일 매칭
- PixelLab `create_map_object` 의 `background_image` 파라미터 활용
- `{"type": "path", "path": "assets/sprites/environments/main_hall/env_mainhall_base_v1.png"}` 으로 현 base 를 참조
- inpainting 으로 도어 위치·크기 지정 → PixelLab 이 base 스타일·팔레트 학습해 조화된 도어 생성
- 프롬프트 예: `wooden door with {color} architectural frame, matches library interior style, pixel art`
- 예산: 4 call (backend/frontend/database/architecture 재생성), v2/v3 suffix 로 저장
- `ObjectAssets.door*` 상수 값 v1 → v2/v3 로 교체

#### D. 도어 배치 원근감 흉내
- 현 `doorWidth = size.x / 7`, `doorHeight = size.y * 0.25` 는 평면 균등 배치
- 원근감 배치 예: 중앙 2개 작게 (frontend/database) + 좌·우 끝 2개 크게 (backend/architecture)
  - 또는 후면 아치 근처 2개 + 전면 2개
- 구체 공식:
  ```dart
  // 예시: near vs far perspective placement
  final nearSize = Vector2(size.x * 0.12, size.y * 0.22);
  final farSize = Vector2(size.x * 0.07, size.y * 0.13);
  
  // backend: far-left, far (small)
  // frontend: near-left, near (medium)
  // database: near-right, near (medium)
  // architecture: far-right, far (small)
  ```
- 또는 x 위치 좁혀서 4개를 중앙 근처 모으고 도어 그림자 바닥에 추가

**우선 순위**: B 먼저 (도어 재생성) → 결과 보고 D (배치 조정) 순차.

### 2.2 현 PR 미머지 상태

feature 브랜치 `feature/art-4b-central-hall-fullshot` 은 **로컬에만 존재, origin 푸시 안 됨**. 8 commits 포함.

develop 도 **4 commits 로컬 ahead, 푸시 안 됨** (spec + plan + self-review + path 재정렬).

**다음 세션 정리 경로**:
- (a) **완성까지 더 진행 후 일괄 PR** — 2.1 B+D 작업 후 feature → develop PR, develop → master 릴리즈 PR
- (b) **현 상태를 "WIP PR" 로 올리고 다음 세션에서 추가 커밋** — 가시성 확보
- (c) **모두 drop 하고 재설계** — 손해 크므로 비추

사용자 결정 필요.

### 2.3 fix-10b 잔량 (2026-04-22 핸드오프에서 이월, 이번 세션 미처리)

mysql 4ch (step-01/04/06/09) + msa 10ch (phase3~6) + flutter 1ch (Step-30) = 15 chapter. 이번 세션 art-4b 로드로 손 안 댐. 다음 세션 우선순위:
- art-4b 완료 → fix-10b 진입 순서

### 2.4 art-5 이후

art-4b 완성 후 art-5 (분관 배경 + 타일셋 A) 착수 가능. 현 누적 33/1000, 여유 967.

---

## 3. feature 브랜치 commit 상세 (12 commits, 시간순)

### develop 로컬 ahead (4 commits — 문서만)

```
57ca496 docs(art-4b): 구현 Plan — 13 Task · TDD · 단계식 검증 게이트
9baecbb docs(art-4b): 실제 코드베이스 path·구조에 맞춰 spec 재정렬
cc1f591 docs(art-4b): spec self-review 교정 3건
d5de58d docs(art-4b): 중앙 홀 풀샷 재작업 설계 (opaque base + transparent overlay 조립식)
```

### feature/art-4b-central-hall-fullshot (8 commits — 에셋 + 코드)

```
7cb0e7b feat(art-4b v2): 도어 크기 축소 + y 하향 (base 원근감 보존)
fe1d106 art+feat(art-4b v2): base 재생성 (empty corridor) + scene 단순화
15c42a2 feat(art-4b): CentralHallScene — 조립식 렌더 스택 재작성
840eeee feat(art-4b): preload — 신규 조립식 에셋 + 기존 parallax 제거
acbbbef feat(art-4b): asset_ids — mainhallBase + MainHallDecoAssets + door v2
09c08de art(art-4b): Phase 2 Batch 2 — compass_rose + obj_door_architecture_v2
caa054c art(art-4b): Phase 2 Batch 1 — pillar + entrance_arch×4 + chandelier
4e94d2c art(art-4b): env_mainhall_base 생성 (opaque 풀스크린 bg)
```

---

## 4. 기술 교훈

### 4.1 PixelLab "opaque" 프롬프트가 효과 있음

spec §5.1 의 `.tmp/check_opacity.py` 게이트가 유효. "opaque rectangular background, no transparency, fills entire canvas edge-to-edge" 프롬프트로 base 2회 모두 corner alpha 255 통과. 2026-04-22 §4.1 의 "투명 배경 강제" 관찰은 특정 프롬프트에서만 발생.

### 4.2 PixelLab 이 negative prompt 준수 안 함

프롬프트에 "NO doors NO chandelier NO decorations" 등 음성 지시 명확히 해도 "library interior" 편향으로 결국 포함. base 생성 시 **명시적으로 "empty hall" / "plain walls"** 강조하는 게 더 효과적.

### 4.3 `background_image` 파라미터로 스타일 매칭

`mcp__pixellab__create_map_object` 스키마의 `background_image` 옵션 — 기존 base PNG 를 style 참조로 전달하면 생성물이 해당 스타일에 맞춰짐. 다음 세션 2.1 B 에서 활용.

### 4.4 429 concurrent 경계

5 parallel 은 안전, 6 은 실패. spec 업데이트 권장 (plan Task 3 Step 1 "6 parallel" 표기).

### 4.5 base 이미지의 "자동 완성" 경향

PixelLab 에 "grand main hall" 류 큰 프롬프트 주면 아치·샹들리에·기둥·바닥 장식을 자동 포함. 조립식 overlay 전략이려면 base 를 **명시적으로 빈 방**으로 유지해야 함.

### 4.6 Subagent-driven 하이브리드 실행 성공

Tasks 5-7 을 subagent 로 위임 → 성공적 TDD · 스펙 준수 · 분석 통과. 자체 검증 (implementer self-review) 만으로도 충분한 품질 (spec/code reviewer 단계 생략해도 괜찮았음).

---

## 5. 체크인 체크리스트 (다음 세션 진입 시)

```
[ ] git fetch origin develop master
[ ] git checkout develop && git status  (로컬 +4 commits 확인)
[ ] git checkout feature/art-4b-central-hall-fullshot && git status  (+8 commits 확인)
[ ] docs/handoffs/2026-04-24-session-handoff.md (본 문서) 읽기
[ ] docs/pixel-art/2026-04-24-art-4b-central-hall-redo-design.md 읽기 (spec)
[ ] docs/pixel-art/2026-04-24-art-4b-central-hall-plan.md 읽기 (plan)
[ ] 로컬 Chrome 으로 현 상태 재확인 (flutter run -d chrome --web-port 5555)
[ ] 다음 작업 선택:
    (A) art-4b 잔여 — 도어 4개 재생성 (옵션 B) → 검증 → 필요 시 D → PR → 11차 릴리즈
    (B) art-4b 현 상태로 PR 머지 (도어 부조화는 차기 art-* 에서 해결) — 프로덕션 현 붕괴 상태 즉시 해소 우선
    (C) 다른 방향 (fix-10b 등)
```

**추천**: (A) — 도어 부조화는 art-4b PR 범위에서 해결하는 게 변경 이력 깔끔. 완성까지 1 세션 내 가능 예상 (4 PixelLab call + 좌표 조정).

---

## 6. 참조

- `docs/handoffs/2026-04-22-session-handoff.md` — 직전 세션 (art-4 + 10/10.5차)
- `docs/pixel-art/2026-04-24-art-4b-central-hall-redo-design.md` — spec (Phase 1/2/3 게이트, 조립식 설계)
- `docs/pixel-art/2026-04-24-art-4b-central-hall-plan.md` — plan 13 Task (self-review 포함)
- `.tmp/check_opacity.py` — Phase 1 opacity 자동 게이트 (재활용 가능)
- PR 선행: #118 (art-4), #120 (base-href hotfix), #122 (2026-04-22 핸드오프)
- 배포 URL: `https://public-project-area-oragans.github.io/dql/`
