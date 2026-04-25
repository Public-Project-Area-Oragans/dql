# DOL — 세션 중간 진행 기록 (2026-04-25 art-4c)

> art-4c 도어 v3 재생성 + 후면 클러스터 진행 중. Task 1-7 완료, Task 8 (Headed Chrome 시각 검증) 사용자 판정 대기.

- **작성일**: 2026-04-25
- **마지막 commit (HEAD)**: `091b2fa` (Task 6 scene wiring)
- **브랜치**: `feature/art-4c-doors-redo` (origin/develop 위 rebase 됨, 미푸시)
- **누적 PixelLab call**: 33 + 4 = **37 / 1000**

---

## 1. 완료된 PR (이번 세션)

| PR | 머지 commit | 내용 |
|---|---|---|
| #123 | `54e2a84` | docs/ 폴더 5개 카테고리 재구성 (handoffs/phases/designs/workflows/pixel-art) |
| #124 | `9348178` | art-4b 중앙 홀 풀샷 재작업 (opaque base + 4 도어 조립식) — 도어 mismatch 잔존 상태로 머지 |

**중요**: 11차 릴리즈 (develop → master) **미진행**. art-4c 완성 후 11.5차로 통합 릴리즈할지 사용자 결정 (옵션 B 선택했음).

---

## 2. art-4c 진행 (Task 1-7 완료, Task 8 대기)

### 2.1 Spec + Plan (이미 머지됨, develop 에 존재)

- `docs/pixel-art/2026-04-25-art-4c-doors-redo-design.md` (spec, commit `b04dd44` 후 rebase 로 `ef7ce61`)
- `docs/pixel-art/2026-04-25-art-4c-doors-redo-plan.md` (plan, commit `5edac6a` 후 rebase 로 `0caaef6`)

### 2.2 art-4c 브랜치 commits (총 6 commits ahead of develop)

```
091b2fa feat(art-4c): scene.dart 가 CentralHallSceneLayout 사용 + 도어 v3
796540b art(art-4c): Phase 2 3 도어 v3 (frontend/database/architecture)
2613dce art(art-4c): Phase 1 파일럿 backend 도어 v3 (arched + green keystone, 64x96)
1d9a8b1 feat(art-4c): asset_ids door v3 + 테스트 갱신 (PNG 미존재 RED 허용)
724c306 feat(art-4c): CentralHallSceneLayout 순수 함수 + 테스트
0caaef6 docs(art-4c): 구현 Plan — 12 Task · TDD · Headed Chrome 게이트
ef7ce61 docs(art-4c): 도어 4개 재생성 + 후면 클러스터 배치 spec
```

### 2.3 Task 진척표

| # | Task | 상태 | 비고 |
|---|---|---|---|
| 1 | Pre-flight | ✅ | scene shape/pubspec/base v2 모두 PASS |
| 2 | CentralHallSceneLayout TDD | ✅ | implementer DONE → spec ✅ → code reviewer **APPROVED**. Minor: DoorTransform doc comment + private constructor (Task 10 cleanup) |
| 3 | asset_ids door v3 (TDD) | ✅ | 4 const v3, suffix test 갱신, 184/184 PASS. Important: 코멘트 truncation (Task 10 cleanup) |
| 4 | Phase 1 backend 파일럿 PixelLab | ✅ | basic mode 64×96, arched + green keystone star, 사용자 PASS |
| 5 | Phase 2 일괄 3 도어 | ✅ | frontend (sapphire blue) + database (amber) + architecture (purple), 모두 64×96 transparent, 사용자 PASS |
| 6 | scene.dart 가 layout 사용 | ✅ | implementer DONE → spec ✅ → code reviewer APPROVED. Minor: import sort order (Task 10 cleanup) |
| 7 | analyze + 전체 test | ✅ | art-4c 파일 0 issues, 184/184 PASS. (29 issues 는 모두 pre-existing `tools/content_builder.dart`, art-4c 무관) |
| **8** | **Headed Chrome 로컬** | **🔄 진행 중** | Chrome 재시작 (background `bm3iiu3zv`), 사용자 5체크 판정 대기 |
| 9 | PROGRESS + MANIFEST | ⏸ | art-4c 섹션 + 누적 33→37 갱신 + v1/v2 deprecated 주석 |
| 10 | PR + 머지 | ⏸ | cleanup commit (Task 2/3/6 minor 통합) → push → gh pr create → CI watch → merge → 11.5차 릴리즈 |
| 11 | 배포 검증 | ⏸ | GitHub Pages 배포 + 5 시각 체크 |
| 12 | 핸드오프 + CLAUDE.md | ⏸ | `2026-04-25-session-handoff.md` (본 mid-session 문서를 정식 핸드오프로 승격) |

