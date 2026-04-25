# PIXEL ART MIGRATION PROGRESS

> art-0 ~ art-9 누적 진행 추적. 매 PR 머지 후 본 문서 업데이트.

- **총 PR 수**: 10 (art-0 ~ art-9)
- **총 예상 에셋**: ~120 (Manifest §10.1)
- **총 API 호출 예산**: 1000 call (2026-04-19 사용자 결정, 기존 plan 290 대비 3.5×)
- **실 사용 누적**: 37 / 1000

---

## art-0 — Style Anchors (MERGED)

- 상태: **MERGED (PR #74)**
- 생성 에셋: 3 (character / environment / object 각 v1)
- API 호출: 3
- 파일:
  - `assets/sprites/_anchors/anchor_character_v1.png` 64×96
  - `assets/sprites/_anchors/anchor_environment_v1.png` 256×144
  - `assets/sprites/_anchors/anchor_object_v1.png` 64×64

## art-1 — Rendering Infrastructure (MERGED)

- 상태: **MERGED (PR #75)**
- 생성 에셋: 0 (코드 스캐폴딩 only)
- API 호출: 0
- 산출: `asset_ids.dart` / `sprite_registry.dart` / `nine_slice.dart` / `pixel_nine_slice.dart` / `tool/verify_palette.dart` + 13 테스트

## art-2 — UI Chrome (DONE)

- 상태: 구현 완료 (PR 대기)
- 생성 에셋: 8 (Frame 5 + Button 3상태)
- API 호출: 9 (hover 1회 재시도 포함)
- 참고: PixelLab 이 요청 128×64 / 64×32 대신 128×128 / 64×64 로 생성 → 원본 유지,
  9-slice 인셋 파라미터로 스케일링 해결. 품질 iterate 는 art-2b 로 별도 분리 가능.
- 파일:
  - `assets/sprites/ui/frames/ui_frame_dialog_v1.png` 128×128
  - `assets/sprites/ui/frames/ui_frame_quest_v1.png` 128×128
  - `assets/sprites/ui/frames/ui_frame_book_v1.png` 128×128
  - `assets/sprites/ui/frames/ui_frame_panel_v1.png` 128×128
  - `assets/sprites/ui/frames/ui_frame_code_terminal_v1.png` 128×128
  - `assets/sprites/ui/buttons/ui_button_primary_v1.png` 64×64
  - `assets/sprites/ui/buttons/ui_button_primary_hover_v1.png` 64×64
  - `assets/sprites/ui/buttons/ui_button_primary_pressed_v1.png` 64×64
- 코드: `steampunk_panel.dart` · `steampunk_button.dart` · `dialogue_overlay.dart` ·
  `quest_board_overlay.dart` · `asset_ids.dart` (prefix 버그 수정) · `pubspec.yaml` ·
  `asset_ids_test.dart` · `structure_assembly_simulator_test.dart`.

## art-3 — Title Scene (DONE)

- 상태: 구현 완료 (PR 대기)
- 생성 에셋: 2 (배경 + 로고 — press start / github icon 은 Flutter 네이티브 텍스트로 대체)
- API 호출: 2
- 파일:
  - `assets/sprites/environments/title/env_title_bg_v1.png` 256×256 (요청 256×144, PixelLab 이 정사각으로 생성 — cover fit 으로 흡수)
  - `assets/sprites/ui/logos/ui_logo_title_v1.png` 256×256 (요청 256×128, 상동)
- 코드: `lib/presentation/screens/title_screen.dart` (신설) · `lib/core/router/app_router.dart` (`/` → Title) · `lib/core/assets/asset_ids.dart` (`UiAssets.logoTitle` + `EnvironmentAssets.titleBg` prefix 버그 수정) · `pubspec.yaml`.
- Manifest §1.3 "타이틀 로고 Flutter 정적 이미지" 준수 — Flame 씬 미개입.
- 알려진 이슈: `verify_palette.dart` fail (AA 엣지로 16색 외 색상). art-2 와 동일 패턴 — art-9 폴리시 단계에서 quantize 처리 예정.

## art-4 — Central Hall + Wing Doors (DONE)

- 상태: 구현 완료 (PR 대기)
- 생성 에셋: 7 (main hall 3층 parallax + 4 분관 문)
- API 호출: 8 (architecture 도어 1회 concurrent job 429 → 재시도 성공)
- 파일:
  - `assets/sprites/environments/main_hall/env_mainhall_bg_far_v1.png` 256×256 (요청 256×144, PixelLab 이 정사각으로 생성 — art-3 동일 패턴)
  - `assets/sprites/environments/main_hall/env_mainhall_bg_mid_v1.png` 256×256
  - `assets/sprites/environments/main_hall/env_mainhall_bg_near_v1.png` 256×256
  - `assets/sprites/objects/doors/obj_door_backend_v1.png` 64×64 (요청 64×96 → 정사각)
  - `assets/sprites/objects/doors/obj_door_database_v1.png` 64×64
  - `assets/sprites/objects/doors/obj_door_frontend_v1.png` 64×64
  - `assets/sprites/objects/doors/obj_door_architecture_v1.png` 64×64
- 코드: `central_hall_scene.dart` (3층 parallax + 분관 문 스프라이트 id 주입), `wing_door_component.dart` (`RectangleComponent` → `PositionComponent` + `SpriteComponent` child + fallback rect), `dol_game.dart` (`images.prefix = ''` + preload 리스트 확장), `asset_ids.dart` (prefix 버그 `sprites/` → `assets/sprites/`), `pubspec.yaml` (2 디렉토리 선언).
- 분관별 색상: Bible §1.3 적용 — backend=green steam, database=amber, frontend=prism(gold+cyan), architecture=pure gold. 기존 코드 라벨(마법사의 탑 등)은 유지.
- art-2b 에서 선취된 hover/pressed ColorFilter 가 `SpriteComponent` 에도 그대로 적용됨 (`TappableComponent` 믹스인의 `saveLayer` 가 자식 트리 전체를 감쌈).
- 알려진 이슈: `verify_palette.dart` fail (AA 엣지로 16색 외 색상) — art-2/3 동일 패턴. art-9 폴리시 단계에서 quantize 처리 예정.

## art-4b — Central Hall Fullshot Redo (DONE)

- 상태: 머지됨 (PR #124)
- 생성 에셋: 9 (env_mainhall_base v2 + deco_pillar + deco_entrance_arch ×4 + deco_chandelier + deco_compass_rose + obj_door_architecture v2)
- API 호출: 11 (base v1 1 + base v2 1 + pillar 1 + arch ×4 + chandelier 1 (concurrent 429 retry 포함) + compass 1 + door_architecture v2 1)
- 핵심: art-4 의 3층 parallax 가 `create_map_object` 투명 강제로 객체처럼 떠 보이는 프로덕션 붕괴 해소. opaque base v2 (steampunk corridor) + 4 도어 overlay 단순화 (overlay 자산은 보존, art-8 폴리시에서 재활용).
- 알려진 한계: 도어 4개 스타일이 base v2 의 어두운 pastel 팔레트와 부조화 + 2D 평면 배치가 base 3D corridor 원근감과 mismatch — art-4c 에서 해소.
- 코드: `lib/game/scenes/central_hall_scene.dart` (조립식 렌더 스택 재작성) · `lib/core/assets/asset_ids.dart` (`MainHallDecoAssets` 클래스 신규 + `mainhallBase`) · `lib/game/dol_game.dart` (preload 12 신규 상수). 178 테스트 모두 GREEN.
- 파일:
  - `assets/sprites/environments/main_hall/env_mainhall_base_v1.png` 256×256 (실 콘텐츠 v2 — 빈 corridor)
  - `assets/sprites/environments/main_hall/deco_pillar.png` (overlay 자산, 현 단계 미사용)
  - `assets/sprites/environments/main_hall/deco_entrance_arch_{backend,database,frontend,architecture}.png` ×4
  - `assets/sprites/environments/main_hall/deco_chandelier.png`
  - `assets/sprites/environments/main_hall/deco_compass_rose.png`
  - `assets/sprites/objects/doors/obj_door_architecture_v2.png` 64×64

## art-4c — Doors Redo + Cluster Layout (DONE)

- 상태: 구현 완료 (PR 대기)
- 생성 에셋: 4 (obj_door_{backend,frontend,database,architecture} v3)
- API 호출: 4 (Phase 1 backend 파일럿 1 + Phase 2 일괄 3, 재시도 0)
- 핵심: 도어 4개를 arched stone doorway form + keystone accent 로 재생성하여 base v2 corridor 와 조화. 좌표 공식을 `CentralHallSceneLayout` 순수 함수로 추출 (TDD 격리). 후면 아치 근처 클러스터 배치 (`/8` 폭, x 중심점 [0.25, 0.42, 0.58, 0.75], y 0.45). 라벨을 도어 위 반투명 plaque + JetBrainsMonoHangul 폰트로 분리 (한글 가독성).
- 코드: `lib/game/scenes/central_hall_scene_layout.dart` (신규) · `lib/game/scenes/central_hall_scene.dart` (layout 함수 사용) · `lib/core/assets/asset_ids.dart` (도어 4개 v3) · `lib/game/components/wing_door_component.dart` (라벨 plaque + Hangul 폰트) · `pubspec.yaml` (JetBrainsMonoHangul 폰트 등록). 184 테스트 GREEN.
- 파일:
  - `assets/sprites/objects/doors/obj_door_backend_v3.png` 64×96 (deep forest green keystone)
  - `assets/sprites/objects/doors/obj_door_frontend_v3.png` 64×96 (deep sapphire blue)
  - `assets/sprites/objects/doors/obj_door_database_v3.png` 64×96 (burnished amber)
  - `assets/sprites/objects/doors/obj_door_architecture_v3.png` 64×96 (deep amethyst purple)
  - `assets/fonts/JetBrainsMonoHangul-Regular.ttf` ~2.6MB (SIL OFL 1.1)
  - `assets/fonts/JetBrainsMonoHangul-Bold.ttf` ~2.6MB
- 발견 사항: PixelLab `create_map_object` 가 metadata 에 64×64 로 표시하지만 실제 다운로드 PNG 는 64×96 (요청 그대로). 후속 art-* 에서 metadata 값 신뢰 말고 PIL 직접 검증.

## art-5 ~ art-9 (TODO)

- 미착수

---

## 누적 집계

| 단계 | 상태 | 에셋 | API call | 누적 에셋 | 누적 call |
|---|---|---|---|---|---|
| art-0 | ✅ MERGED | 3 | 3 | 3 | 3 |
| art-1 | ✅ MERGED | 0 | 0 | 3 | 3 |
| art-2 | ✅ DONE | 8 | 9 | 11 | 12 |
| art-3 | ✅ DONE | 2 | 2 | 13 | 14 |
| art-4 | ✅ DONE | 7 | 8 | 20 | 22 |
| art-4b | ✅ MERGED | 9 | 11 | 29 | 33 |
| art-4c | ✅ DONE | 4 | 4 | 33 | 37 |
| art-5 | - | ~35 | ~50 | — | — |
| art-6 | - | ~35 | ~50 | — | — |
| art-7 | - | ~28 | ~40 | — | — |
| art-8 | - | ~36 | ~50 | — | — |
| art-9 | - | ~8 | ~12 | — | — |
| **합계 (예상)** | | **~180** | **~254** | | |

**잉여 예산**: 1000 − 254 (최종 예상) = 746 call. variant 재생성·retry·품질 반복용.

art-4b 예산: 9 에셋 / 11 call (base 1회 재생성 포함). art-4c 예산 효율: 4 에셋 / 4 call (재시도 0 — `background_image` 없이도 명시적 프롬프트 만으로 1회 통과).
