# Dev Quest Library — Phase 1 구현 계획

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 도트풍 마법 도서관에서 퀘스트 기반으로 개발 문서를 학습하는 Flutter Web 게임의 Phase 1 구현

**Architecture:** Flame 게임 엔진으로 도서관 씬/NPC/책장을 렌더링하고, Flutter 위젯 오버레이로 대화/퀴즈/책 열람 UI를 구현하는 하이브리드 구조. Riverpod으로 양 레이어 상태를 통합 관리하며, 마크다운 문서를 빌드 타임에 JSON으로 변환하여 번들링한다.

**Tech Stack:** Flutter Web 3.41.x, Flame 1.21.x, Riverpod 3.x, freezed 3.x, GoRouter 17.x, Dio 5.9.x, Hive 2.2.x, GitHub Gist API

**GitHub:** `https://github.com/Public-Project-Area-Oragans/dol.git`

**Spec:** `docs/2026-04-17-dev-quest-library-design.md`

---

## File Structure

```
D:\workspace\dol\
├─ lib/
│   ├─ main.dart                              ── 앱 진입점
│   ├─ app.dart                               ── MaterialApp + ProviderScope
│   │
│   ├─ core/
│   │   ├─ constants/
│   │   │   ├─ app_colors.dart                ── 스팀펑크 색상 팔레트
│   │   │   ├─ app_sizes.dart                 ── 공통 사이즈 상수
│   │   │   └─ asset_paths.dart               ── 에셋 경로 상수
│   │   ├─ theme/
│   │   │   └─ steampunk_theme.dart           ── 다크 기반 스팀펑크 테마
│   │   └─ router/
│   │       └─ app_router.dart                ── GoRouter 설정
│   │
│   ├─ data/
│   │   ├─ models/
│   │   │   ├─ library_model.dart             ── Library, Wing freezed 모델
│   │   │   ├─ npc_model.dart                 ── NPC freezed 모델
│   │   │   ├─ book_model.dart                ── Book, Chapter, TheoryContent, SimulatorConfig
│   │   │   ├─ quest_model.dart               ── Quest, DialogueTree, DialogueNode
│   │   │   ├─ quiz_model.dart                ── MixedQuiz, QuizQuestion
│   │   │   └─ player_progress_model.dart     ── PlayerProgress
│   │   ├─ repositories/
│   │   │   ├─ content_repository.dart        ── 콘텐츠 JSON 로드
│   │   │   └─ progress_repository.dart       ── 진행 상태 CRUD
│   │   └─ datasources/
│   │       ├─ local/
│   │       │   └─ hive_datasource.dart       ── Hive 로컬 저장
│   │       └─ remote/
│   │           └─ gist_datasource.dart       ── GitHub Gist API
│   │
│   ├─ domain/
│   │   └─ providers/
│   │       ├─ content_providers.dart         ── 콘텐츠 프로바이더
│   │       ├─ progress_providers.dart        ── 진행 상태 프로바이더
│   │       ├─ quest_providers.dart           ── 퀘스트 상태 프로바이더
│   │       └─ game_providers.dart            ── 게임 씬 상태 프로바이더
│   │
│   ├─ game/
│   │   ├─ dol_game.dart                      ── FlameGame 메인 클래스
│   │   ├─ scenes/
│   │   │   ├─ title_scene.dart               ── 타이틀 씬
│   │   │   ├─ central_hall_scene.dart        ── 중앙 홀 씬
│   │   │   └─ wing_scene.dart               ── 분관 씬 (재사용)
│   │   ├─ components/
│   │   │   ├─ npc_component.dart             ── NPC 스프라이트 + 클릭
│   │   │   ├─ bookshelf_component.dart       ── 책장 스프라이트 + 클릭
│   │   │   ├─ spirit_component.dart          ── 정령/골렘 스프라이트
│   │   │   ├─ wing_door_component.dart       ── 분관 입구 클릭 영역
│   │   │   └─ particle_effects.dart          ── 마법 파티클
│   │   └─ mixins/
│   │       └─ tappable_component.dart        ── 포인트앤클릭 공통 믹스인
│   │
│   ├─ presentation/
│   │   ├─ screens/
│   │   │   ├─ game_screen.dart               ── GameWidget + 오버레이 통합
│   │   │   ├─ login_screen.dart              ── GitHub 로그인 / 스킵
│   │   │   └─ book_reader_screen.dart        ── 책 열람 (이론 + 시뮬레이터)
│   │   ├─ overlays/
│   │   │   ├─ dialogue_overlay.dart          ── NPC 대화창
│   │   │   ├─ quiz_overlay.dart              ── 혼합 퀴즈
│   │   │   ├─ quest_board_overlay.dart       ── 퀘스트 게시판
│   │   │   └─ hud_overlay.dart               ── 진행도/메뉴 HUD
│   │   ├─ simulators/
│   │   │   └─ code_step_simulator.dart       ── 코드 스텝 시뮬레이터 (Phase 1)
│   │   └─ widgets/
│   │       ├─ steampunk_button.dart          ── 스팀펑크 버튼
│   │       ├─ steampunk_panel.dart           ── 스팀펑크 패널 프레임
│   │       ├─ theory_card.dart               ── 이론 카드 위젯
│   │       └─ quest_badge.dart               ── 퀘스트 뱃지
│   │
│   └─ services/
│       ├─ gist_service.dart                  ── GitHub Gist CRUD 서비스
│       └─ asset_manager.dart                 ── 스프라이트 시트 관리
│
├─ assets/
│   ├─ sprites/
│   │   ├─ backgrounds/                       ── 배경 (placeholder → PixelLab 교체)
│   │   ├─ npcs/                              ── NPC (placeholder → PixelLab 교체)
│   │   ├─ spirits/                           ── 정령/골렘
│   │   ├─ bookshelves/                       ── 책장
│   │   └─ ui/                                ── UI 프레임
│   └─ fonts/                                 ── 픽셀/스팀펑크 폰트
│
├─ content/                                   ── JSON 콘텐츠 (빌드 결과물)
│   ├─ books/
│   └─ quests/
│
├─ docs-source/                               ── git submodule
│
├─ tools/
│   └─ content_builder.dart                   ── MD → JSON 변환
│
├─ test/
│   ├─ data/
│   │   ├─ models/
│   │   │   ├─ book_model_test.dart
│   │   │   ├─ quest_model_test.dart
│   │   │   └─ player_progress_test.dart
│   │   └─ repositories/
│   │       ├─ content_repository_test.dart
│   │       └─ progress_repository_test.dart
│   ├─ domain/
│   │   └─ providers/
│   │       ├─ quest_providers_test.dart
│   │       └─ progress_providers_test.dart
│   ├─ services/
│   │   └─ gist_service_test.dart
│   ├─ tools/
│   │   └─ content_builder_test.dart
│   └─ presentation/
│       ├─ widgets/
│       │   └─ steampunk_button_test.dart
│       └─ simulators/
│           └─ code_step_simulator_test.dart
│
├─ .github/
│   └─ workflows/
│       ├─ ci.yml                             ── PR 체크 (test + lint)
│       └─ sync-and-deploy.yml                ── submodule 동기화 + 배포
│
├─ pubspec.yaml
├─ analysis_options.yaml
└─ .gitignore
```

---

## Task 1: 프로젝트 스캐폴딩

**Files:**
- Create: `pubspec.yaml`, `lib/main.dart`, `lib/app.dart`, `analysis_options.yaml`, `.gitignore`
- Create: `lib/core/constants/app_colors.dart`
- Create: `lib/core/theme/steampunk_theme.dart`
- Create: `lib/core/router/app_router.dart`

- [ ] **Step 1: Flutter 프로젝트 생성**

```bash
cd D:\workspace\dol
flutter create --platforms web --org com.dol .
```

Expected: `lib/main.dart`, `web/`, `pubspec.yaml` 등 생성

- [ ] **Step 2: pubspec.yaml 의존성 설정**

```yaml
name: dol
description: Dev Quest Library — 게임형 문서 학습 시스템
publish_to: 'none'
version: 0.1.0

environment:
  sdk: ^3.11.0

dependencies:
  flutter:
    sdk: flutter

  # 게임 엔진
  flame: ^1.21.0

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

  # 유틸
  intl: ^0.19.0
  uuid: ^4.5.1
  collection: ^1.18.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  build_runner: ^2.4.0
  json_serializable: ^6.8.0
  freezed: ^3.0.0
  hive_generator: ^2.0.1
  riverpod_generator: ^4.0.0+1
  riverpod_lint: ^3.1.0
  custom_lint: ^0.6.4
  flutter_lints: ^5.0.0

flutter:
  uses-material-design: true

  assets:
    - assets/sprites/backgrounds/
    - assets/sprites/npcs/
    - assets/sprites/spirits/
    - assets/sprites/bookshelves/
    - assets/sprites/ui/
    - assets/fonts/
    - content/books/
    - content/quests/
```

- [ ] **Step 3: analysis_options.yaml 설정**

```yaml
include: package:flutter_lints/flutter.yaml

analyzer:
  plugins:
    - custom_lint
  errors:
    invalid_annotation_target: ignore
  exclude:
    - "**/*.g.dart"
    - "**/*.freezed.dart"

linter:
  rules:
    prefer_const_constructors: true
    prefer_const_declarations: true
    avoid_print: true
```

- [ ] **Step 4: .gitignore 업데이트**

기존 Flutter .gitignore에 추가:

```
# Superpowers
.superpowers/

# Generated
*.g.dart
*.freezed.dart

# Hive
*.hive
*.lock

# Content build cache
content/books/**/*.json
content/quests/**/*.json
```

- [ ] **Step 5: app_colors.dart 작성**

```dart
// lib/core/constants/app_colors.dart
import 'dart:ui';

abstract final class AppColors {
  // 기본 배경
  static const darkWalnut = Color(0xFF0F0B07);
  static const deepPurple = Color(0xFF1A1420);
  static const midPurple = Color(0xFF2A1F30);

  // 강조
  static const gold = Color(0xFFB8860B);
  static const brightGold = Color(0xFFFFD700);

  // 마법
  static const magicPurple = Color(0xFF7B68EE);
  static const steamGreen = Color(0xFF2E8B57);

  // 텍스트
  static const parchment = Color(0xFFF5EFE0);
  static const inkBrown = Color(0xFF3D2517);

  // 가구
  static const woodDark = Color(0xFF3D2517);
  static const woodMid = Color(0xFF5C3D2E);
}
```

