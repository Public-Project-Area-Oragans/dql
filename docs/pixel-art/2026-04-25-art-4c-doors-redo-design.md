# art-4c — 도어 4개 재생성 + 후면 클러스터 배치 (Spec)

> art-4b 잔여. base v2 corridor 와 부조화하는 도어 4개 (backend/frontend/database v1 + architecture v2) 를
> `background_image` 참조 기반으로 재생성. **arched stone doorway form + keystone accent** 식별,
> 배치는 후면 아치 근처 클러스터로 전환.

- **작성일**: 2026-04-25
- **선행**: art-4b (`feature/art-4b-central-hall-fullshot`, 8 commits 미푸시) → develop 머지 (현 도어 mismatch 상태 그대로 11차 릴리즈) **선결**
- **본 PR**: 11.5차 릴리즈
- **현 PixelLab 누적**: 33 / 1000, 본 PR 예산 4–8 call, 잉여 ≥ 959

---

## 1. Goal & Scope

### 1.1 In-scope
- 도어 4개 재생성 (`obj_door_{branch}_v3.png`)
- `central_hall_scene.dart` 도어 배치 좌표 변경 (후면 클러스터)
- `asset_ids.dart` 도어 상수 v3 갱신
- 신규 테스트 `central_hall_scene_test.dart` (TDD)
- 기존 `asset_ids_test.dart` v3 assertion 추가
- 문서 갱신 (`PIXEL_ART_PROGRESS.md`, `PIXEL_ART_ASSET_MANIFEST.md`)

### 1.2 Out-of-scope
- base/pillar/arch/chandelier/compass 에셋 — art-4b 결정 유지, 변경 없음
- 분관 씬 (backend/frontend/database/architecture) — art-5 이후
- 도어 hover 라벨 / 클릭 인터랙션 — 기존 로직 재사용

---

## 2. Branch & PR Flow

```
1. feature/art-4b-central-hall-fullshot → PR → develop 머지 (11차 릴리즈, 도어 mismatch 잠시 잔존)
2. develop 에서 feature/art-4c-doors-redo 분기 (본 spec 은 이 브랜치에 commit)
3. Phase 1 파일럿: backend 1 도어 생성 → 검증
4. Phase 2 일괄: frontend / database / architecture 3 도어
5. Phase 3 코드: scene.dart + asset_ids.dart + 테스트 (TDD)
6. Phase 4 검증: flutter test + Headed Chrome 로컬
7. PR → develop → 11.5차 릴리즈 (master)
8. 배포 검증
```

dependency: `feature/docs-reorganize` PR 은 어느 시점이든 독립 머지 가능 (충돌 없음).

---

## 3. Asset Specs

### 3.1 도어 4개

| 에셋 | 분관 | 키스톤 색 (HEX 가이드) | 파일 | 구버전 → 신버전 |
|---|---|---|---|---|
| `obj_door_backend_v3` | backend | 진초록 `#4a7c59` | `assets/sprites/objects/doors/` | v1 → v3 |
| `obj_door_frontend_v3` | frontend | 진청 `#3a6ea5` | 동일 | v1 → v3 |
| `obj_door_database_v3` | database | 황동/주황 `#c0843e` | 동일 | v1 → v3 |
| `obj_door_architecture_v3` | architecture | 진보라 `#7b5d9c` | 동일 | v2 → v3 |

치수: **64×96** (기존 64×64 → 세로 +50%, arched form headroom 확보).

### 3.2 PixelLab 호출 파라미터

`mcp__pixellab__create_map_object` 호출 (4건 모두 동일 형태, `{branch}/{color}` 만 치환):

```yaml
description: |
  arched stone doorway with weathered muted gray base,
  prominent {color} keystone with glowing rune at top,
  set into corridor wall, perspective view,
  matches library interior style, dark pastel palette,
  pixel art, transparent background
background_image:
  type: path
  path: assets/sprites/environments/main_hall/env_mainhall_base_v1.png
width: 64
height: 96
```

분관별 `{color}` 값:
- backend → "deep forest green"
- frontend → "deep sapphire blue"
- database → "burnished amber/orange"
- architecture → "deep amethyst purple"

### 3.3 구버전 PNG 처리

- v1/v2 PNG 파일은 **트리에 보존** (rollback 대비, 코드 참조 없음)
- asset_ids.dart 한 줄 revert 만으로 즉시 복구 가능

---

## 4. Code Changes

### 4.1 `lib/core/assets/asset_ids.dart`

```dart
class ObjectAssets {
  // 기존
  static const String doorBackend = 'obj_door_backend_v3';      // v1 → v3
  static const String doorFrontend = 'obj_door_frontend_v3';    // v1 → v3
  static const String doorDatabase = 'obj_door_database_v3';    // v1 → v3
  static const String doorArchitecture = 'obj_door_architecture_v3'; // v2 → v3
  // ...
}
```

### 4.2 `lib/game/scenes/central_hall_scene.dart`

도어 배치 좌표 공식 변경:

```dart
// art-4b: doorWidth = size.x / 7, doorHeight = size.y * 0.25, y = size.y * 0.5
// art-4c: 후면 아치 근처 클러스터, /11 폭, 64×96 비율
const doorWidthRatio = 1 / 11;       // ≈ 9% width
const doorAspect = 1.5;               // 64×96 → height = width × 1.5
const doorYRatio = 0.45;              // 후면 아치 근처 (이전 0.5 → 0.45)
const doorXRatios = [0.32, 0.43, 0.54, 0.65]; // 중앙 50% 폭 등간격

final doorWidth = size.x * doorWidthRatio;
final doorHeight = doorWidth * doorAspect;
final doorY = size.y * doorYRatio;

// 도어 생성 순서 (인덱스 고정): i=0 backend, 1 frontend, 2 database, 3 architecture
for (var i = 0; i < 4; i++) {
  doors[i].size = Vector2(doorWidth, doorHeight);
  doors[i].position = Vector2(size.x * doorXRatios[i], doorY);
}
```

