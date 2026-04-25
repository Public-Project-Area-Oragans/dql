# DOL — 세션 핸드오프 (2026-04-22)

> 2026-04-21~22 세션. fix-10b mysql step-11~20 10 chapter · 383 entries 주입 + art-4 중앙 홀 픽셀아트 이주 + 10차·10.5차(base-href hotfix) 릴리즈 연속 배포. 배포 URL 이동 `/dol/` → `/dql/`.
> **다음 세션 최우선**: art-4b — 중앙 홀 단일 풀샷 일러스트 재작업 (현 parallax 3층이 투명 객체로 생성돼 시각 붕괴).

- **작성일**: 2026-04-22 (UTC 14:20)
- **master HEAD**: `7481abd` release 10.5차 merge
- **develop HEAD**: `= master` (0 ahead, 0 behind)
- **현재 단계**: P0 진행 + 픽셀아트 이주 art-4 완료 (art-5 착수 대기) + R7 fix-10b 잔량 14 chapter

---

## 1. 이번 세션 완료분

### 1.1 fix-10b — mysql describer 캐시 383 entries (MERGED #117)

Phase 3·4·5 10개 chapter 에 교육 의도 중심 한국어 prose 주입.

| Chapter | Entries | Phase | 주제 |
|---|---|---|---|
| step-11 | 37 | 3 | 집계 함수 (COUNT/SUM/AVG/MAX/MIN) |
| step-12 | 40 | 3 | GROUP BY / HAVING |
| step-13 | 51 | 3 | JOIN 기본·심화 (ON vs WHERE, Self Join) |
| step-14 | 42 | 3 | 서브쿼리 (스칼라/인라인뷰/중첩, EXISTS) |
| step-15 | 35 | 3 | CTE(WITH) 와 View + 재귀 CTE |
| step-16 | 39 | 3 | 윈도우 함수 + DATETIME·TIMESTAMP·JSON |
| step-17 | 35 | 4 | 정규화 (1NF/2NF/3NF) + 반정규화 |
| step-18 | 41 | 4 | 키·관계 모델 (1:1/1:N/N:M, FK) |
| step-19 | 28 | 4 | ERD 설계 + 미니 프로젝트 |
| step-20 | 35 | 5 | 인덱스 기본·자료구조 (B-Tree, 클러스터드) |

- 평균 265자 (min 207, max 386), 목표 범위 200~400 안쪽
- placeholder 0 건, content_builder 재빌드 시 완전 주입
- 해시 재현 검증: `.tmp/extract_blocks.py` Python 스크립트가 `ai_diagram_describer.dart` 의 `sha256(utf8(body)).hex` 로직을 재현, mysql-step-10 55/55 교차 일치로 신뢰성 확보
- 이 패턴(`.tmp/extract_blocks.py` + `.tmp/list_blocks.py` + chapter 별 `build_stepNN.py`)은 남은 chapter 처리에도 재사용 가능

### 1.2 art-4 — 중앙 홀 + 분관 문 픽셀아트 (MERGED #118, 배포됨)

Placeholder RectangleComponent → PixelLab 픽셀아트 7 에셋.

- `env_mainhall_bg_far/mid/near` (256×256 — 요청 256×144 였으나 PixelLab 정사각 생성, art-3 동일 패턴)
- `obj_door_{backend,database,frontend,architecture}` (64×64 — 요청 64×96 → 정사각)
- API 8 call (예산 18 대비 56% 절감, architecture 도어만 concurrent 429 재시도)
- 분관별 지배색 Bible §1.3 적용 (backend=green steam, database=amber, frontend=prism, architecture=pure gold). 코드 라벨(마법사의 탑 등)은 유지
- `WingDoorComponent`: RectangleComponent → PositionComponent + SpriteComponent child + 라벨용 자식 컴포넌트 + fallback Rectangle
- `CentralHallScene`: 3층 parallax 스프라이트 로드된 것만 누적
- `dol_game.dart`: `images.prefix = ''` 설정해 asset_ids.dart 풀 경로(`assets/sprites/...`) 호환
- `asset_ids.dart`: mainhall/door 상수의 `sprites/` 결여 prefix 버그 수정
- art-2b `TappableComponent` saveLayer tint 가 SpriteComponent 에도 그대로 계승됨

### 1.3 배포 릴리즈 2연속

| 릴리즈 | PR | 포함 | master commit |
|---|---|---|---|
| 10차 | #119 | fix-10b #117 + art-4 #118 | `8ac1b14` (merge commit) |
| 10.5차 | #121 | base-href hotfix #120 | `7481abd` (merge commit) |

### 1.4 배포 사고 + 복구 (10.5차 hotfix)

10차 배포 직후 프로덕션 404 다발 (manifest.json·flutter_bootstrap.js·favicon 전부). 원인: GitHub 에서 repo 가 **`dol` → `dql`** 로 이름 변경되어 Pages URL 이 `/dql/` 에서만 서빙되는데, 빌드 워크플로는 `--base-href /dol/` 하드코딩.