### 2.4 사용된 PixelLab 호출 (Phase 1+2)

| Object ID | 분관 | 색 | 파일 |
|---|---|---|---|
| `68ce621f-a945-4b5c-b434-aa913f097824` | backend | deep forest green | `assets/sprites/objects/doors/obj_door_backend_v3.png` |
| `11106f76-06ae-4790-9bf3-2d11c25a69bc` | frontend | deep sapphire blue | `obj_door_frontend_v3.png` |
| `6de8afe6-4d74-4979-a09c-d1e07edde9d0` | database | burnished amber/orange | `obj_door_database_v3.png` |
| `cdf8c58d-d0da-43da-906c-665d3cc20489` | architecture | deep amethyst purple | `obj_door_architecture_v3.png` |

**중요 발견**: PixelLab `create_map_object` 가 metadata 에 64×64 로 표시하지만 **실제 다운로드 PNG 는 64×96** (요청 그대로). 추후 art-* 작업 시 metadata 의 size 값 신뢰 말고 실제 PIL 검증 사용.

### 2.5 Layout 좌표 공식 (현 적용)

```dart
class CentralHallSceneLayout {
  static const double doorWidthRatio = 1 / 11;
  static const double doorAspect = 1.5; // 64×96 PNG 비율
  static const double doorYRatio = 0.45;
  static const List<double> doorXRatios = [0.32, 0.43, 0.54, 0.65];
}
```

Task 8 결과에 따라 hotfix 가능. 가능한 조정안:
- 도어 너무 작음 → `doorWidthRatio = 1/9` 또는 `1/10`
- 도어 너무 위 → `doorYRatio = 0.5`
- 도어 좌우 좁음 → `doorXRatios = [0.28, 0.41, 0.55, 0.68]`
- 4 도어 너무 가까움 → x 간격 +0.02 단위 확장

조정 시 `central_hall_scene_layout_test.dart` 의 expected 값도 동기 갱신 필요.

---

## 3. 코드 리뷰 누적 결과 (Task 10 cleanup commit 으로 통합 처리 예정)

### 3.1 Important — 1건
- `lib/core/assets/asset_ids.dart` line 183-184: 도어 코멘트 단축 시 hover/pressed (TappableComponent ColorFilter) + glow art-9 이월 노트 누락 → 3번째 줄로 복원 권장

### 3.2 Minor — 4건
- `lib/game/scenes/central_hall_scene_layout.dart` line 7: `DoorTransform` doc comment 추가 (`/// Computed size and position for one door slot, produced by [CentralHallSceneLayout].`)
- `lib/game/scenes/central_hall_scene_layout.dart` line 13: `CentralHallSceneLayout._();` private constructor 추가 (instantiation 방지)
- `lib/game/scenes/central_hall_scene.dart` line 8: import sort order — `central_hall_scene_layout.dart` 가 `wing_door_component.dart` 보다 앞 (c < w)
- `test/core/assets/asset_ids_test.dart` line 170-171: suffix test 가 doorBackend/Architecture 만 sample — frontend/database 도 추가 권장

---

## 4. 재개 시 다음 단계

1. Task 8 사용자 5체크 판정 → PASS 시 Task 9 진입, 부분 PASS 시 layout ratio hotfix
2. Task 9: `docs/pixel-art/PIXEL_ART_PROGRESS.md` art-4c 섹션 + 누적 37/1000 갱신, `PIXEL_ART_ASSET_MANIFEST.md` v1/v2 deprecated 주석
3. Task 10: cleanup commit → push → gh pr create (base develop) → merge → 11.5차 릴리즈 PR (develop → master)
4. Task 11: GitHub Pages 배포 검증
5. Task 12: 정식 핸드오프 작성 (본 mid-session 문서 정리·확장), CLAUDE.md 참조 갱신

---

## 5. 참조

- art-4c spec: `docs/pixel-art/2026-04-25-art-4c-doors-redo-design.md`
- art-4c plan: `docs/pixel-art/2026-04-25-art-4c-doors-redo-plan.md`
- 직전 세션 핸드오프: `docs/handoffs/2026-04-24-session-handoff.md`
- 머지된 PR: #123 (docs reorg) + #124 (art-4b)
- 현 base 이미지: `assets/sprites/environments/main_hall/env_mainhall_base_v1.png` (실은 v2 콘텐츠)
- 배포 URL: `https://public-project-area-oragans.github.io/dql/`
