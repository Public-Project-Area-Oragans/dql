import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../dol_game.dart';

class TitleScene extends Component with HasGameReference<DolGame> {
  @override
  Future<void> onLoad() async {
    add(RectangleComponent(
      size: game.size,
      paint: Paint()..color = const Color(0xFF0F0B07),
    ));
  }
}