정확한 `doorXRatios` / `doorYRatio` 는 첫 Headed Chrome 검증 후 ±1-2회 hotfix 가능.

### 4.3 테스트 (TDD)

**신규 `test/game/scenes/central_hall_scene_test.dart`**:
- 4 도어 컴포넌트 생성 검증
- 각 도어 size/position 이 §4.2 공식과 일치 (`closeTo`, tolerance 0.5)
- 4 도어가 v3 asset_id 매핑 (backend/frontend/database/architecture 순)

**테스트 격리 전략**: 좌표 공식을 순수 함수 (예: `CentralHallSceneLayout.doorTransforms(Vector2)`)
로 추출하여 PNG 로드 없이 단위 테스트. Phase 1/2 PNG 생성과 독립적으로 RED→GREEN 가능.

**기존 `test/core/assets/asset_ids_test.dart`** 4건 추가:
```dart
expect(ObjectAssets.doorBackend, 'obj_door_backend_v3');
expect(ObjectAssets.doorFrontend, 'obj_door_frontend_v3');
expect(ObjectAssets.doorDatabase, 'obj_door_database_v3');
expect(ObjectAssets.doorArchitecture, 'obj_door_architecture_v3');
```

TDD 순서: 테스트 작성 → RED → asset_ids/scene 수정 → GREEN.

### 4.4 `pubspec.yaml`

선조사 후 결정:
- 현 등록이 `assets/sprites/objects/doors/` **dir-level** → 변경 없음 (신규 파일 자동 인식)
- 현 등록이 **개별 파일 단위** → 4 PNG 항목 추가 (구버전 v1/v2 항목은 보존)

Phase 3 작업 시 `cat pubspec.yaml | grep doors/` 로 확인.

### 4.5 문서

| 파일 | 변경 |
|---|---|
| `docs/pixel-art/PIXEL_ART_PROGRESS.md` | art-4c 섹션 추가, 누적 33 → 37–41 / 1000 |
| `docs/pixel-art/PIXEL_ART_ASSET_MANIFEST.md` | 4 도어 v3 등록, v1/v2 deprecated 주석 |
| `docs/handoffs/2026-04-25-session-handoff.md` | 세션 종료 시 작성 |
| `CLAUDE.md` | 핸드오프 참조 갱신 |

---

## 5. Verification Gates

| Phase | 검증 | 통과 조건 | 실패 시 |
|---|---|---|---|
| **Phase 1: 파일럿 1 도어 (backend)** | `.tmp/check_opacity.py` (transparent corner) + 육안 (arched form, keystone 식별) | 두 검사 PASS | 프롬프트 강화 ≤ 3회 → 그래도 실패 시 form 단순화 (option a: 팔레트만 매칭) 로 pivot, 사용자 재승인 |
| **Phase 2: 일괄 3 도어** | 동일 (파일별 opacity + 육안) | 4 도어 모두 PASS | 단건 재생성, 색상 키워드만 조정. +3 call buffer |
| **Phase 3: TDD 코드 검증** | `flutter test test/game/scenes/central_hall_scene_test.dart` + `flutter analyze` | 신규 테스트 + 178 기존 테스트 모두 GREEN | 좌표 공식 또는 asset_id 매핑 수정 |
| **Phase 4: Headed Chrome 로컬** | `flutter run -d chrome --web-port 5555` | 4 도어 가시 + 클릭 가능 + 후면 아치와 융합 | scene.dart 좌표 hotfix 1-2회 |
| **Phase 5: 배포 검증** | GitHub Pages 머지 후 URL 확인 | 프로덕션 4 도어 정상 | hotfix PR (10.5차 패턴) |

---

## 6. Budget & Rollback

### 6.1 PixelLab 예산
- Phase 1: 1 call (backend 파일럿)
- Phase 2: 3 call (나머지 3 도어)
- 재시도 buffer: ≤ 4 call (worst case 모든 도어 1회 재생성)
- **합계: 4 ~ 8 call** (현 33 / 1000, 잉여 967)

### 6.2 롤백
- art-4c PR merge **전**: 브랜치 force-push 또는 reset 으로 되감기
- merge **후** 프로덕션 문제: revert PR → master 재배포 (10.5차 hotfix 패턴)
- v1/v2 PNG 보존 → asset_ids 한 줄 revert 만으로 즉시 복구

### 6.3 중단·재개
- Phase 1 통과 후 backend v3 개별 commit → 다음 세션 재개 가능
- Phase 2 batch 도중 중단 시 이미 생성된 PNG 만 commit, 재개 시 미생성분만 진행

---

## 7. 참조

- `docs/handoffs/2026-04-24-session-handoff.md` §2.1 — art-4c 요구사항 원천 (option B → D)
- `docs/pixel-art/2026-04-24-art-4b-central-hall-redo-design.md` — art-4b spec (선행)
- `docs/pixel-art/2026-04-24-art-4b-central-hall-plan.md` — art-4b plan (선행)
- `docs/pixel-art/PIXEL_ART_ASSET_BIBLE.md` §1.3 — 분관별 지배색
- `docs/pixel-art/PIXEL_ART_ASSET_MANIFEST.md` — 기존 에셋 목록
- `docs/pixel-art/PIXEL_ART_PROGRESS.md` — art-* 누적 진행
- `.tmp/check_opacity.py` — Phase 1 opacity 자동 게이트 (재활용)
