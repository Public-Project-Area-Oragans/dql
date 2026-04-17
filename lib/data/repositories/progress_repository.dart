import '../datasources/local/hive_datasource.dart';
import '../models/player_progress_model.dart';
import '../../services/gist_service.dart';

class ProgressRepository {
  final HiveDatasource _local;
  final GistService _gist;

  ProgressRepository({
    required HiveDatasource local,
    required GistService gist,
  })  : _local = local,
        _gist = gist;

  PlayerProgress? loadLocal() => _local.loadProgress();

  Future<void> saveLocal(PlayerProgress progress) =>
      _local.saveProgress(progress);

  Future<PlayerProgress?> loadRemote(String token) =>
      _gist.loadProgress(token);

  Future<void> saveRemote(String token, PlayerProgress progress) =>
      _gist.saveProgress(token, progress);
}
