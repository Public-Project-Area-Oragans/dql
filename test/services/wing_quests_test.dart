import 'package:dol/data/models/quest_model.dart';
import 'package:dol/services/wing_quests.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('WingQuests.forWing', () {
    test('4개 분관 각각에 최소 1개 샘플 퀘스트', () {
      for (final wing in const ['backend', 'frontend', 'database', 'architecture']) {
        final list = WingQuests.forWing(wing);
        expect(list, isNotEmpty, reason: '$wing 분관 퀘스트가 비어있음');
        for (final q in list) {
          expect(q.wingId, wing);
          expect(q.requiredChapters, isNotEmpty);
          expect(q.dialogueTree.nodes, isNotEmpty);
        }
      }
    });

    test('알 수 없는 wingId는 빈 리스트', () {
      expect(WingQuests.forWing('unknown'), isEmpty);
    });
  });

  group('WingQuests.withStatus', () {
    test('requiredChapters 전부 완료 시 status=completed', () {
      final original = WingQuests.forWing('backend').first;
      final completed = original.requiredChapters.toSet();
      final updated = WingQuests.withStatus('backend', completed);
      expect(updated.first.status, QuestStatus.completed);
    });

    test('requiredChapters 미완료 시 status=inProgress', () {
      final updated = WingQuests.withStatus('backend', const {});
      expect(updated.first.status, QuestStatus.inProgress);
    });

    test('일부만 완료해도 completed 아님', () {
      final original = WingQuests.forWing('backend').first;
      final partial = {original.requiredChapters.first};
      // requiredChapters 전체가 들어있지 않으면 inProgress
      if (original.requiredChapters.length > 1) {
        final updated = WingQuests.withStatus('backend', partial);
        expect(updated.first.status, QuestStatus.inProgress);
      }
    });

    test('알 수 없는 wingId → 빈 리스트', () {
      expect(WingQuests.withStatus('nope', const {}), isEmpty);
    });
  });
}
