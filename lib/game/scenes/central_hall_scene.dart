import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/assets/asset_ids.dart';
import '../components/wing_door_component.dart';
import '../dol_game.dart';
import '../rendering/sprite_registry.dart';

/// 중앙 홀 씬 (art-4b v2).
///
/// art-4 의 3층 parallax 가 `create_map_object` 투명 강제 제약으로 객체처럼
/// 떠 보이는 붕괴를 해결하기 위해 opaque base + 도어 overlay 구성으로
/// 재정렬. 렌더 스택 (뒤→앞):
///
///   1. fallback 단색 (SpriteRegistry 로드 실패 대비)
///   2. env_mainhall_base (opaque 풀스크린 front-facing corridor)
///   3. WingDoorComponent × 4 (상호작용)
///
/// 초기 구상(v1) 의 pillar / entrance_arch / chandelier / compass_rose
/// overlay 는 base 이미지가 이미 책장·아치·샹들리에·컴퍼스를 포함해 중복·
/// 충돌 발생으로 현 단계에서 skip. 에셋 자체는 보존되어 art-8 폴리시 단계의
/// 독립 좌표·애니메이션에서 재활용 예정.
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

    // art-4b v2: pillar / entrance_arch / chandelier / compass_rose overlay 를
    // skip. 새 base 이미지가 이미 책장·아치·샹들리에·컴퍼스를 포함하고 있어
    // overlay 중복·충돌 발생. 에셋은 보존 (art-8 폴리시 단계에서 별도 좌표 ·
    // 애니메이션으로 재활용). 현 단계는 opaque base + 4 도어 구성으로 단순화.
    //
    // _addPillars(size);
    // _addEntranceArches(size);
    // _addCenterDecorations(size);

    // 6. 4 분관 문.
    _addWingDoors(size);
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

    // art-4b v2: 도어 크기·위치 조정. base corridor 원근감 보존 위해 축소
    // (/5 → /7, 0.3 → 0.25) + 바닥 쪽으로 내림 (0.4 → 0.5). PNG 자체가 64×64
    // 정사각이므로 비율 정사각에 가깝게 유지.
    final doorWidth = size.x / 7;
    final doorHeight = size.y * 0.25;
    final y = size.y * 0.5;

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
