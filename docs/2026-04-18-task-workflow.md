# DOL — Task 워크플로 표준

> 하나의 Task(기능/버그/문서)가 브랜치 생성부터 master 릴리즈·프로덕션 배포까지 지나가는 표준 절차.
> 이 문서는 **본 프로젝트의 실제 관행**(PR #17~#45의 경험)을 기준으로 정리됨.

- **최초 작성**: 2026-04-18
- **전제**: `develop` 브랜치에서 시작, master는 릴리즈만.

---

## 0. 한눈에 보기

```
┌─ gh cli 체크
├─ develop 동기화
├─ feature/* 브랜치
├─ 구현 + 테스트
├─ 로컬 analyze + test pass 확인
├─ commit (Conventional Commits 스타일)
├─ push → PR (base: develop)
├─ CI 모니터링 (test + integration)
│      실패 시 → 원인 파악 → 추가 커밋 → CI 재실행
├─ merge (squash, develop)
├─ 다음 Task 반복 ...
│
└─ 주기적 release PR (base: master, head: develop)
      └─ 머지(일반 merge, history 보존) → Sync & Deploy
         └─ CDN 전파 대기 → 배포 URL 검증
```

---

## 1. 시작 전 체크

```bash
gh --version && gh auth status | head -5
git branch --show-current
git status --short
```

- 미반영 변경 있으면 stash/commit 후 깨끗한 상태에서 시작.
- develop이 최신인지 확인:
  ```bash
  git checkout develop && git pull origin develop
  ```

---

## 2. 브랜치 네이밍

- **feature**: `feature/<범위>-<주제>` (예: `feature/task-2-6b-widget-interaction-tests`)
- **fix**: `fix/<대상>` (예: `fix/web-renderer-removed`)
- **docs**: `docs/<주제>` 또는 `feature/<주제>` (본 프로젝트는 feature로도 허용)
- **chore/ci**: `feature/ci-<주제>` (예: `feature/ci-integration-strict`)

```bash
git checkout -b feature/<범위>-<주제>
```

---

## 3. 구현 루프

1. **작은 단위 단위 테스트** 먼저 (TDD 필수는 아니지만 회귀 가드 우선).
2. 코드 변경.
3. 관련 테스트 작성/수정:
   - 단위: `test/**/*_test.dart`
   - 위젯: `test/presentation/**`
   - integration: `integration_test/*.dart` (CI에서만 실행)
4. freezed/riverpod 변경 시 `dart run build_runner build --delete-conflicting-outputs`.

### 3.1 필수 통과 조건 (커밋 전)

```bash
flutter analyze lib/      # No issues
flutter test              # 전부 green
```

info 레벨 warning도 0이어야 함 (CI가 exit 1 처리).

---

## 4. 커밋

### 4.1 메시지 스타일 (Conventional Commits 변형)

```
<type>(<scope>): <요약 한 줄>

<본문: 변경 이유, 영향, 테스트 결과>

<푸터: How to verify / 참조 PR>
```

**type**: `feat`, `fix`, `chore`, `docs`, `test`, `refactor`, `ci`, `perf`, `style`.
**scope**: Task 코드 or 다이어그램 서브 PR (`task-2-6b`, `diagram-7`, `ci`, `troubleshooting` 등).

### 4.2 예시

```
feat(diagram-9): flowchart 인용 라벨 내 `()` 괄호 보존

PR #38 배포 후 재측정에서 raw flowchart 236 → 235로 1개만 회복된
원인 조사. 기존 `[^\]\)\}"]+` 라벨 패턴이 따옴표 안 `)`에서 조기
종료되는 고질적 버그.

- _nodeShapePattern 라벨 부분을 quoted / unquoted 두 alternative로 분기.
- 라벨 캡처: m.group(3) ?? m.group(4).

How to verify:
- flutter test → 133/133 pass
- flutter analyze lib/ → No issues
```

### 4.3 셸에서 Heredoc 주의점

`()` 포함한 본문은 `bash -c "$(cat <<'EOF' ... EOF)"` 형식에서 괄호가 명령 치환으로 해석될 수 있음. 긴 본문은 **파일로 작성 후 `--body-file` 사용**:

```bash
gh pr create --base develop --title "..." --body-file .omc/pr_body.md
```

---

## 5. Push + PR

```bash
git push -u origin <branch>
gh pr create --base develop \
  --title "<type>(<scope>): <요약>" \
  --body-file .omc/pr_body.md
```

**PR 본문 템플릿** (`.omc/pr_body.md`):

```markdown
## Summary

<변경 목적 + 영향 1-2 단락>

## 변경

### `<파일 경로>`

- 변경 1
- 변경 2

## 테스트 (N 신규)

- 케이스 1
- 케이스 2

## Test plan

