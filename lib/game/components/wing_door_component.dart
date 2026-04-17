import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../dol_game.dart';
import '../mixins/tappable_component.dart';

class WingDoorComponent extends RectangleComponent
    with TapCallbacks, TappableComponent, HasGameReference<DolGame> {
  final String wingId;
  final String label;
  final Color color;

  WingDoorComponent({
    required this.wingId,
    required this.label,
    required this.color,
    required Vector2 position,
    required Vector2 size,
  }) : super(
          position: position,
          size: size,
          paint: Paint()..color = color.withValues(alpha: 0.7),
        );

  @override
  void onTapped() {
    game.onWingSelected(wingId);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

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

    textPainter.paint(
      canvas,
      Offset(
        (size.x - textPainter.width) / 2,
        (size.y - textPainter.height) / 2,
      ),
    );
  }
}
