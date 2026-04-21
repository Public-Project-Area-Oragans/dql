import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/assets/asset_ids.dart';
import '../components/wing_door_component.dart';
import '../dol_game.dart';
import '../rendering/sprite_registry.dart';

class CentralHallScene extends Component with HasGameReference<DolGame> {
  @override
  Future<void> onLoad() async {
    // 단색 바닥(FilterQuality 영향 없는 fallback).
    add(RectangleComponent(
      size: game.size,
      paint: Paint()..color = const Color(0xFF1A1420),
    ));

    // art-4: 3층 parallax 배경. 로드된 레이어만 쌓는다 — 하나라도 누락이면
    // 해당 층 skip. 현재는 정적 단일 프레임. 향후 art-4b 에서 카메라 이동 시
    // 시차 스크롤 적용 가능.
    for (final layer in const <String>[
      EnvironmentAssets.mainhallBgFar,
      EnvironmentAssets.mainhallBgMid,
      EnvironmentAssets.mainhallBgNear,
    ]) {
      if (!SpriteRegistry.has(layer)) continue;
      add(SpriteComponent(
        sprite: Sprite(SpriteRegistry.get(layer)),
        size: game.size,
        paint: Paint()..filterQuality = FilterQuality.none,
      ));
    }

    // 4 분관 문 배치 — 기존 위치·크기 로직 그대로 유지, 스프라이트 id 만 추가.
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

    final doorWidth = game.size.x / 5;
    final doorHeight = game.size.y * 0.3;
    final y = game.size.y * 0.4;

    for (var i = 0; i < wings.length; i++) {
      final (id, name, color, spriteId) = wings[i];
      final x = (i + 0.5) * (game.size.x / 4) - doorWidth / 2;

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
