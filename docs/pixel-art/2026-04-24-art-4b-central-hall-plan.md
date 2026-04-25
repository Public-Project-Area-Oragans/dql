# art-4b — 중앙 홀 풀샷 재작업 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 현 3층 parallax 투명 붕괴 상태를 opaque full-shot base + transparent overlay 조립식 구성(총 10 에셋, 9 PixelLab call)으로 교체하여 배포 URL `/dql/` 중앙 홀 시각 복원.

**Architecture:** `create_map_object` API 의 투명 강제 제약을 프롬프트(`opaque rectangular background, fills entire canvas edge-to-edge`)로 우회. 단계식 검증 — Phase 1 base 1장 생성 후 opacity 자동 게이트 통과 확인, Phase 2 나머지 8장 일괄 생성, Phase 3 배포 URL 시각 확인. 실패 시 route (2) 다른 PixelLab API 탐색 (사용자 재승인).

**Tech Stack:** Flutter / Flame / Dart / PixelLab MCP / Python 3 + Pillow / GitHub Actions (deploy)

**Spec:** [docs/pixel-art/2026-04-24-art-4b-central-hall-redo-design.md](2026-04-24-art-4b-central-hall-redo-design.md)

---

## File Structure

**Create (신규):**
- `.tmp/check_opacity.py` — opacity 자동 검증 스크립트 (git 추적 X)
- `assets/sprites/environments/main_hall/env_mainhall_base_v1.png` — opaque 풀스크린 bg
- `assets/sprites/environments/main_hall/deco_mainhall_pillar_v1.png` — 좌·우 mirror 공용
- `assets/sprites/environments/main_hall/deco_mainhall_entrance_arch_backend_v1.png`
- `assets/sprites/environments/main_hall/deco_mainhall_entrance_arch_database_v1.png`
- `assets/sprites/environments/main_hall/deco_mainhall_entrance_arch_frontend_v1.png`
- `assets/sprites/environments/main_hall/deco_mainhall_entrance_arch_architecture_v1.png`
- `assets/sprites/environments/main_hall/deco_mainhall_chandelier_v1.png`
- `assets/sprites/environments/main_hall/deco_mainhall_compass_rose_v1.png`
- `assets/sprites/objects/doors/obj_door_architecture_v2.png` — 도어 형태 명확화 재생성
- `docs/handoffs/2026-04-24-session-handoff.md` — 세션 종료 시

**Modify (수정):**
- `lib/core/assets/asset_ids.dart` — `EnvironmentAssets.mainhallBase` + 신규 `MainHallDecoAssets` 클래스 + `ObjectAssets.doorArchitecture` 를 v2 경로로 교체
- `lib/game/dol_game.dart` — `SpriteRegistry.preload` id 리스트 갱신
- `lib/game/scenes/central_hall_scene.dart` — 3층 parallax `for` 루프 제거 후 신규 조립식 렌더
- `test/core/assets/asset_ids_test.dart` — 신규 상수 회귀 테스트 추가, 기존 parallax 테스트 대체
- `docs/pixel-art/PIXEL_ART_PROGRESS.md` — art-4b 섹션 + 누적 22→32/1000 업데이트
- `docs/pixel-art/PIXEL_ART_ASSET_MANIFEST.md` — 신규 에셋 등록
- `CLAUDE.md` — 최신 핸드오프 링크 갱신

---

## Task 1: 브랜치 생성 + Opacity 검증 스크립트 준비

**Files:**
- Create: `.tmp/check_opacity.py`

- [ ] **Step 1: 최신 develop 동기화 + 브랜치 생성**

```bash
git fetch origin develop master
git checkout develop && git pull --ff-only
git status  # Expected: working tree clean
git checkout -b feature/art-4b-central-hall-fullshot
```

- [ ] **Step 2: Python Pillow 설치 확인**

```bash
python -c "from PIL import Image; print(Image.__version__)"
```

Expected: 버전 출력 (예: `10.0.0`). 실패 시: `pip install Pillow`

- [ ] **Step 3: `.tmp/check_opacity.py` 작성**

```python
# .tmp/check_opacity.py
"""PNG 의 4 corner 픽셀 alpha == 255 여부 검증. art-4b Phase 1 opacity 게이트."""
import sys
from PIL import Image

path = sys.argv[1]
img = Image.open(path).convert("RGBA")
w, h = img.size
corners = [
    img.getpixel((0, 0)),
    img.getpixel((w - 1, 0)),
    img.getpixel((0, h - 1)),
    img.getpixel((w - 1, h - 1)),
]
opaque = all(c[3] == 255 for c in corners)
print(f"{'PASS' if opaque else 'FAIL'} - corners: {[c[3] for c in corners]}")
sys.exit(0 if opaque else 1)
```

- [ ] **Step 4: 스크립트 자체검증 — 2×2 opaque 테스트 PNG 생성 후 실행**

```bash
python -c "from PIL import Image; Image.new('RGBA', (2,2), (255,0,0,255)).save('.tmp/test_opaque.png')"
python .tmp/check_opacity.py .tmp/test_opaque.png
```

Expected: `PASS - corners: [255, 255, 255, 255]` (종료 코드 0)

- [ ] **Step 5: 실패 케이스 자체검증 — 2×2 transparent 테스트 PNG**

```bash
python -c "from PIL import Image; Image.new('RGBA', (2,2), (255,0,0,0)).save('.tmp/test_trans.png')"
python .tmp/check_opacity.py .tmp/test_trans.png; echo "exit=$?"
```

Expected: `FAIL - corners: [0, 0, 0, 0]`, `exit=1`

- [ ] **Step 6: 테스트 PNG 정리**

```bash
rm .tmp/test_opaque.png .tmp/test_trans.png
```

Task 1 종료 시점 — 아직 커밋할 변경 없음 (`.tmp/` 는 미추적).

---

## Task 2: Phase 1 — env_mainhall_base 생성 + Opacity 게이트

**Files:**
- Create: `assets/sprites/environments/main_hall/env_mainhall_base_v1.png`

- [ ] **Step 1: PixelLab MCP 도구 스키마 로드**

```
ToolSearch query="select:mcp__pixellab__create_map_object,mcp__pixellab__get_map_object"
```

로드된 스키마로 생성·다운로드 도구 사용 가능.

- [ ] **Step 2: `create_map_object` 호출 — base bg 생성**

프롬프트 (정확히 이 문자열):

```
opaque rectangular background, no transparency, fills entire canvas edge-to-edge, steampunk arcane library grand main hall interior, 4 archway entrances visible along walls (top-left top-right bottom-left bottom-right), ornate stone walls with brass filigree, marble floor, vaulted ceiling with chandelier hint, warm dusk lighting, no text no words, pixel art 256x256
```

크기: 256×256 요청 (PixelLab 강제로 정사각 출력).

