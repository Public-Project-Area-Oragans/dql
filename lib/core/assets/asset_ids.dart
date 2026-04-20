/// 프로젝트 스프라이트 자산 ID 타입-세이프 상수.
///
/// `PIXEL_ART_ASSET_MANIFEST.md` §6 네이밍 규칙에 따라 파일 경로를 전량 문자열
/// 상수로 고정. Flame `images.load(...)` / Flutter `AssetImage(...)` 양쪽 모두
/// 동일한 경로를 참조. 오타 방지 + IDE 자동완성 + grep 기반 리팩터 가능.
///
/// 전 경로는 `assets/sprites/` prefix 를 가정 — pubspec `flutter.assets:` 블록이
/// 해당 서브트리를 선언해야 로드 가능. art-* PR 별로 자산 생성과 함께 pubspec
/// 선언을 점진 확장.
///
/// Manifest §8.2 파일명 규칙 예: `char_npc_mechanic_walk_e_v1.png`.
/// 본 파일의 상수명은 Manifest §6.2 camelCase 변환 규칙 준수.
library;

// ── Style Anchors (art-0) ─────────────────────────────────────────────
// _anchors/ 는 Manifest §7.2 대로 런타임 번들 제외. 상수 등록 목적은
// 런타임이 아닌 build tool / QA 스크립트 참조용.
class AnchorAssets {
  const AnchorAssets._();

  static const character = 'assets/sprites/_anchors/anchor_character_v1.png';
  static const environment =
      'assets/sprites/_anchors/anchor_environment_v1.png';
  static const object = 'assets/sprites/_anchors/anchor_object_v1.png';
}

// ── UI Frames & Buttons (art-2) ───────────────────────────────────────
// 9-slice 대응 128×64 프레임 등. art-2 PR 에서 실제 PNG 채워짐.
class UiAssets {
  const UiAssets._();

  static const frameDialog =
      'assets/sprites/ui/frames/ui_frame_dialog_v1.png';
  static const frameQuest =
      'assets/sprites/ui/frames/ui_frame_quest_v1.png';
  static const frameBook = 'assets/sprites/ui/frames/ui_frame_book_v1.png';
  static const framePanel =
      'assets/sprites/ui/frames/ui_frame_panel_v1.png';
  static const frameCodeTerminal =
      'assets/sprites/ui/frames/ui_frame_code_terminal_v1.png';

  static const buttonPrimaryIdle =
      'assets/sprites/ui/buttons/ui_button_primary_v1.png';
  static const buttonPrimaryHover =
      'assets/sprites/ui/buttons/ui_button_primary_hover_v1.png';
  static const buttonPrimaryPressed =
      'assets/sprites/ui/buttons/ui_button_primary_pressed_v1.png';

  // ── art-3 Title Logo ─────────────────────────────────────────────
  static const logoTitle = 'assets/sprites/ui/logos/ui_logo_title_v1.png';
}

// ── NPC Portraits (art-2) ─────────────────────────────────────────────
// 64×64 대화창 초상화.
class PortraitAssets {
  const PortraitAssets._();

  static const wizard = 'sprites/ui/portraits/ui_portrait_wizard_v1.png';
  static const alchemist = 'sprites/ui/portraits/ui_portrait_alchemist_v1.png';
  static const mechanic = 'sprites/ui/portraits/ui_portrait_mechanic_v1.png';
  static const architect = 'sprites/ui/portraits/ui_portrait_architect_v1.png';
  static const player = 'sprites/ui/portraits/ui_portrait_player_v1.png';
}

// ── Characters (art-7) — 4 분관 마스터 NPC ────────────────────────────
// 4-frame idle sheet (256×96) + 2-frame talk (128×96).
class CharacterAssets {
  const CharacterAssets._();

  static const wizardIdle = 'sprites/characters/wizard/char_wizard_idle_v1.png';
  static const wizardTalk = 'sprites/characters/wizard/char_wizard_talk_v1.png';

  static const alchemistIdle =
      'sprites/characters/alchemist/char_alchemist_idle_v1.png';
  static const alchemistTalk =
      'sprites/characters/alchemist/char_alchemist_talk_v1.png';

  static const mechanicIdle =
      'sprites/characters/mechanic/char_mechanic_idle_v1.png';
  static const mechanicTalk =
      'sprites/characters/mechanic/char_mechanic_talk_v1.png';

  static const architectIdle =
      'sprites/characters/architect/char_architect_idle_v1.png';
  static const architectTalk =
      'sprites/characters/architect/char_architect_talk_v1.png';
}

// ── Environments (art-3/4/5/6) ────────────────────────────────────────
// 256×144 풀샷 배경 + parallax 3층 구조.
class EnvironmentAssets {
  const EnvironmentAssets._();

