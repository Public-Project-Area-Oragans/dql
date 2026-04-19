# PIXEL ART MIGRATION PROGRESS

> art-0 ~ art-9 누적 진행 추적. 매 PR 머지 후 본 문서 업데이트.

- **총 PR 수**: 10 (art-0 ~ art-9)
- **총 예상 에셋**: ~120 (Manifest §10.1)
- **총 API 호출 예산**: 1000 call (2026-04-19 사용자 결정, 기존 plan 290 대비 3.5×)
- **실 사용 누적**: 3 / 1000

---

## art-0 — Style Anchors (PROGRESS)

- 상태: **승인 대기** (PR 대기)
- 생성 에셋: 3 (character / environment / object 각 v1)
- API 호출: 3 (variant 1개씩 생성, 품질 양호로 추가 variant 생략)
- 파일:
  - `assets/sprites/_anchors/anchor_character_v1.png` 64×96
  - `assets/sprites/_anchors/anchor_environment_v1.png` 256×144
  - `assets/sprites/_anchors/anchor_object_v1.png` 64×64

---

## art-1 — Rendering Infrastructure (TODO)

- 미착수

## art-2 ~ art-9 (TODO)

- 미착수

---

## 누적 집계

| 단계 | 상태 | 에셋 | API call | 누적 에셋 | 누적 call |
|---|---|---|---|---|---|
| art-0 | 대기 | 3 | 3 | 3 | 3 |
| art-1 | - | 0 | 0 | 3 | 3 |
| art-2 | - | ~10 | ~10 | — | — |
| art-3 | - | ~4 | ~6 | — | — |
| art-4 | - | ~12 | ~18 | — | — |
| art-5 | - | ~35 | ~50 | — | — |
| art-6 | - | ~35 | ~50 | — | — |
| art-7 | - | ~28 | ~40 | — | — |
| art-8 | - | ~36 | ~50 | — | — |
| art-9 | - | ~8 | ~12 | — | — |
| **합계 (예상)** | | **~171** | **~239** | | |

**잉여 예산**: 1000 − 239 = 761 call. variant 재생성·retry·품질 반복용.