- [ ] **Step 3: 결과 PNG 다운로드 및 저장**

`mcp__pixellab__get_map_object` 로 job 결과 조회 → PNG 바이너리를 `assets/sprites/environments/main_hall/env_mainhall_base_v1.png` 로 저장.

- [ ] **Step 4: Opacity 검증 실행**

```bash
python .tmp/check_opacity.py assets/sprites/environments/main_hall/env_mainhall_base_v1.png
```

**분기**:
- `PASS` → Task 3 으로 진행
- `FAIL` → Step 5 재시도 루프

- [ ] **Step 5 (FAIL 시만): 프롬프트 강화 재시도 1회차**

프롬프트에 추가 강제어:

```
SOLID OPAQUE BACKGROUND, completely filled rectangle, no alpha channel, no transparent pixels anywhere, painted flat color background extending beyond all visible elements, [기존 프롬프트]
```

다시 Step 3-4.

- [ ] **Step 6 (여전히 FAIL): 재시도 2회차**

프롬프트에 네거티브 프롬프트 문법 시도 (PixelLab 지원 여부 미확인, 실패해도 손해 없음):

```
[기존 강화 프롬프트] | negative: transparent, alpha, cutout, png alpha channel
```

다시 Step 3-4.

- [ ] **Step 7 (여전히 FAIL): 재시도 3회차 — 레퍼런스 이미지 접근**

만약 `create_map_object` 가 reference image 파라미터를 지원한다면, 기존 opaque 에셋 (예: art-3 title bg) 을 레퍼런스로 전달. 지원 안 하면 이 단계 skip.

- [ ] **Step 8 (3회 모두 FAIL): route (2) pivot — 사용자 재승인 요청**

다음 상태로 사용자에게 보고:
- 시도한 프롬프트 3개
- 각 시도의 opacity 검증 결과
- 추가 탐색 후보: `mcp__pixellab__create_topdown_tileset` / `create_tiles_pro` — 이들의 출력이 opaque 인지 스키마 확인 필요

사용자 응답 대기.

- [ ] **Step 9: PASS 후 커밋**

```bash
git add assets/sprites/environments/main_hall/env_mainhall_base_v1.png
git commit -m "$(cat <<'EOF'
art(art-4b): env_mainhall_base 생성 (opaque 풀스크린 bg)

- Phase 1 opacity 게이트 통과 (PASS, corner alpha 255×4)
- 256×256 steampunk arcane library main hall interior
- 3층 parallax 대체 예정 (후속 Task 에서 asset_ids + scene 갱신)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 3: Phase 2 Batch 1 — pillar + entrance_arch × 4 + chandelier (6 병렬)

**Files:**
- Create: 6 PNG files in `assets/sprites/environments/main_hall/`

- [ ] **Step 1: 6 에셋 동시 생성 (429 concurrent limit == 6 이므로 정확히 경계)**

병렬 호출 (단일 메시지 내 6 tool uses):

| ID | 프롬프트 |
|---|---|
| `deco_mainhall_pillar_v1` | `ornate steampunk library pillar with brass filigree and engraved runes, tall column from floor to ceiling, transparent background, pixel art 64x64` |
| `deco_mainhall_entrance_arch_backend_v1` | `archway frame with green steam glowing glyphs, mechanical gears and pipes motif, transparent background, pixel art 64x64` |
| `deco_mainhall_entrance_arch_database_v1` | `archway frame with amber glowing database sigils, crystal motif, transparent background, pixel art 64x64` |
| `deco_mainhall_entrance_arch_frontend_v1` | `archway frame with prismatic iridescent glyphs, stained glass motif, transparent background, pixel art 64x64` |
| `deco_mainhall_entrance_arch_architecture_v1` | `archway frame with pure gold runes, blueprint compass motif, transparent background, pixel art 64x64` |
| `deco_mainhall_chandelier_v1` | `ornate brass chandelier with crystal pendants and warm magical glow, hanging from above, transparent background, pixel art 128x128` |

- [ ] **Step 2: 6 결과 모두 다운로드**

각 job_id 별로 `get_map_object` 호출, PNG 를 `assets/sprites/environments/main_hall/` 에 저장 (파일명은 테이블의 ID + `.png`).

- [ ] **Step 3: 로컬 시각 확인 (사용자 눈 검사 단계)**

6 PNG 를 그림 뷰어로 열어 확인:
- 분관별 지배색 준수 (green steam / amber / prismatic / pure gold)
- 디테일 스케일 적정 (너무 단순화되지 않음)
- 투명 배경 (chandelier·pillar 주변 투명 확인)

문제 있는 에셋 ID 목록 수집 → Step 4 로 재생성, 없으면 Step 5 로 스킵.

- [ ] **Step 4 (필요 시): 문제 에셋 단건 재생성**

문제 있는 ID 마다 프롬프트 일부 보강 후 단건 `create_map_object`. 재생성 예산 최대 +3 call.

- [ ] **Step 5: 커밋**

```bash
git add assets/sprites/environments/main_hall/deco_mainhall_pillar_v1.png \
        assets/sprites/environments/main_hall/deco_mainhall_entrance_arch_backend_v1.png \
        assets/sprites/environments/main_hall/deco_mainhall_entrance_arch_database_v1.png \
        assets/sprites/environments/main_hall/deco_mainhall_entrance_arch_frontend_v1.png \
        assets/sprites/environments/main_hall/deco_mainhall_entrance_arch_architecture_v1.png \
        assets/sprites/environments/main_hall/deco_mainhall_chandelier_v1.png
git commit -m "$(cat <<'EOF'
art(art-4b): Phase 2 Batch 1 — pillar + entrance_arch×4 + chandelier

- 분관별 지배색 glow 프레임 4종 (green/amber/prismatic/gold)
- pillar 는 좌·우 mirror 재사용 예정
- 샹들리에는 art-8 폴리시 단계에서 파티클 효과 가능하도록 분리

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 4: Phase 2 Batch 2 — compass_rose + obj_door_architecture_v2 (2 병렬)

**Files:**
- Create: `assets/sprites/environments/main_hall/deco_mainhall_compass_rose_v1.png`
- Create: `assets/sprites/objects/doors/obj_door_architecture_v2.png`

- [ ] **Step 1: 2 에셋 병렬 생성**

| ID | 프롬프트 |
|---|---|
| `deco_mainhall_compass_rose_v1` | `decorative marble compass rose inlay on floor, top-down view, brass and gold inlay, transparent background, pixel art 128x128` |
| `obj_door_architecture_v2` | `ornate wooden door with pure gold architectural frame, blueprint and compass engravings, clearly rectangular door shape filling most of the frame, wooden texture, transparent background, pixel art 64x64` |

- [ ] **Step 2: 다운로드 및 저장**

