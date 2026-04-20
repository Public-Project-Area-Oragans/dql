# DOL 프로젝트 작업 가이드

## 프로젝트 개요

Flutter Web + Flame 기반 픽셀아트 게임형 문서 학습 시스템.
중세+스팀펑크+마법 세계관의 도서관에서 NPC 퀘스트를 통해 개발 문서를 학습한다.

## 핵심 규칙

### 아키텍처
- **Flame**: 도서관 씬, 스프라이트, 클릭 영역 감지 전담
- **Flutter 위젯**: 대화창, 퀴즈, 책 열람 등 복잡한 UI 전담
- **Riverpod**: 양 레이어 상태를 단일 소스로 관리
- **freezed 3.x**: 모든 데이터 모델은 `abstract class ... with _$...` 문법 사용

### 코드 생성
```bash
dart run build_runner build --delete-conflicting-outputs
```
- freezed, json_serializable, riverpod_generator 사용
- 생성 파일(`*.g.dart`, `*.freezed.dart`)은 git에 포함하지 않음

### 의존성 주의사항
- `hive_generator` 사용 금지 — `riverpod_lint`와 analyzer 버전 충돌. Hive는 `Box<String>`으로 사용
- `custom_lint`는 `^0.8.1` 이상 사용 (freezed_annotation 3.x 호환)

### 브랜치 전략
```
master ← develop ← feature/task-XX-*
```
- 모든 작업은 `develop`에서 feature 브랜치 생성
- PR → develop merge → 다음 Task 반복
- master는 안정 릴리즈만

### 콘텐츠 파이프라인
- 원본: `develop-study-documents` 레포 (git submodule → `docs-source/`)
- 변환: `dart run tools/content_builder.dart docs-source`
- 결과: `content/books/<category>/book.json`

### 배포
- Flutter Web + CanvasKit 렌더러
- GitHub Pages: `https://public-project-area-oragans.github.io/dol/`
- `--base-href /dol/` 필수

## 구현 계획

`docs/2026-04-17-dev-quest-library-plan.md` + [**로드맵 피벗 문서**](docs/2026-04-18-roadmap-pivot-personal-first.md) 참조.
현재 단계: **P0 (개인 사용용 전체 기능 완성)**. 1주일 대조군 실험 게이트 제거됨.
순차 로드맵: P0 완성 → P1 전 언어 실사용 → P2 팀 버전 → P3 공개 버전 (각 단계 별도 설계).

## 참조 문서

- [**세션 핸드오프 (2026-04-20)**](docs/2026-04-20-session-handoff.md) — **새 세션 진입 시 최우선 읽기. subagent describer 파이프라인 + fix-10b 캐시 ~3,126 entries 누적 + art-2 MERGED + 잔량 24 chapter.**
- [세션 핸드오프 (2026-04-19)](docs/2026-04-19-session-handoff.md) — 직전 세션
- [세션 핸드오프 (2026-04-18)](docs/2026-04-18-session-handoff.md) — 직직전 세션
- [**로드맵 피벗 (2026-04-18)**](docs/2026-04-18-roadmap-pivot-personal-first.md) — **현재 단계 P0 · 순차 로드맵. Phase 2 §10 게이트 대체.**
- [**Phase 계획**](docs/2026-04-18-phase-plan.md) — P0~P3 단계별 산출물·전환 기준·잔여 태스크 (P0-5 NPC 보강 포함)
- [**Task 워크플로**](docs/2026-04-18-task-workflow.md) — 브랜치→커밋→PR→머지→릴리즈 표준 절차
- [**작업 이력**](docs/2026-04-18-work-history.md) — PR #1~#54 전체 타임라인 + 배포 릴리즈 기록 (릴리즈 #54 = P0-5 NPC)
- [**트러블슈팅 저널**](docs/2026-04-18-troubleshooting-journal.md) — 세션 간 재발 방지용 문제·해결 축적. **같은 증상 만나면 먼저 여기 검색.**
- [Phase 1 설계](docs/2026-04-17-dev-quest-library-design.md) — 아키텍처 · 데이터 모델 · 화면 흐름 · **4개 분관 + NPC 역할** 정의 (백엔드=Java·Spring / 프론트=Dart·Flutter / DB=MySQL / 아키=MSA)
- [Phase 1 구현 계획](docs/2026-04-17-dev-quest-library-plan.md) — Task 상세
- [Phase 2 설계](docs/2026-04-18-dev-quest-library-phase2-design.md) — MSA 구조 조립 시뮬레이터 (§10은 로드맵 피벗이 대체)
- [Phase 3 다이어그램 위젯 이주 설계](docs/2026-04-18-diagram-widget-migration-design.md) — ASCII/표/Mermaid → Flutter 위젯
- [P0-5 NPC 분관 보강 설계](docs/2026-04-18-npc-branch-enhancement-design.md) — Claude API 기반 NPC Q&A + 책장 카테고리 필터 + 퀘스트 분관화
- [**2026-04-19 재작업 요구사항**](docs/2026-04-19-requirements-consolidated.md) — R0~R7 실사용 결함 + AI 설명 파이프라인 정책
- [2026-04-19 ASCII→위젯 이주 설계](docs/2026-04-19-ascii-to-widget-migration-design.md) — R2 기술 설계
- [Pixel Art Asset Bible](docs/PIXEL_ART_ASSET_BIBLE.md) / [Asset Manifest](docs/PIXEL_ART_ASSET_MANIFEST.md) — 픽셀아트 스타일·아키텍처 락
- [Pixel Art Anchor Approval](docs/PIXEL_ART_ANCHOR_APPROVAL.md) — art-0 승인 게이트
- [Pixel Art Progress](docs/PIXEL_ART_PROGRESS.md) — art-0~9 누적 진행
- [flutter-setup 스킬](../develop-study-documents/Skillbook/flutter-setup/) — Flutter 패키지/설정 레퍼런스
