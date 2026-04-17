import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../dol_game.dart';
import '../mixins/tappable_component.dart';

class NpcComponent extends RectangleComponent
    with TapCallbacks, TappableComponent, HasGameReference<DolGame> {
  final String npcId;
  final String npcName;
  final Color color;
  VoidCallback? onNpcTapped;

  NpcComponent({
    required this.npcId,
    required this.npcName,
    required this.color,
    required Vector2 position,
    this.onNpcTapped,
  }) : super(
          position: position,
          size: Vector2(64, 80),
          paint: Paint()..color = color,
        );

  @override
  void onTapped() {
    onNpcTapped?.call();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final textPainter = TextPainter(
      text: TextSpan(
        text: npcName,
        style: const TextStyle(
          color: Color(0xFFFFD700),
          fontSize: 10,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset((size.x - textPainter.width) / 2, size.y + 4),
    );
  }
}
