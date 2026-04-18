import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/quest_model.dart';
import '../../domain/providers/game_providers.dart';
import '../../domain/providers/npc_qa_providers.dart';
import '../../domain/providers/quest_providers.dart';
import '../../game/dol_game.dart';
import '../overlays/dialogue_overlay.dart';
import '../overlays/hud_overlay.dart';
import '../overlays/quest_board_overlay.dart';

class GameScreen extends ConsumerStatefulWidget {
  const GameScreen({super.key});

  @override
  ConsumerState<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends ConsumerState<GameScreen> {
  late final DolGame _game;

  @override
  void initState() {
    super.initState();
    _game = DolGame()
      ..onWingSelectedCallback = (wingId) {
        ref.read(currentWingIdProvider.notifier).select(wingId);
        ref.read(currentSceneProvider.notifier).goTo(GameScene.wing);
        _game.loadWing(wingId);
      }
      ..onNpcTappedCallback = (npcId) {
        // NPC-4: Q&A 탭이 담당 NPC persona를 참조하도록 id 저장.
        ref.read(activeNpcIdProvider.notifier).set(npcId);
        ref
            .read(activeDialogueProvider.notifier)
            .startDialogue(_placeholderTreeFor(npcId));
      }
      ..onShelfTappedCallback = (_, category) {
        // NPC-1: 분관 책장 클릭 시 해당 카테고리로 QuestBoard 필터링.
        ref.read(questBoardFilterCategoryProvider.notifier).set(category);
        ref.read(questBoardOpenProvider.notifier).open();
      };
  }

  @override
  Widget build(BuildContext context) {
    final scene = ref.watch(currentSceneProvider);
    final dialogue = ref.watch(activeDialogueProvider);
    final boardOpen = ref.watch(questBoardOpenProvider);

    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game),
          const HudOverlay(),
          if (scene == GameScene.wing && dialogue == null && !boardOpen)
            Positioned(
              top: 16,
              left: 16,
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: Color(0xFFFFD700)),
                onPressed: () {
                  ref.read(currentSceneProvider.notifier).goTo(GameScene.centralHall);
                  ref.read(currentWingIdProvider.notifier).clear();
                  _game.loadCentralHall();
                },
              ),
            ),
          if (dialogue != null) DialogueOverlay(onClose: () {}),
          if (boardOpen)
            QuestBoardOverlay(
              onClose: () {
                ref.read(questBoardOpenProvider.notifier).close();
                ref.read(questBoardFilterCategoryProvider.notifier).clear();
              },
              onChapterSelected: (bookId, chapterId) {
                ref.read(questBoardOpenProvider.notifier).close();
                ref.read(questBoardFilterCategoryProvider.notifier).clear();
                context.go('/book/$bookId/chapter/$chapterId');
              },
            ),
        ],
      ),
    );
  }
}

/// Task 7의 콘텐츠 바인딩 전까지 사용하는 NPC별 플레이스홀더 대화.
DialogueTree _placeholderTreeFor(String npcId) {
  final speaker = _npcSpeakerName[npcId] ?? npcId;
  return DialogueTree(
    startNodeId: 'intro',
    nodes: [
      DialogueNode(
        id: 'intro',
        speakerName: speaker,
        text: '어서 오게, 여행자여. 이 분관에는 아직 네게 줄 퀘스트가 준비되지 않았다.',
        choices: const [
          DialogueChoice(text: '더 듣기', nextNodeId: 'outro'),
          DialogueChoice(text: '돌아간다', nextNodeId: 'end'),
        ],
      ),
      const DialogueNode(
        id: 'outro',
        speakerName: '',
        text: '곧 책장에서 첫 번째 시험이 열릴 것이다. 그때 다시 찾아오라.',
        choices: [],
      ),
      const DialogueNode(
        id: 'end',
        speakerName: '',
        text: '그럼, 다음에 보지.',
        choices: [],
      ),
    ],
  );
}

const _npcSpeakerName = {
  'wizard': '아르카누스',
  'mechanic': '코그윈',
  'alchemist': '메르쿠리아',
  'architect': '모뉴멘타',
};
