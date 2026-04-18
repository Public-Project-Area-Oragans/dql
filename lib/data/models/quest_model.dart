import 'package:freezed_annotation/freezed_annotation.dart';
import 'quiz_model.dart';

part 'quest_model.freezed.dart';
part 'quest_model.g.dart';

enum QuestStatus { locked, available, inProgress, completed }

@freezed
abstract class DialogueChoice with _$DialogueChoice {
  const factory DialogueChoice({
    required String text,
    required String nextNodeId,
    @Default(false) bool isCorrect,
  }) = _DialogueChoice;

  factory DialogueChoice.fromJson(Map<String, dynamic> json) =>
      _$DialogueChoiceFromJson(json);
}

@freezed
abstract class DialogueNode with _$DialogueNode {
  const factory DialogueNode({
    required String id,
    required String speakerName,
    required String text,
    required List<DialogueChoice> choices,
    bool? isCorrectPath,
  }) = _DialogueNode;

  factory DialogueNode.fromJson(Map<String, dynamic> json) =>
      _$DialogueNodeFromJson(json);
}

@freezed
abstract class DialogueTree with _$DialogueTree {
  const factory DialogueTree({
    required String startNodeId,
    required List<DialogueNode> nodes,
  }) = _DialogueTree;

  factory DialogueTree.fromJson(Map<String, dynamic> json) =>
      _$DialogueTreeFromJson(json);
}

@freezed
abstract class QuestReward with _$QuestReward {
  const factory QuestReward({
    required int xp,
    String? title,
  }) = _QuestReward;

  factory QuestReward.fromJson(Map<String, dynamic> json) =>
      _$QuestRewardFromJson(json);
}

@freezed
abstract class Quest with _$Quest {
  const factory Quest({
    required String id,
    required String title,
    required String description,
    required String npcId,
    required List<String> requiredChapters,
    required DialogueTree dialogueTree,
    MixedQuiz? mixedQuiz,
    required QuestReward reward,
    @Default(QuestStatus.locked) QuestStatus status,
    // P0-5 NPC-2: 퀘스트의 분관/카테고리 범위. 책장 필터 + QuestBoard
    // 분류에 사용.
    @Default('') String wingId,
    @Default([]) List<String> relatedCategories,
  }) = _Quest;

  factory Quest.fromJson(Map<String, dynamic> json) => _$QuestFromJson(json);
}