- [ ] **Step 6: steampunk_theme.dart 작성**

```dart
// lib/core/theme/steampunk_theme.dart
import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

abstract final class SteampunkTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.darkWalnut,
        colorScheme: const ColorScheme.dark(
          primary: AppColors.gold,
          secondary: AppColors.magicPurple,
          surface: AppColors.deepPurple,
          onPrimary: AppColors.darkWalnut,
          onSecondary: AppColors.parchment,
          onSurface: AppColors.parchment,
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(
            color: AppColors.brightGold,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
          headlineMedium: TextStyle(
            color: AppColors.gold,
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
          bodyLarge: TextStyle(
            color: AppColors.parchment,
            fontSize: 16,
          ),
          bodyMedium: TextStyle(
            color: AppColors.parchment,
            fontSize: 14,
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.woodMid,
            foregroundColor: AppColors.gold,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: AppColors.gold, width: 1),
            ),
          ),
        ),
      );
}
```

- [ ] **Step 7: app_router.dart 작성**

```dart
// lib/core/router/app_router.dart
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../presentation/screens/game_screen.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/book_reader_screen.dart';

part 'app_router.g.dart';

@riverpod
GoRouter appRouter(AppRouterRef ref) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/game',
        builder: (context, state) => const GameScreen(),
      ),
      GoRoute(
        path: '/book/:bookId/chapter/:chapterId',
        builder: (context, state) {
          final bookId = state.pathParameters['bookId']!;
          final chapterId = state.pathParameters['chapterId']!;
          return BookReaderScreen(bookId: bookId, chapterId: chapterId);
        },
      ),
    ],
  );
}
```

- [ ] **Step 8: main.dart + app.dart 작성**

```dart
// lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  runApp(const ProviderScope(child: DolApp()));
}
```

```dart
// lib/app.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/steampunk_theme.dart';
import 'core/router/app_router.dart';

class DolApp extends ConsumerWidget {
  const DolApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Dev Quest Library',
      theme: SteampunkTheme.dark,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
```

- [ ] **Step 9: 에셋 디렉토리 + placeholder 생성**

```bash
mkdir -p assets/sprites/{backgrounds,npcs,spirits,bookshelves,ui}
mkdir -p assets/fonts
mkdir -p content/{books,quests}
mkdir -p docs-source
mkdir -p tools
```

각 sprites 하위 폴더에 `.gitkeep` 파일 생성하여 빈 디렉토리 유지.

- [ ] **Step 10: 코드 생성 실행**

```bash
flutter pub get
dart run build_runner build --delete-conflicting-outputs
```

Expected: `app_router.g.dart` 생성

- [ ] **Step 11: Flutter Web 실행 확인**

```bash
flutter run -d chrome --web-port=8080
```

Expected: 빈 앱이 Chrome에서 열림 (다크 배경, 에러 없음)

- [ ] **Step 12: 커밋**

```bash
git add -A
git commit -m "feat: Flutter 프로젝트 스캐폴딩 + 의존성 + 테마 설정"
```

---

## Task 2: freezed 데이터 모델

**Files:**
- Create: `lib/data/models/book_model.dart`
- Create: `lib/data/models/quest_model.dart`
- Create: `lib/data/models/quiz_model.dart`
- Create: `lib/data/models/npc_model.dart`
- Create: `lib/data/models/library_model.dart`
- Create: `lib/data/models/player_progress_model.dart`
- Test: `test/data/models/book_model_test.dart`
- Test: `test/data/models/quest_model_test.dart`
- Test: `test/data/models/player_progress_test.dart`

- [ ] **Step 1: book_model.dart 테스트 작성**

```dart
// test/data/models/book_model_test.dart
import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:dol/data/models/book_model.dart';

void main() {
  group('Chapter', () {
    test('fromJson creates valid Chapter', () {
      final json = {
        'id': 'java-step01',
        'title': 'Java란 무엇인가',
        'order': 1,
        'theory': {
          'sections': [
            {'title': 'JVM 개요', 'content': 'JVM은...'}
          ],
          'codeExamples': [
            {'language': 'java', 'code': 'public class Main {}', 'description': '기본 클래스'}
          ],
          'diagrams': [],
        },
        'simulator': {
          'type': 'codeStep',
          'steps': [
            {'instruction': '변수를 선언하세요', 'code': 'int x = 10;', 'expectedState': {'x': 10}}
          ],
          'completionCriteria': {'minStepsCompleted': 1},
        },
        'isCompleted': false,
      };

      final chapter = Chapter.fromJson(json);

      expect(chapter.id, 'java-step01');
      expect(chapter.title, 'Java란 무엇인가');
      expect(chapter.order, 1);
      expect(chapter.theory.sections.length, 1);
      expect(chapter.simulator.type, SimulatorType.codeStep);
      expect(chapter.isCompleted, false);
    });

    test('toJson produces valid JSON', () {
      final chapter = Chapter(
        id: 'dart-step01',
        title: 'Dart 개요',
        order: 1,
        theory: TheoryContent(
          sections: [TheorySection(title: 'Dart란', content: 'Dart는...')],
          codeExamples: [],
          diagrams: [],
        ),
        simulator: SimulatorConfig(
          type: SimulatorType.codeStep,
          steps: [],
          completionCriteria: CompletionRule(minStepsCompleted: 0),
        ),
        isCompleted: false,
      );

      final json = chapter.toJson();
      final restored = Chapter.fromJson(json);

      expect(restored, chapter);
    });
  });

  group('Book', () {
    test('totalProgress calculates correctly', () {
      final book = Book(
        id: 'java-spring',
        title: 'Java & Spring',
        category: 'java',
        chapters: [
          _makeChapter('ch1', completed: true),
          _makeChapter('ch2', completed: true),
          _makeChapter('ch3', completed: false),
          _makeChapter('ch4', completed: false),
        ],
      );

      expect(book.totalProgress, 0.5);
    });

    test('totalProgress is 0 when no chapters', () {
      final book = Book(
        id: 'empty',
        title: 'Empty',
        category: 'test',
        chapters: [],
      );

      expect(book.totalProgress, 0.0);
    });
  });
}

Chapter _makeChapter(String id, {required bool completed}) {
  return Chapter(
    id: id,
    title: id,
    order: 0,
    theory: TheoryContent(sections: [], codeExamples: [], diagrams: []),
    simulator: SimulatorConfig(
      type: SimulatorType.codeStep,
      steps: [],
      completionCriteria: CompletionRule(minStepsCompleted: 0),
    ),
    isCompleted: completed,
  );
}
```

- [ ] **Step 2: 테스트 실행하여 실패 확인**

```bash
flutter test test/data/models/book_model_test.dart
```

Expected: FAIL — `book_model.dart` 없음

- [ ] **Step 3: book_model.dart 구현**

```dart
// lib/data/models/book_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'book_model.freezed.dart';
part 'book_model.g.dart';

enum SimulatorType {
  codeStep,
  blockAssembly,
  flowTrace,
  sqlLab,
}

@freezed
class TheorySection with _$TheorySection {
  const factory TheorySection({
    required String title,
    required String content,
  }) = _TheorySection;

  factory TheorySection.fromJson(Map<String, dynamic> json) =>
      _$TheorySectionFromJson(json);
}

@freezed
class CodeBlock with _$CodeBlock {
  const factory CodeBlock({
    required String language,
    required String code,
    required String description,
  }) = _CodeBlock;

  factory CodeBlock.fromJson(Map<String, dynamic> json) =>
      _$CodeBlockFromJson(json);
}

@freezed
class DiagramData with _$DiagramData {
  const factory DiagramData({
    required String type,
    required String content,
  }) = _DiagramData;

  factory DiagramData.fromJson(Map<String, dynamic> json) =>
      _$DiagramDataFromJson(json);
}

@freezed
class TheoryContent with _$TheoryContent {
  const factory TheoryContent({
    required List<TheorySection> sections,
    required List<CodeBlock> codeExamples,
    required List<DiagramData> diagrams,
  }) = _TheoryContent;

  factory TheoryContent.fromJson(Map<String, dynamic> json) =>
      _$TheoryContentFromJson(json);
}

@freezed
class SimStep with _$SimStep {
  const factory SimStep({
    required String instruction,
    required String code,
    required Map<String, dynamic> expectedState,
  }) = _SimStep;

  factory SimStep.fromJson(Map<String, dynamic> json) =>
      _$SimStepFromJson(json);
}

@freezed
class CompletionRule with _$CompletionRule {
  const factory CompletionRule({
    required int minStepsCompleted,
  }) = _CompletionRule;

  factory CompletionRule.fromJson(Map<String, dynamic> json) =>
      _$CompletionRuleFromJson(json);
}

@freezed
class SimulatorConfig with _$SimulatorConfig {
  const factory SimulatorConfig({
    required SimulatorType type,
    required List<SimStep> steps,
    required CompletionRule completionCriteria,
  }) = _SimulatorConfig;

  factory SimulatorConfig.fromJson(Map<String, dynamic> json) =>
      _$SimulatorConfigFromJson(json);
}

@freezed
class Chapter with _$Chapter {
  const factory Chapter({
    required String id,
    required String title,
    required int order,
    required TheoryContent theory,
    required SimulatorConfig simulator,
    @Default(false) bool isCompleted,
  }) = _Chapter;

  factory Chapter.fromJson(Map<String, dynamic> json) =>
      _$ChapterFromJson(json);
}

@freezed
class Book with _$Book {
  const Book._();

  const factory Book({
    required String id,
    required String title,
    required String category,
    required List<Chapter> chapters,
  }) = _Book;

  double get totalProgress {
    if (chapters.isEmpty) return 0.0;
    final completed = chapters.where((c) => c.isCompleted).length;
    return completed / chapters.length;
  }

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
}
```

- [ ] **Step 4: 코드 생성 + 테스트 통과 확인**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/data/models/book_model_test.dart
```

Expected: ALL PASS

- [ ] **Step 5: quest_model.dart 테스트 작성**

```dart
// test/data/models/quest_model_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dol/data/models/quest_model.dart';

