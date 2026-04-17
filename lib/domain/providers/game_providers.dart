import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'game_providers.g.dart';

enum GameScene { title, centralHall, wing }

@riverpod
class CurrentScene extends _$CurrentScene {
  @override
  GameScene build() => GameScene.title;

  void goTo(GameScene scene) => state = scene;
}

@riverpod
class CurrentWingId extends _$CurrentWingId {
  @override
  String? build() => null;

  void select(String wingId) => state = wingId;
  void clear() => state = null;
}