- `compass_rose` → `assets/sprites/environments/main_hall/`
- `door_architecture_v2` → `assets/sprites/objects/doors/`

- [ ] **Step 3: 시각 확인**

- `compass_rose`: top-down 원형, 중앙 기준 대칭, 투명 배경
- `door_architecture_v2`: 명확히 "도어" 형태 (scroll 만 있던 v1 실패 해결 확인). 문제 시 Step 4.

- [ ] **Step 4 (필요 시): door v2 재생성**

문제 있으면 프롬프트에 추가 강제: `rectangular doorway, vertical wooden planks, brass door handle, frame surrounds the door, NOT a scroll, NOT a parchment`.

- [ ] **Step 5: 커밋**

```bash
git add assets/sprites/environments/main_hall/deco_mainhall_compass_rose_v1.png \
        assets/sprites/objects/doors/obj_door_architecture_v2.png
git commit -m "$(cat <<'EOF'
art(art-4b): Phase 2 Batch 2 — compass_rose + obj_door_architecture_v2

- 바닥 중앙 컴퍼스 로즈 (top-down marble inlay)
- architecture 도어 재생성 (v1 scroll-only 문제 해결, 명확한 도어 형태)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 5: `asset_ids.dart` 상수 추가 + 테스트

**Files:**
- Modify: `lib/core/assets/asset_ids.dart`
- Modify: `test/core/assets/asset_ids_test.dart`

- [ ] **Step 1: 테스트 먼저 — 신규 상수 존재 검증 (실패 확인용)**

`test/core/assets/asset_ids_test.dart` 의 `EnvironmentAssets — 3 parallax 레이어` 그룹을 다음으로 대체:

```dart
  group('EnvironmentAssets — art-4b 중앙 홀 base', () {
    test('mainhallBase 경로 assets/sprites/environments/main_hall/ 하위', () {
      expect(
        EnvironmentAssets.mainhallBase,
        'assets/sprites/environments/main_hall/env_mainhall_base_v1.png',
      );
    });

    test('deprecated parallax 상수는 여전히 참조 가능 (호환성 유지)', () {
      // art-4b 에서 deprecated 표시. art-5 일괄 삭제 전까지 유지.
      expect(EnvironmentAssets.mainhallBgFar, contains('bg_far'));
      expect(EnvironmentAssets.mainhallBgMid, contains('bg_mid'));
      expect(EnvironmentAssets.mainhallBgNear, contains('bg_near'));
    });

    test('4 wing 배경 각각 far/mid/near', () {
      const wings = ['backend', 'database', 'frontend', 'architecture'];
      const assets = [
        EnvironmentAssets.backendBgFar,
        EnvironmentAssets.databaseBgFar,
        EnvironmentAssets.frontendBgFar,
        EnvironmentAssets.architectureBgFar,
      ];
      for (var i = 0; i < wings.length; i++) {
        expect(assets[i], contains('${wings[i]}_wing'));
        expect(assets[i], contains('bg_far'));
      }
    });
  });

  group('MainHallDecoAssets — art-4b 조립식 오버레이', () {
    test('pillar / chandelier / compass_rose 경로', () {
      expect(
        MainHallDecoAssets.pillar,
        'assets/sprites/environments/main_hall/deco_mainhall_pillar_v1.png',
      );
      expect(
        MainHallDecoAssets.chandelier,
        'assets/sprites/environments/main_hall/deco_mainhall_chandelier_v1.png',
      );
      expect(
        MainHallDecoAssets.compassRose,
        'assets/sprites/environments/main_hall/deco_mainhall_compass_rose_v1.png',
      );
    });

    test('entrance_arch 4 분관 색 구분', () {
      expect(
        MainHallDecoAssets.entranceArchBackend,
        contains('entrance_arch_backend'),
      );
      expect(
        MainHallDecoAssets.entranceArchDatabase,
        contains('entrance_arch_database'),
      );
      expect(
        MainHallDecoAssets.entranceArchFrontend,
        contains('entrance_arch_frontend'),
      );
      expect(
        MainHallDecoAssets.entranceArchArchitecture,
        contains('entrance_arch_architecture'),
      );
    });
  });
```

또한 `ObjectAssets` 그룹이 있다면 `doorArchitecture` 가 v2 경로인지 단언 추가 (없으면 신규 추가):

```dart
  group('ObjectAssets — art-4b door v2', () {
    test('doorArchitecture 는 v2 로 업그레이드됨', () {
      expect(
        ObjectAssets.doorArchitecture,
        'assets/sprites/objects/doors/obj_door_architecture_v2.png',
      );
    });
  });
```

또한 `파일명 v1 suffix 일관성` 테스트에서 `doorArchitecture` 항목은 `_v2.png` endsWith 로 예외 처리 필요 — 해당 테스트를 다음으로 수정:

```dart
  group('파일명 버전 suffix 일관성', () {
    test('v1 또는 v2 suffix 로 끝난다', () {
      final ids = <String>[
        AnchorAssets.character,
        AnchorAssets.environment,
        AnchorAssets.object,
        UiAssets.frameDialog,
        UiAssets.buttonPrimaryIdle,
        PortraitAssets.wizard,
        CharacterAssets.wizardIdle,
        EnvironmentAssets.mainhallBase,
        MainHallDecoAssets.pillar,
        ObjectAssets.doorBackend,
        ObjectAssets.doorArchitecture,
        TilesetAssets.commonFloor,
        VfxAssets.dustAmbient,
      ];
      for (final id in ids) {
        expect(
          id.endsWith('_v1.png') || id.endsWith('_v2.png'),
          isTrue,
          reason: 'failed on $id',
        );
      }
    });
  });
```

- [ ] **Step 2: 테스트 실행 — 실패 확인**

```bash
flutter test test/core/assets/asset_ids_test.dart
```

Expected: 컴파일 오류 "undefined identifier: MainHallDecoAssets" 등. 아직 상수 추가 전.

- [ ] **Step 3: `asset_ids.dart` 에 상수 추가**

`EnvironmentAssets` 클래스 내부, `// Main Hall (art-4) — 3 parallax layers` 주석 위에 추가:

```dart
  // Main Hall (art-4b) — opaque full-shot base
  static const mainhallBase =
      'assets/sprites/environments/main_hall/env_mainhall_base_v1.png';
```

`mainhallBgFar/Mid/Near` 세 상수 앞에 deprecated 주석:

```dart
  // Main Hall (art-4) — 3 parallax layers
  // NOTE(art-4b): deprecated. `mainhallBase` + `MainHallDecoAssets` 로 대체.
  // art-5 일괄 삭제 예정까지 호환성 유지.
  @Deprecated('Use MainHallDecoAssets + mainhallBase. Remove in art-5.')
  static const mainhallBgFar =
      'assets/sprites/environments/main_hall/env_mainhall_bg_far_v1.png';
  @Deprecated('Use MainHallDecoAssets + mainhallBase. Remove in art-5.')
  static const mainhallBgMid =
      'assets/sprites/environments/main_hall/env_mainhall_bg_mid_v1.png';
  @Deprecated('Use MainHallDecoAssets + mainhallBase. Remove in art-5.')
  static const mainhallBgNear =
      'assets/sprites/environments/main_hall/env_mainhall_bg_near_v1.png';
```