void main() {
  group('DialogueTree', () {
    test('fromJson creates valid tree', () {
      final json = {
        'startNodeId': 'node1',
        'nodes': [
          {
            'id': 'node1',
            'speakerName': '아르카누스',
            'text': 'Java의 핵심을 아는가?',
            'choices': [
              {'text': 'JVM이 핵심입니다', 'nextNodeId': 'node2', 'isCorrect': true},
              {'text': '잘 모르겠습니다', 'nextNodeId': 'node3', 'isCorrect': false},
            ],
            'isCorrectPath': null,
          },
        ],
      };

      final tree = DialogueTree.fromJson(json);

      expect(tree.startNodeId, 'node1');
      expect(tree.nodes.length, 1);
      expect(tree.nodes.first.choices.length, 2);
      expect(tree.nodes.first.choices.first.isCorrect, true);
    });
  });

  group('Quest', () {
    test('status transitions', () {
      final quest = Quest(
        id: 'q1',
        title: 'Java 기초 마스터',
        description: 'Java step 1-5 학습',
        npcId: 'wizard',
        requiredChapters: ['java-step01', 'java-step02'],
        dialogueTree: DialogueTree(startNodeId: 's', nodes: []),
        mixedQuiz: null,
        reward: QuestReward(xp: 100, title: null),
        status: QuestStatus.locked,
      );

      expect(quest.status, QuestStatus.locked);

      final available = quest.copyWith(status: QuestStatus.available);
      expect(available.status, QuestStatus.available);
    });
  });
}
```

- [ ] **Step 6: 테스트 실패 확인**

```bash
flutter test test/data/models/quest_model_test.dart
```

Expected: FAIL

- [ ] **Step 7: quest_model.dart 구현**

```dart
// lib/data/models/quest_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'quest_model.freezed.dart';
part 'quest_model.g.dart';

enum QuestStatus { locked, available, inProgress, completed }

@freezed
class DialogueChoice with _$DialogueChoice {
  const factory DialogueChoice({
    required String text,
    required String nextNodeId,
    @Default(false) bool isCorrect,
  }) = _DialogueChoice;

  factory DialogueChoice.fromJson(Map<String, dynamic> json) =>
      _$DialogueChoiceFromJson(json);
}

@freezed
class DialogueNode with _$DialogueNode {
  const factory DialogueNode({
    required String id,
    required String speakerName,
    required String text,
    required List<DialogueChoice> choices,
    bool? isCorrectPath,
  }) = _DialogueNode;

  factory DialogueNode.fromJson(Map<String, dynamic> json) =>
      _$DialogueNodeFromJson(json);
}

@freezed
class DialogueTree with _$DialogueTree {
  const factory DialogueTree({
    required String startNodeId,
    required List<DialogueNode> nodes,
  }) = _DialogueTree;

  factory DialogueTree.fromJson(Map<String, dynamic> json) =>
      _$DialogueTreeFromJson(json);
}

@freezed
class QuestReward with _$QuestReward {
  const factory QuestReward({
    required int xp,
    String? title,
  }) = _QuestReward;

  factory QuestReward.fromJson(Map<String, dynamic> json) =>
      _$QuestRewardFromJson(json);
}

@freezed
class Quest with _$Quest {
  const factory Quest({
    required String id,
    required String title,
    required String description,
    required String npcId,
    required List<String> requiredChapters,
    required DialogueTree dialogueTree,
    MixedQuiz? mixedQuiz,
    required QuestReward reward,
    @Default(QuestStatus.locked) QuestStatus status,
  }) = _Quest;

  factory Quest.fromJson(Map<String, dynamic> json) => _$QuestFromJson(json);
}
```

- [ ] **Step 8: quiz_model.dart 구현**

```dart
// lib/data/models/quiz_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz_model.freezed.dart';
part 'quiz_model.g.dart';

enum QuizType { multipleChoice, codeFill, oxJudge }

@freezed
class QuizQuestion with _$QuizQuestion {
  const factory QuizQuestion({
    required QuizType type,
    required String prompt,
    required List<String> options,
    required String correctAnswer,
    required String explanation,
  }) = _QuizQuestion;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) =>
      _$QuizQuestionFromJson(json);
}

@freezed
class MixedQuiz with _$MixedQuiz {
  const factory MixedQuiz({
    required List<QuizQuestion> questions,
    @Default(3) int passThreshold,
  }) = _MixedQuiz;

  factory MixedQuiz.fromJson(Map<String, dynamic> json) =>
      _$MixedQuizFromJson(json);
}
```

- [ ] **Step 9: npc_model.dart + library_model.dart 구현**

```dart
// lib/data/models/npc_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'quest_model.dart';

part 'npc_model.freezed.dart';
part 'npc_model.g.dart';

@freezed
class NpcModel with _$NpcModel {
  const factory NpcModel({
    required String id,
    required String name,
    required String role,
    required String spriteAsset,
    required List<Quest> quests,
  }) = _NpcModel;

  factory NpcModel.fromJson(Map<String, dynamic> json) =>
      _$NpcModelFromJson(json);
}

@freezed
class Spirit with _$Spirit {
  const factory Spirit({
    required String id,
    required String name,
    required String spriteAsset,
    required String bookshelfId,
  }) = _Spirit;

  factory Spirit.fromJson(Map<String, dynamic> json) =>
      _$SpiritFromJson(json);
}
```

```dart
// lib/data/models/library_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';
import 'npc_model.dart';
import 'book_model.dart';

part 'library_model.freezed.dart';
part 'library_model.g.dart';

@freezed
class Bookshelf with _$Bookshelf {
  const factory Bookshelf({
    required String id,
    required String category,
    required List<Book> books,
  }) = _Bookshelf;

  factory Bookshelf.fromJson(Map<String, dynamic> json) =>
      _$BookshelfFromJson(json);
}

@freezed
class Wing with _$Wing {
  const factory Wing({
    required String id,
    required String name,
    required String role,
    required NpcModel npc,
    required List<Bookshelf> shelves,
    required List<Spirit> spirits,
  }) = _Wing;

  factory Wing.fromJson(Map<String, dynamic> json) => _$WingFromJson(json);
}

@freezed
class Library with _$Library {
  const factory Library({
    required String id,
    required String name,
    required List<Wing> wings,
  }) = _Library;

  factory Library.fromJson(Map<String, dynamic> json) =>
      _$LibraryFromJson(json);
}
```

- [ ] **Step 10: player_progress_model.dart 테스트 + 구현**

```dart
// test/data/models/player_progress_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dol/data/models/player_progress_model.dart';

void main() {
  test('PlayerProgress serialization roundtrip', () {
    final progress = PlayerProgress(
      playerId: 'test-uuid',
      completedChapters: {'java-step01', 'java-step02'},
      completedQuests: {'q1'},
      currentWing: 'backend',
      lastSavedAt: DateTime(2026, 4, 17),
    );

    final json = progress.toJson();
    final restored = PlayerProgress.fromJson(json);

    expect(restored.playerId, 'test-uuid');
    expect(restored.completedChapters, contains('java-step01'));
    expect(restored.completedQuests, contains('q1'));
    expect(restored.currentWing, 'backend');
  });

  test('isChapterCompleted returns correct result', () {
    final progress = PlayerProgress(
      playerId: 'test',
      completedChapters: {'ch1', 'ch2'},
      completedQuests: {},
      lastSavedAt: DateTime.now(),
    );

    expect(progress.isChapterCompleted('ch1'), true);
    expect(progress.isChapterCompleted('ch3'), false);
  });
}
```

```dart
// lib/data/models/player_progress_model.dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_progress_model.freezed.dart';
part 'player_progress_model.g.dart';

@freezed
class PlayerProgress with _$PlayerProgress {
  const PlayerProgress._();

  const factory PlayerProgress({
    required String playerId,
    required Set<String> completedChapters,
    required Set<String> completedQuests,
    String? currentWing,
    required DateTime lastSavedAt,
  }) = _PlayerProgress;

  bool isChapterCompleted(String chapterId) =>
      completedChapters.contains(chapterId);

  bool isQuestCompleted(String questId) =>
      completedQuests.contains(questId);

  factory PlayerProgress.fromJson(Map<String, dynamic> json) =>
      _$PlayerProgressFromJson(json);
}
```

- [ ] **Step 11: 전체 코드 생성 + 테스트**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/data/models/
```

Expected: ALL PASS

- [ ] **Step 12: 커밋**

```bash
git add lib/data/models/ test/data/models/
git commit -m "feat: freezed 데이터 모델 (Book, Quest, NPC, Library, PlayerProgress)"
```

---

## Task 3: 콘텐츠 파서 (MD → JSON)

**Files:**
- Create: `tools/content_builder.dart`
- Test: `test/tools/content_builder_test.dart`

- [ ] **Step 1: 콘텐츠 빌더 테스트 작성**

