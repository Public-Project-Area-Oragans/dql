import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../dol_game.dart';

class WingScene extends Component with HasGameReference<DolGame> {
  final String wingId;
  final String wingName;
  final Color themeColor;

  WingScene({
    required this.wingId,
    required this.wingName,
    required this.themeColor,
  });

  @override
  Future<void> onLoad() async {
    add(RectangleComponent(
      size: game.size,
      paint: Paint()..color = themeColor.withValues(alpha: 0.3),
    ));
  }
}
