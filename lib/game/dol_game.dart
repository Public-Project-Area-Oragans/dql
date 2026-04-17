import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'scenes/central_hall_scene.dart';
import 'scenes/wing_scene.dart';

class DolGame extends FlameGame {
  VoidCallback? onNavigateToHall;
  void Function(String wingId)? onWingSelectedCallback;
  void Function(String npcId)? onNpcTappedCallback;

  @override
  Color backgroundColor() => const Color(0xFF0F0B07);

  @override
  Future<void> onLoad() async {
    await loadCentralHall();
  }

  Future<void> loadCentralHall() async {
    children.toList().forEach(remove);
    add(CentralHallScene());
  }

  Future<void> loadWing(String wingId) async {
    children.toList().forEach(remove);

    final wingConfig = _wingConfigs[wingId];
    if (wingConfig == null) return;

    add(WingScene(
      wingId: wingId,
      wingName: wingConfig.$1,
      themeColor: wingConfig.$2,
    ));
  }

  void onWingSelected(String wingId) {
    onWingSelectedCallback?.call(wingId);
  }

  void onNpcTapped(String npcId) {
    onNpcTappedCallback?.call(npcId);
  }

  static final _wingConfigs = <String, (String, Color)>{
    'backend': ('마법사의 탑', const Color(0xFF7B68EE)),
    'frontend': ('기계공의 작업장', const Color(0xFFFF6347)),
    'database': ('연금술사의 실험실', const Color(0xFF2E8B57)),
    'architecture': ('건축가의 설계실', const Color(0xFF9370DB)),
  };
}
