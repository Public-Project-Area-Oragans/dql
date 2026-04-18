import 'dart:io';

import 'package:dol/data/models/quest_model.dart';
import 'package:dol/domain/providers/progress_providers.dart';
import 'package:dol/domain/providers/wing_quests_providers.dart';
import 'package:dol/services/wing_quests.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// P0-5 NPC-6: wingQuestsProvider가 progress 변화에 따라 상태를 갱신하는지 검증.
void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('wing_quests_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<String>('progress');
  });

  tearDown(() async {
    try {
      await Hive.deleteFromDisk();
    } catch (_) {}
    try {
      await Hive.close();
    } catch (_) {}
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  test('wingId 빈 문자열이면 빈 리스트', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(wingQuestsProvider('')), isEmpty);
  });

  test('progress 변화 시 status 재계산', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final backendQuest = WingQuests.forWing('backend').first;
    final required = backendQuest.requiredChapters.toSet();

    // 초기 상태: inProgress
    final initial = container.read(wingQuestsProvider('backend'));
    expect(initial.first.status, QuestStatus.inProgress);

    // 필요 챕터 완료 후: completed
    for (final chapter in required) {
      container.read(progressProvider.notifier).completeChapter(chapter);
    }
    final after = container.read(wingQuestsProvider('backend'));
    expect(after.first.status, QuestStatus.completed);
  });

  test('알 수 없는 wingId는 빈 리스트', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    expect(container.read(wingQuestsProvider('nope')), isEmpty);
  });
}
