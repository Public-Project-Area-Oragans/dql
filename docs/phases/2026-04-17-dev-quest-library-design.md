# Dev Quest Library — 설계 문서

> 도트풍 마법 도서관에서 퀘스트 기반으로 개발 문서를 학습하는 게임형 학습 시스템

- **작성일**: 2026-04-17
- **프로젝트 위치**: `D:\workspace\dol`
- **콘텐츠 소스**: `D:\workspace\develop-study-documents` (git submodule)
- **GitHub**: `https://github.com/Public-Project-Area-Oragans/dol.git`
- **배포**: GitHub Pages (`https://public-project-area-oragans.github.io/dol/`)
- **기술 스택**: Flutter Web + Flame + Riverpod

---

## 1. 프로젝트 개요

### 1.1 목적

`develop-study-documents` 레포지토리에 축적된 개발 학습 문서(Java, Dart, Flutter, MySQL, MSA 등)를 **픽셀아트 도서관 세계관** 안에서 **NPC 퀘스트 기반으로 학습**하는 인터랙티브 게임형 시스템.

### 1.2 타겟 사용자

- **초기**: 개인 학습 도구 (인증 없이 로컬 저장)
- **확장**: 공개 서비스 (GitHub OAuth 인증 + Gist 저장)

### 1.3 세계관

**중세 + 스팀펑크 + 마법** — 증기 동력과 마법이 공존하는 고대 도서관. 각 분관은 기술 분야를 상징하는 고유한 분위기를 가진다.

### 1.4 비주얼 스타일

