import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/providers/game_providers.dart';
import '../../game/dol_game.dart';

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
      };
  }

  @override
  Widget build(BuildContext context) {
    final scene = ref.watch(currentSceneProvider);

    return Scaffold(
      body: Stack(
        children: [
          GameWidget(game: _game),
          if (scene == GameScene.wing)
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
        ],
      ),
    );
  }
}
