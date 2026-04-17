import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../dol_game.dart';
import '../components/wing_door_component.dart';

class CentralHallScene extends Component with HasGameReference<DolGame> {
  @override
  Future<void> onLoad() async {
    add(RectangleComponent(
      size: game.size,
      paint: Paint()..color = const Color(0xFF1A1420),
    ));

    final wings = [
      ('backend', '마법사의 탑', const Color(0xFF7B68EE)),
      ('frontend', '기계공의 작업장', const Color(0xFFFF6347)),
      ('database', '연금술사의 실험실', const Color(0xFF2E8B57)),
      ('architecture', '건축가의 설계실', const Color(0xFF9370DB)),
    ];

    final doorWidth = game.size.x / 5;
    final doorHeight = game.size.y * 0.3;
    final y = game.size.y * 0.4;

    for (var i = 0; i < wings.length; i++) {
      final (id, name, color) = wings[i];
      final x = (i + 0.5) * (game.size.x / 4) - doorWidth / 2;

      add(WingDoorComponent(
        wingId: id,
        label: name,
        color: color,
        position: Vector2(x, y),
        size: Vector2(doorWidth, doorHeight),
      ));
    }
  }
}
