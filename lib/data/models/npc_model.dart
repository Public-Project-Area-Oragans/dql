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
    // P0-5 NPC-2: 담당 카테고리 (book.json의 category 값 기준).
    // wing_scene._wingNpcConfig와 정합 유지.
    @Default([]) List<String> expertiseCategories,
    // npc_personas.dart 상수 테이블 lookup key.
    // (예: 'wizard_backend', 'mechanic_frontend')
    @Default('') String personaPromptKey,
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
