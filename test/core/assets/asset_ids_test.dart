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
    test('UI 프레임 경로는 sprites/ui/frames/ 하위', () {
      expect(UiAssets.frameDialog, startsWith('sprites/ui/frames/'));
      expect(UiAssets.frameQuest, startsWith('sprites/ui/frames/'));
      expect(UiAssets.frameBook, startsWith('sprites/ui/frames/'));
      expect(UiAssets.framePanel, startsWith('sprites/ui/frames/'));
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

  group('EnvironmentAssets — 3 parallax 레이어', () {
    test('main hall far / mid / near 3층', () {
      expect(EnvironmentAssets.mainhallBgFar, contains('bg_far'));
      expect(EnvironmentAssets.mainhallBgMid, contains('bg_mid'));
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

  group('파일명 v1 suffix 일관성', () {
    test('모든 경로는 _v1.png 로 끝난다', () {
      final ids = <String>[
        AnchorAssets.character,
        AnchorAssets.environment,
        AnchorAssets.object,
        UiAssets.frameDialog,
        UiAssets.buttonPrimaryIdle,
        PortraitAssets.wizard,
        CharacterAssets.wizardIdle,
        EnvironmentAssets.mainhallBgFar,
        ObjectAssets.doorBackend,
        TilesetAssets.commonFloor,
        VfxAssets.dustAmbient,
      ];
      for (final id in ids) {
        expect(id, endsWith('_v1.png'), reason: 'failed on $id');
      }
    });
  });
}