```dart
// test/tools/content_builder_test.dart
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';

// content_builder는 standalone 스크립트이므로 직접 함수를 import
// 테스트용으로 핵심 파싱 로직만 추출하여 테스트

void main() {
  group('parseMdToChapter', () {
    test('extracts title from first heading', () {
      const md = '''
# Step 01 — Java란 무엇인가

## JVM 개요

JVM(Java Virtual Machine)은 자바 프로그램을 실행하는 가상 머신이다.

## 기본 문법

```java
public class Main {
    public static void main(String[] args) {
        System.out.println("Hello");
    }
}
```
''';

      final result = parseMdToChapter(md, 'java-step01', 1);

      expect(result['id'], 'java-step01');
      expect(result['title'], 'Step 01 — Java란 무엇인가');
      expect(result['order'], 1);
      expect(result['theory']['sections'], isNotEmpty);
      expect(result['theory']['codeExamples'], isNotEmpty);
      expect(result['theory']['codeExamples'][0]['language'], 'java');
    });

    test('handles markdown with no code blocks', () {
      const md = '''
# Step 02 — 개발환경 세팅

## IDE 설치

IntelliJ IDEA를 설치한다.

## SDK 설정

JDK 21을 다운로드한다.
''';

      final result = parseMdToChapter(md, 'java-step02', 2);

      expect(result['theory']['sections'].length, 2);
      expect(result['theory']['codeExamples'], isEmpty);
    });
  });
}

/// MD 파일을 챕터 JSON으로 변환하는 핵심 로직
Map<String, dynamic> parseMdToChapter(String markdown, String id, int order) {
  final lines = markdown.split('\n');

  // 제목 추출 (첫 번째 # 헤딩)
  var title = id;
  for (final line in lines) {
    if (line.startsWith('# ') && !line.startsWith('## ')) {
      title = line.substring(2).trim();
      break;
    }
  }

  // 섹션 추출 (## 헤딩 기준)
  final sections = <Map<String, String>>[];
  final codeExamples = <Map<String, String>>[];
  String? currentSection;
  final currentContent = StringBuffer();
  var inCodeBlock = false;
  String? codeLanguage;
  final codeBuffer = StringBuffer();

  for (final line in lines) {
    if (line.startsWith('```') && !inCodeBlock) {
      inCodeBlock = true;
      codeLanguage = line.substring(3).trim();
      if (codeLanguage.isEmpty) codeLanguage = 'text';
      codeBuffer.clear();
      continue;
    }

    if (line.startsWith('```') && inCodeBlock) {
      inCodeBlock = false;
      codeExamples.add({
        'language': codeLanguage ?? 'text',
        'code': codeBuffer.toString().trimRight(),
        'description': currentSection ?? '',
      });
      continue;
    }

    if (inCodeBlock) {
      codeBuffer.writeln(line);
      continue;
    }

    if (line.startsWith('## ')) {
      if (currentSection != null) {
        sections.add({
          'title': currentSection,
          'content': currentContent.toString().trim(),
        });
      }
      currentSection = line.substring(3).trim();
      currentContent.clear();
      continue;
    }

    if (line.startsWith('# ') && !line.startsWith('## ')) continue;

    currentContent.writeln(line);
  }

  // 마지막 섹션 추가
  if (currentSection != null) {
    sections.add({
      'title': currentSection,
      'content': currentContent.toString().trim(),
    });
  }

  return {
    'id': id,
    'title': title,
    'order': order,
    'theory': {
      'sections': sections,
      'codeExamples': codeExamples,
      'diagrams': <Map<String, String>>[],
    },
    'simulator': {
      'type': 'codeStep',
      'steps': <Map<String, dynamic>>[],
      'completionCriteria': {'minStepsCompleted': 0},
    },
    'isCompleted': false,
  };
}
```

- [ ] **Step 2: 테스트 실행 → 통과 확인**

테스트 파일 내에 파싱 로직이 포함되어 있으므로 바로 통과해야 함:

```bash
flutter test test/tools/content_builder_test.dart
```

Expected: ALL PASS

- [ ] **Step 3: tools/content_builder.dart 작성**

```dart
// tools/content_builder.dart
import 'dart:convert';
import 'dart:io';

/// MD 문서를 JSON 콘텐츠로 변환하는 빌드 스크립트
///
/// 사용법: dart run tools/content_builder.dart [docs-source-path]
void main(List<String> args) {
  final docsPath = args.isNotEmpty ? args[0] : 'docs-source';
  final outputPath = 'content/books';

  final categories = {
    'java-spring': 'Java & Spring',
    'dart': 'Dart Programing',
    'flutter': 'Flutter Programing',
    'mysql': 'Mysql Study',
    'msa': 'MSA',
  };

  for (final entry in categories.entries) {
    final categoryId = entry.key;
    final folderName = entry.value;
    final sourceDir = Directory('$docsPath/$folderName');

    if (!sourceDir.existsSync()) {
      print('⚠ 폴더 없음: ${sourceDir.path}');
      continue;
    }

    final outDir = Directory('$outputPath/$categoryId');
    outDir.createSync(recursive: true);

    final mdFiles = sourceDir
        .listSync()
        .whereType<File>()
        .where((f) => f.path.endsWith('.md'))
        .toList()
      ..sort((a, b) => a.path.compareTo(b.path));

    final chapters = <Map<String, dynamic>>[];

    for (var i = 0; i < mdFiles.length; i++) {
      final file = mdFiles[i];
      final fileName = file.uri.pathSegments.last.replaceAll('.md', '');
      final id = '$categoryId-$fileName';
      final content = file.readAsStringSync();

      chapters.add(parseMdToChapter(content, id, i + 1));
    }

    final book = {
      'id': categoryId,
      'title': folderName,
      'category': categoryId,
      'chapters': chapters,
    };

    final outFile = File('${outDir.path}/book.json');
    outFile.writeAsStringSync(
      const JsonEncoder.withIndent('  ').convert(book),
    );

    print('✓ $categoryId: ${chapters.length}개 챕터 → ${outFile.path}');
  }
}

Map<String, dynamic> parseMdToChapter(String markdown, String id, int order) {
  final lines = markdown.split('\n');

  var title = id;
  for (final line in lines) {
    if (line.startsWith('# ') && !line.startsWith('## ')) {
      title = line.substring(2).trim();
      break;
    }
  }

  final sections = <Map<String, String>>[];
  final codeExamples = <Map<String, String>>[];
  String? currentSection;
  final currentContent = StringBuffer();
  var inCodeBlock = false;
  String? codeLanguage;
  final codeBuffer = StringBuffer();

  for (final line in lines) {
    if (line.startsWith('```') && !inCodeBlock) {
      inCodeBlock = true;
      codeLanguage = line.substring(3).trim();
      if (codeLanguage.isEmpty) codeLanguage = 'text';
      codeBuffer.clear();
      continue;
    }

    if (line.startsWith('```') && inCodeBlock) {
      inCodeBlock = false;
      codeExamples.add({
        'language': codeLanguage ?? 'text',
        'code': codeBuffer.toString().trimRight(),
        'description': currentSection ?? '',
      });
      continue;
    }

    if (inCodeBlock) {
      codeBuffer.writeln(line);
      continue;
    }

    if (line.startsWith('## ')) {
      if (currentSection != null) {
        sections.add({
          'title': currentSection,
          'content': currentContent.toString().trim(),
        });
      }
      currentSection = line.substring(3).trim();
      currentContent.clear();
      continue;
    }

    if (line.startsWith('# ') && !line.startsWith('## ')) continue;

    currentContent.writeln(line);
  }

  if (currentSection != null) {
    sections.add({
      'title': currentSection,
      'content': currentContent.toString().trim(),
    });
  }

  return {
    'id': id,
    'title': title,
    'order': order,
    'theory': {
      'sections': sections,
      'codeExamples': codeExamples,
      'diagrams': <Map<String, String>>[],
    },
    'simulator': {
      'type': 'codeStep',
      'steps': <Map<String, dynamic>>[],
      'completionCriteria': {'minStepsCompleted': 0},
    },
    'isCompleted': false,
  };
}
```

- [ ] **Step 4: 실제 문서로 빌드 테스트**

```bash
cd D:\workspace\dol
dart run tools/content_builder.dart "D:/workspace/develop-study-documents"
```

Expected: 5개 카테고리의 book.json 파일 생성

- [ ] **Step 5: 커밋**

```bash
git add tools/ test/tools/ content/
git commit -m "feat: MD → JSON 콘텐츠 빌더 + 테스트"
```

---

## Task 4: Flame 게임 셸 + 씬 관리

**Files:**
- Create: `lib/game/dol_game.dart`
- Create: `lib/game/scenes/title_scene.dart`
- Create: `lib/game/scenes/central_hall_scene.dart`
- Create: `lib/game/scenes/wing_scene.dart`
- Create: `lib/game/mixins/tappable_component.dart`
- Create: `lib/presentation/screens/game_screen.dart`
- Create: `lib/presentation/screens/login_screen.dart`
- Create: `lib/domain/providers/game_providers.dart`

- [ ] **Step 1: game_providers.dart 작성**

```dart
// lib/domain/providers/game_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'game_providers.g.dart';

enum GameScene { title, centralHall, wing }

@riverpod
class CurrentScene extends _$CurrentScene {
  @override
  GameScene build() => GameScene.title;

  void goTo(GameScene scene) => state = scene;
}

@riverpod
class CurrentWingId extends _$CurrentWingId {
  @override
  String? build() => null;

  void select(String wingId) => state = wingId;
  void clear() => state = null;
}
```

- [ ] **Step 2: tappable_component.dart 작성**

```dart
// lib/game/mixins/tappable_component.dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// 포인트앤클릭 공통 믹스인
/// 클릭 가능한 모든 게임 컴포넌트에 적용
mixin TappableComponent on PositionComponent, TapCallbacks {
  bool _isHovered = false;

  bool get isHovered => _isHovered;

  void onTapped();

  @override
  void onTapUp(TapUpEvent event) {
    onTapped();
  }
}
```

- [ ] **Step 3: title_scene.dart 작성**

```dart
// lib/game/scenes/title_scene.dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../dol_game.dart';

class TitleScene extends Component with HasGameReference<DolGame> {
  @override
  Future<void> onLoad() async {
    // Phase 1: 단색 배경 + 텍스트 (PixelLab 에셋 교체 예정)
    add(RectangleComponent(
      size: game.size,
      paint: Paint()..color = const Color(0xFF0F0B07),
    ));
  }
}
```

- [ ] **Step 4: central_hall_scene.dart 작성**

```dart
// lib/game/scenes/central_hall_scene.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../dol_game.dart';
import '../components/wing_door_component.dart';

class CentralHallScene extends Component with HasGameReference<DolGame> {
  @override
  Future<void> onLoad() async {
    // 배경 (placeholder)
    add(RectangleComponent(
      size: game.size,
      paint: Paint()..color = const Color(0xFF1A1420),
    ));

    // 4개 분관 입구
    final wings = [
      ('backend', '마법사의 탑', const Color(0xFF7B68EE)),
      ('frontend', '기계공의 작업장', const Color(0xFFFF6347)),
      ('database', '연금술사의 실험실', const Color(0xFF2E8B57)),
      ('architecture', '건축가의 설계실', const Color(0xFF9370DB)),
    ];

    final doorWidth = game.size.x / 5;
    final doorHeight = game.size.y * 0.3;
    final y = game.size.y * 0.4;

    for (var i = 0; i < wings.length; i++) {
      final (id, name, color) = wings[i];
      final x = (i + 0.5) * (game.size.x / 4) - doorWidth / 2;

      add(WingDoorComponent(
        wingId: id,
        label: name,
        color: color,
        position: Vector2(x, y),
        size: Vector2(doorWidth, doorHeight),
      ));
    }
  }
}
```

- [ ] **Step 5: wing_door_component.dart 작성**

```dart
// lib/game/components/wing_door_component.dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../dol_game.dart';
import '../mixins/tappable_component.dart';