`EnvironmentAssets` 바로 뒤에 신규 클래스 추가:

```dart
// ── Main Hall Decorations (art-4b) ────────────────────────────────────
// 중앙 홀 opaque base 위에 올리는 transparent overlay 에셋.
// base 는 `EnvironmentAssets.mainhallBase` 사용.
// art-4 의 3층 parallax 가 create_map_object 투명 강제로 붕괴된 문제를
// 조립식 opaque base + transparent overlay 로 해결 (art-4b).
class MainHallDecoAssets {
  const MainHallDecoAssets._();

  // 좌·우 mirror 재사용. Flame SpriteComponent.scale = Vector2(-1, 1) 로 반전.
  static const pillar =
      'assets/sprites/environments/main_hall/deco_mainhall_pillar_v1.png';

  // 4 분관 문 뒤 배치. 지배색 glow 프레임 (Bible §1.3).
  static const entranceArchBackend =
      'assets/sprites/environments/main_hall/deco_mainhall_entrance_arch_backend_v1.png';
  static const entranceArchDatabase =
      'assets/sprites/environments/main_hall/deco_mainhall_entrance_arch_database_v1.png';
  static const entranceArchFrontend =
      'assets/sprites/environments/main_hall/deco_mainhall_entrance_arch_frontend_v1.png';
  static const entranceArchArchitecture =
      'assets/sprites/environments/main_hall/deco_mainhall_entrance_arch_architecture_v1.png';

  // 천장 중앙 샹들리에. art-8 폴리시에서 빛 파티클 추가 예정.
  static const chandelier =
      'assets/sprites/environments/main_hall/deco_mainhall_chandelier_v1.png';

  // 바닥 중앙 원형 인레이.
  static const compassRose =
      'assets/sprites/environments/main_hall/deco_mainhall_compass_rose_v1.png';
}
```

`ObjectAssets.doorArchitecture` 상수 값을 v2 로 교체:

```dart
  // art-4b: v1 (scroll-only 붕괴) → v2 (명확한 도어 형태) 로 업그레이드.
  static const doorArchitecture =
      'assets/sprites/objects/doors/obj_door_architecture_v2.png';
```

- [ ] **Step 4: 테스트 실행 — 통과 확인**

```bash
flutter test test/core/assets/asset_ids_test.dart
```

Expected: 모든 테스트 PASS.

- [ ] **Step 5: flutter analyze — 경고 없는지 확인 (deprecated 사용 경고 포함 예상)**

```bash
flutter analyze
```

Expected: `info: 'mainhallBgFar' is deprecated` 류 경고가 `central_hall_scene.dart` 에서 발생. Task 7 에서 해결될 예정. analyzer error 0 이어야 함.

- [ ] **Step 6: 커밋**

```bash
git add lib/core/assets/asset_ids.dart test/core/assets/asset_ids_test.dart
git commit -m "$(cat <<'EOF'
feat(art-4b): asset_ids — mainhallBase + MainHallDecoAssets + door v2

- EnvironmentAssets.mainhallBase (opaque 풀스크린)
- MainHallDecoAssets: pillar / entrance_arch×4 / chandelier / compass_rose
- ObjectAssets.doorArchitecture v1 → v2 (scroll-only 해결)
- bg_far/mid/near 는 @Deprecated (art-5 삭제 예정)
- 회귀 테스트 9건 추가·교체

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 6: `dol_game.dart` preload id 리스트 갱신

**Files:**
- Modify: `lib/game/dol_game.dart` (lines 33-44)

- [ ] **Step 1: preload ids 리스트 교체**

`lib/game/dol_game.dart` 의 `SpriteRegistry.preload(...)` 블록 내 `ids` 배열을 다음으로 교체:

```dart
    await SpriteRegistry.preload(
      images: images,
      ids: const <String>[
        // art-4b: opaque base + transparent overlay 조립식. 기존 3층 parallax
        // (bg_far/mid/near) 는 create_map_object 투명 강제로 붕괴되어 제거.
        EnvironmentAssets.mainhallBase,
        MainHallDecoAssets.pillar,
        MainHallDecoAssets.entranceArchBackend,
        MainHallDecoAssets.entranceArchDatabase,
        MainHallDecoAssets.entranceArchFrontend,
        MainHallDecoAssets.entranceArchArchitecture,
        MainHallDecoAssets.chandelier,
        MainHallDecoAssets.compassRose,
        // 4 분관 문. architecture 는 v2 로 갱신됨 (상수 레벨 경로 교체).
        ObjectAssets.doorBackend,
        ObjectAssets.doorDatabase,
        ObjectAssets.doorFrontend,
        ObjectAssets.doorArchitecture,
      ],
    );
```

- [ ] **Step 2: flutter analyze**

```bash
flutter analyze
```

Expected: `dol_game.dart` 에서 deprecated 참조 경고 사라짐. analyzer error 0.

- [ ] **Step 3: 커밋**

```bash
git add lib/game/dol_game.dart
git commit -m "$(cat <<'EOF'
feat(art-4b): preload — 신규 조립식 에셋 + 기존 parallax 제거

- SpriteRegistry.preload ids 에서 mainhallBg{Far,Mid,Near} 제거
- mainhallBase + 8 MainHallDecoAssets + 4 doors 로 대체
- 총 12 신규 preload (pillar_right 는 mirror 재사용으로 미포함)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 7: `CentralHallScene.onLoad` 재작성

**Files:**
- Modify: `lib/game/scenes/central_hall_scene.dart`

- [ ] **Step 1: 신규 렌더 로직으로 전체 교체**

`lib/game/scenes/central_hall_scene.dart` 의 파일 전체를 다음으로 교체:

```dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/assets/asset_ids.dart';
import '../components/wing_door_component.dart';
import '../dol_game.dart';
import '../rendering/sprite_registry.dart';

/// 중앙 홀 씬 (art-4b).
///
/// art-4 의 3층 parallax 가 `create_map_object` 투명 강제 제약으로 객체처럼
/// 떠 보이는 붕괴를 해결하기 위해 opaque base + transparent overlay 조립식으로
/// 재구성. 렌더 스택 (뒤→앞):
///
///   1. fallback 단색 (SpriteRegistry 로드 실패 대비)
///   2. env_mainhall_base (opaque 풀스크린)
///   3. deco_pillar (좌·우 mirror)
///   4. deco_entrance_arch × 4 (도어 뒤, scale 1.25 로 도어 외곽 glow)
///   5. deco_chandelier + deco_compass_rose (중앙 고정 장식)
///   6. WingDoorComponent × 4 (상호작용)
///
/// 각 레이어마다 `SpriteRegistry.has(...)` 로 로드 여부 확인. 누락 시 해당
/// 레이어 skip (fallback 단색 bg 가 그대로 노출).
class CentralHallScene extends Component with HasGameReference<DolGame> {
  @override
  Future<void> onLoad() async {
    final size = game.size;

    // 1. Fallback 단색 (base 스프라이트 로드 실패 시 노출).
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFF1A1420),
    ));

    // 2. env_mainhall_base (opaque 풀스크린).
    if (SpriteRegistry.has(EnvironmentAssets.mainhallBase)) {
      add(SpriteComponent(
        sprite: Sprite(SpriteRegistry.get(EnvironmentAssets.mainhallBase)),
        size: size,
        paint: Paint()..filterQuality = FilterQuality.none,
      ));
    }

    // 3. Pillars — 좌·우 mirror.
    _addPillars(size);

    // 4. Entrance arches — 각 도어 뒤에 배치, scale 1.25 로 glow 확장.
    _addEntranceArches(size);

    // 5. 중앙 장식 — 샹들리에(위) + 컴퍼스 로즈(아래).
    _addCenterDecorations(size);

    // 6. 4 분관 문.
    _addWingDoors(size);
  }

  void _addPillars(Vector2 size) {
    if (!SpriteRegistry.has(MainHallDecoAssets.pillar)) return;
    final sprite = Sprite(SpriteRegistry.get(MainHallDecoAssets.pillar));
    final pillarSize = Vector2(size.x * 0.08, size.y * 0.8);
    final paint = Paint()..filterQuality = FilterQuality.none;

    // Left pillar
    add(SpriteComponent(
      sprite: sprite,
      size: pillarSize,
      position: Vector2(size.x * 0.05, size.y * 0.1),
      paint: paint,
    ));

    // Right pillar — horizontal mirror.
    add(SpriteComponent(
      sprite: sprite,
      size: pillarSize,
      position: Vector2(size.x * 0.95, size.y * 0.1),
      anchor: Anchor.topRight,
      scale: Vector2(-1, 1),
      paint: paint,
    ));
  }

  void _addEntranceArches(Vector2 size) {
    // 4 도어 위치와 1:1 매칭. 도어 좌표 계산은 `_addWingDoors` 와 동일.
    final doorWidth = size.x / 5;
    final doorHeight = size.y * 0.3;
    final y = size.y * 0.4;

    final archAssets = <String>[
      MainHallDecoAssets.entranceArchBackend,
      MainHallDecoAssets.entranceArchFrontend,
      MainHallDecoAssets.entranceArchDatabase,
      MainHallDecoAssets.entranceArchArchitecture,
    ];

    for (var i = 0; i < archAssets.length; i++) {
      final archId = archAssets[i];
      if (!SpriteRegistry.has(archId)) continue;
      final x = (i + 0.5) * (size.x / 4) - doorWidth / 2;
      // scale 1.25 로 도어 64×64 외곽에 ~8px glow 띠 노출. 중앙 정렬.
      final archSize = Vector2(doorWidth * 1.25, doorHeight * 1.25);
      final offsetX = (doorWidth - archSize.x) / 2;
      final offsetY = (doorHeight - archSize.y) / 2;
      add(SpriteComponent(
        sprite: Sprite(SpriteRegistry.get(archId)),
        size: archSize,
        position: Vector2(x + offsetX, y + offsetY),
        paint: Paint()..filterQuality = FilterQuality.none,
      ));
    }
  }

  void _addCenterDecorations(Vector2 size) {
    // Chandelier — 화면 상단 중앙.
    if (SpriteRegistry.has(MainHallDecoAssets.chandelier)) {
      final chSize = Vector2(size.x * 0.2, size.y * 0.25);
      add(SpriteComponent(
        sprite: Sprite(SpriteRegistry.get(MainHallDecoAssets.chandelier)),
        size: chSize,
        position: Vector2((size.x - chSize.x) / 2, size.y * 0.02),
        paint: Paint()..filterQuality = FilterQuality.none,
      ));
    }

    // Compass rose — 화면 하단 중앙.
    if (SpriteRegistry.has(MainHallDecoAssets.compassRose)) {
      final crSize = Vector2(size.x * 0.2, size.y * 0.15);
      add(SpriteComponent(
        sprite: Sprite(SpriteRegistry.get(MainHallDecoAssets.compassRose)),
        size: crSize,
        position: Vector2((size.x - crSize.x) / 2, size.y * 0.82),
        paint: Paint()..filterQuality = FilterQuality.none,
      ));
    }
  }

  void _addWingDoors(Vector2 size) {
    final wings = <(String, String, Color, String)>[
      (
        'backend',
        '마법사의 탑',
        const Color(0xFF7B68EE),
        ObjectAssets.doorBackend,
      ),
      (
        'frontend',
        '기계공의 작업장',
        const Color(0xFFFF6347),
        ObjectAssets.doorFrontend,
      ),
      (
        'database',
        '연금술사의 실험실',
        const Color(0xFF2E8B57),
        ObjectAssets.doorDatabase,
      ),
      (
        'architecture',
        '건축가의 설계실',
        const Color(0xFF9370DB),
        ObjectAssets.doorArchitecture,
      ),
    ];

    final doorWidth = size.x / 5;
    final doorHeight = size.y * 0.3;
    final y = size.y * 0.4;

    for (var i = 0; i < wings.length; i++) {
      final (id, name, color, spriteId) = wings[i];
      final x = (i + 0.5) * (size.x / 4) - doorWidth / 2;
      add(WingDoorComponent(
        wingId: id,
        label: name,
        color: color,
        spriteId: spriteId,
        position: Vector2(x, y),
        size: Vector2(doorWidth, doorHeight),
      ));
    }
  }
}
```

**주의**: `_addEntranceArches` 의 arch 순서 배열이 `_addWingDoors` 의 wings 순서(`backend`, `frontend`, `database`, `architecture`) 와 일치해야 동일 인덱스에 매칭됨. 위 코드는 올바르게 매칭.

- [ ] **Step 2: flutter analyze**

```bash
flutter analyze
```

Expected: deprecated 경고 0 (parallax 상수 참조 제거됨), error 0.

- [ ] **Step 3: 커밋**

