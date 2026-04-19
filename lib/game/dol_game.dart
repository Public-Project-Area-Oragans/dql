import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import 'rendering/sprite_registry.dart';
import 'scenes/central_hall_scene.dart';
import 'scenes/wing_scene.dart';

class DolGame extends FlameGame {
  VoidCallback? onNavigateToHall;
  void Function(String wingId)? onWingSelectedCallback;
  void Function(String npcId)? onNpcTappedCallback;
  void Function(String shelfId, String category)? onShelfTappedCallback;

  @override
  Color backgroundColor() => const Color(0xFF0F0B07);

  @override
  Future<void> onLoad() async {
    // art-1: SpriteRegistry 프리로드 훅. 현재는 자산 목록 비어 있어 no-op.
    // art-2 이후 UI 프레임·캐릭터·배경 자산이 추가될 때마다 이 리스트를
    // 확장. `SpriteRegistry.has(...)` 로 씬 · 위젯 측에서 로드 여부 분기.
    //
    // art-3 (타이틀 씬) 에서 FixedResolutionViewport(320×180) 전환 예정.
    // 그때까지는 기본 viewport 유지 (placeholder 렌더).
    await SpriteRegistry.preload(
      images: images,
      ids: const <String>[
        // 현재 프리로드 자산 없음. art-2 부터 UiAssets.frameDialog 등 주입.
      ],
    );

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

  void onShelfTapped(String shelfId, String category) {
    onShelfTappedCallback?.call(shelfId, category);
  }

  static final _wingConfigs = <String, (String, Color)>{
    'backend': ('마법사의 탑', const Color(0xFF7B68EE)),
    'frontend': ('기계공의 작업장', const Color(0xFFFF6347)),
    'database': ('연금술사의 실험실', const Color(0xFF2E8B57)),
    'architecture': ('건축가의 설계실', const Color(0xFF9370DB)),
  };
}
