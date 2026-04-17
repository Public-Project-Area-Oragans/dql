import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import '../../models/player_progress_model.dart';

class HiveDatasource {
  static const _boxName = 'progress';
  static const _key = 'player_progress';

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
  }

  Future<void> saveProgress(PlayerProgress progress) async {
    final box = Hive.box<String>(_boxName);
    await box.put(_key, jsonEncode(progress.toJson()));
  }

  PlayerProgress? loadProgress() {
    final box = Hive.box<String>(_boxName);
    final json = box.get(_key);
    if (json == null) return null;
    return PlayerProgress.fromJson(jsonDecode(json) as Map<String, dynamic>);
  }

  Future<void> clear() async {
    final box = Hive.box<String>(_boxName);
    await box.delete(_key);
  }
}