- **고해상도 도트풍 일러스트** (Celeste/Eastward 스타일)
- **색상 팔레트**: 어두운 갈색(#0f0b07) + 금색(#b8860b) + 보라 마법광 + 녹색 증기
- **에셋 생성**: PixelLab AI (MCP 연동)

---

## 2. 아키텍처

### 2.1 하이브리드 구조 (Flame + Flutter)

```
┌─────────────────────────────────────────────┐
│                Flutter Web App              │
├──────────────────┬──────────────────────────┤
│   Flame Layer    │    Flutter UI Layer      │
│                  │                          │
│  - 도서관 배경    │  - 대화 시스템 (Dialog)   │
│  - NPC 스프라이트 │  - 퀴즈 UI (Form)        │
│  - 정령/골렘     │  - 인벤토리/진행도 패널   │
│  - 파티클 이펙트  │  - 메뉴/설정             │
│  - 씬 전환       │  - 책 열람 뷰어           │
│                  │                          │
│  GameWidget      │  Overlay Widgets         │
├──────────────────┴──────────────────────────┤
│              State Management               │
│         (Riverpod — 양 레이어 공유)           │
├─────────────────────────────────────────────┤
│              Data Layer                     │
│  - 문서 파서 (MD → Quest 데이터)             │
│  - 진행 상태 (GitHub Gist 연동)              │
│  - 에셋 매니저 (PixelLab 스프라이트)          │
├─────────────────────────────────────────────┤
│              Deploy: GitHub Pages           │
│  (flutter build web --web-renderer canvaskit)│
└─────────────────────────────────────────────┘
```

### 2.2 설계 원칙

- **Flame**은 순수 렌더링 담당 — 도서관 씬, 스프라이트, 클릭 영역 감지
- **Flutter 위젯**은 복잡한 UI 담당 — 텍스트, 폼, 스크롤, 마크다운 뷰어
- **Riverpod**으로 양 레이어 상태를 단일 소스로 관리
- 마크다운 문서는 빌드 타임에 JSON 퀘스트 데이터로 변환하여 번들링

---

## 3. 화면 흐름

### 3.1 전체 흐름

```
[스플래시/타이틀]
    │
    ▼
[GitHub 로그인] ── 스킵 가능 (로컬 저장 모드)
    │
    ▼
[중앙 홀] ◄─────────────────────────┐
    │                                │
    ├─ 클릭: 마법사 NPC ──► [백엔드 분관]  │
    ├─ 클릭: 연금술사 NPC ► [DB 분관]      │
    ├─ 클릭: 기계공 NPC ──► [프론트 분관]  │
    ├─ 클릭: 건축가 NPC ──► [아키 분관]    │
    ├─ 클릭: 퀘스트 게시판 ► [퀘스트 목록] │
    └─ 클릭: 뒤로/홀 ────────────────┘
```

### 3.2 분관 내부 흐름

```
[분관 진입]
    │
    ├─ NPC 클릭 → [대화 시작] → 퀘스트 수락
    │
    ├─ 책장 클릭 → 정령/골렘 안내 → [책 목록]
    │   └─ 책 선택 → [챕터 목록]
    │       └─ 챕터 진입 → [이론 페이지] + [인터랙티브 스텝 시뮬레이터]
    │
    └─ 퀘스트 진행 중 → [대화 분기 테스트]
        └─ 간헐적 → [혼합 퀴즈 화면]
            └─ 통과 → 퀘스트 완료 → 보상 연출
```

### 3.3 책 열람 구조

마크다운을 그대로 렌더링하지 않고, **이론 + 인터랙티브 스텝 시뮬레이터**로 재구성:

```
[챕터 진입]
    │
    ├─ [이론 페이지] ── MD 내용을 요약·재구성한 핵심 이론
    │   └─ 스팀펑크 UI로 렌더링 (코드 블록, 다이어그램 포함)
    │
    └─ [인터랙티브 스텝 시뮬레이터]
        ├─ 코드 실행 시뮬레이션 ── 한 줄씩 실행하며 상태 변화 시각화
        ├─ 구조 조립 ── 드래그&드롭으로 코드/아키텍처 블록 조립
        ├─ 흐름 추적 ── 요청/데이터 흐름을 따라가며 각 단계 확인
        └─ SQL 실습 ── 쿼리 입력 → 테이블 결과 시뮬레이션
```

### 3.4 주요 화면

| 화면 | 레이어 | 설명 |
|------|--------|------|
| 타이틀/로그인 | Flutter 전체 | 스팀펑크 로고 + GitHub 연동 버튼 |
| 중앙 홀 | Flame + Flutter 오버레이 | 4개 분관 입구 + NPC + 퀘스트 게시판 |
| 분관 내부 | Flame + Flutter 오버레이 | 해당 분야 책장 + NPC + 정령/골렘 |
| 대화 시스템 | Flutter 오버레이 | RPG 스타일 대화창, 선택지 분기 |
| 이론 뷰 | Flutter 전체 | MD에서 추출한 핵심 이론, 스팀펑크 책 스타일 UI |
| 시뮬레이터 | Flame + Flutter | 코드 스텝/구조 조립/흐름 추적/SQL 실습 |
| 퀴즈 화면 | Flutter 오버레이 | 객관식/코드 빈칸/OX 혼합 |

### 3.5 레이아웃 확장 전략

- **초기**: 중앙 홀 + 4개 분관 (백엔드/프론트엔드/DB/아키텍처)
- **확장**: 문서 카테고리 증가 시 다층 도서관(타워형)으로 전환. 층별 분야 배치 + 엘리베이터/계단 UI 추가.

---

## 4. 데이터 모델

### 4.1 핵심 엔티티

```
Library
  └─ wings: List<Wing>

Wing (분관)
  ├─ id, name, role (backend/frontend/db/architecture)
  ├─ npc: NPC
  ├─ shelves: List<Bookshelf>
  └─ spirits: List<Spirit>

NPC
  ├─ id, name, role, spriteAsset
  ├─ dialogues: List<DialogueTree>
  └─ quests: List<Quest>

Bookshelf (책장)
  ├─ id, category (java, dart, flutter, mysql, msa)
  └─ books: List<Book>

Book (= 학습 문서 폴더)
  ├─ id, title, category
  ├─ chapters: List<Chapter>
  └─ totalProgress: double

Chapter (= 마크다운 파일 1개)
  ├─ id, title, order
  ├─ theory: TheoryContent
  ├─ simulator: SimulatorConfig
  └─ isCompleted: bool

TheoryContent
  ├─ sections: List<TheorySection>
  ├─ codeExamples: List<CodeBlock>
  └─ diagrams: List<DiagramData>

SimulatorConfig
  ├─ type: SimulatorType (codeStep/blockAssembly/flowTrace/sqlLab)
  ├─ steps: List<SimStep>
  └─ completionCriteria: CompletionRule

Quest (퀘스트)
  ├─ id, title, description
  ├─ npcId, requiredChapters: List<String>
  ├─ dialogueTree: DialogueTree
  ├─ mixedQuiz: MixedQuiz?
  ├─ reward: QuestReward
  └─ status: QuestStatus (locked/available/inProgress/completed)

DialogueTree (대화 분기)
  ├─ nodes: List<DialogueNode>
  └─ startNodeId: String

DialogueNode
  ├─ id, speakerName, text
  ├─ choices: List<DialogueChoice>
  └─ isCorrectPath: bool?

MixedQuiz
  ├─ questions: List<QuizQuestion>
  └─ passThreshold: int

QuizQuestion
  ├─ type: QuizType (multipleChoice/codeFill/oxJudge)
  ├─ prompt, options, correctAnswer
  └─ explanation: String

PlayerProgress (GitHub Gist 저장)
  ├─ playerId              ── GitHub 로그인: GitHub user ID / 스킵: uuid.v4() 로컬 생성
  ├─ completedChapters: Set<String>
  ├─ completedQuests: Set<String>
  ├─ currentWing: String?
  └─ lastSavedAt: DateTime

QuestReward (Phase 1: 단순 완료 표시)
  ├─ xp: int               ── 경험치 (Phase 1: 표시만, 레벨 시스템은 이후 확장)
  └─ title: String?         ── 칭호 (이후 확장)
```

### 4.2 문서 매핑

| study-documents 구조 | 게임 내 구조 |
|----------------------|-------------|
| `Java & Spring/` 폴더 (48 파일) | Book 1권 → 백엔드 분관 책장 |
| `Dart Programing/` 폴더 (24 파일) | Book 1권 → 프론트엔드 분관 책장 |
| `Flutter Programing/` 폴더 (32 파일) | Book 1권 → 프론트엔드 분관 책장 |
| `Mysql Study/` 폴더 (31 파일) | Book 1권 → DB 분관 책장 |
| `MSA/` 폴더 (46 파일) | Book 1권 → 아키텍처 분관 책장 |
| step/phase MD 파일 1개 | Chapter 1개 (이론 + 시뮬레이터) |

---

## 5. NPC 설계

### 5.1 역할 기반 NPC

| NPC | 이름 | 역할 | 비주얼 컨셉 | 담당 |
|-----|------|------|-------------|------|
| 마법사 | 아르카누스 | 백엔드 마스터 | 보라 로브, 부유하는 코드 스크롤, 수정 지팡이 | Java & Spring |
| 연금술사 | 메르쿠리아 | 데이터 마스터 | 가죽 앞치마, 증류 장치, 빛나는 데이터 약병 | MySQL |
| 기계공 | 코그윈 | 프론트엔드 마스터 | 고글, 기어 팔찌, 증기 동력 도구 벨트 | Dart & Flutter |
| 건축가 | 모뉴멘타 | 아키텍처 마스터 | 도면 두루마리, 컴퍼스, 미니어처 건축 모형 | MSA |

### 5.2 보조 정령/골렘

- **책 정령**: 떠다니는 빛나는 책 형태. 각 책장에 배치되어 책 목록/내용 안내.
- **책장 골렘**: 나무+기어 소재의 작은 골렘. 책장 정리/추천 역할.

### 5.3 퀘스트 구조

- NPC가 퀘스트를 부여 (특정 챕터 학습 요구)
- 학습 완료 후 NPC에게 복귀 → **대화 분기 테스트** (메인)
- 간헐적으로 **혼합 퀴즈** (객관식 + 코드 빈칸 + OX) 출제
- 통과 시 퀘스트 완료 + 보상 연출

### 5.4 상호작용 방식

- **포인트 앤 클릭**: 도서관 전경에서 NPC/책장을 직접 클릭
- 캐릭터 이동 없음, 클릭 시 즉시 상호작용 시작

---

## 6. 프로젝트 구조

```
D:\workspace\dol\
│
├─ lib/
│   ├─ main.dart
│   ├─ app.dart
│   │
│   ├─ core/
│   │   ├─ constants/          ── 색상, 사이즈, 에셋 경로
│   │   ├─ theme/              ── 스팀펑크 테마 (다크 기반)
│   │   ├─ router/             ── GoRouter 설정
│   │   └─ utils/
│   │
│   ├─ data/
│   │   ├─ models/             ── freezed 데이터 모델
│   │   ├─ repositories/
│   │   ├─ datasources/
│   │   │   ├─ local/          ── SharedPreferences / Hive
│   │   │   └─ remote/         ── GitHub Gist API
│   │   └─ parsers/
│   │       └─ md_to_quest_parser.dart
│   │
│   ├─ domain/
│   │   ├─ entities/
│   │   ├─ usecases/
│   │   └─ providers/          ── Riverpod 프로바이더
│   │
│   ├─ game/                   ── Flame 레이어
│   │   ├─ dev_quest_game.dart
│   │   ├─ scenes/
│   │   │   ├─ central_hall_scene.dart
│   │   │   ├─ wing_scene.dart
│   │   │   └─ title_scene.dart
│   │   ├─ components/
│   │   │   ├─ npc_component.dart
│   │   │   ├─ bookshelf_component.dart
│   │   │   ├─ spirit_component.dart
│   │   │   └─ particle_effects.dart
│   │   └─ mixins/
│   │       └─ clickable_mixin.dart
│   │
│   ├─ presentation/           ── Flutter UI 레이어
│   │   ├─ screens/
│   │   │   ├─ game_screen.dart
│   │   │   ├─ book_reader_screen.dart
│   │   │   └─ login_screen.dart
│   │   ├─ overlays/
│   │   │   ├─ dialogue_overlay.dart
│   │   │   ├─ quiz_overlay.dart
│   │   │   ├─ quest_board_overlay.dart
│   │   │   └─ hud_overlay.dart
│   │   ├─ simulators/
│   │   │   ├─ code_step_simulator.dart
│   │   │   ├─ block_assembly.dart
│   │   │   ├─ flow_trace.dart
│   │   │   └─ sql_lab.dart
│   │   └─ widgets/
│   │       ├─ steampunk_button.dart
│   │       ├─ theory_card.dart
│   │       └─ quest_badge.dart
│   │
│   └─ services/
│       ├─ gist_service.dart
│       ├─ asset_manager.dart
│       └─ audio_service.dart
│
├─ assets/
│   ├─ sprites/                ── PixelLab AI 생성 에셋
│   │   ├─ backgrounds/
│   │   ├─ npcs/
│   │   ├─ spirits/
│   │   ├─ bookshelves/
│   │   └─ ui/
│   ├─ fonts/
│   └─ audio/
│
├─ content/                    ── 퀘스트 콘텐츠 (빌드 결과물)
│   ├─ books/
│   │   ├─ java-spring/
│   │   ├─ dart/
│   │   ├─ flutter/
│   │   ├─ mysql/
│   │   └─ msa/
│   └─ quests/
│
├─ docs/                       ── 프로젝트 문서
│   └─ 2026-04-17-dev-quest-library-design.md
│
├─ docs-source/                ── git submodule (develop-study-documents)
│
├─ tools/
│   └─ content_builder.dart    ── MD → JSON 변환 스크립트
│
├─ .github/
│   └─ workflows/
│       └─ sync-and-deploy.yml ── submodule 동기화 + 빌드 + 배포
│
├─ web/
├─ pubspec.yaml
└─ README.md
```

---

## 7. 의존성

```yaml
dependencies:
  flutter:
    sdk: flutter

  # 게임 엔진
  flame: ^1.21.0
  flame_audio: ^2.10.4

  # 상태관리
  flutter_riverpod: ^3.1.0
  riverpod_annotation: ^4.0.0

  # 라우팅
  go_router: ^17.2.0

  # 네트워크
  dio: ^5.9.2
  pretty_dio_logger: ^1.4.0

  # JSON / 모델
  json_annotation: ^4.9.0
  freezed_annotation: ^3.0.0

  # 로컬 저장소
  shared_preferences: ^2.3.3
  hive: ^2.2.3
  hive_flutter: ^1.1.0

  # UI
  flutter_screenutil: ^5.9.3
  flutter_markdown: ^0.7.6
  flutter_svg: ^2.0.10+1
  cached_network_image: ^3.4.1

  # 유틸
  intl: ^0.19.0
  uuid: ^4.5.1
  collection: ^1.18.0

dev_dependencies:
  build_runner: ^2.4.0
  json_serializable: ^6.8.0
  freezed: ^3.0.0
  hive_generator: ^2.0.1
  riverpod_generator: ^4.0.0+1
  riverpod_lint: ^3.1.0
  custom_lint: ^0.6.4
```

---

## 8. 에셋 파이프라인

### 8.1 PixelLab MCP 생성 목록

| 카테고리 | 에셋 | 설명 |
|----------|------|------|
| backgrounds | central_hall | 중앙 홀 (증기 파이프 + 마법 수정 샹들리에) |
| backgrounds | wing_backend | 마법사 탑 내부 |
| backgrounds | wing_frontend | 기계공 작업장 |
| backgrounds | wing_database | 연금술사 실험실 |
| backgrounds | wing_architecture | 건축가 설계실 |
| npcs | wizard | 마법사 아르카누스 (idle, talk, quest-give) |
| npcs | alchemist | 연금술사 메르쿠리아 (idle, talk, brew) |
| npcs | mechanic | 기계공 코그윈 (idle, talk, tinker) |
| npcs | architect | 건축가 모뉴멘타 (idle, talk, blueprint) |
| spirits | book_spirit | 떠다니는 빛나는 책 |
| spirits | shelf_golem | 나무+기어 소재 골렘 |
| bookshelves | magic/steam/crystal | 3종 책장 변형 |
| ui | dialogue_frame | 양피지 + 기어 장식 대화창 |
| ui | quiz_frame | 퀴즈 패널 프레임 |
| ui | quest_board | 나무 + 핀 퀘스트 게시판 |
| ui | buttons | normal/hover/pressed 3상태 |
| ui | hud_frame | 진행도 바, 메뉴 프레임 |

### 8.2 스프라이트 처리

- PixelLab AI 생성 → PNG 출력
- 스프라이트 시트 패킹 (TexturePacker 또는 수동)
- Flame `SpriteSheet` / `SpriteAnimation` 설정

---

## 9. 배포 전략

### 9.1 빌드 파이프라인

```
1. tools/content_builder.dart 실행
   └─ docs-source/*.md → content/books/*.json

2. flutter build web --release --web-renderer canvaskit --base-href /dol/
   └─ build/web/ 생성

3. build/web/ → gh-pages 브랜치 배포
   └─ https://public-project-area-oragans.github.io/dol/
```

### 9.2 콘텐츠 자동 동기화

| 위치 | 워크플로우 | 역할 |
|------|-----------|------|
| `develop-study-documents` | `notify-game.yml` | MD 변경 push 시 dol에 repository_dispatch 이벤트 전송 |
| `dol` | `sync-and-deploy.yml` | 이벤트 수신 → submodule 갱신 → content_builder → Flutter 빌드 → gh-pages 배포 |

### 9.3 동기화 흐름

```
develop-study-documents에서 MD 수정 & push
    │
    ▼
notify-game.yml → repository_dispatch 이벤트 전송
    │
    ▼
dol의 sync-and-deploy.yml 트리거
    │
    ├─ git submodule update --remote
    ├─ dart run tools/content_builder.dart
    ├─ flutter build web --release --web-renderer canvaskit
    └─ gh-pages 브랜치에 배포
```

---

## 10. 우선 구현 범위 (Phase 1)

### 10.1 타겟 문서

| 카테고리 | 문서 수 | 분관 |
|----------|---------|------|
| Java & Spring | 48 챕터 | 백엔드 분관 |
| Dart | 24 챕터 | 프론트엔드 분관 |
| Flutter | 32 챕터 | 프론트엔드 분관 |
| MySQL | 31 챕터 | DB 분관 |
| MSA | 46 챕터 | 아키텍처 분관 |

### 10.2 Phase 1 목표

1. 프로젝트 스캐폴딩 + Flame/Flutter 하이브리드 기반 구축
2. 중앙 홀 씬 + 4개 분관 씬 (배경 + NPC + 책장)
3. NPC 대화 시스템 + 퀘스트 수락/완료 흐름
4. 책 열람 (이론 뷰 + 코드 스텝 시뮬레이터 1종)
5. 대화 분기 테스트 + 혼합 퀴즈 (간헐)
6. GitHub Gist 진행 저장
7. GitHub Pages 배포 + 자동 동기화

### 10.3 이후 확장

- 추가 문서 카테고리 (Python, React, Docker, K8s 등)
- 다층 도서관 레이아웃 전환
- 시뮬레이터 타입 추가 (구조 조립, 흐름 추적, SQL 실습)
- BGM/효과음
- 보상 시스템 (뱃지, 칭호)
