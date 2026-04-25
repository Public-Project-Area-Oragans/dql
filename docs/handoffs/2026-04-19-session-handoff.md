# DOL — 세션 핸드오프 (2026-04-19)

> 2026-04-19 실사용 체크 → 결함 R0~R6 해소 + R7 이론 재구성 1~2 단계 + 픽셀아트 이주 art-0~1 개시까지.
> 다음 세션 진입 시 이 문서 먼저 읽고 오픈 PR 상태 + 외부 사용자 작업 항목 확인.

- **작성일**: 2026-04-19
- **작성 시점 커밋**: develop `a67a8ba` (PR #72 fix-10b 머지 후), feature 브랜치 3 개 open
- **현재 단계**: P0 진행 + 독립 트랙 Art 이주 개시

---

## 1. 완료한 것 (이번 세션)

### 1.1 실사용 결함 해소 (R0~R6)

| PR | 태그 | 내용 |
|---|---|---|
| #56 | fix-1 | content_builder 자연정렬 (MSA phase1→10→2 버그) |
| #57 | fix-2 | 분관 QuestBoard ExpansionTile 평탄화 |
| #58 | fix-3 | ASCII fontFamilyFallback |
| #60 | fix-4a | JetBrainsMono 번들 |
| #62 | fix-5 | NPC ❓ 질문 탭 상시 노출 |
| #63 | fix-6 | QuestBoard 책 헤더 제거 + 책 사이 divider + 이모지 제거 (R0+R4+R3) |
| #65 | fix-4b | ContentBlock.boxDiagram 모델 스켈레톤 |
| #66 | fix-4c | AsciiGridDiagram CustomPaint 렌더 |
| #68 | fix-9 | QuestBoardFilterCategory 등 UI 상태 `@Riverpod(keepAlive:true)` (R6 근본) |

### 1.2 R7 이론 콘텐츠 재구성 (부분 완료)

| PR | 태그 | 내용 |
|---|---|---|
| #70 | fix-10a | 이론 섹션 펜스 drop, prose 전용. 5 카테고리 181 챕터 재빌드 |
| #72 | fix-10b | `tools/ai_diagram_describer.dart` + `substituteFencesWithDescriptions` 파이프라인 |

### 1.3 문서 신설

- `docs/designs/2026-04-19-requirements-consolidated.md` — 재작업 요구사항 정리 (R0~R7 + 에스컬레이션)
- `docs/designs/2026-04-19-ascii-to-widget-migration-design.md` — ASCII 이주 설계 (approach A/B/C)
- `docs/pixel-art/PIXEL_ART_ASSET_BIBLE.md`, `docs/pixel-art/PIXEL_ART_ASSET_MANIFEST.md` — 픽셀아트 스타일·아키텍처 규격
- `docs/pixel-art/PIXEL_ART_ANCHOR_APPROVAL.md` — art-0 승인 게이트
- `docs/pixel-art/PIXEL_ART_PROGRESS.md` — art-0~9 진행 추적
- `C:/Users/deepe/.claude/plans/optimized-yawning-rocket.md` — 픽셀아트 이주 9-PR 플랜

### 1.4 Describer 1차 실행 결과

- `ai_diagram_describer` 첫 실행: **1739 성공 / 2525 실패**. 실패 원인 **Anthropic API credit 소진**.
- 성공분 181 파일 7768 라인 cache commit → PR #76 open.
- 재충전 후 재실행 시 해시 dedup 으로 1739 skip → 2525 만 재호출.

### 1.5 배포 릴리즈 (develop → master)

| 릴리즈 PR | 포함 | master commit |
|---|---|---|
| #59 | fix-1/2/3 + 문서 | `18edbb6` |
| #61 | fix-4a | `af212e8` |
| #64 | fix-5/6 | `458b07c` |
| #67 | fix-4b/4c | `ca11f24` |
| #69 | fix-9 | `5cca758` |
| #71 | fix-10a | `1fc2292` |
| #73 | fix-10b | `5cca758` |

프로덕션: `https://public-project-area-oragans.github.io/dol/` — `Last-Modified: 2026-04-19 05:16:34 GMT` 기준 fix-10b 까지 반영.

### 1.6 headed Chrome 실측 검증 (직접)

- fix-9 배포 후 — MSA 분관 첫 탭 시 MSA 챕터만 즉시 노출 확인 (`/game` → glass-pane 클릭 → MSA 책장 클릭).
- fix-10a 배포 후 — MSA msa-roadmap 이론 탭 진입 → ASCII 박스 완전히 사라지고 prose + list 만 노출 확인.

---

## 2. 오픈 PR (머지 대기, 다음 세션 우선)

### 2.1 PR #74 — art(art-0) style anchors

- 3 앵커 v1 (character 64×96 / environment 256×144 / object 64×64) PixelLab 생성.
- Bible §4.4 5점 체크리스트 리뷰어 승인 필요.
- **머지 = `art-anchor-approved` 라벨 적용 = 이후 art-* PR 언락**.

### 2.2 PR #75 — art(art-1) rendering infra

- 코드 스캐폴딩 only (가시 변화 0):
  - `lib/core/rendering/nine_slice_insets.dart`
  - `lib/core/assets/asset_ids.dart`
  - `lib/game/rendering/sprite_registry.dart`
  - `lib/game/rendering/nine_slice.dart`
  - `lib/presentation/widgets/pixel_nine_slice.dart`
  - `tool/verify_palette.dart` (Bible §7.1 팔레트 게이트)
  - `lib/game/dol_game.dart` (`SpriteRegistry.preload` 훅)
  - `pubspec.yaml` (`image: ^4.3.0`)
  - tests 13 케이스
- **의존**: art-0 merge 후 순서적 머지.

### 2.3 PR #76 — fix(fix-10b-part1) 캐시 1739 건

- `content/diagram-descriptions/` 181 파일 (j/d/f 3 카테고리 완성, mysql/msa 0).
- 샘플 descriptions 품질 리뷰 권장.

---

## 3. 사용자 작업 항목 (다음 세션 착수 전 필수)

### 3.1 API 키 revoke + 재발급

**이 세션에서 ANTHROPIC_API_KEY 가 2회 chat 에 노출됨** (백그라운드 실행 + task summary 재출력). Anthropic 콘솔에서 즉시 revoke 후 새 키 발급.

### 3.2 API Credit 재충전

Describer 2차 실행을 위해 필요. 새 키 + credit 준비 완료 시 `!` 프리픽스로:
```
!ANTHROPIC_API_KEY=sk-ant-... dart run tools/ai_diagram_describer.dart docs-source
```
예상 소요 ~30분 (2525 블록 처리). mysql + msa 집중 생성.

### 3.3 PR 승인·머지

1. **#74 art-0 승인 + 라벨 적용 + merge**. Bible §4.4 체크리스트 모든 항목 확인.
2. **#75 art-1** — art-0 머지 후 auto/squash merge.
3. **#76 fix-10b-part1** — descriptions 샘플 품질 확인 후 merge.

---

## 4. 진행 중 (미완 / 다음 세션)

### 4.1 fix-10 시리즈 (R7 후속)

| PR | 상태 | 범위 |
|---|---|---|
| fix-10b-part2 (대기) | credit 재충전 후 | 나머지 2525 설명 생성 + cache commit + release |
| fix-10c | 미착수 | Chapter JSON `simulatorContent.codeSnippets` 스키마 + content_builder 코드 수집 |
| fix-10d | 미착수 | 시뮬레이터 UI 에 코드 팝업/side panel (인터랙션 유지) |
| fix-10e | 미착수 | docs-source submodule update + 전체 재빌드 + 배포 |

### 4.2 픽셀아트 이주 (art-2 이후)

설계: `C:/Users/deepe/.claude/plans/optimized-yawning-rocket.md`

| PR | 범위 | 예산 |
|---|---|---|
| art-2 | UI 크롬 (9-slice 프레임, 버튼, 대화 오버레이) ~10 에셋 | ~15 call |
| art-3 | 타이틀 씬 | ~6 call |
| art-4 | 중앙 홀 + 분관 문 | ~18 call |
| art-5 | 분관 배경 + 타일셋 A (backend+database) | ~50 call |
| art-6 | 분관 배경 + 타일셋 B (frontend+architecture) | ~50 call |
| art-7 | NPC 4 분관 마스터 | ~40 call |
| art-8 | 책장 + 정령 + 데코 | ~50 call |
| art-9 | 전환 + 폴리시 + 최종 감사 | ~12 call |

**예산 현황**: 3 / 1000 call 사용. 761 잉여.

---

## 5. 다음 세션 체크인 체크리스트

```
[ ] git checkout develop && git pull
[ ] git log --oneline origin/master..develop 으로 develop 리드 확인
[ ] gh pr list --state open (3 PR: #74 #75 #76)
[ ] docs/handoffs/2026-04-19-session-handoff.md (본 문서) 읽기
[ ] docs/designs/2026-04-19-requirements-consolidated.md §3.1 표 최신 상태 확인
[ ] 사용자 API 키 revoke + credit 재충전 여부 확인
[ ] PR #74 리뷰 → 승인 → art-anchor-approved 라벨 → merge
[ ] PR #75 art-1 merge
[ ] PR #76 품질 검토 → merge
[ ] describer 재실행 → 나머지 2525 cache 생성
[ ] fix-10b-part2 cache commit + release PR
[ ] 이후: fix-10c (simulator codeSnippets) 또는 art-2 (UI 크롬) 둘 중 선택
```

---

## 6. 참조

- `docs/handoffs/2026-04-18-session-handoff.md` — 직전 세션 (완료)
- `docs/designs/2026-04-19-requirements-consolidated.md` — R0~R7 원점 문서
- `docs/designs/2026-04-19-ascii-to-widget-migration-design.md` — R2 기술 설계
- `docs/pixel-art/PIXEL_ART_ASSET_BIBLE.md` / `docs/pixel-art/PIXEL_ART_ASSET_MANIFEST.md` — 스타일·아키텍처
- `docs/pixel-art/PIXEL_ART_ANCHOR_APPROVAL.md` — art-0 승인 게이트
- `docs/pixel-art/PIXEL_ART_PROGRESS.md` — art-* 누적 추적
- `C:/Users/deepe/.claude/plans/optimized-yawning-rocket.md` — 픽셀아트 이주 9-PR 플랜
- `docs/workflows/2026-04-18-work-history.md` / `docs/phases/2026-04-18-phase-plan.md` — P0 컨텍스트