```bash
git add lib/game/scenes/central_hall_scene.dart
git commit -m "$(cat <<'EOF'
feat(art-4b): CentralHallScene — 조립식 렌더 스택 재작성

- 3층 parallax for 루프 제거
- 렌더 스택: fallback → base → pillars×2 → entrance_arch×4 → chandelier + compass → doors×4
- pillar 는 좌·우 mirror 재사용 (scale = Vector2(-1, 1))
- entrance_arch 는 도어 좌표와 1:1 매칭, scale 1.25 로 glow 외곽 노출
- 각 레이어 SpriteRegistry.has() 로 누락 시 skip

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 8: 로컬 검증 — analyze + chrome 시각 확인

**Files:** 변경 없음 (검증만)

- [ ] **Step 1: flutter pub get**

```bash
flutter pub get
```

Expected: `Got dependencies!` (이미 최신이면 `Resolving dependencies...` 후 빠르게 종료).

- [ ] **Step 2: flutter analyze 전체**

```bash
flutter analyze
```

Expected: `No issues found!` 또는 기존 프로젝트 베이스라인 경고만. error 0.

- [ ] **Step 3: 기존 테스트 전체 실행**

```bash
flutter test
```

Expected: 모든 테스트 PASS. 실패 시 원인 조사 (신규 asset_ids 변경이 다른 테스트 깨뜨리진 않는지).

- [ ] **Step 4: 로컬 Chrome 빌드·실행**

```bash
flutter run -d chrome --web-port 5555
```

- [ ] **Step 5: 중앙 홀 시각 체크리스트**

브라우저에서 `http://localhost:5555`:

- [ ] 타이틀 씬 → PRESS TO START → 중앙 홀 진입
- [ ] 중앙 홀이 opaque 배경으로 꽉 찬다 (단색 fallback 아닌 실제 bg 이미지)
- [ ] 좌·우 기둥 보인다
- [ ] 4 도어 뒤로 분관별 지배색 glow 띠 보인다 (green/amber/prismatic/gold)
- [ ] 상단 중앙 샹들리에 + 하단 중앙 컴퍼스 로즈 보인다
- [ ] 각 도어 클릭 → 해당 wing 씬으로 전환 (콜백 작동)
- [ ] architecture 도어가 "도어" 형태 (scroll 아님)
- [ ] 라벨("마법사의 탑" 등) 이 도어 중앙에 가독성 있게 표시

실패 항목 있으면 원인 조사:
- 이미지 미로드 → `SpriteRegistry.preload` id 리스트 확인
- 좌표 이상 → `central_hall_scene.dart` 위치 계수 조정
- 시각 품질 이상 → 해당 에셋 재생성 (Task 3·4 참조)

- [ ] **Step 6: Ctrl+C 로 dev 서버 종료**

Task 8 에서는 커밋할 코드 변경 없음 (검증만). 시각 검증 결과는 PR body 에 기록.

---

## Task 9: 문서 갱신

**Files:**
- Modify: `docs/pixel-art/PIXEL_ART_PROGRESS.md`
- Modify: `docs/pixel-art/PIXEL_ART_ASSET_MANIFEST.md`

- [ ] **Step 1: `PIXEL_ART_PROGRESS.md` 에 art-4b 섹션 추가**

파일 말미에 새 섹션 append:

```markdown
## art-4b — 중앙 홀 풀샷 재작업 (조립식)

**상태**: 완료 (2026-04-24)
**PR**: #(TBD — 병합 후 업데이트)

### 변경

art-4 의 3층 parallax 가 `create_map_object` 투명 강제로 객체처럼 떠 보이는 붕괴를 해결.

- env_mainhall_base (opaque 풀스크린, Phase 1 opacity 게이트 PASS)
- deco_pillar (좌·우 mirror 재사용)
- deco_entrance_arch × 4 (지배색 glow 프레임)
- deco_chandelier + deco_compass_rose (중앙 장식)
- obj_door_architecture v1 → v2 (scroll-only 문제 해결)

### API call

- art-4b: 9 call (base 1 + pillar 1 + arch 4 + chandelier 1 + compass 1 + arch_door_v2 1)
- **누적**: 22 + 9 = **31 / 1000** (잉여 969)
```

- [ ] **Step 2: `PIXEL_ART_ASSET_MANIFEST.md` 에 신규 에셋 등록**

해당 문서의 "Environments" 또는 "Main Hall" 섹션에 다음 추가 (파일 구조에 맞춰 조정):

```markdown
### art-4b 중앙 홀 조립식 (2026-04-24)

| 파일 | 사이즈 | 역할 |
|---|---|---|
| `env_mainhall_base_v1.png` | 256×256 | opaque 풀스크린 bg |
| `deco_mainhall_pillar_v1.png` | 64×64 | 기둥 (좌·우 mirror) |
| `deco_mainhall_entrance_arch_{backend,database,frontend,architecture}_v1.png` | 64×64 × 4 | 지배색 glow 프레임 |
| `deco_mainhall_chandelier_v1.png` | 128×128 | 천장 샹들리에 |
| `deco_mainhall_compass_rose_v1.png` | 128×128 | 바닥 인레이 |
| `obj_door_architecture_v2.png` | 64×64 | architecture 도어 재생성 |

`env_mainhall_bg_{far,mid,near}_v1.png` 3종은 `@Deprecated` (art-5 일괄 삭제 예정).
```

- [ ] **Step 3: 커밋**

```bash
git add docs/pixel-art/PIXEL_ART_PROGRESS.md docs/pixel-art/PIXEL_ART_ASSET_MANIFEST.md
git commit -m "$(cat <<'EOF'
docs(art-4b): PROGRESS + MANIFEST — 중앙 홀 조립식 에셋 등록

- 누적 API call 22 → 31/1000
- 신규 8 에셋 + door v2 등록
- bg_{far,mid,near}_v1 deprecated 상태 기록 (art-5 삭제)

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

---

## Task 10: PR 생성 → develop 머지

**Files:** 변경 없음 (git 작업만)

- [ ] **Step 1: 브랜치 push**

```bash
git push -u origin feature/art-4b-central-hall-fullshot
```

- [ ] **Step 2: PR 생성**

```bash
gh pr create --base develop --title "art(art-4b): 중앙 홀 풀샷 재작업 (opaque base + 조립식 overlay)" --body "$(cat <<'EOF'
## 요약

- art-4 의 3층 parallax 가 `create_map_object` 투명 강제로 객체처럼 떠 보이는 붕괴 해결
- opaque `env_mainhall_base` + 8 transparent overlay + v2 arch door 로 조립식 재구성
- API call 9 (Phase 1 base 1 + Phase 2 overlays 7 + door v2 1), 누적 22→31/1000

## 변경

### 에셋 (9 신규)

- `env_mainhall_base_v1` (256×256, opaque 풀스크린 bg — Phase 1 opacity 게이트 PASS)
- `deco_mainhall_pillar_v1` (좌·우 mirror 재사용)
- `deco_mainhall_entrance_arch_{backend,database,frontend,architecture}_v1` × 4 (지배색 glow)
- `deco_mainhall_chandelier_v1` + `deco_mainhall_compass_rose_v1`
- `obj_door_architecture_v2` (v1 scroll-only 문제 해결)