class WingDoorComponent extends RectangleComponent
    with TapCallbacks, TappableComponent, HasGameReference<DolGame> {
  final String wingId;
  final String label;
  final Color color;

  WingDoorComponent({
    required this.wingId,
    required this.label,
    required this.color,
    required Vector2 position,
    required Vector2 size,
  }) : super(
          position: position,
          size: size,
          paint: Paint()..color = color.withOpacity(0.7),
        );

  @override
  void onTapped() {
    game.onWingSelected(wingId);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 분관 이름 텍스트
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        (size.y - textPainter.height) / 2,
      ),
    );
  }
}
```

- [ ] **Step 6: wing_scene.dart 작성**

```dart
// lib/game/scenes/wing_scene.dart
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../dol_game.dart';

class WingScene extends Component with HasGameReference<DolGame> {
  final String wingId;
  final String wingName;
  final Color themeColor;

  WingScene({
    required this.wingId,
    required this.wingName,
    required this.themeColor,
  });

  @override
  Future<void> onLoad() async {
    // 배경 (placeholder)
    add(RectangleComponent(
      size: game.size,
      paint: Paint()..color = themeColor.withOpacity(0.3),
    ));

    // NPC, 책장 등은 Task 5에서 추가
  }
}
```

- [ ] **Step 7: dol_game.dart 작성**

```dart
// lib/game/dol_game.dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'scenes/title_scene.dart';
import 'scenes/central_hall_scene.dart';
import 'scenes/wing_scene.dart';

class DolGame extends FlameGame with HasTappables {
  VoidCallback? onNavigateToHall;
  void Function(String wingId)? onWingSelectedCallback;

  @override
  Color backgroundColor() => const Color(0xFF0F0B07);

  @override
  Future<void> onLoad() async {
    await loadCentralHall();
  }

  Future<void> loadCentralHall() async {
    children.whereType<Component>().toList().forEach(remove);
    add(CentralHallScene());
  }

  Future<void> loadWing(String wingId) async {
    children.whereType<Component>().toList().forEach(remove);

    final wingConfig = _wingConfigs[wingId];
    if (wingConfig == null) return;

    add(WingScene(
      wingId: wingId,
      wingName: wingConfig.$1,
      themeColor: wingConfig.$2,
    ));
  }

  void onWingSelected(String wingId) {
    onWingSelectedCallback?.call(wingId);
  }

  static final _wingConfigs = <String, (String, Color)>{
    'backend': ('마법사의 탑', const Color(0xFF7B68EE)),
    'frontend': ('기계공의 작업장', const Color(0xFFFF6347)),
    'database': ('연금술사의 실험실', const Color(0xFF2E8B57)),
    'architecture': ('건축가의 설계실', const Color(0xFF9370DB)),
  };
}
```

- [ ] **Step 8: game_screen.dart 작성**

```dart
// lib/presentation/screens/game_screen.dart
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/game_providers.dart';
import '../../game/dol_game.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final DolGame _game;

  @override
  void initState() {
    super.initState();
    _game = DolGame()
      ..onWingSelectedCallback = (wingId) {
        ref.read(currentWingIdProvider.notifier).select(wingId);
        ref.read(currentSceneProvider.notifier).goTo(GameScene.wing);
        _game.loadWing(wingId);
      };
  }

  @override
  Widget build(BuildContext context) {
    final scene = ref.watch(currentSceneProvider);

    return Scaffold(
      body: Stack(
        children: [
          // Flame 게임 레이어
          GameWidget(game: _game),

          // HUD 오버레이 (뒤로 가기 버튼 등)
          if (scene == GameScene.wing)
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFFFFD700)),
                onPressed: () {
                  ref.read(currentSceneProvider.notifier).goTo(GameScene.centralHall);
                  ref.read(currentWingIdProvider.notifier).clear();
                  _game.loadCentralHall();
                },
              ),
            ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 9: login_screen.dart 작성**

```dart
// lib/presentation/screens/login_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkWalnut,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Dev Quest Library',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '마법 도서관에서 개발을 배우다',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.gold,
                  ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () {
                // TODO: GitHub OAuth 연동 (Phase 1: 스킵)
                context.go('/game');
              },
              child: const Text('GitHub로 로그인'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/game'),
              child: const Text(
                '로그인 없이 시작',
                style: TextStyle(color: AppColors.parchment),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 10: book_reader_screen.dart placeholder 작성**

```dart
// lib/presentation/screens/book_reader_screen.dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class BookReaderScreen extends StatelessWidget {
  final String bookId;
  final String chapterId;

  const BookReaderScreen({
    super.key,
    required this.bookId,
    required this.chapterId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$bookId / $chapterId'),
        backgroundColor: AppColors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/game'),
        ),
      ),
      body: const Center(
        child: Text('책 열람 화면 (Task 8에서 구현)'),
      ),
    );
  }
}
```

- [ ] **Step 11: 코드 생성 + 실행 확인**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome --web-port=8080
```

Expected: 로그인 화면 → "로그인 없이 시작" → 중앙 홀 (4개 분관 입구 표시) → 분관 클릭 → 분관 씬 → 뒤로 가기

- [ ] **Step 12: 커밋**

```bash
git add lib/game/ lib/presentation/screens/ lib/domain/providers/
git commit -m "feat: Flame 게임 셸 + 씬 관리 + 중앙 홀/분관 전환"
```

---

## Task 5: NPC + 책장 컴포넌트

**Files:**
- Create: `lib/game/components/npc_component.dart`
- Create: `lib/game/components/bookshelf_component.dart`
- Create: `lib/game/components/spirit_component.dart`
- Modify: `lib/game/scenes/wing_scene.dart`

- [ ] **Step 1: npc_component.dart 작성**

```dart
// lib/game/components/npc_component.dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../dol_game.dart';
import '../mixins/tappable_component.dart';

class NpcComponent extends RectangleComponent
    with TapCallbacks, TappableComponent, HasGameReference<DolGame> {
  final String npcId;
  final String npcName;
  final Color color;
  VoidCallback? onNpcTapped;

  NpcComponent({
    required this.npcId,
    required this.npcName,
    required this.color,
    required Vector2 position,
    this.onNpcTapped,
  }) : super(
          position: position,
          size: Vector2(64, 80),
          paint: Paint()..color = color,
        );

  @override
  void onTapped() {
    onNpcTapped?.call();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // NPC 이름 표시
    final textPainter = TextPainter(
      text: TextSpan(
        text: npcName,
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset((size.x - textPainter.width) / 2, size.y + 4),
    );
  }
}
```

- [ ] **Step 2: bookshelf_component.dart 작성**

```dart
// lib/game/components/bookshelf_component.dart
import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../dol_game.dart';
import '../mixins/tappable_component.dart';

class BookshelfComponent extends RectangleComponent
    with TapCallbacks, TappableComponent, HasGameReference<DolGame> {
  final String shelfId;
  final String category;
  VoidCallback? onShelfTapped;

  BookshelfComponent({
    required this.shelfId,
    required this.category,
    required Vector2 position,
    required Vector2 size,
    this.onShelfTapped,
  }) : super(
          position: position,
          size: size,
          paint: Paint()..color = const Color(0xFF5C3D2E),
        );

  @override
  void onTapped() {
    onShelfTapped?.call();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    // 금색 테두리
    final borderPaint = Paint()
      ..color = const Color(0xFFB8860B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(size.toRect(), borderPaint);

    // 카테고리 라벨
    final textPainter = TextPainter(
      text: TextSpan(
        text: category.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFB8860B),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset((size.x - textPainter.width) / 2, (size.y - textPainter.height) / 2),
    );
  }
}
```

- [ ] **Step 3: spirit_component.dart 작성**

```dart
// lib/game/components/spirit_component.dart
import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class SpiritComponent extends CircleComponent {
  final String spiritId;
  double _time = 0;
  final double _floatSpeed;
  final double _floatRange;

  SpiritComponent({
    required this.spiritId,
    required Vector2 position,
    double radius = 12,
  })  : _floatSpeed = 1.5 + Random().nextDouble(),
        _floatRange = 4 + Random().nextDouble() * 4,
        super(
          position: position,
          radius: radius,
          paint: Paint()..color = const Color(0xFFFFD700).withOpacity(0.6),
        );

  late final Vector2 _basePosition;

  @override
  Future<void> onLoad() async {
    _basePosition = position.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    // 부유 애니메이션
    position.y = _basePosition.y + sin(_time * _floatSpeed) * _floatRange;
  }
}
```

- [ ] **Step 4: wing_scene.dart에 NPC + 책장 + 정령 추가**

```dart
// lib/game/scenes/wing_scene.dart (전체 교체)
import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../dol_game.dart';
import '../components/npc_component.dart';
import '../components/bookshelf_component.dart';
import '../components/spirit_component.dart';

class WingScene extends Component with HasGameReference<DolGame> {
  final String wingId;
  final String wingName;
  final Color themeColor;

  WingScene({
    required this.wingId,
    required this.wingName,
    required this.themeColor,
  });

  @override
  Future<void> onLoad() async {
    // 배경
    add(RectangleComponent(
      size: game.size,
      paint: Paint()..color = themeColor.withOpacity(0.15),
    ));

    final config = _wingNpcConfig[wingId];
    if (config == null) return;

    // NPC 배치 (화면 좌측)
    add(NpcComponent(
      npcId: config.npcId,
      npcName: config.npcName,
      color: themeColor,
      position: Vector2(game.size.x * 0.15, game.size.y * 0.4),
      onNpcTapped: () {
        game.overlays.add('dialogue');
      },
    ));

    // 책장 배치 (화면 우측)
    final shelfWidth = game.size.x * 0.2;
    final shelfHeight = game.size.y * 0.5;

    for (var i = 0; i < config.categories.length; i++) {
      final x = game.size.x * 0.5 + i * (shelfWidth + 20);
      add(BookshelfComponent(
        shelfId: '${wingId}_shelf_$i',
        category: config.categories[i],
        position: Vector2(x, game.size.y * 0.25),
        size: Vector2(shelfWidth, shelfHeight),
        onShelfTapped: () {
          game.overlays.add('questBoard');
        },
      ));

      // 정령 배치 (책장 위)
      add(SpiritComponent(
        spiritId: '${wingId}_spirit_$i',
        position: Vector2(x + shelfWidth / 2, game.size.y * 0.2),
      ));
    }
  }
}

class _WingNpcConfig {
  final String npcId;
  final String npcName;
  final List<String> categories;

  const _WingNpcConfig(this.npcId, this.npcName, this.categories);
}

final _wingNpcConfig = {
  'backend': _WingNpcConfig('wizard', '아르카누스', ['java']),
  'frontend': _WingNpcConfig('mechanic', '코그윈', ['dart', 'flutter']),
  'database': _WingNpcConfig('alchemist', '메르쿠리아', ['mysql']),
  'architecture': _WingNpcConfig('architect', '모뉴멘타', ['msa']),
};
```

