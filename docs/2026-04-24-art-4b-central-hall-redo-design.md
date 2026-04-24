# art-4b — 중앙 홀 풀샷 재작업 설계

> 2026-04-22 세션 핸드오프 §2.1 최우선 항목. 현 3층 parallax 투명 붕괴 상태를 opaque full-shot bg + transparent overlay 조립식 구성으로 교체하여 프로덕션 중앙 홀 시각 복원.

- **작성일**: 2026-04-24
- **선행 PR**: #118 (art-4 중앙 홀 + 4 분관 도어), #120 (base-href hotfix `/dol/` → `/dql/`)
- **선행 이슈**: #118 의 3층 parallax 가 `create_map_object` transparent 강제 제약으로 객체처럼 떠 보이는 붕괴
- **범위**: 단일 PR `feature/art-4b-central-hall-fullshot` → develop 머지 → 11차 릴리즈 후보

---

## 1. 목표와 성공 기준

### 1.1 목표

현 배포(`/dql/`) 중앙 홀의 시각 붕괴를 조립식 컴포지션으로 교체. 풀스크린 opaque base 1종 + 분리 가능한 transparent overlay 8종 + architecture 도어 재생성 1종(총 10 에셋 / 9 call, pillar mirror 재사용 시)으로 art-8(폴리시) 단계에서 개별 애니메이션·교체가 가능하도록 한다.

### 1.2 성공 기준

1. `env_mainhall_base.png` 의 4 corner 픽셀 alpha == 255 (자동 스크립트 검증)
2. 배포 URL `https://public-project-area-oragans.github.io/dql/` 에서 중앙 홀이:
   - 전체 화면을 opaque 배경으로 채움
   - 샹들리에·컴퍼스 로즈·기둥·4 도어가 의도된 위치에 렌더됨
