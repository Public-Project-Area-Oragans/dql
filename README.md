# DOL — Dev Quest Library

> 도트풍 마법 도서관에서 퀘스트 기반으로 개발 문서를 학습하는 게임형 학습 시스템

## 개요

[develop-study-documents](https://github.com/Qahnaarin/develop-study-documents) 레포지토리에 축적된 개발 학습 문서(Java, Dart, Flutter, MySQL, MSA 등)를 **픽셀아트 도서관 세계관** 안에서 **NPC 퀘스트 기반으로 학습**하는 인터랙티브 게임입니다.

## 세계관

**중세 + 스팀펑크 + 마법** — 증기 동력과 마법이 공존하는 고대 도서관

| NPC | 이름 | 역할 | 담당 |
|-----|------|------|------|
| 마법사 | 아르카누스 | 백엔드 마스터 | Java & Spring |
| 연금술사 | 메르쿠리아 | 데이터 마스터 | MySQL |
| 기계공 | 코그윈 | 프론트엔드 마스터 | Dart & Flutter |
| 건축가 | 모뉴멘타 | 아키텍처 마스터 | MSA |

## 기술 스택

| 구성 | 기술 |
|------|------|
| 프레임워크 | Flutter Web 3.41.x |
| 게임 엔진 | Flame 1.21.x |
| 상태 관리 | Riverpod 3.x |
| 라우팅 | GoRouter 17.x |
| 데이터 모델 | freezed 3.x |
| 저장 | Hive (로컬) + GitHub Gist (원격) |
| 에셋 생성 | PixelLab AI (MCP) |
| 배포 | GitHub Pages (CanvasKit) |

## 아키텍처

```
┌──────────────────┬──────────────────────────┐
│   Flame Layer    │    Flutter UI Layer       │
│  도서관 배경/NPC  │  대화/퀴즈/책 열람 UI     │
├──────────────────┴──────────────────────────┤
│         Riverpod (상태 관리 공유)             │
├─────────────────────────────────────────────┤
│         Data Layer (MD→JSON, Gist)          │
└─────────────────────────────────────────────┘
```

## 시작하기

```bash
# 의존성 설치
flutter pub get

# 코드 생성 (freezed, json_serializable)
dart run build_runner build --delete-conflicting-outputs

# 콘텐츠 빌드 (MD → JSON)
dart run tools/content_builder.dart docs-source

# 개발 서버 실행
flutter run -d chrome --web-port=8080

# 릴리즈 빌드
flutter build web --release --web-renderer canvaskit --base-href /dol/
```

## 프로젝트 구조

```
lib/
├─ core/          # 상수, 테마, 라우터
├─ data/          # freezed 모델, 리포지토리, 데이터소스
├─ domain/        # 프로바이더, 유스케이스
├─ game/          # Flame 씬, 컴포넌트, 믹스인
├─ presentation/  # 화면, 오버레이, 시뮬레이터, 위젯
└─ services/      # Gist 서비스, 에셋 매니저
```

## 문서

- [설계 문서](docs/2026-04-17-dev-quest-library-design.md)
- [구현 계획서](docs/2026-04-17-dev-quest-library-plan.md)

## 브랜치 전략

```
master ← develop ← feature/task-XX-*
```

- `master`: 안정 릴리즈
- `develop`: 개발 통합
- `feature/*`: Task별 기능 브랜치 → develop PR → merge

## 라이선스

Private Project