  // Title (art-3)
  static const titleBg =
      'assets/sprites/environments/title/env_title_bg_v1.png';

  // Main Hall (art-4) — 3 parallax layers
  static const mainhallBgFar =
      'sprites/environments/main_hall/env_mainhall_bg_far_v1.png';
  static const mainhallBgMid =
      'sprites/environments/main_hall/env_mainhall_bg_mid_v1.png';
  static const mainhallBgNear =
      'sprites/environments/main_hall/env_mainhall_bg_near_v1.png';

  // Backend wing (art-5)
  static const backendBgFar =
      'sprites/environments/backend_wing/env_backend_wing_bg_far_v1.png';
  static const backendBgMid =
      'sprites/environments/backend_wing/env_backend_wing_bg_mid_v1.png';
  static const backendBgNear =
      'sprites/environments/backend_wing/env_backend_wing_bg_near_v1.png';

  // Database wing (art-5)
  static const databaseBgFar =
      'sprites/environments/database_wing/env_database_wing_bg_far_v1.png';
  static const databaseBgMid =
      'sprites/environments/database_wing/env_database_wing_bg_mid_v1.png';
  static const databaseBgNear =
      'sprites/environments/database_wing/env_database_wing_bg_near_v1.png';

  // Frontend wing (art-6)
  static const frontendBgFar =
      'sprites/environments/frontend_wing/env_frontend_wing_bg_far_v1.png';
  static const frontendBgMid =
      'sprites/environments/frontend_wing/env_frontend_wing_bg_mid_v1.png';
  static const frontendBgNear =
      'sprites/environments/frontend_wing/env_frontend_wing_bg_near_v1.png';

  // Architecture wing (art-6)
  static const architectureBgFar =
      'sprites/environments/architecture_wing/env_architecture_wing_bg_far_v1.png';
  static const architectureBgMid =
      'sprites/environments/architecture_wing/env_architecture_wing_bg_mid_v1.png';
  static const architectureBgNear =
      'sprites/environments/architecture_wing/env_architecture_wing_bg_near_v1.png';
}

// ── Map Objects (art-4, art-8) ────────────────────────────────────────
class ObjectAssets {
  const ObjectAssets._();

  // Wing doors (art-4) — 64×96 + 4-frame glow
  static const doorBackend =
      'sprites/objects/doors/obj_door_backend_v1.png';
  static const doorDatabase =
      'sprites/objects/doors/obj_door_database_v1.png';
  static const doorFrontend =
      'sprites/objects/doors/obj_door_frontend_v1.png';
  static const doorArchitecture =
      'sprites/objects/doors/obj_door_architecture_v1.png';
  static const doorGlow =
      'sprites/objects/doors/obj_door_glow_v1.png';

  // Bookshelves (art-8) — 64×96 per wing variant
  static const bookshelfBackend =
      'sprites/objects/furniture/obj_backend_bookshelf_v1.png';
  static const bookshelfDatabase =
      'sprites/objects/furniture/obj_database_bookshelf_v1.png';
  static const bookshelfFrontend =
      'sprites/objects/furniture/obj_frontend_bookshelf_v1.png';
  static const bookshelfArchitecture =
      'sprites/objects/furniture/obj_architecture_bookshelf_v1.png';

  // Quest board (art-4)
  static const questBoard = 'sprites/objects/quest_board/obj_quest_board_v1.png';
}

// ── Tilesets (art-5/6) ────────────────────────────────────────────────
// 32×32 Wang 타일셋. wings 별 벽·바닥 조합.
class TilesetAssets {
  const TilesetAssets._();

  static const commonFloor =
      'sprites/tilesets/tileset_common_floor_v1.png';
  static const backendWall =
      'sprites/tilesets/tileset_backend_wall_v1.png';
  static const databaseWall =
      'sprites/tilesets/tileset_database_wall_v1.png';
  static const frontendWall =
      'sprites/tilesets/tileset_frontend_wall_v1.png';
  static const architectureWall =
      'sprites/tilesets/tileset_architecture_wall_v1.png';
}

// ── VFX (art-8/9) ────────────────────────────────────────────────────
class VfxAssets {
  const VfxAssets._();

  static const dustAmbient = 'sprites/vfx/vfx_dust_ambient_v1.png';
  static const steamGreen = 'sprites/vfx/vfx_steam_green_v1.png';
  static const magicPurple = 'sprites/vfx/vfx_magic_purple_v1.png';
  static const sparkGold = 'sprites/vfx/vfx_spark_gold_v1.png';
  static const sceneFadeGear = 'sprites/vfx/vfx_scene_fade_gear_v1.png';
}
