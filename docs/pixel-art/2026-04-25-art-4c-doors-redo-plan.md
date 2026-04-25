# art-4c — Doors Redo Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 4 도어 (backend/frontend/database/architecture) 를 base v2 corridor 와 조화하는 arched stone doorway form + keystone accent 로 재생성, 후면 아치 근처 클러스터 배치로 전환.

**Architecture:** PixelLab `background_image` 파라미터로 base 스타일 학습 → 좌표 공식을 순수 함수 (`CentralHallSceneLayout`) 로 추출하여 PNG 무관 TDD → wing scene 은 layout 함수만 호출. 파일럿 1 도어 (backend) 검증 후 일괄 3 도어.

**Tech Stack:** Flutter (Flame), Dart test framework, PixelLab MCP (`mcp__pixellab__create_map_object`), Pillow (`.tmp/check_opacity.py`).

**Spec:** [docs/pixel-art/2026-04-25-art-4c-doors-redo-design.md](2026-04-25-art-4c-doors-redo-design.md)

**선결 조건:** art-4b PR (`feature/art-4b-central-hall-fullshot`) 가 develop 머지 완료, 11차 릴리즈 배포된 상태.

---

## File Structure

| 파일 | 동작 | 책임 |
|---|---|---|
| `lib/game/scenes/central_hall_scene_layout.dart` | **Create** | 도어 transform (size + position) 산출 순수 함수. PNG 무관, 테스트 격리. |
| `test/game/scenes/central_hall_scene_layout_test.dart` | **Create** | layout 함수 단위 테스트 (좌표 공식 검증). |
| `lib/game/scenes/central_hall_scene.dart` | **Modify** | `_addWingDoors` 가 layout 함수를 호출하도록 변경. |
| `lib/core/assets/asset_ids.dart` | **Modify** | door 상수 v1/v2 → v3. |
| `test/core/assets/asset_ids_test.dart` | **Modify** | door v3 assertion 4건 추가. |
| `assets/sprites/objects/doors/obj_door_backend_v3.png` | **Create** | PixelLab Phase 1 산출 (64×96). |
| `assets/sprites/objects/doors/obj_door_frontend_v3.png` | **Create** | PixelLab Phase 2. |
| `assets/sprites/objects/doors/obj_door_database_v3.png` | **Create** | PixelLab Phase 2. |
| `assets/sprites/objects/doors/obj_door_architecture_v3.png` | **Create** | PixelLab Phase 2. |
| `pubspec.yaml` | **Unchanged** | dir-level 등록 (`- assets/sprites/objects/doors/`) 이므로 v3 자동 인식. |
| `docs/pixel-art/PIXEL_ART_PROGRESS.md` | **Modify** | art-4c 섹션 + 누적 갱신. |
| `docs/pixel-art/PIXEL_ART_ASSET_MANIFEST.md` | **Modify** | door v3 4건 등록 + v1/v2 deprecated 주석. |
| `docs/handoffs/2026-04-25-session-handoff.md` | **Create** | 세션 종료 시. |
| `CLAUDE.md` | **Modify** | 핸드오프 참조 갱신. |

---

## Task 1: Pre-flight + 브랜치 진입

**Files:** none (read-only)

- [ ] **Step 1: develop 동기화**

```bash
git checkout develop
git fetch origin develop master
git pull origin develop  # art-4b 머지 후 최신 develop
```

- [ ] **Step 2: feature/art-4c-doors-redo 브랜치 진입 (또는 rebase)**

본 spec 은 이미 `feature/art-4c-doors-redo` 브랜치 `b04dd44` 에 commit 됨. develop 위에 rebase 필요:

```bash
git checkout feature/art-4c-doors-redo
git rebase develop
git status  # clean 확인
```

- [ ] **Step 3: scene.dart 현재 상태 확인 (art-4b 후 baseline)**

Run: `cat lib/game/scenes/central_hall_scene.dart | head -100`

확인사항:
- `_addWingDoors(Vector2 size)` 메서드 존재
- `final doorWidth = size.x / 7;` (현 art-4b 좌표)
- `final doorHeight = size.y * 0.25;`
- `final y = size.y * 0.5;`
- 도어 순서: `backend → frontend → database → architecture`

