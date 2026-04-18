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

@riverpod
class QuestBoardOpen extends _$QuestBoardOpen {
  @override
  bool build() => false;

  void open() => state = true;
  void close() => state = false;
}

/// 분관 책장에서 QuestBoard를 열 때 해당 분관의 카테고리를 전달.
/// null이면 전체 노출 (중앙 홀 등).
@riverpod
class QuestBoardFilterCategory extends _$QuestBoardFilterCategory {
  @override
  String? build() => null;

  void set(String? category) => state = category;
  void clear() => state = null;
}