- `https://...github.io/dol/` → 404
- `https://...github.io/dql/` → 200

수정 (3 파일): `.github/workflows/sync-and-deploy.yml`, `README.md`, `CLAUDE.md` 모두 `/dol/` → `/dql/`. docs/ 의 과거 핸드오프는 히스토리 보존 차원에서 그대로 유지.

**교훈**: GitHub repo rename 시 워크플로 base-href + README + CLAUDE.md 동시 반영 필요. git remote URL 은 자동 리다이렉트되지만 Pages 경로는 안 됨.

---

## 2. 미처리 잔량 (다음 세션 최우선)

### 2.1 art-4b — 중앙 홀 풀샷 일러스트 재작업 🔥 최우선

**문제**: 현 배포 화면(스크린샷 확인 필요)에서 3층 parallax bg 가 전부 `create_map_object` transparent 출력이라 풀스크린 배경 역할을 못하고 중앙에 샹들리에+기둥+바닥 컴퍼스 로즈가 '객체처럼' 떠 있는 상태. 도어 크기도 불균형 (architecture 는 작은 스크롤만 생성됨). "기계공의 작업장" 라벨이 중앙 샹들리에와 겹침.

**해결 방향 (옵션 3 채택)**:
- 중앙홀 전체를 **단일 256×144 풀 일러스트** 로 재받기 (현 3 레이어 대체)
- 도어는 해당 일러스트 위에 오버레이
- API ~3 call 예상
- 이상적으로는 `create_map_object` 대신 다른 API (PixelLab 이 fullscreen bg 용 API 를 제공하는지 확인 필요) 또는 프롬프트에 'opaque rectangular background, no transparency' 를 명시

**세부 작업 목록**:
1. PixelLab 에서 "opaque rectangular 256×144 steampunk arcane library main hall, 4 wing entrances visible in the background, warm dusk lighting" 류 프롬프트로 풀샷 bg 1장 생성
2. (선택) 별도 중앙 장식 오브젝트(샹들리에 등)가 필요하면 추가 레이어로
3. architecture 도어를 64×96 비율로 재생성 (현 64×64 은 scroll 만 있어서 도어 같지 않음)
4. `CentralHallScene`: 3층 parallax 제거, 단일 bg + 도어 오버레이 구조
5. `asset_ids.dart`: 새 풀샷 bg 상수 추가, parallax far/mid/near 는 주석 처리 또는 제거
6. 배포 headed Chrome 검증 → 도어 위치·라벨 가독성 확인 → art-5 착수 여부 판단

### 2.2 fix-10b describer 미완 14 chapter (2026-04-21 핸드오프 잔량에서 이월)

**mysql (4ch, 고난도 반복 실패)**:
- `mysql-step-01`, `step-04`, `step-06`, `step-09` — subagent 2회 이상 중단 이력. Claude 메인 직접 처리 또는 API credit 재충전 후 `ai_diagram_describer.dart` 재실행 권장

**msa (10ch)**:
- `phase3-step4-api-contract` · `phase4-step2/3/4` · `phase5-step1/2/3` · `phase6-step1/2/3`

**flutter (1ch)**:
- `Step-30-CICD`

**해결 경로 우선순위**:
1. 메인 직접 처리: 이번 세션에서 검증된 `.tmp/extract_blocks.py` + `build_stepNN.py` 패턴 재사용. chapter 당 ~30-50 entries × 200~400자 prose. 1 chapter / 세션 페이스
2. API credit 있으면 `ai_diagram_describer.dart` 재실행 — 해시 dedup 로 이미 생성된 ~3,509 entries skip, 잔량만 재호출
3. subagent batch 는 계속 제외 (사용자 지시 유지)

### 2.3 art-5 분관 배경 + 타일셋 (A: backend + database)

art-4b 마무리 후 착수. 현재 누적 22 / 1000 call, 잉여 978 매우 여유.

- 에셋 ~35 (각 분관 bg 3층 parallax + `create_topdown_tileset` ~15 타일씩)
- `lib/game/scenes/wing_scene.dart` 에 타일맵 로더 추가
- backend + database 경로 활성, frontend/architecture 는 feature flag fallback

---

## 3. 진행 중 / 미착수 (장기)

### 3.1 fix-10 시리즈 (R7 후속)

| PR | 상태 | 범위 |
|---|---|---|
| fix-10b (mysql 잔량 4) | 미완 | step-01/04/06/09 |
| fix-10b (msa 잔량 10) | 미완 | phase3-6 |
| fix-10b (flutter 잔량 1) | 미완 | Step-30 CICD |
| fix-10c | 미착수 | Chapter JSON `simulatorContent.codeSnippets` 스키마 |
| fix-10d | 미착수 | 시뮬레이터 UI 코드 팝업 |
| fix-10e | 미착수 | docs-source submodule update + 전체 재빌드 |

### 3.2 픽셀아트 이주 잔여 (art-4b/5~9)