상이하면 plan 좌표 변경 식 (Task 6) 을 baseline 에 맞춰 조정.

- [ ] **Step 4: pubspec.yaml dir-level 등록 확인**

Run: `grep -A 2 'doors/' pubspec.yaml`

기대 출력:
```
    - assets/sprites/objects/doors/
```

dir-level 이면 Task 5/6 의 새 PNG 는 자동 인식. 만약 파일별 등록이면 Task 7 추가.

- [ ] **Step 5: base v2 corner alpha 재확인**

Run: `python .tmp/check_opacity.py assets/sprites/environments/main_hall/env_mainhall_base_v1.png`

기대 출력: `PASS - corners: [255, 255, 255, 255]`

FAIL 시 plan 중단, base 재생성 (out of scope).

---

## Task 2: 도어 좌표 layout 순수 함수 (TDD)

**Files:**
- Create: `lib/game/scenes/central_hall_scene_layout.dart`
- Test: `test/game/scenes/central_hall_scene_layout_test.dart`

- [ ] **Step 1: 테스트 파일 작성 (RED)**

```dart
// test/game/scenes/central_hall_scene_layout_test.dart
import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dol/game/scenes/central_hall_scene_layout.dart';

void main() {
  group('CentralHallSceneLayout.doorTransforms', () {
    test('4 도어 transform 반환', () {
      final transforms = CentralHallSceneLayout.doorTransforms(Vector2(1100, 720));
      expect(transforms.length, 4);
    });

    test('도어 width = sceneWidth / 11', () {
      final transforms = CentralHallSceneLayout.doorTransforms(Vector2(1100, 720));
      for (final t in transforms) {
        expect(t.size.x, closeTo(100, 0.01)); // 1100 / 11 = 100
      }
    });

    test('도어 height = width * 1.5 (64×96 비율)', () {
      final transforms = CentralHallSceneLayout.doorTransforms(Vector2(1100, 720));
      for (final t in transforms) {
        expect(t.size.y, closeTo(150, 0.01)); // 100 * 1.5 = 150
      }
    });

    test('도어 y = sceneHeight * 0.45', () {
      final transforms = CentralHallSceneLayout.doorTransforms(Vector2(1100, 720));
      for (final t in transforms) {
        expect(t.position.y, closeTo(324, 0.01)); // 720 * 0.45 = 324
      }
    });

    test('도어 x = sceneWidth * [0.32, 0.43, 0.54, 0.65] (등간격 클러스터)', () {
      final transforms = CentralHallSceneLayout.doorTransforms(Vector2(1100, 720));
      final expectedXs = [352.0, 473.0, 594.0, 715.0]; // 1100 * 비율
      for (var i = 0; i < 4; i++) {
        expect(transforms[i].position.x, closeTo(expectedXs[i], 0.01));
      }
    });

    test('도어 인덱스 순서 고정 (i=0 backend, 1 frontend, 2 database, 3 architecture)', () {
      // 인덱스 의미는 사용처에서 보장 — layout 은 4 슬롯만 제공.
      // 본 테스트는 의도 문서화 용 (assertion 없음).
      final transforms = CentralHallSceneLayout.doorTransforms(Vector2(1100, 720));
      expect(transforms.length, 4);
    });
  });
}
```

- [ ] **Step 2: 테스트 실행 (FAIL 확인)**

Run: `flutter test test/game/scenes/central_hall_scene_layout_test.dart`

Expected: 컴파일 에러 또는 "Target of URI doesn't exist" — `central_hall_scene_layout.dart` 미존재.

- [ ] **Step 3: layout 파일 생성 (GREEN)**

