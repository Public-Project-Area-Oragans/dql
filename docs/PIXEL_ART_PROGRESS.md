# PIXEL ART MIGRATION PROGRESS

> art-0 ~ art-9 누적 진행 추적. 매 PR 머지 후 본 문서 업데이트.

- **총 PR 수**: 10 (art-0 ~ art-9)
- **총 예상 에셋**: ~120 (Manifest §10.1)
- **총 API 호출 예산**: 1000 call (2026-04-19 사용자 결정, 기존 plan 290 대비 3.5×)
- **실 사용 누적**: 12 / 1000

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

## art-3 ~ art-9 (TODO)

- 미착수

---

## 누적 집계

| 단계 | 상태 | 에셋 | API call | 누적 에셋 | 누적 call |
|---|---|---|---|---|---|
| art-0 | ✅ MERGED | 3 | 3 | 3 | 3 |
| art-1 | ✅ MERGED | 0 | 0 | 3 | 3 |
| art-2 | ✅ DONE | 8 | 9 | 11 | 12 |
| art-3 | - | ~4 | ~6 | — | — |
| art-4 | - | ~12 | ~18 | — | — |
| art-5 | - | ~35 | ~50 | — | — |
| art-6 | - | ~35 | ~50 | — | — |
| art-7 | - | ~28 | ~40 | — | — |
| art-8 | - | ~36 | ~50 | — | — |
| art-9 | - | ~8 | ~12 | — | — |
| **합계 (예상)** | | **~171** | **~239** | | |

**잉여 예산**: 1000 − 239 (최종 예상) = 761 call. variant 재생성·retry·품질 반복용.
