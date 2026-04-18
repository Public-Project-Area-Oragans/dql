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

- [**로드맵 피벗 (2026-04-18)**](docs/2026-04-18-roadmap-pivot-personal-first.md) — **현재 단계·다음 단계 기준 문서. Phase 2 §10 게이트 대체.**
- [Phase 1 설계 문서](docs/2026-04-17-dev-quest-library-design.md) — 전체 아키텍처, 데이터 모델, 화면 흐름
- [Phase 1 구현 계획서](docs/2026-04-17-dev-quest-library-plan.md) — Task별 상세 구현 단계
- [Phase 2 설계 문서](docs/2026-04-18-dev-quest-library-phase2-design.md) — MSA 구조 조립 시뮬레이터 (§10 실험 게이트는 로드맵 피벗이 대체)
- [Phase 3 다이어그램 위젯 이주 설계](docs/2026-04-18-diagram-widget-migration-design.md) — ASCII/표/Mermaid → 순수 Flutter 위젯 이주 설계
- [**트러블슈팅 저널**](docs/2026-04-18-troubleshooting-journal.md) — 세션 간 재발 방지용 문제·해결 축적. **같은 증상 만나면 먼저 여기 검색.**
- [flutter-setup 스킬](../develop-study-documents/Skillbook/flutter-setup/) — Flutter 패키지/설정 레퍼런스