```dart
// lib/game/scenes/central_hall_scene_layout.dart
import 'package:flame/components.dart';

/// 중앙 홀 도어 4개의 transform (size + position) 산출.
///
/// art-4c: base v2 의 후면 아치 근처에 4 도어 클러스터 배치.
/// 도어 순서 (인덱스 고정): 0=backend, 1=frontend, 2=database, 3=architecture.
class DoorTransform {
  final Vector2 size;
  final Vector2 position;
  const DoorTransform({required this.size, required this.position});
}

class CentralHallSceneLayout {
  static const double doorWidthRatio = 1 / 11;
  static const double doorAspect = 1.5; // 64×96 PNG 비율
  static const double doorYRatio = 0.45;
  static const List<double> doorXRatios = [0.32, 0.43, 0.54, 0.65];

  static List<DoorTransform> doorTransforms(Vector2 sceneSize) {
    final width = sceneSize.x * doorWidthRatio;
    final height = width * doorAspect;
    final y = sceneSize.y * doorYRatio;

    return [
      for (final xRatio in doorXRatios)
        DoorTransform(
          size: Vector2(width, height),
          position: Vector2(sceneSize.x * xRatio, y),
        ),
    ];
  }
}
```

- [ ] **Step 4: 테스트 실행 (GREEN 확인)**

Run: `flutter test test/game/scenes/central_hall_scene_layout_test.dart`

Expected: `All tests passed!` (5 tests).

- [ ] **Step 5: 커밋**

```bash
git add lib/game/scenes/central_hall_scene_layout.dart \
        test/game/scenes/central_hall_scene_layout_test.dart
git commit -m "feat(art-4c): CentralHallSceneLayout 순수 함수 + 테스트"
```

---

## Task 3: asset_ids 도어 v3 갱신 (TDD)

**Files:**
- Modify: `lib/core/assets/asset_ids.dart`
- Modify: `test/core/assets/asset_ids_test.dart`

- [ ] **Step 1: 기존 asset_ids_test.dart 의 도어 assertion 위치 확인**

Run: `grep -n 'door' test/core/assets/asset_ids_test.dart`

기대: `ObjectAssets.doorBackend` 등 v1/v2 assertion 존재.

- [ ] **Step 2: v3 assertion 으로 수정 (RED)**

기존 4 assertion 을 다음과 같이 변경:

```dart
expect(ObjectAssets.doorBackend, 'obj_door_backend_v3');
expect(ObjectAssets.doorFrontend, 'obj_door_frontend_v3');
expect(ObjectAssets.doorDatabase, 'obj_door_database_v3');
expect(ObjectAssets.doorArchitecture, 'obj_door_architecture_v3');
```

- [ ] **Step 3: 테스트 실행 (FAIL 확인)**

Run: `flutter test test/core/assets/asset_ids_test.dart`

Expected: 4건 FAIL (현 값 v1/v2).

- [ ] **Step 4: asset_ids.dart v3 갱신 (GREEN)**

`lib/core/assets/asset_ids.dart` 의 `ObjectAssets` 내 door 상수 4건 변경:

```dart
class ObjectAssets {
  // ...기존 다른 상수 유지...

  // art-4c: 도어 v3 (base v2 와 매칭되는 arched stone form + keystone accent).
  static const String doorBackend = 'obj_door_backend_v3';
  static const String doorFrontend = 'obj_door_frontend_v3';
  static const String doorDatabase = 'obj_door_database_v3';
  static const String doorArchitecture = 'obj_door_architecture_v3';
}
```

- [ ] **Step 5: 테스트 실행 (GREEN 확인)**

Run: `flutter test test/core/assets/asset_ids_test.dart`

Expected: `All tests passed!`.

- [ ] **Step 6: 전체 테스트 영향 확인**

Run: `flutter test 2>&1 | tail -20`

Expected: layout 테스트 + asset_ids 테스트 PASS, 다른 도어 의존 테스트 영향 점검. scene 컴포넌트 테스트가 도어 sprite 로드를 강제하면 Phase 4 PNG 생성 전까지 RED 가능 — 그 경우 본 task 끝에서는 commit 만 하고 Phase 4 후 재실행.

- [ ] **Step 7: 커밋**

```bash
git add lib/core/assets/asset_ids.dart test/core/assets/asset_ids_test.dart
git commit -m "feat(art-4c): asset_ids door v3 + 테스트 갱신 (PNG 미존재 RED 허용)"
```

---

## Task 4: Phase 1 — 파일럿 backend 도어 생성

**Files:**
- Create: `assets/sprites/objects/doors/obj_door_backend_v3.png`

- [ ] **Step 1: PixelLab 호출 (backend)**

`mcp__pixellab__create_map_object` 호출 1건:

