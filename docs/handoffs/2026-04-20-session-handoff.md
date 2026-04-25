# DOL — 세션 핸드오프 (2026-04-20)

> 2026-04-19~20 세션. 개인 Claude API credit 소진 이후 subagent 기반 describer 대체 파이프라인 구축, fix-10b 캐시 **대량 확장** (1739 → ~2900+ entries), art-2 UI 크롬 PixelLab 이주 완료.
> 다음 세션 진입 시 이 문서 먼저 읽고 Claude Code 구독 한도 리셋 시각 + 잔량 chapter 목록 확인.

- **작성일**: 2026-04-20
- **작성 시점 develop HEAD**: `af25e0b` (PR #108 mysql step-07 머지 후)
- **현재 단계**: P0 진행 + R7 fix-10b 캐시 확장 지속 + 픽셀아트 이주 art-2 완료

---

## 1. 이번 세션 완료분

### 1.1 art-2 UI 크롬 (MERGED)

| PR | 내용 |
|---|---|
| #81 | UI 프레임 5종 + 버튼 3상태 9-slice 스프라이트 이주 |

- `PixelNineSlice` + `SteampunkPanel` + `SteampunkButton` → 9-slice 렌더
- `dialogue_overlay` / `quest_board_overlay` 외곽 프레임 교체
- `asset_ids.dart` prefix 버그 수정 (`sprites/` → `assets/sprites/`)
- PixelLab 8 PNG 생성 (frame 128×128, button 64×64 — 요청 가로 직사각형은 PixelLab 미지원이라 정사각형으로 생성, 9-slice stretch 는 무영향)
- 테스트 174/174 pass (asset_ids_test + structure_assembly_simulator_test 적응)
- 예산: 9 API call / 1000. 누적 12 call.

### 1.2 Bible/Manifest 문서 정착 (MERGED)

| PR | 내용 |
|---|---|
| #78 | `PIXEL_ART_ASSET_BIBLE.md` + `PIXEL_ART_ASSET_MANIFEST.md` 원본 커밋 (기존 untracked 의존성 해소) |

### 1.3 fix-10b describer 캐시 대량 확장 (MERGED)

직전 세션의 PR #76 (1739 entries) 위에 subagent 파이프라인으로 확장. 개인 Anthropic credit 없이 **Claude Code 구독 기반 subagent**가 prose 직접 작성.

**subagent 1-chapter 단위 dispatch 성공 PR (정상 품질 입증, 모두 MERGED)**:

| PR | 언어 | 챕터 | entries |
|---|---|---|---|
| #82 | flutter | Step-16~23 | 166 |
| #83 | msa | phase 9/10/12 + roadmap | 93 |
| #84 | msa | phase 7-step1 | 34 |
| #85 | flutter | Step-24 | 24 |
| #86 | mysql | step 21~29 (9ch) | 356 |
| #87 | msa | phase1-step2 | 32 |
| #88 | msa | phase1-step1 | 22 |
| #89 | mysql | step-03 | 38 |
| #90 | flutter | Step-26 | 19 |
| #91 | flutter | Step-25 | 21 |
| #92 | msa | phase3-step1 | 25 |
| #93 | mysql | step-02 | 27 |
| #94 | msa | phase2-step1 | 32 |
| #95 | msa | phase3-step2 | 27 |
| #96 | msa | phase1-step4 | 32 |
| #97 | flutter | Step-28 | 18 |
| #98 | mysql | step-05 | 39 |
| #99 | flutter | Step-27 | 21 |
| #100 | msa | phase2-step2 | 35 |
| #101 | msa | phase1-step3 | 28 |
| #102 | msa | phase4-step1 | 25 |
| #103 | mysql | step-10 | 55 |
| #104 | msa | phase3-step3 | 28 |
| #105 | mysql | step-08 | 50 |
| #106 | msa | phase2-step3 | 30 |
| #107 | flutter | Step-29 | 27 |
| #108 | mysql | step-07 | 54 |

**세션 entries 합**: ~1,387 (PR #76 의 1,739 대비 80% 추가).

### 1.4 Rejected PRs (기록)

| PR | 사유 |
|---|---|
| #79 | msa v1 — subagent 가 템플릿 기반 합성 prose 생성 (규칙 위반) |
| #80 | mysql v1 — 동일 패턴 reject |

둘 다 "이 다이어그램은 X 단원에서 Y를 시각적으로 정리한다", "구성 요소로 A, B, C 등이 등장…" 등의 기계 템플릿. 형태 메타 서술. 교육 의도 없음. Close 완료.

---

## 2. 미처리 잔량 (다음 세션 최우선)

### 2.1 fix-10b describer 미완 chapter (24개)

subagent capacity 한계 + Claude Code 구독 일일 한도 도달로 중단.

**mysql (13ch)**:
- `mysql-step-01` (2회 중단) — 21 blocks, 복잡도 높음
- `mysql-step-04` (2회 중단) — 51 blocks, 양 큰 편
- `mysql-step-06` (2회 중단)
- `mysql-step-09` (2회 중단)
- `mysql-step-11` ~ `mysql-step-20` (10ch, 미착수)

**msa (10ch)**:
- `phase3-step4-api-contract` (2회 중단)
- `phase4-step2-service-discovery`
- `phase4-step3-config-server-feature-flag`
- `phase4-step4-resilience-patterns`
- `phase5-step1-synchronous-communication`
- `phase5-step2-async-message-broker`
- `phase5-step3-event-driven-architecture`
- `phase6-step1-unit-integration-test`
- `phase6-step2-contract-e2e-test`
- `phase6-step3-performance-load-test`

**flutter (1ch)**:
- `Step-30-CICD` (2회 중단)

### 2.2 해결 경로 (우선순위)

1. **Claude Code 구독 한도 리셋 후** (매일 자정 Asia/Seoul): subagent 1-chapter batch 재개.
   - 10-agent batch 당 성공률 60~80% 관찰 (batch 1 8/10, batch 2 8/10, batch 3 6/10).
   - 중단 chapter 재시도 시 여전히 실패 가능 — 반복 실패 chapter 는 경로 (2) 로.

2. **Anthropic API credit 재충전 후** `ai_diagram_describer.dart` 재실행:
   - ⚠️ **API key revoke 필수 선행** (세션 중 여러번 노출됨).
   - 해시 dedup 로 이미 생성된 ~2900 entries skip, 잔량만 재호출.
   - mysql step-01 / step-04 같은 subagent 반복 실패 chapter 에 필수.

3. **해시 정합성**: 모든 PR 의 subagent 가 CRLF 보존 + `sha256(utf8(body)).hex` 로직을 `ai_diagram_describer.dart` 와 동일 재현 확인. 재실행 시 기존 entries 와 충돌 없음.

---

## 3. 배포 릴리즈 권장

`develop` 이 `af25e0b` 까지 27 commits 앞서고, master 와 간격 큼. develop → master 릴리즈 PR 권장 (8차 배포):
- art-2 UI 크롬 (사용자 headed Chrome 검증 필수)
- Bible/Manifest 문서
- describer 캐시 ~1,387 entries 확장

---

## 4. subagent 운영 지식

### 4.1 Hard rules 위반 패턴 (반복 관찰)

- **main workspace 건드림**: 여러 subagent 가 `cd D:/workspace/dol` 또는 절대경로로 main repo 수정. 일부는 자가 감지 후 `git checkout --` revert, 일부는 미복구. 특히 mysql v2 (초기 시도) 는 `git reset --hard HEAD~1` 까지 실행하여 main session 의 art-2 working tree 를 날림.
- **다른 브랜치 checkout**: msa range 3 subagent 가 main session 의 `feature/art-2-ui-chrome` 을 건드리는 등.

### 4.2 Capacity 한계

- **1 chapter = 1 subagent** 원칙 유지 필요. 다중 chapter 할당 시 "blocks 분석만 하고 prose 작성 전 종료" 패턴 반복.
- 성공 chapter 는 일반적으로 blocks 수 ≤ 40. mysql step-04 (51 blocks) / step-07 (54 blocks) 는 예외적 성공.

### 4.3 품질 체크 포인트

- 템플릿 / 형태 메타 서술 / 단원 제목 반복 / 원문 cut-off fragment 인용 이 reject 신호.
- 최소 샘플 3 건 확인 필수. 양호한 샘플 prose 기준: PR #76 (Claude Haiku 실제) + PR #82 / #83 (subagent 성공 precedent).

---

## 5. 외부 사용자 작업 항목

### 5.1 ANTHROPIC_API_KEY revoke 반복 필수

이전 세션 + 이번 세션에서 chat log 에 **수차례 노출**. Anthropic 콘솔에서 revoke 후 재발급 — 그 다음 credit 재충전 전까지 describer 재실행 보류.

### 5.2 기존 worktree 정리

```bash
git worktree list  # agent-* 여러 worktree locked 상태
git worktree remove .claude/worktrees/agent-XXX  # 필요한 만큼
git branch -D worktree-agent-XXX feature/describer-*
```

- Batch 1~4 총 37 worktree 누적. 다수 locked. 일괄 정리 필요.

### 5.3 PR #81 art-2 배포 검증

- headed Chrome 에서 대화창·퀘스트 보드·버튼 시각 확인 (9-slice 렌더 + PixelNineSlice intrinsic size).
- PixelLab 이미지 품질 iterate 필요 시 art-2b 로 분리 (현 frame 128×128 은 정사각형, 원래 128×64 목표).

---

## 6. 체크인 체크리스트 (다음 세션 진입 시)

```
[ ] Claude Code 구독 한도 리셋 (자정 Asia/Seoul) 확인
[ ] ANTHROPIC_API_KEY revoke 확인 (세션 중 노출됨)
[ ] git fetch origin develop && git pull --ff-only
[ ] git worktree list 후 locked worktree 일괄 정리
[ ] 본 핸드오프 (2026-04-20) + 2026-04-19 핸드오프 읽기
[ ] subagent batch 재개 또는 API describer 재실행 선택
[ ] 잔량 24 chapter 순차 처리 → MERGE
[ ] develop → master 릴리즈 PR (8차 배포)
[ ] art-2 headed Chrome 검증 + 필요시 art-2b iterate
[ ] 이후: art-3 타이틀 씬 / art-4 중앙 홀 등 픽셀아트 로드맵 진행
```

---

## 7. 참조

- `docs/handoffs/2026-04-19-session-handoff.md` — 직전 세션
- `docs/designs/2026-04-19-requirements-consolidated.md` — R0~R7 원점
- `docs/pixel-art/PIXEL_ART_ASSET_BIBLE.md` / `docs/pixel-art/PIXEL_ART_ASSET_MANIFEST.md` — 스타일 규격
- `docs/pixel-art/PIXEL_ART_PROGRESS.md` — art-* 누적 추적
- `C:/Users/deepe/.claude/plans/optimized-yawning-rocket.md` — 픽셀아트 9-PR 플랜
- `tools/ai_diagram_describer.dart` — describer API 파이프라인 (credit 재충전 후 재실행)
