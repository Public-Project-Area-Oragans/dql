import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/providers/game_providers.dart';

class HudOverlay extends ConsumerWidget {
  const HudOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scene = ref.watch(currentSceneProvider);
    final wingId = ref.watch(currentWingIdProvider);

    return Positioned(
      top: 8,
      right: 8,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.deepPurple.withValues(alpha: 0.8),
          border: Border.all(color: AppColors.gold.withValues(alpha: 0.5)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          scene == GameScene.centralHall
              ? '📍 중앙 홀'
              : '📍 ${wingId ?? ""}',
          style: const TextStyle(
            color: AppColors.gold,
            fontSize: 12,
          ),
        ),
      ),
    );
  }
}
