import 'package:flame/components.dart';
import 'package:flame/events.dart';
import 'package:flutter/material.dart';
import '../dol_game.dart';
import '../mixins/tappable_component.dart';

class BookshelfComponent extends RectangleComponent
    with TapCallbacks, TappableComponent, HasGameReference<DolGame> {
  final String shelfId;
  final String category;
  VoidCallback? onShelfTapped;

  BookshelfComponent({
    required this.shelfId,
    required this.category,
    required Vector2 position,
    required Vector2 size,
    this.onShelfTapped,
  }) : super(
          position: position,
          size: size,
          paint: Paint()..color = const Color(0xFF5C3D2E),
        );

  @override
  void onTapped() {
    onShelfTapped?.call();
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);

    final borderPaint = Paint()
      ..color = const Color(0xFFB8860B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawRect(size.toRect(), borderPaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: category.toUpperCase(),
        style: const TextStyle(
          color: Color(0xFFB8860B),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset((size.x - textPainter.width) / 2, (size.y - textPainter.height) / 2),
    );
  }
}