- [x] `flutter test` → N/N pass
- [x] `flutter analyze lib/` → No issues
- [ ] 머지 후 확인할 것

🤖 Generated with [Claude Code](https://claude.com/claude-code)
```

---

## 6. CI 모니터링

### 6.1 필수 통과 (strict)

- `test` 잡: `flutter pub get` → `build_runner` → `content_builder` → `flutter analyze lib/` → `flutter test`
- `integration` 잡: 위 + `flutter drive --driver=test_driver/integration_test.dart ...`

PR #44(2026-04-18)부터 두 잡 모두 머지 차단 조건.

### 6.2 CI 실패 시 행동

1. `gh pr checks <N>` 으로 실패 잡 확인.
2. `gh run view <runId> --log-failed` 로 실패 원인.
3. 로컬에서 재현 → 수정 → 새 커밋 → push (자동 CI 재실행).
4. `--amend` 금지 (훅 실패 상황 등 특수 케이스 제외). **새 커밋으로 수정**.

### 6.3 flaky 잡 정책

- 새 CI 스텝은 `continue-on-error: true`로 시작 가능.
- 2~3회 연속 녹색 누적 후 strict로 승격 (예: PR #44의 integration).

---

## 7. 머지

### 7.1 develop 머지 (feature → develop)

**squash 권장** (history 깔끔, 머지 커밋 자동 제목).

```bash
gh pr merge <N> --squash --delete-branch
```

### 7.2 master 머지 (develop → master, 릴리즈)

**일반 merge** (history 보존).

```bash
gh pr merge <N> --merge
```

### 7.3 안전 수칙

- master 머지는 배포 파이프라인을 자동 실행 → 되돌리기 비용 큼. 로컬 테스트 + CI 녹색 + PR 리뷰 후 실행.
- 금지:
  - `--no-verify` (훅 스킵)
  - `git push --force` master
  - `rm -rf` 류 destructive 명령 사용자 승인 없이

---

## 8. 릴리즈 (develop → master)

### 8.1 시점

- 누적된 feature N개가 "배포 가능 단위"로 묶일 때.
- 긴급 수정 1건이어도 즉시 릴리즈 가능 (Phase 3 PR #36, #39, #41 등).

### 8.2 절차

```bash
git checkout develop && git pull origin develop
gh pr create --base master --head develop \
  --title "release: <요약>" \
  --body-file .omc/release_body.md
```

본문에는 포함 PR 목록 + 예상 효과 + 검증 체크리스트 포함.

### 8.3 머지 + 배포 감시

```bash
gh pr merge <N> --merge
gh run list --workflow=sync-and-deploy.yml --limit 1 --json databaseId,status
```

Sync & Deploy 성공 후 GitHub Pages CDN 전파 대기 (평균 1~3분, 최대 5분).

### 8.4 배포 검증 패턴

```bash
# 1. 사이트 up 확인
curl -sI https://public-project-area-oragans.github.io/dol/

# 2. book.json 에셋 존재 + 사이즈 타당성
curl -sI https://public-project-area-oragans.github.io/dol/assets/content/books/msa/book.json | grep -iE 'last-modified|content-length'

# 3. 블록 타입 분포 (Python with PYTHONIOENCODING=utf-8)
python .omc/analyze_raw34.py    # 또는 유사 스크립트
```

---

## 9. Checkpoint별 재개 지점

세션 중단 후 재개 시 다음 순서로 확인:

1. **현재 브랜치**: `git branch --show-current`
2. **작업 트리 상태**: `git status --short`
3. **develop과의 diff**: `git log origin/develop..HEAD --oneline`
4. **열린 PR 목록**: `gh pr list --state open`
5. **최근 CI 실행**: `gh run list --limit 5`
6. **메모리/문서**: MEMORY.md, `docs/2026-04-18-troubleshooting-journal.md` 해당 주제 검색.

---

## 10. 안티패턴 (하지 말 것)

- `--amend` 빈번 사용 — 머지 이력 꼬임.
- 단일 PR에 **다중 추정 수정**을 묶어 넣기 — 실측 원인 분리 어려움. 한 변경 → 한 PR.
- `master` 직접 push — 절대 금지.
- CI 녹색 없이 머지 — strict 정책 우회.
- info 레벨 warning 방치 — 다음 PR에서 CI 실패로 돌아옴.
- 문서 생성 누락 — 큰 결정(로드맵 피벗 등)은 반드시 문서화.

---

## 11. 참조

- 로드맵: `docs/2026-04-18-roadmap-pivot-personal-first.md`
- Phase 계획: `docs/2026-04-18-phase-plan.md`
- 작업 이력: `docs/2026-04-18-work-history.md`
- 트러블슈팅: `docs/2026-04-18-troubleshooting-journal.md`
- 프로젝트 가이드: `CLAUDE.md`