| PR | 범위 | 예산 (누적) |
|---|---|---|
| art-4b | 중앙 홀 풀샷 재작업 + architecture 도어 재생성 | ~4 call (~26) |
| art-5 | 분관 배경 + 타일셋 A (backend+database) | ~50 call (~76) |
| art-6 | 분관 배경 + 타일셋 B (frontend+architecture) | ~50 call (~126) |
| art-7 | NPC 4 분관 마스터 | ~40 call (~166) |
| art-8 | 책장 + 정령 + 데코 | ~50 call (~216) |
| art-9 | 전환 + 폴리시 + 팔레트 quantize + 최종 감사 | ~12 call (~228) |

**현재 누적**: 22 / 1000 call. **잉여**: 978 (매우 여유).

---

## 4. 기술 교훈 (다음 세션 참고)

### 4.1 PixelLab `create_map_object` 한계

- **정사각형 강제**: 요청 256×144 / 64×96 → 실제 256×256 / 64×64. 비정사각 요청은 정사각으로 올림/내림됨
- **투명 배경 강제**: 모든 출력이 transparent 배경의 '객체'. 풀스크린 rectangular bg 용도로는 부적합
- **컨텐츠 스케일**: 64×96 요청이 64×64 로 축소되면 디테일도 함께 축소 (architecture 도어는 scroll 하나만 남음)
- **concurrent job 429**: 6개 이상 동시 큐잉 시 "maximum number of concurrent jobs" 에러. 재시도 필수

### 4.2 Flame Images prefix 설정

- 기본 `Images` 인스턴스의 prefix 는 `assets/images/`. asset_ids.dart 가 `assets/sprites/...` 풀 경로를 사용하면 `images.prefix = ''` 로 비워야 함
- art-4 에서 `dol_game.dart` 에 `images.prefix = ''` 추가. 이후 모든 Flame 스프라이트 로드는 풀 경로 그대로

### 4.3 `TappableComponent` mixin + SpriteComponent 호환성

- art-2b 에서 설계된 `saveLayer(null, tint)` 패턴이 자식 트리 전체를 감싸므로 `SpriteComponent` 자식에도 그대로 hover/pressed 적용됨
- 자식 순서: SpriteComponent 먼저 → 라벨 TextComponent 나중에 추가하면 라벨이 최상단 렌더 + 공통 tint

### 4.4 GitHub repo rename → Pages URL 변경

- repo rename `dol` → `dql` 시 `https://...github.io/dol/` 가 영구 404, `/dql/` 만 서빙
- git remote URL 은 자동 리다이렉트되지만 base-href 는 수동 변경 필요
- 핸드오프 문서들의 과거 URL 참조는 히스토리 보존 차원에서 그대로 유지 (복원할 필요 없음)

### 4.5 release PR merge 방식

- develop → master 릴리즈 PR 은 **반드시 merge commit**. squash 하면 history 단절 (8차 #111 사례)
- 최근 9차·10차·10.5차 전부 merge commit 정책 유지

---

## 5. 체크인 체크리스트 (다음 세션 진입 시)

```
[ ] git fetch origin develop master && git pull --ff-only
[ ] gh pr list --state open (현재 0 예상)
[ ] docs/handoffs/2026-04-22-session-handoff.md (본 문서) 읽기
[ ] docs/pixel-art/PIXEL_ART_PROGRESS.md 누적 22/1000 확인
[ ] 배포 URL https://public-project-area-oragans.github.io/dql/ 접속 시 중앙 홀 현황 시각 확인
[ ] 다음 작업 선택:
    (A) art-4b 중앙 홀 풀샷 재작업 [최우선]
    (B) fix-10b chapter 1-2 개 메인 직접 처리 (.tmp/extract_blocks.py 패턴 재사용)
    (C) art-5 착수 (art-4b 전에 하면 또 풀샷 없는 상태로 분관 배경만 쌓임)
[ ] CLAUDE.md 참조 최신 핸드오프 2026-04-22 로 갱신됐는지 확인
```

---

## 6. 참조

- `docs/handoffs/2026-04-21-session-handoff.md` — 직전 세션 (art-2b + art-3 + 8/9차 릴리즈)
- `docs/handoffs/2026-04-20-session-handoff.md` — subagent describer 파이프라인
- `docs/designs/2026-04-19-requirements-consolidated.md` — R0~R7 원점
- `docs/pixel-art/PIXEL_ART_ASSET_BIBLE.md` / `docs/pixel-art/PIXEL_ART_ASSET_MANIFEST.md` — 스타일 규격
- `docs/pixel-art/PIXEL_ART_PROGRESS.md` — art-* 누적 (22/1000 call)
- `C:/Users/deepe/.claude/plans/optimized-yawning-rocket.md` — 픽셀아트 9-PR 플랜
- `.tmp/extract_blocks.py` / `.tmp/list_blocks.py` / `.tmp/build_step11.py` ~ `build_step20.py` — fix-10b 메인 직접 처리 파이프라인 (재사용 가능)
- 배포 URL: `https://public-project-area-oragans.github.io/dql/`