```yaml
description: |
  arched stone doorway with weathered muted gray base,
  prominent deep forest green keystone with glowing rune at top,
  set into corridor wall, perspective view,
  matches library interior style, dark pastel palette,
  pixel art, transparent background
background_image:
  type: path
  path: assets/sprites/environments/main_hall/env_mainhall_base_v1.png
width: 64
height: 96
```

저장 경로: `assets/sprites/objects/doors/obj_door_backend_v3.png`.

429 concurrent 발생 시 재호출 (단건이므로 거의 안전).

- [ ] **Step 2: opacity 검증 (transparent 도어이므로 corner alpha=0 기대)**

Run: `python .tmp/check_opacity.py assets/sprites/objects/doors/obj_door_backend_v3.png`

도어 PNG 는 **투명 배경** 이므로 `.tmp/check_opacity.py` 는 base 검증 용 — 본 단계는 별도 검사:

Run:
```bash
python -c "from PIL import Image; im = Image.open('assets/sprites/objects/doors/obj_door_backend_v3.png').convert('RGBA'); w, h = im.size; print(f'{w}x{h} corners: {[im.getpixel((0,0))[3], im.getpixel((w-1,0))[3], im.getpixel((0,h-1))[3], im.getpixel((w-1,h-1))[3]]}')"
```

Expected:
- 치수: `64x96`
- corners alpha: `[0, 0, 0, 0]` (transparent 배경) — 일부 modeling artifact 로 ≤16 까지 허용.

코너가 불투명이면 도어 본체와 배경이 분리 안 된 것 → 재생성.

- [ ] **Step 3: 육안 검사 (이미지 열어 확인)**

체크리스트:
- [ ] arched form (위가 둥근 아치 모양)
- [ ] 본체가 무광 회색 stone 톤
- [ ] 상단 keystone 에 진초록 + 빛나는 rune 식별 가능
- [ ] base v2 의 어두운 pastel 팔레트와 조화
- [ ] "도어" 로 인식 가능 (책장·창문 등으로 오인되지 않음)

5건 모두 PASS 시 Step 4. 1건이라도 부족하면 Step 5 (재생성).

- [ ] **Step 4: 커밋 (PASS 시)**

```bash
git add assets/sprites/objects/doors/obj_door_backend_v3.png
git commit -m "art(art-4c): Phase 1 파일럿 backend 도어 v3 (background_image 매칭)"
```

다음 Task 5 진행.

- [ ] **Step 5: 재생성 (FAIL 시, ≤ 3회)**

프롬프트 조정 옵션:
- arched form 부족 → `description` 에 "tall narrow arch" 강조
- keystone 식별 어려움 → "large prominent green keystone, glowing brightly"
- 색상 너무 밝음 → "muted forest green, dark tone, low saturation"

3회 재시도 후에도 부족 시:
- option a (form 단순화: wooden door + colored frame) 로 fallback, 사용자 재승인 후 진행
- 사용자 결정 시까지 plan 중단

---

## Task 5: Phase 2 — 일괄 3 도어 생성

**Files:**
- Create: `obj_door_frontend_v3.png` / `obj_door_database_v3.png` / `obj_door_architecture_v3.png`

- [ ] **Step 1: 3 도어 일괄 PixelLab 호출 (parallel ≤ 5 안전)**

각 호출은 Task 4 와 동일 형식, `description` 의 색상만 치환:

| 분관 | `{color}` 치환 |
|---|---|
| frontend | `deep sapphire blue` |
| database | `burnished amber and orange` |
| architecture | `deep amethyst purple` |

3 건이므로 한 메시지에서 3 tool call 동시 발사 (5 parallel 안전 한계 내).

저장 경로:
- `assets/sprites/objects/doors/obj_door_frontend_v3.png`
- `assets/sprites/objects/doors/obj_door_database_v3.png`
- `assets/sprites/objects/doors/obj_door_architecture_v3.png`

- [ ] **Step 2: opacity + 치수 검증 (3건)**

Run:
```bash
for f in frontend database architecture; do
  python -c "from PIL import Image; im = Image.open('assets/sprites/objects/doors/obj_door_${f}_v3.png').convert('RGBA'); w, h = im.size; print(f'${f}: {w}x{h} corners alpha: {[im.getpixel((0,0))[3], im.getpixel((w-1,0))[3], im.getpixel((0,h-1))[3], im.getpixel((w-1,h-1))[3]]}')"
done
```

