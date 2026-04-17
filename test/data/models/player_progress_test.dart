import 'package:flutter_test/flutter_test.dart';
import 'package:dol/data/models/player_progress_model.dart';

void main() {
  test('PlayerProgress serialization roundtrip', () {
    final progress = PlayerProgress(
      playerId: 'test-uuid',
      completedChapters: {'java-step01', 'java-step02'},
      completedQuests: {'q1'},
      currentWing: 'backend',
      lastSavedAt: DateTime(2026, 4, 17),
    );

    final json = progress.toJson();
    final restored = PlayerProgress.fromJson(json);

    expect(restored.playerId, 'test-uuid');
    expect(restored.completedChapters, contains('java-step01'));
    expect(restored.completedQuests, contains('q1'));
    expect(restored.currentWing, 'backend');
  });

  test('isChapterCompleted returns correct result', () {
    final progress = PlayerProgress(
      playerId: 'test',
      completedChapters: {'ch1', 'ch2'},
      completedQuests: {},
      lastSavedAt: DateTime.now(),
    );

    expect(progress.isChapterCompleted('ch1'), true);
    expect(progress.isChapterCompleted('ch3'), false);
  });

  test('isQuestCompleted returns correct result', () {
    final progress = PlayerProgress(
      playerId: 'test',
      completedChapters: {},
      completedQuests: {'q1', 'q2'},
      lastSavedAt: DateTime.now(),
    );

    expect(progress.isQuestCompleted('q1'), true);
    expect(progress.isQuestCompleted('q99'), false);
  });
}
