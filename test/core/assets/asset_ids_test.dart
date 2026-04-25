import 'package:dol/core/assets/asset_ids.dart';
import 'package:flutter_test/flutter_test.dart';

/// art-1 — 자산 ID 상수 회귀 가드. 파일명 규칙 (Manifest §8.2 / §6.2) 준수.
void main() {
  group('AnchorAssets', () {
    test('3 앵커 경로는 assets/sprites/_anchors/ 하위', () {
      expect(
        AnchorAssets.character,
        'assets/sprites/_anchors/anchor_character_v1.png',
      );
      expect(
        AnchorAssets.environment,
        'assets/sprites/_anchors/anchor_environment_v1.png',
      );
      expect(
        AnchorAssets.object,
        'assets/sprites/_anchors/anchor_object_v1.png',
      );
    });
  });

  group('UiAssets', () {
    // art-2: pubspec assets 와 rootBundle.load 호환 위해 'assets/' prefix 필수.
    test('UI 프레임 경로는 assets/sprites/ui/frames/ 하위', () {
      expect(UiAssets.frameDialog, startsWith('assets/sprites/ui/frames/'));
      expect(UiAssets.frameQuest, startsWith('assets/sprites/ui/frames/'));
      expect(UiAssets.frameBook, startsWith('assets/sprites/ui/frames/'));
      expect(UiAssets.framePanel, startsWith('assets/sprites/ui/frames/'));
      expect(
        UiAssets.frameCodeTerminal,
        startsWith('assets/sprites/ui/frames/'),
      );
    });

    test('UI 버튼 경로는 assets/sprites/ui/buttons/ 하위', () {
      expect(
        UiAssets.buttonPrimaryIdle,
        startsWith('assets/sprites/ui/buttons/'),
      );
      expect(
        UiAssets.buttonPrimaryHover,
        startsWith('assets/sprites/ui/buttons/'),
      );
      expect(
        UiAssets.buttonPrimaryPressed,
        startsWith('assets/sprites/ui/buttons/'),
      );
    });

    test('버튼 3 상태 네이밍', () {
      expect(UiAssets.buttonPrimaryIdle, contains('ui_button_primary'));
      expect(UiAssets.buttonPrimaryHover, contains('hover'));
      expect(UiAssets.buttonPrimaryPressed, contains('pressed'));
    });
  });

  group('CharacterAssets — 4 분관 NPC', () {
    test('idle / talk 각각 존재', () {
      expect(CharacterAssets.wizardIdle, contains('char_wizard_idle'));
      expect(CharacterAssets.wizardTalk, contains('char_wizard_talk'));
      expect(CharacterAssets.alchemistIdle, contains('alchemist_idle'));
      expect(CharacterAssets.mechanicIdle, contains('mechanic_idle'));
      expect(CharacterAssets.architectIdle, contains('architect_idle'));
    });
  });

  group('EnvironmentAssets — art-4b 중앙 홀 base', () {
    test('mainhallBase 경로 assets/sprites/environments/main_hall/ 하위', () {
      expect(
        EnvironmentAssets.mainhallBase,
        'assets/sprites/environments/main_hall/env_mainhall_base_v1.png',
      );
    });

    test('deprecated parallax 상수는 여전히 참조 가능 (호환성 유지)', () {
      // art-4b 에서 deprecated 표시. art-5 일괄 삭제 전까지 유지.
      // ignore: deprecated_member_use_from_same_package
      expect(EnvironmentAssets.mainhallBgFar, contains('bg_far'));
      // ignore: deprecated_member_use_from_same_package
      expect(EnvironmentAssets.mainhallBgMid, contains('bg_mid'));
      // ignore: deprecated_member_use_from_same_package
      expect(EnvironmentAssets.mainhallBgNear, contains('bg_near'));
    });

    test('4 wing 배경 각각 far/mid/near', () {
      const wings = ['backend', 'database', 'frontend', 'architecture'];
      const assets = [
        EnvironmentAssets.backendBgFar,
        EnvironmentAssets.databaseBgFar,
        EnvironmentAssets.frontendBgFar,
        EnvironmentAssets.architectureBgFar,
      ];
      for (var i = 0; i < wings.length; i++) {
        expect(assets[i], contains('${wings[i]}_wing'));
        expect(assets[i], contains('bg_far'));
      }
    });
  });

  group('MainHallDecoAssets — art-4b 조립식 오버레이', () {
    test('pillar / chandelier / compass_rose 경로', () {
      expect(
        MainHallDecoAssets.pillar,
        'assets/sprites/environments/main_hall/deco_mainhall_pillar_v1.png',
      );
      expect(
        MainHallDecoAssets.chandelier,
        'assets/sprites/environments/main_hall/deco_mainhall_chandelier_v1.png',
      );
      expect(
        MainHallDecoAssets.compassRose,
        'assets/sprites/environments/main_hall/deco_mainhall_compass_rose_v1.png',
      );
    });

    test('entrance_arch 4 분관 색 구분', () {
      expect(
        MainHallDecoAssets.entranceArchBackend,
        contains('entrance_arch_backend'),
      );
      expect(
        MainHallDecoAssets.entranceArchDatabase,
        contains('entrance_arch_database'),
      );
      expect(
        MainHallDecoAssets.entranceArchFrontend,
        contains('entrance_arch_frontend'),
      );
      expect(
        MainHallDecoAssets.entranceArchArchitecture,
        contains('entrance_arch_architecture'),
      );
    });
  });

  group('ObjectAssets — art-4c door v3', () {
    test('4 도어 모두 v3 로 업그레이드됨 (arched stone form)', () {
      expect(
        ObjectAssets.doorBackend,
        'assets/sprites/objects/doors/obj_door_backend_v3.png',
      );
      expect(
        ObjectAssets.doorFrontend,
        'assets/sprites/objects/doors/obj_door_frontend_v3.png',
      );
      expect(
        ObjectAssets.doorDatabase,
        'assets/sprites/objects/doors/obj_door_database_v3.png',
      );
      expect(
        ObjectAssets.doorArchitecture,
        'assets/sprites/objects/doors/obj_door_architecture_v3.png',
      );
    });
  });

  group('파일명 버전 suffix 일관성', () {
    test('v1, v2, v3 suffix 로 끝난다', () {
      final ids = <String>[
        AnchorAssets.character,
        AnchorAssets.environment,
        AnchorAssets.object,
        UiAssets.frameDialog,
        UiAssets.buttonPrimaryIdle,
        PortraitAssets.wizard,
        CharacterAssets.wizardIdle,
        EnvironmentAssets.mainhallBase,
        MainHallDecoAssets.pillar,
        ObjectAssets.doorBackend,
        ObjectAssets.doorFrontend,
        ObjectAssets.doorDatabase,
        ObjectAssets.doorArchitecture,
        TilesetAssets.commonFloor,
        VfxAssets.dustAmbient,
      ];
      for (final id in ids) {
        expect(
          id.endsWith('_v1.png') || id.endsWith('_v2.png') || id.endsWith('_v3.png'),
          isTrue,
          reason: 'failed on $id',
        );
      }
    });
  });
}