- [ ] **Step 5: 실행 확인**

```bash
flutter run -d chrome --web-port=8080
```

Expected: 분관 진입 시 NPC(색상 사각형) + 책장(갈색 사각형+금테) + 부유하는 정령(금색 원) 표시

- [ ] **Step 6: 커밋**

```bash
git add lib/game/components/ lib/game/scenes/wing_scene.dart
git commit -m "feat: NPC, 책장, 정령 컴포넌트 + 분관 씬 배치"
```

---

## Task 6: NPC 대화 시스템

**Files:**
- Create: `lib/presentation/overlays/dialogue_overlay.dart`
- Create: `lib/domain/providers/quest_providers.dart`
- Modify: `lib/presentation/screens/game_screen.dart`

- [ ] **Step 1: quest_providers.dart 작성**

```dart
// lib/domain/providers/quest_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/quest_model.dart';

part 'quest_providers.g.dart';

@riverpod
class ActiveDialogue extends _$ActiveDialogue {
  @override
  DialogueState? build() => null;

  void startDialogue(DialogueTree tree) {
    final startNode = tree.nodes.firstWhere((n) => n.id == tree.startNodeId);
    state = DialogueState(tree: tree, currentNode: startNode, history: []);
  }

  void selectChoice(DialogueChoice choice) {
    if (state == null) return;
    final nextNode = state!.tree.nodes.firstWhere((n) => n.id == choice.nextNodeId,
        orElse: () => state!.currentNode);
    state = DialogueState(
      tree: state!.tree,
      currentNode: nextNode,
      history: [...state!.history, state!.currentNode.id],
    );
  }

  void endDialogue() => state = null;
}

class DialogueState {
  final DialogueTree tree;
  final DialogueNode currentNode;
  final List<String> history;

  const DialogueState({
    required this.tree,
    required this.currentNode,
    required this.history,
  });

  bool get isEnd => currentNode.choices.isEmpty;
}
```

- [ ] **Step 2: dialogue_overlay.dart 작성**

```dart
// lib/presentation/overlays/dialogue_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/providers/quest_providers.dart';
import '../../data/models/quest_model.dart';

class DialogueOverlay extends ConsumerWidget {
  final VoidCallback onClose;

  const DialogueOverlay({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dialogueState = ref.watch(activeDialogueProvider);

    if (dialogueState == null) {
      return const SizedBox.shrink();
    }

    final node = dialogueState.currentNode;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.deepPurple.withOpacity(0.95),
          border: Border.all(color: AppColors.gold, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // 화자 이름
            Text(
              node.speakerName,
              style: const TextStyle(
                color: AppColors.brightGold,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            // 대화 내용
            Text(
              node.text,
              style: const TextStyle(
                color: AppColors.parchment,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),

            // 선택지 또는 닫기
            if (dialogueState.isEnd)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ref.read(activeDialogueProvider.notifier).endDialogue();
                    onClose();
                  },
                  child: const Text(
                    '[대화 종료]',
                    style: TextStyle(color: AppColors.gold),
                  ),
                ),
              )
            else
              ...node.choices.map((choice) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        ref
                            .read(activeDialogueProvider.notifier)
                            .selectChoice(choice);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.gold.withOpacity(0.5),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '▸ ${choice.text}',
                          style: const TextStyle(
                            color: AppColors.parchment,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: game_screen.dart에 대화 오버레이 통합**

`game_screen.dart`의 `Stack` children에 대화 오버레이 추가:

```dart
// game_screen.dart의 Stack children에 추가
if (ref.watch(activeDialogueProvider) != null)
  DialogueOverlay(
    onClose: () {
      _game.overlays.remove('dialogue');
    },
  ),
```

- [ ] **Step 4: 테스트용 대화 데이터로 실행 확인**

NPC 클릭 시 테스트 대화 트리가 시작되도록 `wing_scene.dart`의 `onNpcTapped` 수정:

```dart
onNpcTapped: () {
  // 테스트 대화 (나중에 콘텐츠 데이터로 교체)
  // GameScreen에서 Riverpod으로 연동
  game.overlays.add('dialogue');
},
```

```bash
flutter run -d chrome --web-port=8080
```

Expected: NPC 클릭 → 대화창 표시 → 선택지 클릭 → 다음 대화 → 종료

- [ ] **Step 5: 커밋**

```bash
git add lib/presentation/overlays/dialogue_overlay.dart lib/domain/providers/quest_providers.dart lib/presentation/screens/game_screen.dart
git commit -m "feat: NPC 대화 시스템 오버레이 + 대화 분기 상태 관리"
```

---

## Task 7: 퀘스트 게시판 + 혼합 퀴즈

**Files:**
- Create: `lib/presentation/overlays/quest_board_overlay.dart`
- Create: `lib/presentation/overlays/quiz_overlay.dart`
- Create: `lib/presentation/overlays/hud_overlay.dart`
- Create: `lib/domain/providers/content_providers.dart`
- Modify: `lib/presentation/screens/game_screen.dart`

- [ ] **Step 1: content_providers.dart 작성**

```dart
// lib/domain/providers/content_providers.dart
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/book_model.dart';

part 'content_providers.g.dart';

@riverpod
Future<List<Book>> allBooks(AllBooksRef ref) async {
  final categories = ['java-spring', 'dart', 'flutter', 'mysql', 'msa'];
  final books = <Book>[];

  for (final cat in categories) {
    try {
      final jsonStr = await rootBundle.loadString('content/books/$cat/book.json');
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      books.add(Book.fromJson(json));
    } catch (_) {
      // 콘텐츠가 아직 빌드되지 않은 경우 스킵
    }
  }

  return books;
}

@riverpod
Book? bookById(BookByIdRef ref, String bookId) {
  final books = ref.watch(allBooksProvider).valueOrNull ?? [];
  return books.where((b) => b.id == bookId).firstOrNull;
}
```

- [ ] **Step 2: quest_board_overlay.dart 작성**

```dart
// lib/presentation/overlays/quest_board_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/providers/content_providers.dart';

class QuestBoardOverlay extends ConsumerWidget {
  final VoidCallback onClose;
  final void Function(String bookId, String chapterId) onChapterSelected;