3. 4 도어 클릭 영역이 스프라이트 경계와 일치하고 라벨이 샹들리에·기둥과 겹치지 않음
4. `obj_door_architecture` 재생성 결과가 "문" 으로 인식 (#118 의 scroll-only 문제 해결)
5. 누적 PixelLab API call ≤ 35/1000 (현 22 + art-4b 신규 ~10)

---

## 2. 아키텍처 — 렌더 스택

### 2.1 Flame 컴포넌트 트리 (`CentralHallScene`)

```
CentralHallScene (PositionComponent, size = gameSize)
├─ SpriteComponent        env_mainhall_base              priority 0
├─ SpriteComponent        deco_pillar_left               priority 10
├─ SpriteComponent        deco_pillar_right (mirror)     priority 10
├─ SpriteComponent        deco_entrance_arch_backend     priority 20
├─ SpriteComponent        deco_entrance_arch_database    priority 20
├─ SpriteComponent        deco_entrance_arch_frontend    priority 20
├─ SpriteComponent        deco_entrance_arch_architecture priority 20
├─ SpriteComponent        deco_chandelier_central        priority 30
├─ SpriteComponent        deco_compass_rose_floor        priority 30
├─ WingDoorComponent × 4  (SpriteComponent + TextComponent 자식) priority 40
```

- priority 값이 낮을수록 먼저 그려짐(뒤). 동일 priority 내 add 순서 유지
- `env_mainhall_base` 는 풀스크린 fill (Flame 가상 좌표 256×144 기준 scale)
- entrance_arch 는 도어 뒤·기둥 앞에 배치되어 분관별 지배색 glow 를 도어 주변에 노출

### 2.2 좌표 전략 — 반응형 앵커

- 기준 해상도 256×144 (Flame 가상). 실제 canvasSize 비례
- 모든 앵커는 `central_hall_layout.dart` 의 `Vector2` 상수로 고정
- 도어 4개는 중앙 기준 2×2 대칭:
  - backend: top-left
  - database: top-right
  - frontend: bottom-left
  - architecture: bottom-right
- entrance_arch 는 각 도어 앵커 기준 center 일치. 에셋 크기는 동일 64×64 이지만 Flame `SpriteComponent.scale = Vector2.all(1.25)` 로 렌더 시 80×80 상당으로 확대하여 도어 경계 외곽 ~8px glow 띠가 노출됨
- 라벨은 기존 `WingDoorComponent` 의 도어 중앙 배치 로직 유지 (변경 없음). base 가 opaque 풀스크린이 되면 기존 라벨 위치(도어 내부 y 중앙)는 샹들리에(screen y ~20%)·컴퍼스(screen y ~90%)와 수직 분리됨 — 현 배포의 "라벨이 샹들리에와 겹침" 문제는 3층 parallax 가 객체로 떠서 생긴 착시로, opaque bg 복구 후 자동 해소

### 2.3 에셋 로드 파이프라인

- `lib/game/dol_game.dart` 의 `onLoad()` 에서 `SpriteRegistry.preload(images: images, ids: [...])` id 리스트에 신규 9 상수 추가. 기존 `mainhallBgFar/Mid/Near` 는 리스트에서 제거
- 로드 실패한 id 는 `SpriteRegistry.has(id) == false` 로 표시 → `CentralHallScene` 이 각 layer 마다 `has()` 체크하여 단색 `RectangleComponent` fallback 으로 대체 (art-2b 패턴)
- pillar_right 는 pillar_left 와 동일 PNG 재사용 (scale 반전), preload 대상 개수는 신규 8 PNG (base + pillar_left + entrance_arch × 4 + chandelier + compass) + 재생성 arch 도어 1 PNG

### 2.4 Riverpod 관여

- 이 씬은 렌더만 담당 → Riverpod 상태 변경 없음
- 도어 클릭은 기존 `wingNavigationProvider` 재사용 (#118 에서 연결됨)

---

## 3. 에셋 리스트 + PixelLab 프롬프트

### 3.1 컴포넌트 10종

| # | 에셋 ID | API | 크기 | 투명도 |
|---|---|---|---|---|
| 1 | `env_mainhall_base` | `create_map_object` | 256×256 | **opaque** (프롬프트 강제) |
| 2 | `deco_pillar_left` | `create_map_object` | 64×64 | transparent |
| 3 | `deco_pillar_right` | mirror 재사용 | — | — |
| 4 | `deco_entrance_arch_backend` | `create_map_object` | 64×64 | transparent |
| 5 | `deco_entrance_arch_database` | `create_map_object` | 64×64 | transparent |
| 6 | `deco_entrance_arch_frontend` | `create_map_object` | 64×64 | transparent |
| 7 | `deco_entrance_arch_architecture` | `create_map_object` | 64×64 | transparent |
| 8 | `deco_chandelier_central` | `create_map_object` | 128×128 | transparent |
| 9 | `deco_compass_rose_floor` | `create_map_object` | 128×128 | transparent |
| 10 | `obj_door_architecture` (재생성) | `create_map_object` | 64×64 | transparent |

**pillar mirror**: Flame `SpriteComponent` 의 `scale = Vector2(-1, 1)` 로 좌우 반전하여 1 에셋을 좌·우에 재사용. API call 1 절약.

### 3.2 프롬프트 골격

| 에셋 | 프롬프트 |
|---|---|
| `env_mainhall_base` | "**opaque rectangular background, no transparency, fills entire canvas edge-to-edge**, steampunk arcane library grand main hall, 4 archway entrances visible along walls (top-left top-right bottom-left bottom-right), ornate stone walls, marble floor, vaulted ceiling, warm dusk lighting with brass accents, no text no words, pixel art 256×256" |
| `deco_pillar_left` | "ornate steampunk library pillar with brass filigree, tall column from floor to ceiling, transparent background, pixel art 64×64 scaled to tall aspect ratio" |
| `deco_entrance_arch_backend` | "archway frame with **green steam** glowing glyphs, mechanical gears motif, transparent background, 64×64 pixel art" |
| `deco_entrance_arch_database` | "archway frame with **amber** glowing database sigils, crystal motif, transparent, 64×64 pixel art" |
| `deco_entrance_arch_frontend` | "archway frame with **prismatic iridescent** glyphs, stained glass motif, transparent, 64×64 pixel art" |
| `deco_entrance_arch_architecture` | "archway frame with **pure gold** runes, blueprint compass motif, transparent, 64×64 pixel art" |
| `deco_chandelier_central` | "ornate brass chandelier with crystal pendants and warm magical glow, hanging from above, transparent background, 128×128 pixel art" |
| `deco_compass_rose_floor` | "decorative marble compass rose inlay on floor, top-down perspective, brass and gold, transparent background, 128×128 pixel art" |
| `obj_door_architecture` | "**ornate wooden door with pure gold architectural frame**, blueprint engravings, **clearly rectangular door shape filling most of frame**, transparent background, 64×64 pixel art" |

### 3.3 지배색 Bible §1.3 준수

- backend = green steam
- database = amber
- frontend = prismatic iridescent
- architecture = pure gold

art-4 도어와 동일 색 시스템이 entrance_arch 프레임에도 적용되어 도어 주변 glow 로 분관 식별성 강화.

### 3.4 호출 예산

- 정상 경로: **9 call** (pillar mirror 가정) 또는 **10 call** (no mirror)
- route (2) fallback 시: **+3 call** ≈ **12~13 call**
- 누적 22 + 10 = **32 / 1000** (잉여 968)

---

## 4. 코드 변경 범위

### 4.1 수정

| 파일 | 변경 |
|---|---|
| `lib/game/scenes/central_hall_scene.dart` | 3층 parallax `for` 루프 제거. `onLoad()` 에서 base → pillar × 2 → entrance_arch × 4 → chandelier + compass → door × 4 순서로 add. 각 레이어마다 `SpriteRegistry.has(...)` 체크 후 성공 시 SpriteComponent, 실패 시 RectangleComponent fallback |
| `lib/core/assets/asset_ids.dart` | `EnvironmentAssets` 에 `mainhallBase` 상수 추가. 신규 `MainHallDecoAssets` 클래스에 pillar / entrance_arch × 4 / chandelier / compass 상수 추가. 기존 `mainhallBgFar/Mid/Near` 는 `@Deprecated` 주석 후 유지 (파일 삭제는 art-5 일괄) |
| `lib/game/dol_game.dart` | `SpriteRegistry.preload` id 리스트에서 `mainhallBgFar/Mid/Near` 제거 후 신규 8 상수 + `doorArchitecture` (v2 로 재생성하므로 파일명 변경 시 상수도 갱신) 추가 |
| `pubspec.yaml` | `flutter.assets:` 에 신규 PNG 경로 추가 (또는 디렉터리 prefix 가 이미 커버하는 경우 추가 없음) |

### 4.2 신규

| 파일 | 역할 |
|---|---|
| `lib/game/scenes/central_hall_layout.dart` | `Vector2` 앵커 상수 집합 + `labelPositionFor(Vector2 doorAnchor, double doorHeight)` 함수 |
| `.tmp/check_opacity.py` | PIL 기반 corner alpha 검증. `.tmp/` 는 현재 git 추적 제외 (global ignore 로 추정, `git status` 에서 untracked 표시), repo 커밋 안 함 |

### 4.3 에셋 파일

기존 네이밍 규칙 (`PIXEL_ART_ASSET_MANIFEST.md` §6 `_v1` 접미사 + 카테고리 디렉터리) 준수:

| 경로 | 비고 |
|---|---|
| `assets/sprites/environments/main_hall/env_mainhall_base_v1.png` | 신규 (opaque) |
| `assets/sprites/environments/main_hall/deco_mainhall_pillar_v1.png` | 신규 (좌·우 mirror 재사용) |
| `assets/sprites/environments/main_hall/deco_mainhall_entrance_arch_backend_v1.png` | 신규 |
| `assets/sprites/environments/main_hall/deco_mainhall_entrance_arch_database_v1.png` | 신규 |
| `assets/sprites/environments/main_hall/deco_mainhall_entrance_arch_frontend_v1.png` | 신규 |
| `assets/sprites/environments/main_hall/deco_mainhall_entrance_arch_architecture_v1.png` | 신규 |
| `assets/sprites/environments/main_hall/deco_mainhall_chandelier_v1.png` | 신규 |
| `assets/sprites/environments/main_hall/deco_mainhall_compass_rose_v1.png` | 신규 |
| `assets/sprites/objects/doors/obj_door_architecture_v2.png` | 신규 (v1 와 병존, 상수는 v2 참조로 교체. v1 파일 삭제는 art-5 일괄) |

### 4.4 테스트

| 파일 | 변경 |
|---|---|
| `integration_test/central_hall_test.dart` (옵션, 현 미존재) | 존재 여부에 따라 기존 3층 parallax assertion 을 새 컴포넌트 assertion 으로 교체. 픽셀 비교는 안 함. 없으면 이번 PR 에서 신규 작성은 하지 않음 (art-3b 패턴 유지) |

### 4.5 문서

| 파일 | 변경 |
|---|---|
| `docs/PIXEL_ART_PROGRESS.md` | art-4b 섹션 추가. 누적 22 → 32/1000 업데이트 |
| `docs/PIXEL_ART_ASSET_MANIFEST.md` | 신규 9 에셋 등록 (pillar_right 는 mirror 주석) |
| `docs/2026-04-24-session-handoff.md` | 세션 종료 시 작성 |
| `CLAUDE.md` | 참조 링크를 최신 핸드오프로 갱신 |

---

## 5. 검증 게이트 + 롤백/Pivot 전략

### 5.1 Phase 1 — Opacity 검증 (게이트)

`.tmp/check_opacity.py`:

```python
import sys
from PIL import Image

path = sys.argv[1]
img = Image.open(path).convert("RGBA")
w, h = img.size
corners = [
    img.getpixel((0, 0)),
    img.getpixel((w-1, 0)),
    img.getpixel((0, h-1)),
    img.getpixel((w-1, h-1)),
]
opaque = all(c[3] == 255 for c in corners)
print(f"{'PASS' if opaque else 'FAIL'} - corners: {[c[3] for c in corners]}")
sys.exit(0 if opaque else 1)
```

- **PASS** → Phase 2 진행
- **FAIL** → 프롬프트 강화 재시도 (최대 3회)
- **3회 모두 FAIL** → route (2) pivot: `create_topdown_tileset` / `create_tiles_pro` 스키마에서 opaque 옵션 탐색. 결과에 따라 사용자 재승인 필요

### 5.2 Phase 2 — 에셋 품질 육안 검사

9 (또는 8) 에셋 모두 시각 검사:
- 분관별 지배색 준수
- 디테일 스케일 적정 (scroll-only 같은 단순화 없음)
- 투명 배경 확인 (bg 외 모든 에셋)

문제 있는 에셋은 단건 재생성. 프롬프트 조정 예산 +3 call.

### 5.3 Phase 3 — 배포 Headed Chrome 검증

GitHub Pages 배포 후 `https://public-project-area-oragans.github.io/dql/`:

- [ ] opaque 풀스크린 bg
- [ ] 4 도어 위치 일치, 클릭 가능
- [ ] 라벨이 샹들리에·기둥과 안 겹침
- [ ] architecture 도어가 "문" 으로 인식됨

문제 발견 시 hotfix PR 로 좌표/프롬프트 조정.

### 5.4 롤백 전략

- PR merge 전: 브랜치 리셋 또는 force-push 로 되감기
- PR merge 후 프로덕션 붕괴 시: `feature/art-4b-*` revert PR → master 재배포 (10.5차 hotfix 패턴)
- 현 배포가 이미 붕괴 상태 → revert 해도 악화 없음, 롤백 비용 낮음

### 5.5 중단·재개 지점

| 체크포인트 | 저장 방식 |
|---|---|
| Phase 1 통과 후 | `env_mainhall_base.png` 커밋 → 다음 세션 Phase 2 재개 가능 |
| Phase 2 생성 중 | 에셋 개별 커밋. 세션 중단 시 이미 생성된 파일 skip |
| Phase 3 배포 | merge 후 URL 확인만 남음 |

---

## 6. 실행 절차 요약

1. `develop` 에서 `feature/art-4b-central-hall-fullshot` 브랜치 생성
2. Phase 1: `env_mainhall_base` 1 call 생성 → `.tmp/check_opacity.py` 검증
3. PASS 시 Phase 2: 나머지 8 에셋 병렬 생성 (429 concurrent limit 6 감안, 2 batch)
4. FAIL 시: 프롬프트 강화 재시도 (≤3) → 그래도 FAIL 시 route (2) pivot (사용자 재승인)
5. 에셋 육안 검사 → 단건 재생성
6. 코드 변경 적용 (§4)
7. `flutter analyze` + 로컬 `flutter run -d chrome --web-port 5555` 검증
8. `dart run tools/content_builder.dart docs-source` 필요 여부 확인 (중앙 홀과 무관 예상)
9. 문서 갱신 (`PIXEL_ART_PROGRESS.md`, `PIXEL_ART_ASSET_MANIFEST.md`)
10. 커밋 → PR → develop 머지
11. 11차 릴리즈 PR (develop → master, merge commit 유지)
12. 배포 URL Headed Chrome 검증 (Phase 3)
13. 세션 핸드오프 작성, CLAUDE.md 참조 갱신

---

## 7. 참조

- `docs/2026-04-22-session-handoff.md` §2.1 — art-4b 요구사항 원천
- `docs/PIXEL_ART_ASSET_BIBLE.md` §1.3 — 분관별 지배색
- `docs/PIXEL_ART_ASSET_MANIFEST.md` — 기존 에셋 목록
- `docs/PIXEL_ART_PROGRESS.md` — art-* 누적 진행
- PR #118 — art-4 선행 작업
- PR #120 — base-href hotfix (URL `/dql/` 확정)