Expected: 각 `64x96`, corner alpha ≤ 16.

- [ ] **Step 3: 육안 검사 (3건)**

각 도어에 대해 Task 4 Step 3 의 5 체크리스트 적용. 색상은 분관별 keystone 색 식별 가능해야 함.

- [ ] **Step 4: 커밋 (3 도어 모두 PASS 시)**

```bash
git add assets/sprites/objects/doors/obj_door_{frontend,database,architecture}_v3.png
git commit -m "art(art-4c): Phase 2 3 도어 v3 (frontend/database/architecture)"
```

- [ ] **Step 5: 재생성 (FAIL 시 단건만)**

부족한 도어만 재호출. +3 call buffer 내. 모두 통과 후 Step 4 commit.

---

## Task 6: scene.dart 가 layout 함수를 사용하도록 변경

**Files:**
- Modify: `lib/game/scenes/central_hall_scene.dart`

- [ ] **Step 1: 현재 `_addWingDoors` 메서드 위치 확인**

Run: `grep -n '_addWingDoors\|doorWidth\|doorHeight\|wings\b' lib/game/scenes/central_hall_scene.dart`

기대: `_addWingDoors(Vector2 size)` 메서드가 도어 4개 추가하는 부분.

- [ ] **Step 2: `_addWingDoors` 를 layout 함수 사용 형태로 재작성**

기존 코드 (art-4b):
```dart
void _addWingDoors(Vector2 size) {
  final wings = <(String, String, Color, String)>[
    ('backend', '마법사의 탑', const Color(0xFF7B68EE), ObjectAssets.doorBackend),
    ('frontend', '기계공의 작업장', const Color(0xFFFF6347), ObjectAssets.doorFrontend),
    ('database', '연금술사의 실험실', const Color(0xFF2E8B57), ObjectAssets.doorDatabase),
    ('architecture', '건축가의 설계실', const Color(0xFF9370DB), ObjectAssets.doorArchitecture),
  ];

  final doorWidth = size.x / 7;
  final doorHeight = size.y * 0.25;
  final y = size.y * 0.5;

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
```

신규 코드 (art-4c):
```dart
void _addWingDoors(Vector2 size) {
  final wings = <(String, String, Color, String)>[
    ('backend', '마법사의 탑', const Color(0xFF7B68EE), ObjectAssets.doorBackend),
    ('frontend', '기계공의 작업장', const Color(0xFFFF6347), ObjectAssets.doorFrontend),
    ('database', '연금술사의 실험실', const Color(0xFF2E8B57), ObjectAssets.doorDatabase),
    ('architecture', '건축가의 설계실', const Color(0xFF9370DB), ObjectAssets.doorArchitecture),
  ];

  final transforms = CentralHallSceneLayout.doorTransforms(size);

  for (var i = 0; i < wings.length; i++) {
    final (id, name, color, spriteId) = wings[i];
    add(WingDoorComponent(
      wingId: id,
      label: name,
      color: color,
      spriteId: spriteId,
      position: transforms[i].position,
      size: transforms[i].size,
    ));
  }
}
```

- [ ] **Step 3: import 추가**

파일 상단에 다음 import 추가 (다른 import 와 알파벳 순서 맞춰):

```dart
import 'central_hall_scene_layout.dart';
```

- [ ] **Step 4: 클래스 docstring 업데이트**

기존 docstring 의 art-4b 설명 뒤에 art-4c 추가:

```dart
/// 중앙 홀 씬 (art-4b v2 → art-4c).
///
/// art-4c: 도어 4개를 base v2 corridor 와 조화시키기 위해 v3 (arched stone +
/// keystone accent) 로 재생성하고, 후면 아치 근처 클러스터 배치로 전환.
/// 좌표 공식은 `CentralHallSceneLayout` 순수 함수로 추출 (TDD 격리).
///
/// (이하 art-4b 설명 유지)
```

- [ ] **Step 5: 컴파일 확인**

Run: `flutter analyze lib/game/scenes/central_hall_scene.dart`

Expected: `No issues found!` (0 warnings).

