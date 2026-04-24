import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/assets/asset_ids.dart';
import '../components/wing_door_component.dart';
import '../dol_game.dart';
import '../rendering/sprite_registry.dart';

/// 중앙 홀 씬 (art-4b).
///
/// art-4 의 3층 parallax 가 `create_map_object` 투명 강제 제약으로 객체처럼
/// 떠 보이는 붕괴를 해결하기 위해 opaque base + transparent overlay 조립식으로
/// 재구성. 렌더 스택 (뒤→앞):
///
///   1. fallback 단색 (SpriteRegistry 로드 실패 대비)
///   2. env_mainhall_base (opaque 풀스크린)
///   3. deco_pillar (좌·우 mirror)
///   4. deco_entrance_arch × 4 (도어 뒤, scale 1.25 로 도어 외곽 glow)
///   5. deco_chandelier + deco_compass_rose (중앙 고정 장식)
///   6. WingDoorComponent × 4 (상호작용)
///
/// 각 레이어마다 `SpriteRegistry.has(...)` 로 로드 여부 확인. 누락 시 해당
/// 레이어 skip (fallback 단색 bg 가 그대로 노출).
class CentralHallScene extends Component with HasGameReference<DolGame> {
  @override
  Future<void> onLoad() async {
    final size = game.size;

    // 1. Fallback 단색 (base 스프라이트 로드 실패 시 노출).
    add(RectangleComponent(
      size: size,
      paint: Paint()..color = const Color(0xFF1A1420),
    ));

    // 2. env_mainhall_base (opaque 풀스크린).
    if (SpriteRegistry.has(EnvironmentAssets.mainhallBase)) {
      add(SpriteComponent(
        sprite: Sprite(SpriteRegistry.get(EnvironmentAssets.mainhallBase)),
        size: size,
        paint: Paint()..filterQuality = FilterQuality.none,
      ));
    }

    // 3. Pillars — 좌·우 mirror.
    _addPillars(size);

    // 4. Entrance arches — 각 도어 뒤에 배치, scale 1.25 로 glow 확장.
    _addEntranceArches(size);

    // 5. 중앙 장식 — 샹들리에(위) + 컴퍼스 로즈(아래).
    _addCenterDecorations(size);

    // 6. 4 분관 문.
    _addWingDoors(size);
  }

  void _addPillars(Vector2 size) {
    if (!SpriteRegistry.has(MainHallDecoAssets.pillar)) return;
    final sprite = Sprite(SpriteRegistry.get(MainHallDecoAssets.pillar));
    final pillarSize = Vector2(size.x * 0.08, size.y * 0.8);
    final paint = Paint()..filterQuality = FilterQuality.none;

    // Left pillar
    add(SpriteComponent(
      sprite: sprite,
      size: pillarSize,
      position: Vector2(size.x * 0.05, size.y * 0.1),
      paint: paint,
    ));

    // Right pillar — horizontal mirror.
    add(SpriteComponent(
      sprite: sprite,
      size: pillarSize,
      position: Vector2(size.x * 0.95, size.y * 0.1),
      anchor: Anchor.topRight,
      scale: Vector2(-1, 1),
      paint: paint,
    ));
  }

  void _addEntranceArches(Vector2 size) {
    // 4 도어 위치와 1:1 매칭. 도어 좌표 계산은 `_addWingDoors` 와 동일.
    // wings 순서: backend, frontend, database, architecture (기존 파일과 일치).
    final doorWidth = size.x / 5;
    final doorHeight = size.y * 0.3;
    final y = size.y * 0.4;

    final archAssets = <String>[
      MainHallDecoAssets.entranceArchBackend,
      MainHallDecoAssets.entranceArchFrontend,
      MainHallDecoAssets.entranceArchDatabase,
      MainHallDecoAssets.entranceArchArchitecture,
    ];

    for (var i = 0; i < archAssets.length; i++) {
      final archId = archAssets[i];
      if (!SpriteRegistry.has(archId)) continue;
      final x = (i + 0.5) * (size.x / 4) - doorWidth / 2;
      // scale 1.25 로 도어 64×64 외곽에 ~8px glow 띠 노출. 중앙 정렬.
      final archSize = Vector2(doorWidth * 1.25, doorHeight * 1.25);
      final offsetX = (doorWidth - archSize.x) / 2;
      final offsetY = (doorHeight - archSize.y) / 2;
      add(SpriteComponent(
        sprite: Sprite(SpriteRegistry.get(archId)),
        size: archSize,
        position: Vector2(x + offsetX, y + offsetY),
        paint: Paint()..filterQuality = FilterQuality.none,
      ));
    }
  }

  void _addCenterDecorations(Vector2 size) {
    // Chandelier — 화면 상단 중앙.
    if (SpriteRegistry.has(MainHallDecoAssets.chandelier)) {
      final chSize = Vector2(size.x * 0.2, size.y * 0.25);
      add(SpriteComponent(
        sprite: Sprite(SpriteRegistry.get(MainHallDecoAssets.chandelier)),
        size: chSize,
        position: Vector2((size.x - chSize.x) / 2, size.y * 0.02),
        paint: Paint()..filterQuality = FilterQuality.none,
      ));
    }

    // Compass rose — 화면 하단 중앙.
    if (SpriteRegistry.has(MainHallDecoAssets.compassRose)) {
      final crSize = Vector2(size.x * 0.2, size.y * 0.15);
      add(SpriteComponent(
        sprite: Sprite(SpriteRegistry.get(MainHallDecoAssets.compassRose)),
        size: crSize,
        position: Vector2((size.x - crSize.x) / 2, size.y * 0.82),
        paint: Paint()..filterQuality = FilterQuality.none,
      ));
    }
  }

  void _addWingDoors(Vector2 size) {
    final wings = <(String, String, Color, String)>[
      (
        'backend',
        '마법사의 탑',
        const Color(0xFF7B68EE),
        ObjectAssets.doorBackend,
      ),
      (
        'frontend',
        '기계공의 작업장',
        const Color(0xFFFF6347),
        ObjectAssets.doorFrontend,
      ),
      (
        'database',
        '연금술사의 실험실',
        const Color(0xFF2E8B57),
        ObjectAssets.doorDatabase,
      ),
      (
        'architecture',
        '건축가의 설계실',
        const Color(0xFF9370DB),
        ObjectAssets.doorArchitecture,
      ),
    ];

    final doorWidth = size.x / 5;
    final doorHeight = size.y * 0.3;
    final y = size.y * 0.4;

    for (var i = 0; i < wings.length; i++) {
      final (id, name, color, spriteId) = wings[i];
      final x = (i + 0.5) * (size.x / 4) - doorWidth / 2;
      add(WingDoorComponent(
        wingId: id,
        label: name,
        color: color,
        spriteId: spriteId,
        position: Vector2(x, y),
        size: Vector2(doorWidth, doorHeight),
      ));
    }
  }
}
