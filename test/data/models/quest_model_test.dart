import 'package:flutter_test/flutter_test.dart';
import 'package:dol/data/models/quest_model.dart';

void main() {
  group('DialogueTree', () {
    test('fromJson creates valid tree', () {
      final json = {
        'startNodeId': 'node1',
        'nodes': [
          {
            'id': 'node1',
            'speakerName': '아르카누스',
            'text': 'Java의 핵심을 아는가?',
            'choices': [
              {
                'text': 'JVM이 핵심입니다',
                'nextNodeId': 'node2',
                'isCorrect': true
              },
              {
                'text': '잘 모르겠습니다',
                'nextNodeId': 'node3',
                'isCorrect': false
              },
            ],
            'isCorrectPath': null,
          },
        ],
      };

      final tree = DialogueTree.fromJson(json);

      expect(tree.startNodeId, 'node1');
      expect(tree.nodes.length, 1);
      expect(tree.nodes.first.choices.length, 2);
      expect(tree.nodes.first.choices.first.isCorrect, true);
    });
  });

  group('Quest', () {
    test('status transitions with copyWith', () {
      final quest = Quest(
        id: 'q1',
        title: 'Java 기초 마스터',
        description: 'Java step 1-5 학습',
        npcId: 'wizard',
        requiredChapters: ['java-step01', 'java-step02'],
        dialogueTree: DialogueTree(startNodeId: 's', nodes: []),
        mixedQuiz: null,
        reward: QuestReward(xp: 100, title: null),
        status: QuestStatus.locked,
      );

      expect(quest.status, QuestStatus.locked);

      final available = quest.copyWith(status: QuestStatus.available);
      expect(available.status, QuestStatus.available);
      expect(available.id, 'q1');
    });
  });
}