- [ ] **Step 6: 커밋**

```bash
git add lib/game/scenes/central_hall_scene.dart
git commit -m "feat(art-4c): scene.dart 가 CentralHallSceneLayout 사용 + 도어 v3"
```

---

## Task 7: 전체 테스트 + analyze

**Files:** none (검증)

- [ ] **Step 1: flutter analyze 전체**

Run: `flutter analyze`

Expected: `No issues found!`. 경고 발생 시 수정 후 재실행.

- [ ] **Step 2: flutter test 전체**

Run: `flutter test 2>&1 | tail -5`

Expected: `All tests passed!` 또는 PASS 카운트 (art-4b 시점 178 + 본 PR 신규 5+4 = 187 정도).

FAIL 시:
- layout 테스트 실패 → Task 2 코드 점검
- asset_ids 테스트 실패 → Task 3 코드 점검
- scene 의존 테스트 실패 → 도어 PNG 누락 (Task 4-5 재확인)

- [ ] **Step 3: 커밋 불필요 (검증 단계)**

---

## Task 8: Headed Chrome 로컬 검증

**Files:** none (시각 검증)

- [ ] **Step 1: 로컬 dev server**

Run (background): `flutter run -d chrome --web-port 5555`

브라우저 자동 열림.

- [ ] **Step 2: 중앙 홀 씬으로 이동**

타이틀 → "도서관 입장" 클릭 → 중앙 홀 진입.

- [ ] **Step 3: 시각 체크리스트**

5건:
- [ ] 4 도어가 base 후면 아치 근처에 클러스터링 (중앙 50% 폭)
- [ ] 도어 모두 arched stone form + keystone 색 식별 가능
- [ ] 도어 hover 시 라벨이 다른 도어와 안 겹침
- [ ] 도어 클릭 시 분관 씬 전환 (기존 동작 유지)
- [ ] 전체 분위기 — base 와 도어가 같은 corridor 에 속한 것처럼 보임

- [ ] **Step 4: 좌표 hotfix (필요 시)**

체크 4건 이상 PASS 면 Task 9 진행. 부족 시 `lib/game/scenes/central_hall_scene_layout.dart` 의 ratio 조정:

| 증상 | 조정 |
|---|---|
| 도어 너무 작음 | `doorWidthRatio = 1/9` 또는 `1/10` |
| 도어 너무 위 | `doorYRatio = 0.5` |
| 도어 좌우 좁음 | `doorXRatios = [0.28, 0.41, 0.55, 0.68]` |
| 4 도어 너무 가까움 | x 간격 +0.02 단위 확장 |

조정 후 hot reload (r 키) 로 즉시 반영. 만족스러우면 Task 7 (테스트 재실행, 좌표 변경 시 layout 테스트도 갱신 필요) 후 Task 9.

- [ ] **Step 5: 좌표 변경 시 layout 테스트 동기 갱신 + commit**

`test/game/scenes/central_hall_scene_layout_test.dart` 의 expected 값 새 ratio 로 업데이트, RED→GREEN 확인.

```bash
git add lib/game/scenes/central_hall_scene_layout.dart \
        test/game/scenes/central_hall_scene_layout_test.dart
git commit -m "fix(art-4c): 도어 클러스터 좌표 hotfix"
```

---

## Task 9: 문서 갱신

**Files:**
- Modify: `docs/pixel-art/PIXEL_ART_PROGRESS.md`
- Modify: `docs/pixel-art/PIXEL_ART_ASSET_MANIFEST.md`

- [ ] **Step 1: PIXEL_ART_PROGRESS.md 갱신**

상단 누적 카운터:
```
- **실 사용 누적**: 33 / 1000  →  37 ~ 41 / 1000  (실제 호출 수로 갱신)
```

art-4c 섹션 추가 (art-4b 섹션 뒤):