  const QuestBoardOverlay({
    super.key,
    required this.onClose,
    required this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(allBooksProvider);

    return Center(
      child: Container(
        width: 500,
        height: 400,
        decoration: BoxDecoration(
          color: AppColors.deepPurple,
          border: Border.all(color: AppColors.gold, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            // 헤더
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppColors.gold),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📋 퀘스트 게시판',
                    style: TextStyle(
                      color: AppColors.brightGold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.gold),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),

            // 책 목록
            Expanded(
              child: booksAsync.when(
                data: (books) => ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: books.length,
                  itemBuilder: (context, i) {
                    final book = books[i];
                    return ExpansionTile(
                      title: Text(
                        book.title,
                        style: const TextStyle(color: AppColors.parchment),
                      ),
                      subtitle: Text(
                        '${(book.totalProgress * 100).toInt()}% 완료',
                        style: TextStyle(
                          color: AppColors.gold.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      children: book.chapters.map((ch) {
                        return ListTile(
                          title: Text(
                            ch.title,
                            style: TextStyle(
                              color: ch.isCompleted
                                  ? AppColors.steamGreen
                                  : AppColors.parchment,
                              fontSize: 13,
                            ),
                          ),
                          leading: Icon(
                            ch.isCompleted
                                ? Icons.check_circle
                                : Icons.circle_outlined,
                            color: ch.isCompleted
                                ? AppColors.steamGreen
                                : AppColors.gold,
                            size: 18,
                          ),
                          onTap: () => onChapterSelected(book.id, ch.id),
                        );
                      }).toList(),
                    );
                  },
                ),
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
                error: (e, _) => Center(
                  child: Text('콘텐츠 로드 실패: $e',
                      style: const TextStyle(color: Colors.red)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 3: quiz_overlay.dart 작성**

```dart
// lib/presentation/overlays/quiz_overlay.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/quiz_model.dart';

class QuizOverlay extends StatefulWidget {
  final MixedQuiz quiz;
  final VoidCallback onPass;
  final VoidCallback onFail;

  const QuizOverlay({
    super.key,
    required this.quiz,
    required this.onPass,
    required this.onFail,
  });

  @override
  State<QuizOverlay> createState() => _QuizOverlayState();
}

class _QuizOverlayState extends State<QuizOverlay> {
  int _currentIndex = 0;
  int _correctCount = 0;
  String? _selectedAnswer;
  bool _showResult = false;

  QuizQuestion get _current => widget.quiz.questions[_currentIndex];
  bool get _isLast => _currentIndex >= widget.quiz.questions.length - 1;

  void _submit() {
    if (_selectedAnswer == null) return;

    final isCorrect = _selectedAnswer == _current.correctAnswer;
    if (isCorrect) _correctCount++;

    if (_isLast) {
      setState(() => _showResult = true);
      if (_correctCount >= widget.quiz.passThreshold) {
        Future.delayed(const Duration(seconds: 2), widget.onPass);
      } else {
        Future.delayed(const Duration(seconds: 2), widget.onFail);
      }
    } else {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showResult) {
      final passed = _correctCount >= widget.quiz.passThreshold;
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.deepPurple,
            border: Border.all(color: passed ? AppColors.steamGreen : Colors.red, width: 2),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                passed ? Icons.check_circle : Icons.cancel,
                color: passed ? AppColors.steamGreen : Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                passed ? '통과!' : '재도전 필요',
                style: TextStyle(
                  color: passed ? AppColors.steamGreen : Colors.red,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$_correctCount / ${widget.quiz.questions.length} 정답',
                style: const TextStyle(color: AppColors.parchment),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.deepPurple,
          border: Border.all(color: AppColors.gold, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '문제 ${_currentIndex + 1} / ${widget.quiz.questions.length}',
              style: const TextStyle(color: AppColors.gold, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              _current.prompt,
              style: const TextStyle(
                color: AppColors.parchment,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._current.options.map((option) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedAnswer = option),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedAnswer == option
                              ? AppColors.brightGold
                              : AppColors.gold.withOpacity(0.3),
                          width: _selectedAnswer == option ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        color: _selectedAnswer == option
                            ? AppColors.gold.withOpacity(0.1)
                            : null,
                      ),
                      child: Text(
                        option,
                        style: const TextStyle(color: AppColors.parchment),
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _selectedAnswer != null ? _submit : null,
                child: Text(_isLast ? '제출' : '다음'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
```

- [ ] **Step 4: hud_overlay.dart 작성**

```dart
// lib/presentation/overlays/hud_overlay.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/providers/game_providers.dart';

class HudOverlay extends ConsumerWidget {
  const HudOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scene = ref.watch(currentSceneProvider);
    final wingId = ref.watch(currentWingIdProvider);

    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.deepPurple.withOpacity(0.8),
          border: Border.all(color: AppColors.gold.withOpacity(0.5)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          scene == GameScene.centralHall
              ? '📍 중앙 홀'
              : '📍 ${wingId ?? ""}',
          style: const TextStyle(
            color: AppColors.gold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: game_screen.dart에 모든 오버레이 통합**

`game_screen.dart`의 Stack에 퀘스트 게시판, HUD 추가.

- [ ] **Step 6: 실행 확인 + 커밋**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter run -d chrome --web-port=8080
```

```bash
git add lib/presentation/overlays/ lib/domain/providers/
git commit -m "feat: 퀘스트 게시판 + 혼합 퀴즈 + HUD 오버레이"
```

---

## Task 8: 책 열람 화면 (이론 뷰 + 코드 스텝 시뮬레이터)

**Files:**
- Modify: `lib/presentation/screens/book_reader_screen.dart`
- Create: `lib/presentation/simulators/code_step_simulator.dart`
- Create: `lib/presentation/widgets/theory_card.dart`
- Create: `lib/presentation/widgets/steampunk_panel.dart`
- Create: `lib/presentation/widgets/steampunk_button.dart`
- Test: `test/presentation/simulators/code_step_simulator_test.dart`

- [ ] **Step 1: steampunk_panel.dart + steampunk_button.dart 작성**

```dart
// lib/presentation/widgets/steampunk_panel.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SteampunkPanel extends StatelessWidget {
  final Widget child;
  final String? title;

  const SteampunkPanel({super.key, required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.deepPurple,
        border: Border.all(color: AppColors.gold, width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.gold)),
              ),
              child: Text(
                title!,
                style: const TextStyle(
                  color: AppColors.brightGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }
}
```

```dart
// lib/presentation/widgets/steampunk_button.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SteampunkButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isSmall;

  const SteampunkButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isSmall = false,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.woodMid,
        foregroundColor: AppColors.gold,
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 12 : 20,
          vertical: isSmall ? 6 : 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.gold),
        ),
      ),
      child: Text(label, style: TextStyle(fontSize: isSmall ? 12 : 14)),
    );
  }
}
```

- [ ] **Step 2: theory_card.dart 작성**

```dart
// lib/presentation/widgets/theory_card.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/book_model.dart';
import 'steampunk_panel.dart';

class TheoryCard extends StatelessWidget {
  final TheoryContent theory;

  const TheoryCard({super.key, required this.theory});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 이론 섹션
        for (final section in theory.sections) ...[
          SteampunkPanel(
            title: section.title,
            child: Text(
              section.content,
              style: const TextStyle(
                color: AppColors.parchment,
                fontSize: 14,
                height: 1.6,
              ),
            ),
          ),
          const SizedBox(height: 16),
        ],

        // 코드 예제
        if (theory.codeExamples.isNotEmpty) ...[
          const Text(
            '코드 예제',
            style: TextStyle(
              color: AppColors.brightGold,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          for (final code in theory.codeExamples) ...[
            SteampunkPanel(
              title: '${code.language} — ${code.description}',
              child: SelectableText(
                code.code,
                style: const TextStyle(
                  color: AppColors.steamGreen,
                  fontFamily: 'monospace',
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }
}
```

- [ ] **Step 3: code_step_simulator.dart 테스트 작성**

```dart
// test/presentation/simulators/code_step_simulator_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dol/data/models/book_model.dart';

void main() {
  group('SimulatorConfig step progression', () {
    test('tracks current step index', () {
      final config = SimulatorConfig(
        type: SimulatorType.codeStep,
        steps: [
          SimStep(instruction: 'Step 1', code: 'int x = 1;', expectedState: {'x': 1}),
          SimStep(instruction: 'Step 2', code: 'int y = 2;', expectedState: {'y': 2}),
          SimStep(instruction: 'Step 3', code: 'int z = x + y;', expectedState: {'z': 3}),
        ],
        completionCriteria: CompletionRule(minStepsCompleted: 3),
      );

      expect(config.steps.length, 3);
      expect(config.completionCriteria.minStepsCompleted, 3);
    });
  });
}
```

- [ ] **Step 4: code_step_simulator.dart 구현**

```dart
// lib/presentation/simulators/code_step_simulator.dart
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/book_model.dart';
import '../widgets/steampunk_panel.dart';
import '../widgets/steampunk_button.dart';

class CodeStepSimulator extends StatefulWidget {
  final SimulatorConfig config;
  final VoidCallback onComplete;

  const CodeStepSimulator({
    super.key,
    required this.config,
    required this.onComplete,
  });

  @override
  State<CodeStepSimulator> createState() => _CodeStepSimulatorState();
}

class _CodeStepSimulatorState extends State<CodeStepSimulator> {
  int _currentStep = 0;
  final Map<String, dynamic> _state = {};
  bool _stepExecuted = false;

  SimStep get _step => widget.config.steps[_currentStep];
  bool get _isLast => _currentStep >= widget.config.steps.length - 1;

  void _executeStep() {
    setState(() {
      _state.addAll(_step.expectedState);
      _stepExecuted = true;
    });
  }

  void _nextStep() {
    if (_isLast) {
      widget.onComplete();
      return;
    }
    setState(() {
      _currentStep++;
      _stepExecuted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // 진행도
        Text(
          '스텝 ${_currentStep + 1} / ${widget.config.steps.length}',
          style: const TextStyle(color: AppColors.gold, fontSize: 12),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_currentStep + (_stepExecuted ? 1 : 0)) /
              widget.config.steps.length,
          backgroundColor: AppColors.woodDark,
          valueColor: const AlwaysStoppedAnimation(AppColors.steamGreen),
        ),
        const SizedBox(height: 16),

        // 지시사항
        SteampunkPanel(
          title: '지시사항',
          child: Text(
            _step.instruction,
            style: const TextStyle(color: AppColors.parchment, fontSize: 14),
          ),
        ),
        const SizedBox(height: 12),

        // 코드
        SteampunkPanel(
          title: '코드',
          child: SelectableText(
            _step.code,
            style: const TextStyle(
              color: AppColors.steamGreen,
              fontFamily: 'monospace',
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 12),

        // 상태 시각화
        if (_state.isNotEmpty)
          SteampunkPanel(
            title: '메모리 상태',
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: _state.entries.map((e) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.darkWalnut,
                    border: Border.all(color: AppColors.steamGreen),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${e.key} = ${e.value}',
                    style: const TextStyle(
                      color: AppColors.steamGreen,
                      fontFamily: 'monospace',
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 16),

        // 버튼
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!_stepExecuted)
              SteampunkButton(
                label: '▶ 실행',
                onPressed: _executeStep,
              )
            else
              SteampunkButton(
                label: _isLast ? '✓ 완료' : '다음 →',
                onPressed: _nextStep,
              ),
          ],
        ),
      ],
    );
  }
}
```

- [ ] **Step 5: book_reader_screen.dart 완성**

```dart
// lib/presentation/screens/book_reader_screen.dart (전체 교체)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/providers/content_providers.dart';
import '../../data/models/book_model.dart';
import '../widgets/theory_card.dart';
import '../simulators/code_step_simulator.dart';
import '../widgets/steampunk_button.dart';

class BookReaderScreen extends ConsumerStatefulWidget {
  final String bookId;
  final String chapterId;

  const BookReaderScreen({
    super.key,
    required this.bookId,
    required this.chapterId,
  });

  @override
  ConsumerState<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends ConsumerState<BookReaderScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(bookByIdProvider(widget.bookId));

    if (book == null) {
      return Scaffold(
        backgroundColor: AppColors.darkWalnut,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('책을 찾을 수 없습니다',
                  style: TextStyle(color: AppColors.parchment)),
              const SizedBox(height: 16),
              SteampunkButton(
                label: '돌아가기',
                onPressed: () => context.go('/game'),
              ),
            ],
          ),
        ),
      );
    }

    final chapter = book.chapters.where((c) => c.id == widget.chapterId).firstOrNull;

    if (chapter == null) {
      return Scaffold(
        backgroundColor: AppColors.darkWalnut,
        body: Center(
          child: Text('챕터를 찾을 수 없습니다: ${widget.chapterId}',
              style: const TextStyle(color: AppColors.parchment)),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkWalnut,
      appBar: AppBar(
        backgroundColor: AppColors.deepPurple,
        title: Text(chapter.title,
            style: const TextStyle(color: AppColors.brightGold, fontSize: 16)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => context.go('/game'),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.brightGold,
          unselectedLabelColor: AppColors.parchment,
          tabs: const [
            Tab(text: '📖 이론'),
            Tab(text: '⚡ 시뮬레이터'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // 이론 탭
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: TheoryCard(theory: chapter.theory),
          ),

          // 시뮬레이터 탭
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: chapter.simulator.steps.isNotEmpty
                ? CodeStepSimulator(
                    config: chapter.simulator,
                    onComplete: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('시뮬레이터 완료!'),
                          backgroundColor: AppColors.steamGreen,
                        ),
                      );
                    },
                  )
                : const Center(
                    child: Text(
                      '이 챕터의 시뮬레이터는 준비 중입니다',
                      style: TextStyle(color: AppColors.parchment),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
```

- [ ] **Step 6: 테스트 + 실행 확인**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/presentation/simulators/
flutter run -d chrome --web-port=8080
```

Expected: 퀘스트 게시판에서 챕터 선택 → 책 열람 화면 (이론 탭 + 시뮬레이터 탭)

- [ ] **Step 7: 커밋**

```bash
git add lib/presentation/ test/presentation/
git commit -m "feat: 책 열람 화면 (이론 뷰 + 코드 스텝 시뮬레이터)"
```

---

## Task 9: GitHub Gist 진행 저장 서비스

**Files:**
- Create: `lib/services/gist_service.dart`
- Create: `lib/data/datasources/local/hive_datasource.dart`
- Create: `lib/data/datasources/remote/gist_datasource.dart`
- Create: `lib/data/repositories/progress_repository.dart`
- Create: `lib/domain/providers/progress_providers.dart`
- Test: `test/services/gist_service_test.dart`

- [ ] **Step 1: gist_service.dart 테스트 작성**

```dart
// test/services/gist_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:dol/services/gist_service.dart';

void main() {
  group('GistService', () {
    test('formatProgressToGistContent produces valid JSON', () {
      final content = GistService.formatProgressToJson({
        'playerId': 'test-id',
        'completedChapters': ['ch1', 'ch2'],
        'completedQuests': ['q1'],
        'currentWing': 'backend',
        'lastSavedAt': '2026-04-17T00:00:00.000',
      });

      expect(content, contains('test-id'));
      expect(content, contains('ch1'));
    });
  });
}
```

- [ ] **Step 2: gist_service.dart 구현**

```dart
// lib/services/gist_service.dart
import 'dart:convert';
import 'package:dio/dio.dart';
import '../data/models/player_progress_model.dart';

class GistService {
  final Dio _dio;
  String? _gistId;
  static const _fileName = 'dol-progress.json';

  GistService({required Dio dio}) : _dio = dio;

  /// Gist에서 진행 상태 로드
  Future<PlayerProgress?> loadProgress(String token) async {
    _dio.options.headers['Authorization'] = 'Bearer $token';

    // 기존 Gist 검색
    final response = await _dio.get('https://api.github.com/gists');
    final gists = response.data as List;

    for (final gist in gists) {
      final files = gist['files'] as Map<String, dynamic>;
      if (files.containsKey(_fileName)) {
        _gistId = gist['id'];
        final content = files[_fileName]['content'] as String;
        final json = jsonDecode(content) as Map<String, dynamic>;
        return PlayerProgress.fromJson(json);
      }
    }

    return null;
  }

  /// Gist에 진행 상태 저장
  Future<void> saveProgress(String token, PlayerProgress progress) async {
    _dio.options.headers['Authorization'] = 'Bearer $token';
    final content = formatProgressToJson(progress.toJson());

    if (_gistId != null) {
      // 기존 Gist 업데이트
      await _dio.patch(
        'https://api.github.com/gists/$_gistId',
        data: {
          'files': {
            _fileName: {'content': content}
          }
        },
      );
    } else {
      // 새 Gist 생성
      final response = await _dio.post(
        'https://api.github.com/gists',
        data: {
          'description': 'Dev Quest Library - 학습 진행 상태',
          'public': false,
          'files': {
            _fileName: {'content': content}
          }
        },
      );
      _gistId = response.data['id'];
    }
  }

  static String formatProgressToJson(Map<String, dynamic> data) {
    return const JsonEncoder.withIndent('  ').convert(data);
  }
}
```

- [ ] **Step 3: hive_datasource.dart 구현**

```dart
// lib/data/datasources/local/hive_datasource.dart
import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/player_progress_model.dart';

class HiveDatasource {
  static const _boxName = 'progress';
  static const _key = 'player_progress';

  Future<void> init() async {
    await Hive.openBox<String>(_boxName);
  }

  Future<void> saveProgress(PlayerProgress progress) async {
    final box = Hive.box<String>(_boxName);
    await box.put(_key, jsonEncode(progress.toJson()));
  }

  PlayerProgress? loadProgress() {
    final box = Hive.box<String>(_boxName);
    final json = box.get(_key);
    if (json == null) return null;
    return PlayerProgress.fromJson(jsonDecode(json));
  }

  Future<void> clear() async {
    final box = Hive.box<String>(_boxName);
    await box.delete(_key);
  }
}
```

- [ ] **Step 4: progress_repository.dart + progress_providers.dart 작성**

```dart
// lib/data/repositories/progress_repository.dart
import '../datasources/local/hive_datasource.dart';
import '../models/player_progress_model.dart';
import '../../services/gist_service.dart';

class ProgressRepository {
  final HiveDatasource _local;
  final GistService _gist;

  ProgressRepository({
    required HiveDatasource local,
    required GistService gist,
  })  : _local = local,
        _gist = gist;

  PlayerProgress? loadLocal() => _local.loadProgress();

  Future<void> saveLocal(PlayerProgress progress) =>
      _local.saveProgress(progress);

  Future<PlayerProgress?> loadRemote(String token) =>
      _gist.loadProgress(token);

  Future<void> saveRemote(String token, PlayerProgress progress) =>
      _gist.saveProgress(token, progress);
}
```

```dart
// lib/domain/providers/progress_providers.dart
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/player_progress_model.dart';
import '../../data/datasources/local/hive_datasource.dart';
import '../../services/gist_service.dart';
import '../../data/repositories/progress_repository.dart';
import 'package:dio/dio.dart';

part 'progress_providers.g.dart';

@riverpod
class Progress extends _$Progress {
  @override
  PlayerProgress build() {
    final repo = ProgressRepository(
      local: HiveDatasource(),
      gist: GistService(dio: Dio()),
    );

    return repo.loadLocal() ??
        PlayerProgress(
          playerId: const Uuid().v4(),
          completedChapters: {},
          completedQuests: {},
          lastSavedAt: DateTime.now(),
        );
  }

  void completeChapter(String chapterId) {
    state = state.copyWith(
      completedChapters: {...state.completedChapters, chapterId},
      lastSavedAt: DateTime.now(),
    );
    _save();
  }

  void completeQuest(String questId) {
    state = state.copyWith(
      completedQuests: {...state.completedQuests, questId},
      lastSavedAt: DateTime.now(),
    );
    _save();
  }

  void _save() {
    HiveDatasource().saveProgress(state);
  }
}
```

- [ ] **Step 5: 테스트 + 커밋**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test test/services/
```

```bash
git add lib/services/ lib/data/datasources/ lib/data/repositories/ lib/domain/providers/progress_providers.dart test/services/
git commit -m "feat: GitHub Gist 진행 저장 + Hive 로컬 캐시 + ProgressRepository"
```

---

## Task 10: GitHub Actions 배포 + Submodule

**Files:**
- Create: `.github/workflows/ci.yml`
- Create: `.github/workflows/sync-and-deploy.yml`
- Modify: `.gitmodules` (submodule 설정)

- [ ] **Step 1: git submodule 설정**

```bash
cd D:\workspace\dol
git submodule add https://github.com/Qahnaarin/develop-study-documents.git docs-source
git commit -m "chore: develop-study-documents submodule 추가"
```

- [ ] **Step 2: ci.yml 작성**

```yaml
# .github/workflows/ci.yml
name: CI

on:
  pull_request:
    branches: [main, master]
  push:
    branches: [main, master]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: true

      - uses: subosito/flutter-action@v2
        with:
          channel: stable

      - run: flutter pub get
      - run: dart run build_runner build --delete-conflicting-outputs
      - run: flutter analyze
      - run: flutter test
```

- [ ] **Step 3: sync-and-deploy.yml 작성**

```yaml
# .github/workflows/sync-and-deploy.yml
name: Sync & Deploy

on:
  repository_dispatch:
    types: [docs-updated]
  push:
    branches: [main, master]

permissions:
  contents: write
  pages: write

jobs:
  build-and-deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
        with:
          submodules: true
          fetch-depth: 0

      - uses: subosito/flutter-action@v2
        with:
          channel: stable

      # Submodule 최신화
      - name: Update submodule
        run: |
          git submodule update --remote --merge
          git config user.name "github-actions[bot]"
          git config user.email "github-actions[bot]@users.noreply.github.com"
          git add docs-source
          git diff --cached --quiet || git commit -m "chore: sync docs-source submodule"
          git push

      # 콘텐츠 빌드
      - name: Build content
        run: dart run tools/content_builder.dart docs-source

      # Flutter Web 빌드
      - name: Build web
        run: |
          flutter pub get
          dart run build_runner build --delete-conflicting-outputs
          flutter build web --release --web-renderer canvaskit --base-href /dol/

      # GitHub Pages 배포
      - name: Deploy to GitHub Pages
        uses: peaceiris/actions-gh-pages@v4
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./build/web
```

- [ ] **Step 4: develop-study-documents에 notify 워크플로우 추가**

```yaml
# develop-study-documents/.github/workflows/notify-game.yml
name: Notify Game Repo

on:
  push:
    paths:
      - 'Java & Spring/**'
      - 'Dart Programing/**'
      - 'Flutter Programing/**'
      - 'Mysql Study/**'
      - 'MSA/**'

jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - name: Trigger dol rebuild
        uses: peter-evans/repository-dispatch@v3
        with:
          token: ${{ secrets.DOL_DISPATCH_TOKEN }}
          repository: Public-Project-Area-Oragans/dol
          event-type: docs-updated
```

- [ ] **Step 5: 커밋 + 푸시**

```bash
git add .github/ .gitmodules
git commit -m "ci: GitHub Actions 배포 + submodule 동기화 워크플로우"
git push origin master
```

---

## Task 11: 통합 테스트 + 최종 확인

**Files:**
- 기존 전체 파일 대상

- [ ] **Step 1: 전체 테스트 실행**

```bash
dart run build_runner build --delete-conflicting-outputs
flutter test
```

Expected: ALL PASS

- [ ] **Step 2: 콘텐츠 빌드 + Web 실행 확인**

```bash
dart run tools/content_builder.dart docs-source
flutter run -d chrome --web-port=8080
```

Expected:
1. 로그인 화면 표시
2. "로그인 없이 시작" → 중앙 홀
3. 분관 입구 클릭 → 분관 씬 (NPC + 책장 + 정령)
4. NPC 클릭 → 대화창 (선택지 분기)
5. 책장 클릭 → 퀘스트 게시판 (책 목록)
6. 챕터 선택 → 책 열람 (이론 + 시뮬레이터)
7. 뒤로 가기로 도서관 복귀

- [ ] **Step 3: 릴리즈 빌드 확인**

```bash
flutter build web --release --web-renderer canvaskit --base-href /dol/
```

Expected: `build/web/` 디렉토리 생성, 에러 없음

- [ ] **Step 4: 최종 커밋 + 푸시**

```bash
git add -A
git commit -m "feat: Dev Quest Library Phase 1 완성 — 도서관 게임 학습 시스템"
git push origin master
```

Expected: GitHub Actions CI + 배포 워크플로우 트리거 → `https://public-project-area-oragans.github.io/dol/` 접근 가능
