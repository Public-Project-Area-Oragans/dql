import 'dart:math';
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class SpiritComponent extends CircleComponent {
  final String spiritId;
  double _time = 0;
  final double _floatSpeed;
  final double _floatRange;

  SpiritComponent({
    required this.spiritId,
    required Vector2 position,
    double radius = 12,
  })  : _floatSpeed = 1.5 + Random().nextDouble(),
        _floatRange = 4 + Random().nextDouble() * 4,
        super(
          position: position,
          radius: radius,
          paint: Paint()..color = const Color(0xFFFFD700).withValues(alpha: 0.6),
        );

  late final Vector2 _basePosition;

  @override
  Future<void> onLoad() async {
    await super.onLoad();
    _basePosition = position.clone();
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    position.y = _basePosition.y + sin(_time * _floatSpeed) * _floatRange;
  }
}