### 코드

- `lib/core/assets/asset_ids.dart` — `EnvironmentAssets.mainhallBase`, 신규 `MainHallDecoAssets` 클래스, `doorArchitecture` v2, parallax 상수 @Deprecated
- `lib/game/dol_game.dart` — preload id 리스트 갱신
- `lib/game/scenes/central_hall_scene.dart` — 조립식 렌더 스택 재작성 (fallback → base → pillars → arches → chandelier + compass → doors)
- `test/core/assets/asset_ids_test.dart` — 회귀 테스트 9건 추가·교체

### 문서

- `PIXEL_ART_PROGRESS.md` art-4b 섹션 + 누적 22→31/1000
- `PIXEL_ART_ASSET_MANIFEST.md` 신규 에셋 등록

## 검증

- [x] `flutter analyze` error 0
- [x] `flutter test` 전부 PASS
- [x] 로컬 Chrome 시각 확인 (중앙 홀 opaque bg, 분관별 glow, 도어 클릭, architecture 도어 형태)
- [ ] 프로덕션 배포 후 `/dql/` URL 재검증 (Task 12)

## 관련 문서

- Spec: `docs/pixel-art/2026-04-24-art-4b-central-hall-redo-design.md`
- Plan: `docs/pixel-art/2026-04-24-art-4b-central-hall-plan.md`
- 선행: #118 (art-4), #120 (base-href hotfix)

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 3: CI 대기 (analyze + test)**

```bash
gh pr checks --watch
```

Expected: 모든 체크 PASS. 실패 시 원인 조사·수정.

- [ ] **Step 4: 자가 리뷰 — 사용자 승인 대기**

사용자에게 PR URL 공유 후 승인 요청. 승인 전 머지 금지.

- [ ] **Step 5: merge to develop**

사용자 승인 후:

```bash
gh pr merge --merge  # merge commit (squash 금지 — 핸드오프 §4.5 정책)
```

- [ ] **Step 6: 로컬 develop 동기화**

```bash
git checkout develop && git pull --ff-only
```

---

## Task 11: Release PR 11차 (develop → master)

**Files:** 변경 없음

- [ ] **Step 1: release 브랜치 없이 직접 PR**

```bash
gh pr create --base master --head develop --title "release(11): art-4b 중앙 홀 풀샷 재작업" --body "$(cat <<'EOF'
## 포함 PR

- #(art-4b PR 번호) — art(art-4b): 중앙 홀 풀샷 재작업 (opaque base + 조립식 overlay)

## 배포 체크리스트

- [ ] GitHub Actions `sync-and-deploy.yml` 성공
- [ ] 배포 URL `https://public-project-area-oragans.github.io/dql/` 에서 중앙 홀 opaque 렌더 확인
- [ ] 4 도어 클릭 → wing 씬 전환 작동
- [ ] architecture 도어 형태 정상 (v2 효과 확인)

## merge 방식

**merge commit** (squash 금지). 핸드오프 §4.5 정책 유지.

🤖 Generated with [Claude Code](https://claude.com/claude-code)
EOF
)"
```

- [ ] **Step 2: CI 대기**

```bash
gh pr checks --watch
```

- [ ] **Step 3: merge commit 으로 머지 (사용자 승인 후)**

```bash
gh pr merge --merge
```

- [ ] **Step 4: master 동기화 + tag 확인**

```bash
git checkout master && git pull --ff-only
git log --oneline -5  # 최상단 merge commit 확인
```

---

## Task 12: Phase 3 — 배포 URL 시각 검증

**Files:** 변경 없음

- [ ] **Step 1: GitHub Actions 배포 완료 대기**

```bash
gh run list --workflow=sync-and-deploy.yml --limit 3
gh run watch  # 최신 run 완료까지 대기
```

Expected: `completed success`.

- [ ] **Step 2: 배포 URL 접속**

브라우저로 `https://public-project-area-oragans.github.io/dql/` 열기. 로딩 확인.

- [ ] **Step 3: 중앙 홀 시각 체크리스트 (Task 8 Step 5 와 동일)**

- [ ] 타이틀 → PRESS TO START → 중앙 홀
- [ ] opaque 풀스크린 bg (단색 fallback 아님)
- [ ] 좌·우 기둥 + 4 도어 entrance glow + 샹들리에 + 컴퍼스 로즈
- [ ] 도어 클릭 → wing 씬 전환
- [ ] architecture 도어 형태 정상
- [ ] 라벨 가독성 — 도어 중앙에 "마법사의 탑" 등 명확

**실패 항목 있으면**:
- 이미지 404: GitHub Pages 캐시 강제 새로고침 (Ctrl+Shift+R)
- 여전히 404: 배포 워크플로 `sync-and-deploy.yml` assets 포함 여부 확인
- 레이아웃 이상: hotfix PR 로 좌표 수정

- [ ] **Step 4: 성공 시 PR 본문에 검증 결과 업데이트**

```bash
gh pr comment <art-4b PR 번호> --body "Phase 3 배포 검증 완료 — 배포 URL `/dql/` 에서 중앙 홀 opaque 렌더 정상. 도어·장식·라벨 모두 의도대로 표시."
```

---

## Task 13: 세션 핸드오프 + CLAUDE.md 갱신

**Files:**
- Create: `docs/handoffs/2026-04-24-session-handoff.md`
- Modify: `CLAUDE.md` (참조 링크 블록)

- [ ] **Step 1: `docs/handoffs/2026-04-24-session-handoff.md` 작성**

기존 핸드오프 (`2026-04-22-session-handoff.md`) 구조 따라 작성:

