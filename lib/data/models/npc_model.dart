import 'package:freezed_annotation/freezed_annotation.dart';
import 'quest_model.dart';

part 'npc_model.freezed.dart';
part 'npc_model.g.dart';

@freezed
abstract class NpcModel with _$NpcModel {
  const factory NpcModel({
    required String id,
    required String name,
    required String role,
    required String spriteAsset,
    required List<Quest> quests,
  }) = _NpcModel;

  factory NpcModel.fromJson(Map<String, dynamic> json) =>
      _$NpcModelFromJson(json);
}

@freezed
abstract class Spirit with _$Spirit {
  const factory Spirit({
    required String id,
    required String name,
    required String spriteAsset,
    required String bookshelfId,
  }) = _Spirit;

  factory Spirit.fromJson(Map<String, dynamic> json) =>
      _$SpiritFromJson(json);
}
