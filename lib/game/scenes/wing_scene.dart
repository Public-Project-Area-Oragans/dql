import 'package:flame/components.dart';
import 'package:flutter/material.dart';
import '../dol_game.dart';
import '../components/npc_component.dart';
import '../components/bookshelf_component.dart';
import '../components/spirit_component.dart';

class WingScene extends Component with HasGameReference<DolGame> {
  final String wingId;
  final String wingName;
  final Color themeColor;

  WingScene({
    required this.wingId,
    required this.wingName,
    required this.themeColor,
  });

  @override
  Future<void> onLoad() async {
    add(RectangleComponent(
      size: game.size,
      paint: Paint()..color = themeColor.withValues(alpha: 0.15),
    ));

    final config = _wingNpcConfig[wingId];
    if (config == null) return;

    add(NpcComponent(
      npcId: config.npcId,
      npcName: config.npcName,
      color: themeColor,
      position: Vector2(game.size.x * 0.15, game.size.y * 0.4),
      onNpcTapped: () => game.onNpcTapped(config.npcId),
    ));

    final shelfWidth = game.size.x * 0.2;
    final shelfHeight = game.size.y * 0.5;

    for (var i = 0; i < config.categories.length; i++) {
      final x = game.size.x * 0.5 + i * (shelfWidth + 20);
      final shelfId = '${wingId}_shelf_$i';
      final category = config.categories[i];
      add(BookshelfComponent(
        shelfId: shelfId,
        category: category,
        position: Vector2(x, game.size.y * 0.25),
        size: Vector2(shelfWidth, shelfHeight),
        onShelfTapped: () => game.onShelfTapped(shelfId, category),
      ));

      add(SpiritComponent(
        spiritId: '${wingId}_spirit_$i',
        position: Vector2(x + shelfWidth / 2, game.size.y * 0.2),
      ));
    }
  }
}

class _WingNpcConfig {
  final String npcId;
  final String npcName;
  final List<String> categories;

  const _WingNpcConfig(this.npcId, this.npcName, this.categories);
}

// NPC-1: book.json 카테고리 ID와 정확히 매칭시킴 (과거 'java' 오타 수정).
final _wingNpcConfig = {
  'backend': const _WingNpcConfig('wizard', '아르카누스', ['java-spring']),
  'frontend': const _WingNpcConfig('mechanic', '코그윈', ['dart', 'flutter']),
  'database': const _WingNpcConfig('alchemist', '메르쿠리아', ['mysql']),
  'architecture': const _WingNpcConfig('architect', '모뉴멘타', ['msa']),
};
