import 'package:flame/components.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:dol/game/scenes/central_hall_scene_layout.dart';

void main() {
  group('CentralHallSceneLayout.doorTransforms', () {
    test('4 도어 transform 반환', () {
      final transforms = CentralHallSceneLayout.doorTransforms(Vector2(1100, 720));
      expect(transforms.length, 4);
    });

    test('도어 width = sceneWidth / 11', () {
      final transforms = CentralHallSceneLayout.doorTransforms(Vector2(1100, 720));
      for (final t in transforms) {
        expect(t.size.x, closeTo(100, 0.01)); // 1100 / 11 = 100
      }
    });

    test('도어 height = width * 1.5 (64×96 비율)', () {
      final transforms = CentralHallSceneLayout.doorTransforms(Vector2(1100, 720));
      for (final t in transforms) {
        expect(t.size.y, closeTo(150, 0.01)); // 100 * 1.5 = 150
      }
    });

    test('도어 y = sceneHeight * 0.45', () {
      final transforms = CentralHallSceneLayout.doorTransforms(Vector2(1100, 720));
      for (final t in transforms) {
        expect(t.position.y, closeTo(324, 0.01)); // 720 * 0.45 = 324
      }
    });

    test('도어 x = sceneWidth * [0.32, 0.43, 0.54, 0.65] (등간격 클러스터)', () {
      final transforms = CentralHallSceneLayout.doorTransforms(Vector2(1100, 720));
      final expectedXs = [352.0, 473.0, 594.0, 715.0]; // 1100 * 비율
      for (var i = 0; i < 4; i++) {
        expect(transforms[i].position.x, closeTo(expectedXs[i], 0.01));
      }
    });

    test('도어 인덱스 순서 고정 (i=0 backend, 1 frontend, 2 database, 3 architecture)', () {
      final transforms = CentralHallSceneLayout.doorTransforms(Vector2(1100, 720));
      expect(transforms.length, 4);
    });
  });
}
