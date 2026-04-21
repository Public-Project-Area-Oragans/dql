import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../dol_game.dart';
import '../mixins/tappable_component.dart';
import '../rendering/sprite_registry.dart';

/// 4 분관 입구 문 (art-4).
///
/// 스프라이트 로드 성공 시 `SpriteComponent` 자식으로 실제 분관 문 픽셀아트
/// 렌더, 실패/미로드 시 단색 `RectangleComponent` fallback. 어느 쪽이든
/// 라벨은 중앙에 `TextComponent` 로 덮어 그린다.
///
/// hover / pressed 시각 효과는 `TappableComponent` 믹스인의 ColorFilter
/// tint 로 자식 전체를 일괄 감싼다 (art-2b). Flutter `ColorFilter` 는
/// Bible §3.1 팔레트 락 위반이므로 스프라이트 단계에서 색조를 바꾸지 않음.
class WingDoorComponent extends PositionComponent
    with
        TapCallbacks,
        HoverCallbacks,
        TappableComponent,
        HasGameReference<DolGame> {
  final String wingId;
  final String label;
  final Color color;

  /// art-4: 분관별 도어 스프라이트 id. 미로드 시 단색 rect 로 fallback.
  final String spriteId;

  WingDoorComponent({
    required this.wingId,
    required this.label,
    required this.color,
    required this.spriteId,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  @override
  Future<void> onLoad() async {
    if (SpriteRegistry.has(spriteId)) {
      // 스프라이트 원본 비율을 유지한 채 size 에 contain(fit) 되도록 스케일.
      // 원본은 64×64 (PixelLab) — 도어 프레임 비율(64×96) 보다 짧지만
      // SpriteComponent 가 size 에 맞춰 stretch. 향후 art-4b 에서 비율
      // 보정 가능.
      add(SpriteComponent(
        sprite: Sprite(SpriteRegistry.get(spriteId)),
        size: size,
        // paint 에 FilterQuality.none 을 강제 (Bible §9.1).
        paint: Paint()..filterQuality = FilterQuality.none,
      ));
    } else {
      add(RectangleComponent(
        size: size,
        paint: Paint()..color = color.withValues(alpha: 0.7),
      ));
    }

    // 라벨은 항상 중앙에 덮어 그린다. 자식 순서상 마지막에 추가해 최상단
    // 렌더. TappableComponent tint 로 같이 색조 변함.
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

    add(_LabelComponent(
      painter: textPainter,
      position: Vector2(
        (size.x - textPainter.width) / 2,
        (size.y - textPainter.height) / 2,
      ),
      size: Vector2(textPainter.width, textPainter.height),
    ));
  }

  @override
  void onTapped() {
    game.onWingSelected(wingId);
  }
}

/// 문 라벨 전용 PositionComponent. TextComponent 대신 직접 TextPainter 를
/// 재사용해 폰트·색상 지정 일관성을 유지.
class _LabelComponent extends PositionComponent {
  final TextPainter painter;

  _LabelComponent({
    required this.painter,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  @override
  void render(Canvas canvas) {
    painter.paint(canvas, Offset.zero);
  }
}
