import 'package:dol/data/models/quest_model.dart';
import 'package:dol/domain/providers/npc_qa_providers.dart';
import 'package:dol/domain/providers/quest_providers.dart';
import 'package:dol/presentation/overlays/dialogue_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// fix-5 — NPC DialogueOverlay 의 ❓ 질문 탭이 activeNpcId null 상태에서도
/// 상시 노출되어야 한다. 과거에는 `if (npcId != null) _tabBar()` 로 숨겨져
/// 질문 기능 인지 자체가 불가능했음.
void main() {
  DialogueState _dialogueState() {
    const node = DialogueNode(
      id: 'intro',
      speakerName: '아르카누스',
      text: '어서 오게.',
      choices: [],
    );
    return const DialogueState(
      tree: DialogueTree(startNodeId: 'intro', nodes: [node]),
      currentNode: node,
      history: [],
    );
  }

  Widget harness({String? npcId}) {
    return ProviderScope(
      overrides: [
        activeDialogueProvider.overrideWith(
          () => _StubActiveDialogue(_dialogueState()),
        ),
        activeNpcIdProvider.overrideWith(
          () => _StubActiveNpcId(npcId),
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [DialogueOverlay(onClose: () {})],
          ),
        ),
      ),
    );
  }

  group('DialogueOverlay 탭바 상시 노출 (fix-5)', () {
    testWidgets('activeNpcId 가 null 이어도 💬 대화 / ❓ 질문 탭 모두 렌더',
        (tester) async {
      await tester.pumpWidget(harness(npcId: null));
      await tester.pumpAndSettle();
      expect(find.text('💬 대화'), findsOneWidget);
      expect(find.text('❓ 질문'), findsOneWidget);
    });

    testWidgets('npcId null + 질문 탭 선택 시 안내 placeholder 노출',
        (tester) async {
      await tester.pumpWidget(harness(npcId: null));
      await tester.pumpAndSettle();

      await tester.tap(find.text('❓ 질문'));
      await tester.pumpAndSettle();

      expect(find.textContaining('사서에게 먼저 말을 걸어라'), findsOneWidget);
    });

    testWidgets('npcId 존재 + 질문 탭 선택 시 TextField(_QaBody) 노출',
        (tester) async {
      await tester.pumpWidget(harness(npcId: 'wizard'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('❓ 질문'));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('기본 선택은 💬 대화 탭', (tester) async {
      await tester.pumpWidget(harness(npcId: 'wizard'));
      await tester.pumpAndSettle();
      // dialogue body 의 speakerName 이 보이면 대화 탭.
      expect(find.text('아르카누스'), findsOneWidget);
      // Q&A 탭 body 의 TextField 는 아직 없음 (질문 탭 미선택).
      expect(find.byType(TextField), findsNothing);
    });
  });
}

class _StubActiveDialogue extends ActiveDialogue {
  final DialogueState _value;
  _StubActiveDialogue(this._value);

  @override
  DialogueState? build() => _value;
}

class _StubActiveNpcId extends ActiveNpcId {
  final String? _value;
  _StubActiveNpcId(this._value);

  @override
  String? build() => _value;
}
