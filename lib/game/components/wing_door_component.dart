import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';

import '../dol_game.dart';
import '../mixins/tappable_component.dart';
import '../rendering/sprite_registry.dart';

/// 4 분관 입구 문 (art-4 → art-4c).
///
/// 스프라이트 로드 성공 시 `SpriteComponent` 자식으로 실제 분관 문 픽셀아트
/// 렌더, 실패/미로드 시 단색 `RectangleComponent` fallback.
///
/// art-4c: 라벨은 도어 위에 반투명 plaque 형태의 별도 sign 으로 분리
/// (이전: 도어 중앙 덮어 그리기). 도어 v3 가 작아도 텍스트 가독성 확보.
///
/// hover / pressed 시각 효과는 `TappableComponent` 믹스인의 ColorFilter
/// tint 로 자식 전체를 일괄 감싼다.
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

    // art-4c: 라벨을 도어 위 반투명 plaque 로 분리. 작은 도어에서도 가독성 확보.
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 20,
          fontWeight: FontWeight.bold,
          fontFamily: 'JetBrainsMonoHangul',
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const plaqueHorizontalPadding = 8.0;
    const plaqueVerticalPadding = 4.0;
    const plaqueGap = 6.0; // 도어 상단과 plaque 하단 사이 여백
    final plaqueWidth = textPainter.width + plaqueHorizontalPadding * 2;
    final plaqueHeight = textPainter.height + plaqueVerticalPadding * 2;
    final plaqueX = (size.x - plaqueWidth) / 2;
    final plaqueY = -plaqueHeight - plaqueGap;

    add(_LabelPlaqueComponent(
      painter: textPainter,
      plaquePadding: const EdgeInsets.symmetric(
        horizontal: plaqueHorizontalPadding,
        vertical: plaqueVerticalPadding,
      ),
      position: Vector2(plaqueX, plaqueY),
      size: Vector2(plaqueWidth, plaqueHeight),
    ));
  }

  @override
  void onTapped() {
    game.onWingSelected(wingId);
  }
}

/// 도어 위 반투명 plaque + 텍스트 라벨. art-4c 시각적 가독성 보강.
class _LabelPlaqueComponent extends PositionComponent {
  final TextPainter painter;
  final EdgeInsets plaquePadding;

  _LabelPlaqueComponent({
    required this.painter,
    required this.plaquePadding,
    required Vector2 position,
    required Vector2 size,
  }) : super(position: position, size: size);

  @override
  void render(Canvas canvas) {
    // 반투명 검정 plaque (간판 느낌).
    final rect = Rect.fromLTWH(0, 0, size.x, size.y);
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(3));
    canvas.drawRRect(
      rrect,
      Paint()..color = const Color(0xCC000000), // 80% opacity black
    );
    // 텍스트는 plaque 안쪽 padding 위치에서 그린다.
    painter.paint(canvas, Offset(plaquePadding.left, plaquePadding.top));
  }
}
