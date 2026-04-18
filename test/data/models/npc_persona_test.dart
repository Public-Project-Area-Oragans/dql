import 'dart:convert';

import 'package:dol/data/models/npc_model.dart';
import 'package:dol/data/models/quest_model.dart';
import 'package:dol/services/npc_personas.dart';
import 'package:flutter_test/flutter_test.dart';

/// P0-5 NPC-2: NpcModel / Quest 신규 필드 + NpcPersonas 상수 검증.
void main() {
  group('NpcModel 확장 (expertiseCategories, personaPromptKey)', () {
    test('기본값: 빈 리스트 + 빈 문자열', () {
      const npc = NpcModel(
        id: 'x',
        name: '테스트',
        role: 'tester',
        spriteAsset: 'none',
        quests: [],
      );
      expect(npc.expertiseCategories, isEmpty);
      expect(npc.personaPromptKey, '');
    });

    test('명시 필드 + fromJson round-trip', () {
      final npc = NpcModel.fromJson({
        'id': 'wizard',
        'name': '아르카누스',
        'role': 'wizard',
        'spriteAsset': 'npcs/wizard.png',
        'quests': <Map<String, dynamic>>[],
        'expertiseCategories': ['java-spring'],
        'personaPromptKey': 'wizard_backend',
      });
      expect(npc.expertiseCategories, ['java-spring']);
      expect(npc.personaPromptKey, 'wizard_backend');

      final roundTrip =
          NpcModel.fromJson(jsonDecode(jsonEncode(npc.toJson())) as Map<String, dynamic>);
      expect(roundTrip, npc);
    });
  });

  group('Quest 확장 (wingId, relatedCategories)', () {
    test('기본값: 빈 문자열 + 빈 리스트', () {
      const quest = Quest(
        id: 'q1',
        title: 'X',
        description: 'd',
        npcId: 'wizard',
        requiredChapters: [],
        dialogueTree: DialogueTree(startNodeId: 'intro', nodes: []),
        reward: QuestReward(xp: 0),
      );
      expect(quest.wingId, '');
      expect(quest.relatedCategories, isEmpty);
    });

    test('명시 + round-trip', () {
      final quest = Quest.fromJson({
        'id': 'q1',
        'title': 'Bean LifeCycle 숙련',
        'description': '아르카누스의 시험',
        'npcId': 'wizard',
        'requiredChapters': ['java-spring-ch-bean'],
        'dialogueTree': {'startNodeId': 'intro', 'nodes': []},
        'reward': {'xp': 100},
        'wingId': 'backend',
        'relatedCategories': ['java-spring'],
      });
      expect(quest.wingId, 'backend');
      expect(quest.relatedCategories, ['java-spring']);
    });
  });

  group('NpcPersonas 상수 테이블', () {
    test('4종 NPC 키 모두 존재', () {
      expect(NpcPersonas.all.keys, {
        'wizard_backend',
        'mechanic_frontend',
        'alchemist_database',
        'architect_architecture',
      });
    });

    test('각 prompt에 역할 이름 + 담당 분야 명시', () {
      expect(NpcPersonas.wizardBackend, contains('아르카누스'));
      expect(NpcPersonas.wizardBackend, contains('Java'));
      expect(NpcPersonas.wizardBackend, contains('Spring'));

      expect(NpcPersonas.mechanicFrontend, contains('코그윈'));
      expect(NpcPersonas.mechanicFrontend, contains('Dart'));
      expect(NpcPersonas.mechanicFrontend, contains('Flutter'));

      expect(NpcPersonas.alchemistDatabase, contains('메르쿠리아'));
      expect(NpcPersonas.alchemistDatabase, contains('MySQL'));

      expect(NpcPersonas.architectArchitecture, contains('모뉴멘타'));
      expect(NpcPersonas.architectArchitecture, contains('마이크로서비스'));
    });

    test('forKey lookup: 존재하는 키 / 없는 키', () {
      expect(NpcPersonas.forKey('wizard_backend'), isNotNull);
      expect(NpcPersonas.forKey('unknown_key'), isNull);
    });

    test('모든 prompt는 "담당 외 질문은 ... 안내" 지침 포함', () {
      for (final prompt in NpcPersonas.all.values) {
        expect(prompt, contains('담당 외'),
            reason: 'persona prompt는 담당 외 질문 처리 방침을 포함해야 함');
      }
    });
  });
}
