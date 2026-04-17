import 'package:dio/dio.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:uuid/uuid.dart';
import '../../data/datasources/local/hive_datasource.dart';
import '../../data/models/player_progress_model.dart';
import '../../data/repositories/progress_repository.dart';
import '../../services/gist_service.dart';

part 'progress_providers.g.dart';

@riverpod
HiveDatasource hiveDatasource(Ref ref) => HiveDatasource();

@riverpod
GistService gistService(Ref ref) => GistService(dio: Dio());

@riverpod
ProgressRepository progressRepository(Ref ref) => ProgressRepository(
      local: ref.watch(hiveDatasourceProvider),
      gist: ref.watch(gistServiceProvider),
    );

@riverpod
class Progress extends _$Progress {
  @override
  PlayerProgress build() {
    final repo = ref.watch(progressRepositoryProvider);
    return repo.loadLocal() ??
        PlayerProgress(
          playerId: const Uuid().v4(),
          completedChapters: const {},
          completedQuests: const {},
          lastSavedAt: DateTime.now(),
        );
  }

  void completeChapter(String chapterId) {
    state = state.copyWith(
      completedChapters: {...state.completedChapters, chapterId},
      lastSavedAt: DateTime.now(),
    );
    _save();
  }

  void completeQuest(String questId) {
    state = state.copyWith(
      completedQuests: {...state.completedQuests, questId},
      lastSavedAt: DateTime.now(),
    );
    _save();
  }

  void _save() {
    ref.read(progressRepositoryProvider).saveLocal(state);
  }
}