```markdown
## art-4c — Doors Redo (DONE)

- 상태: 구현 완료 (PR 대기)
- 생성 에셋: 4 도어 v3 (backend/frontend/database/architecture)
- API 호출: <실제 호출 수>
- 핵심: arched stone doorway form + keystone accent (background_image 참조)
- 코드: `central_hall_scene_layout.dart` (신규) · `central_hall_scene.dart` ·
  `asset_ids.dart` · 테스트 9건 신규/갱신
- 파일:
  - `assets/sprites/objects/doors/obj_door_backend_v3.png` 64×96
  - `assets/sprites/objects/doors/obj_door_frontend_v3.png` 64×96
  - `assets/sprites/objects/doors/obj_door_database_v3.png` 64×96
  - `assets/sprites/objects/doors/obj_door_architecture_v3.png` 64×96
```

- [ ] **Step 2: PIXEL_ART_ASSET_MANIFEST.md 갱신**

기존 door v1/v2 항목에 deprecated 주석:
```markdown
- `obj_door_backend_v1.png` — DEPRECATED (art-4c v3 로 대체)
- `obj_door_backend_v3.png` — 현행 (art-4c)
```

(나머지 3 분관도 동일.)

- [ ] **Step 3: 커밋**

```bash
git add docs/pixel-art/PIXEL_ART_PROGRESS.md \
        docs/pixel-art/PIXEL_ART_ASSET_MANIFEST.md
git commit -m "docs(art-4c): PROGRESS + MANIFEST 갱신 (도어 v3)"
```

---

## Task 10: PR 작성 및 develop 머지

**Files:** none (git/gh)

- [ ] **Step 1: 브랜치 push**

```bash
git push -u origin feature/art-4c-doors-redo
```

- [ ] **Step 2: PR 생성**

```bash
gh pr create --base develop --title "art-4c: 도어 4개 재생성 + 후면 클러스터 배치" --body "$(cat <<'EOF'
## Summary
- 도어 4개 (backend/frontend/database/architecture) 를 base v2 corridor 와 조화하는 arched stone doorway form + keystone accent 로 재생성
- 좌표 공식을 `CentralHallSceneLayout` 순수 함수로 추출 (TDD 격리)
- 후면 아치 근처 클러스터 배치 (`/11` 폭, x[0.32~0.65], y 0.45)

## Verification
- [x] flutter analyze 0 issues
- [x] flutter test all GREEN (layout 5 + asset_ids 4 신규 포함)
- [x] Headed Chrome 로컬 5 체크리스트 PASS
- [ ] 배포 검증 (머지 후)

## Spec / Plan
- spec: `docs/pixel-art/2026-04-25-art-4c-doors-redo-design.md`
- plan: `docs/pixel-art/2026-04-25-art-4c-doors-redo-plan.md`

## API 호출
PixelLab `create_map_object`: 4 base + N 재시도. 누적 33 → <실제>.
EOF
)"
```

- [ ] **Step 3: GitHub Actions 통과 확인**

Run: `gh pr checks --watch` (5-10분).

Expected: analyze + test GREEN.

- [ ] **Step 4: develop 머지 (squash 또는 merge commit, 기존 컨벤션 따라)**

기존 PR 들이 merge commit 유지면:
```bash
gh pr merge --merge --delete-branch
```

- [ ] **Step 5: 11.5차 릴리즈 PR (develop → master)**

```bash
git checkout develop && git pull origin develop
gh pr create --base master --head develop --title "Release 11.5: art-4c 도어 v3" --body "..."
```

머지 후 GitHub Pages 자동 배포 시작.

---

## Task 11: 배포 검증

**Files:** none

- [ ] **Step 1: GitHub Actions 배포 완료 대기**

Run: `gh run list --limit 3` — 최신 deploy run 의 status `completed` 확인.

- [ ] **Step 2: 프로덕션 URL 확인**

브라우저로 `https://public-project-area-oragans.github.io/dql/` 열기.

- [ ] **Step 3: 시각 체크 (Task 8 Step 3 와 동일)**

5건 모두 PASS 면 art-4c 종료.

- [ ] **Step 4: 문제 발생 시 hotfix PR (10.5차 패턴)**

좌표 미세조정 → master 직접 PR (또는 develop → master fast-track).

---

## Task 12: 세션 핸드오프 작성

**Files:**
- Create: `docs/handoffs/2026-04-25-session-handoff.md`
- Modify: `CLAUDE.md` (참조 갱신)

- [ ] **Step 1: 핸드오프 문서 작성**

`docs/handoffs/2026-04-25-session-handoff.md` 신규:

```markdown
# DOL — 세션 핸드오프 (2026-04-25)

> art-4c 도어 v3 재생성 + 후면 클러스터 완료. 11.5차 릴리즈 배포.
> 다음 우선순위: art-5 (분관 배경) 또는 fix-10b 잔량.

- **작성일**: 2026-04-25
- **master HEAD**: <11.5차 릴리즈 commit>
- **develop HEAD**: <art-4c 머지 commit>
- **현재 단계**: P0 진행 + art-4 완전 종결, art-5 착수 가능
- **누적 PixelLab call**: <실제>/1000

## 1. 이번 세션 완료분

### 1.1 docs 재구성 (feature/docs-reorganize, 머지됨)
- 24 docs/*.md 를 5 폴더로 분류 (handoffs/phases/designs/workflows/pixel-art)
- CLAUDE.md, README.md, 모든 cross-reference 갱신

### 1.2 art-4c 도어 v3 재생성 (PR #..., 머지됨)
- 4 도어 arched stone form + keystone accent 로 재생성
- `CentralHallSceneLayout` 순수 함수 추출, TDD 격리
- 후면 클러스터 배치 (`/11`, x[0.32~0.65], y 0.45)

## 2. 미해결 + 다음 세션
- art-5 (분관 배경 + 타일셋 A) 착수 가능
- fix-10b 잔량 (mysql 4ch + msa 10ch + flutter 1ch)
- ...
```

- [ ] **Step 2: CLAUDE.md 핸드오프 참조 갱신**

기존 줄:
```
- [**세션 핸드오프 (2026-04-24)**](docs/handoffs/2026-04-24-session-handoff.md) — ...
```

위에 신규 추가:
```
- [**세션 핸드오프 (2026-04-25)**](docs/handoffs/2026-04-25-session-handoff.md) — **새 세션 진입 시 최우선 읽기. art-4c 도어 v3 + 후면 클러스터 + 11.5차 릴리즈. art-5 착수 대기.**
- [세션 핸드오프 (2026-04-24)](docs/handoffs/2026-04-24-session-handoff.md) — 직전 세션 (art-4b 미완)
```

- [ ] **Step 3: 커밋 + push (develop 직접 또는 별도 docs PR)**

```bash
git checkout develop
git pull origin develop
git checkout -b chore/handoff-2026-04-25
git add docs/handoffs/2026-04-25-session-handoff.md CLAUDE.md
git commit -m "docs: 2026-04-25 세션 핸드오프 + CLAUDE.md 참조 갱신"
git push -u origin chore/handoff-2026-04-25
gh pr create --base develop --title "docs: 2026-04-25 핸드오프" --body "art-4c 종료 기록"
gh pr merge --merge --delete-branch
```

---

## 자체 검증 (Self-Review)

이 plan 작성 후 inline 점검 결과:

1. **Spec coverage**: spec §1-7 모든 항목이 task 1-12 에 매핑됨.
   - §1.1 in-scope 7건 → Task 1-9, 12
   - §2 brand/PR flow → Task 1, 10, 11
   - §3 Asset specs → Task 4-5
   - §4 Code changes → Task 2, 3, 6 (+ TDD 격리는 Task 2 의 layout 함수 추출)
   - §5 Verification gates → Task 4 Step 2-3, Task 5, Task 7-8, Task 11
   - §6 Budget/rollback → Task 4-5 (재시도 buffer), Task 11 Step 4
   - §7 참조 → 본 plan 헤더 + Task 9

2. **Placeholder scan**: 모든 step 에 구체 코드/명령/기대 출력 포함. "TBD"/"TODO" 없음. Task 12 Step 1 의 `<11.5차 릴리즈 commit>` 등 placeholder 는 작성 시점 채울 수 있는 데이터로 의도된 빈칸.

3. **Type consistency**: `CentralHallSceneLayout`, `DoorTransform`, `doorTransforms`, ratio 상수명 모두 Task 2 정의와 Task 6 사용처 일치.

4. **Ambiguity**: PixelLab 결과 품질 변동성 → Task 4 Step 5 + Task 5 Step 5 의 재시도/fallback 명시. 좌표 hotfix 가능성 → Task 8 Step 4 명시.
