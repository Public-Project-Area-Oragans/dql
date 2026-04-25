# DOL — 세션 핸드오프 (2026-04-25)

> docs 재구성 + art-4b 머지 + art-4c 도어 v3 완료. 11차 통합 릴리즈 배포. 다음 단계: art-5 (분관 배경) 또는 fix-10b 잔량.

- **작성일**: 2026-04-25
- **master HEAD**: `c9b2d5d` (Release 11 — art-4b + art-4c + docs reorg)
- **develop HEAD**: `5c09fc7` (master 와 동일 내용)
- **현재 단계**: P0 진행 + art-4 완전 종결 (art-4 → art-4b → art-4c), art-5 착수 가능
- **누적 PixelLab call**: **37 / 1000** (잉여 963)

---

## 1. 이번 세션 완료분

### 1.1 docs 재구성 (PR #123, 머지 `54e2a84`)
- 24개 docs/*.md 파일을 5개 카테고리 폴더로 분류:
  - `handoffs/` (6) — 세션 핸드오프
  - `phases/` (5) — Phase 1·2 설계+plan, 로드맵 피벗
  - `designs/` (4) — 기능 설계
  - `workflows/` (3) — task-workflow, troubleshooting, work-history
  - `pixel-art/` (6) — art-4b spec/plan, PIXEL_ART_*
- CLAUDE.md, README.md, 24개 doc 내부 cross-reference 일괄 갱신
- git mv 로 history 보존

### 1.2 art-4b 중앙 홀 풀샷 재작업 (PR #124, 머지 `9348178`)
- 직전 세션 (2026-04-24) 의 8 commits 미푸시 상태에서 push → PR → merge
- art-4 의 3층 parallax 가 `create_map_object` 투명 강제로 객체처럼 떠 보이는 프로덕션 붕괴 해소
- env_mainhall_base v2 + 9 deco 에셋 (pillar/arch×4/chandelier/compass/door_architecture v2) 생성
- `CentralHallScene` 조립식 렌더 스택 재작성, 178 테스트 PASS
- **알려진 한계 (art-4c 에서 해소됨)**: 도어 스타일 mismatch + 평면 배치 vs 3D corridor 부조화

### 1.3 art-4c 도어 v3 + 후면 클러스터 + 라벨 plaque (PR #125, 머지 `5c09fc7`)

`/superpowers:brainstorming` → `writing-plans` → `subagent-driven-development` 플로우로 12 task 실행.

**완료 사항**:
- 도어 4개 v3 재생성 (arched stone form + keystone accent, 분관별 색)
- 좌표 공식을 `CentralHallSceneLayout` 순수 함수로 추출 (TDD 격리)
- 후면 아치 근처 클러스터 배치 (`/8` 폭, 도어 중심 x [0.25, 0.42, 0.58, 0.75], y 0.45)
- 라벨을 도어 위 반투명 plaque 로 분리 + JetBrainsMonoHangul 폰트 번들 (한글 가독성)
- 184 테스트 PASS, flutter analyze 0 issues

**Hotfix iteration (Headed Chrome 검증 중 3회)**:
1. hotfix1: 도어 `/11` → `/8` 확대 + 라벨 plaque 분리 + fontSize 14→16
2. hotfix2: 도어 x centering 버그 수정 (top-left → center 기준) + fontSize 16→20
3. hotfix3: JetBrainsMonoHangul 폰트 번들 (한글 글자 깨짐 해소)

**API 호출**: 4 PixelLab call (재시도 0). 누적 33 → 37/1000.

### 1.4 11차 통합 릴리즈 (PR #126, 머지 `c9b2d5d`)
- develop → master 머지 완료
- GitHub Pages 배포 (Sync & Deploy run `24931550355` success)
- 프로덕션 URL 5체크 PASS

---

## 2. art-4c 핵심 commits (브랜치 `feature/art-4c-doors-redo`, PR #125)

```
8769e08 chore(art-4c): reviewer cleanup (doc comments + private ctor + comment 복원 + suffix test 4건)
21adbd5 docs(art-4c): PROGRESS art-4b/4c 섹션 + 누적 37 + MANIFEST 도어 v3
953215f fix(art-4c hotfix3): JetBrainsMonoHangul 폰트 번들 + 라벨 fontFamily 적용
253de0b fix(art-4c hotfix2): 도어 x centering + fontSize 20 (한글 가독성)
56b50eb fix(art-4c): 도어 1/8 확대 + 라벨을 도어 위 반투명 plaque 로 분리
e56cd1f docs(art-4c): mid-session 진행 기록 저장
091b2fa feat(art-4c): scene.dart 가 CentralHallSceneLayout 사용 + 도어 v3
796540b art(art-4c): Phase 2 3 도어 v3 (frontend/database/architecture)
2613dce art(art-4c): Phase 1 파일럿 backend 도어 v3 (arched + green keystone, 64x96)
1d9a8b1 feat(art-4c): asset_ids door v3 + 테스트 갱신 (PNG 미존재 RED 허용)
724c306 feat(art-4c): CentralHallSceneLayout 순수 함수 + 테스트
0caaef6 docs(art-4c): 구현 Plan — 12 Task · TDD · Headed Chrome 게이트
ef7ce61 docs(art-4c): 도어 4개 재생성 + 후면 클러스터 배치 spec
```

---

## 3. 다음 세션 작업 후보

### 3.1 art-5 (분관 배경 + 타일셋 A) 🟢 권장
- art-4 시리즈 완전 종결, art-5 착수 가능
- Bible §1.3 분관별 지배색 적용 (backend=green, database=amber, frontend=blue, architecture=purple)
- 예산: ~50 PixelLab call (잉여 963 충분)

### 3.2 fix-10b 잔량
- mysql 4ch (step-01/04/06/09) + msa 10ch (phase3~6) + flutter 1ch (Step-30) = **15 chapter**
- 직전 세션 (2026-04-22) 핸드오프부터 이월. art-4 시리즈로 우선순위 밀려있었음

### 3.3 reviewer-flagged minor 잔량 (art-4c)
- `central_hall_scene.dart` import sort: 이미 Dart 컨벤션 (`../../` < `../` < same-dir) 따름. 별도 작업 불필요
- 기타 cleanup commit `8769e08` 에서 모두 처리됨

---

## 4. 기술 교훈

### 4.1 PixelLab metadata size 부정확
`mcp__pixellab__create_map_object` 가 metadata 응답에 64×64 로 표시했지만 **실제 다운로드 PNG 는 64×96** (요청 그대로). 후속 art-* 작업 시 metadata 의 size 값 신뢰 말고 PIL 직접 검증 사용.

### 4.2 PixelLab `background_image` 192×192 한계
inpainting mode 의 max 192×192 픽셀 한계 때문에 base v2 (256×256) 를 직접 background_image 로 못 씀. 결국 art-4c 는 **basic mode (no background_image) + 명시적 스타일 프롬프트** 만으로도 1회 통과 (재시도 0). 이전 세션 §4.3 의 "background_image 활용" 가설은 size 제약으로 보류.

### 4.3 Flutter Web 한글 폰트 fallback 불안정
JetBrainsMono 만 번들된 상태에서 한글은 브라우저 기본 fallback 폰트로 렌더 → 일부 글리프 ("탑" 등) 깨짐. 픽셀아트 게임에 어울리는 mono 한글 폰트 = **JetBrainsMonoHangul** (Jhyub repo, OFL 1.1, 동일 mono metrics + 한글 추가). Regular+Bold 두 weight 만 번들 (~5.2MB) 로 해결.

### 4.4 좌표 공식 추출 → TDD 격리
art-4c 의 `CentralHallSceneLayout.doorTransforms()` 순수 함수 추출이 결정적. PNG 로드 무관하게 RED→GREEN 가능, hotfix 시에도 좌표 변경 + 테스트 갱신만으로 검증 closed-loop. 후속 art-5 이후의 분관 씬 layout 도 같은 패턴 권장.

### 4.5 hotfix 누적 시 commit message 패턴
hotfix1/hotfix2/hotfix3 처럼 번호 매기면 release notes 에서 iteration 흔적 명확. 각 hotfix 가 독립 commit 으로 남으면 부분 revert 도 쉬움.

### 4.6 Subagent-driven 12-task 실행 패턴
- 각 task 마다 implementer + spec reviewer + code quality reviewer 3 단계
- 코드 task 는 sonnet 모델로 비용 효율
- 시각/MCP 의존 task (Phase 1 PixelLab, Headed Chrome) 는 controller 직접 처리
- Review 누적 minor 권고는 **마지막 cleanup commit 으로 통합** (각 task 마다 반영하면 commit 노이즈)

---

## 5. 체크인 체크리스트 (다음 세션 진입 시)

```
[ ] git fetch origin develop master
[ ] git checkout develop && git status  (master 와 동일 위치 확인)
[ ] docs/handoffs/2026-04-25-session-handoff.md (본 문서) 읽기
[ ] docs/pixel-art/PIXEL_ART_PROGRESS.md 누적 37/1000 확인
[ ] CLAUDE.md 참조 문서 최신화 확인
[ ] 다음 작업 선택:
    (A) art-5 (분관 배경) — Bible §1.3 분관별 지배색 적용
    (B) fix-10b 잔량 (mysql/msa/flutter, 15 chapter)
    (C) 다른 우선순위
```

---

## 6. 참조

- 직전 세션: `docs/handoffs/2026-04-24-session-handoff.md` (art-4b 미완)
- 진행 중 기록: `docs/handoffs/2026-04-25-art-4c-mid-session.md` (Task 8 시점, 본 핸드오프로 대체)
- art-4c spec: `docs/pixel-art/2026-04-25-art-4c-doors-redo-design.md`
- art-4c plan: `docs/pixel-art/2026-04-25-art-4c-doors-redo-plan.md`
- 머지된 PR: #123 docs reorg, #124 art-4b, #125 art-4c, #126 release 11
- 배포 URL: `https://public-project-area-oragans.github.io/dql/`
- JetBrainsMonoHangul: https://github.com/Jhyub/JetBrainsMonoHangul (release 20260222)