```markdown
# DOL — 세션 핸드오프 (2026-04-24)

> art-4b 중앙 홀 풀샷 재작업 완료. opaque base + 조립식 overlay 로 3층 parallax 붕괴 해결.

- **작성일**: 2026-04-24
- **master HEAD**: `<11차 merge commit SHA>`
- **develop HEAD**: `= master` (0 ahead, 0 behind)
- **현재 단계**: P0 진행 + 픽셀아트 이주 art-4b 완료 (art-5 착수 대기) + R7 fix-10b 잔량 14 chapter

## 1. 이번 세션 완료분

### 1.1 art-4b — 중앙 홀 풀샷 재작업 (MERGED #<art-4b PR>)

- env_mainhall_base (opaque 풀스크린) + 8 transparent overlay + door v2
- Phase 1 opacity 게이트 PASS (자동 스크립트 `.tmp/check_opacity.py`)
- 누적 API call 22 → 31/1000
- 10.5차 로 프로덕션 시각 붕괴 상태였던 중앙 홀을 정상 복구

### 1.2 배포 릴리즈 11차 (MERGED #<릴리즈 PR>)

merge commit 정책 유지.

## 2. 미처리 잔량 (다음 세션 최우선)

- art-5 분관 배경 + 타일셋 A (backend + database), ~50 call 예상
- fix-10b 잔량: mysql 4ch + msa 10ch + flutter 1ch = 15 chapter

## 3. 체크인 체크리스트

```
[ ] git fetch origin develop master && git pull --ff-only
[ ] docs/handoffs/2026-04-24-session-handoff.md 읽기
[ ] docs/pixel-art/PIXEL_ART_PROGRESS.md 누적 31/1000 확인
[ ] 배포 URL /dql/ 접속 시 중앙 홀 정상 렌더 확인
[ ] 다음 작업: art-5 또는 fix-10b 선택
```

## 4. 기술 교훈

### 4.1 create_map_object opaque 프롬프트 효과

"opaque rectangular background, no transparency, fills entire canvas edge-to-edge" 는 실제로 투명 강제를 우회 가능 (Phase 1 게이트 PASS). 다만 n회 재시도 여부는 세션마다 확인 필요.

### 4.2 조립식 컴포지션 이점

base + overlay 분리로 art-8 폴리시 단계에서 개별 애니메이션·교체 가능. 3층 parallax 보다 유연.

## 5. 참조

- `docs/handoffs/2026-04-22-session-handoff.md` — 직전 세션
- `docs/pixel-art/2026-04-24-art-4b-central-hall-redo-design.md` — art-4b spec
- `docs/pixel-art/2026-04-24-art-4b-central-hall-plan.md` — art-4b plan
```

플레이스홀더 `<...>` 는 실제 값으로 치환.

- [ ] **Step 2: `CLAUDE.md` 최상단 참조 블록 갱신**

기존:
```markdown
- [**세션 핸드오프 (2026-04-22)**](docs/handoffs/2026-04-22-session-handoff.md) — **새 세션 진입 시 최우선 읽기. ...**
```

다음으로 교체:
```markdown
- [**세션 핸드오프 (2026-04-24)**](docs/handoffs/2026-04-24-session-handoff.md) — **새 세션 진입 시 최우선 읽기. art-4b 중앙 홀 풀샷 재작업 완료 · 11차 릴리즈 · art-5 착수 대기.**
- [세션 핸드오프 (2026-04-22)](docs/handoffs/2026-04-22-session-handoff.md) — 직전 세션 (art-4 + 10/10.5차)
```

- [ ] **Step 3: 커밋**

```bash
git add docs/handoffs/2026-04-24-session-handoff.md CLAUDE.md
git commit -m "$(cat <<'EOF'
docs: 2026-04-24 세션 핸드오프 + CLAUDE.md 참조 갱신

- art-4b 중앙 홀 풀샷 재작업 완료 기록
- 11차 릴리즈 배포 + 시각 검증 결과
- 다음 세션 후보: art-5 (분관 배경·타일셋 A) 또는 fix-10b 잔량

Co-Authored-By: Claude Opus 4.7 (1M context) <noreply@anthropic.com>
EOF
)"
```

- [ ] **Step 4: 핸드오프 PR 생성·머지**

```bash
gh pr create --base develop --title "docs: 2026-04-24 세션 핸드오프 + CLAUDE.md 참조 갱신" --body "art-4b 완료 기록 + 다음 세션 체크인 체크리스트"
gh pr checks --watch
# 승인 후
gh pr merge --merge
```

---

## 플랜 자체검증

**Spec coverage 점검**:

| Spec 섹션 | 구현 Task |
|---|---|
| §1.2 성공 기준 1 (corner alpha 255) | Task 2 Step 4 opacity 게이트 |
| §1.2 성공 기준 2 (opaque 풀스크린 + 장식) | Task 12 Step 3 배포 시각 검증 |
| §1.2 성공 기준 3 (도어 클릭 + 라벨) | Task 12 Step 3 체크리스트 |
| §1.2 성공 기준 4 (architecture 도어 형태) | Task 4 Step 4 + Task 12 |
| §1.2 성공 기준 5 (≤ 35 call) | Task 2-4 (9 call) + 재시도 ≤ 6 → 총 ≤ 15 call, 누적 ≤ 37 . 실제 목표 내 |
| §2.1 렌더 스택 | Task 7 `CentralHallScene` 코드 |
| §2.2 좌표 전략 | Task 7 `_addEntranceArches` scale 1.25 |
| §2.3 에셋 로드 파이프라인 | Task 6 `dol_game.dart` preload |
| §3.1-3.2 에셋 리스트 + 프롬프트 | Task 2-4 |
| §3.3 Bible §1.3 지배색 | Task 3 프롬프트 |
| §4.1 코드 수정 | Task 5, 6, 7 |
| §4.3 에셋 파일 | Task 2, 3, 4 |
| §5.1 Phase 1 opacity 게이트 | Task 2 Step 4 |
| §5.2 Phase 2 품질 검사 | Task 3 Step 3, Task 4 Step 3 |
| §5.3 Phase 3 배포 검증 | Task 12 |
| §5.4 롤백 | Task 10 (미머지 시 브랜치 삭제 가능) |
| §5.5 중단·재개 | Task 별 commit 단위 구분 |

**성공 기준 5 예산 재계산**: 정상 경로 9 call. 재시도 예산: Phase 1 ≤3 (+3), Phase 2 단건 재생성 ≤3 (+3). 최악 9 + 6 = 15 call. 누적 22 + 15 = 37. Spec §1.2 의 "≤ 35/1000" 과 2 call 초과 가능. 현실적으로 최악 케이스 발생 확률 낮고, 실제로는 9~12 call 예상. **Spec 기준은 목표치, Plan 은 여유분 포함**. 경계 초과 시 다음 PR 에 이월 가능.

**Placeholder 스캔**: `<art-4b PR 번호>`, `<릴리즈 PR>`, `<11차 merge commit SHA>` — Task 13 Step 1 에서 실제 값으로 치환하도록 플레이스홀더 명시. 의도적 (숫자는 실행 시점에 확정).

**Type 일관성**: `MainHallDecoAssets`, `mainhallBase`, `entranceArchBackend` 등 명칭이 Task 5-7 전체에서 일관. 메서드명 `_addPillars`, `_addEntranceArches`, `_addCenterDecorations`, `_addWingDoors` 모두 Task 7 내 일관.

**Scope**: 단일 PR 로 종결 가능한 크기. art-5 이후 범위 제외.

---

## 참조

- Spec: `docs/pixel-art/2026-04-24-art-4b-central-hall-redo-design.md`
- 선행 핸드오프: `docs/handoffs/2026-04-22-session-handoff.md`
- 픽셀아트 Bible: `docs/pixel-art/PIXEL_ART_ASSET_BIBLE.md`
- PR 선행: #118 (art-4), #120 (base-href hotfix), #122 (핸드오프 2026-04-22)
