import 'package:flame/components.dart';

/// 중앙 홀 도어 4개의 transform (size + position) 산출.
///
/// art-4c: base v2 의 후면 아치 근처에 4 도어 클러스터 배치.
/// 도어 순서 (인덱스 고정): 0=backend, 1=frontend, 2=database, 3=architecture.
class DoorTransform {
  final Vector2 size;
  final Vector2 position;
  const DoorTransform({required this.size, required this.position});
}

class CentralHallSceneLayout {
  static const double doorWidthRatio = 1 / 8; // 1/11 → 1/8 (확대). 1100 / 8 = 137.5
  static const double doorAspect = 1.5; // 64×96 PNG 비율
  static const double doorYRatio = 0.45;
  static const List<double> doorXRatios = [0.25, 0.42, 0.58, 0.75];

  static List<DoorTransform> doorTransforms(Vector2 sceneSize) {
    final width = sceneSize.x * doorWidthRatio;
    final height = width * doorAspect;
    final y = sceneSize.y * doorYRatio;

    return [
      for (final xRatio in doorXRatios)
        DoorTransform(
          size: Vector2(width, height),
          // xRatio 는 도어 중심점, position 은 top-left 이므로 width/2 만큼 좌측 이동.
          position: Vector2(sceneSize.x * xRatio - width / 2, y),
        ),
    ];
  }
}
