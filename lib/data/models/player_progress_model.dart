import 'package:freezed_annotation/freezed_annotation.dart';

part 'player_progress_model.freezed.dart';
part 'player_progress_model.g.dart';

@freezed
abstract class PlayerProgress with _$PlayerProgress {
  const PlayerProgress._();

  const factory PlayerProgress({
    required String playerId,
    required Set<String> completedChapters,
    required Set<String> completedQuests,
    String? currentWing,
    required DateTime lastSavedAt,
  }) = _PlayerProgress;

  bool isChapterCompleted(String chapterId) =>
      completedChapters.contains(chapterId);

  bool isQuestCompleted(String questId) =>
      completedQuests.contains(questId);

  factory PlayerProgress.fromJson(Map<String, dynamic> json) =>
      _$PlayerProgressFromJson(json);
}
