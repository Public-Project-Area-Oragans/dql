import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../domain/providers/quest_providers.dart';

class DialogueOverlay extends ConsumerWidget {
  final VoidCallback onClose;

  const DialogueOverlay({super.key, required this.onClose});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dialogueState = ref.watch(activeDialogueProvider);

    if (dialogueState == null) {
      return const SizedBox.shrink();
    }

    final node = dialogueState.currentNode;

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.deepPurple.withValues(alpha: 0.95),
          border: Border.all(color: AppColors.gold, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              node.speakerName,
              style: const TextStyle(
                color: AppColors.brightGold,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              node.text,
              style: const TextStyle(
                color: AppColors.parchment,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            if (dialogueState.isEnd)
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    ref.read(activeDialogueProvider.notifier).endDialogue();
                    onClose();
                  },
                  child: const Text(
                    '[대화 종료]',
                    style: TextStyle(color: AppColors.gold),
                  ),
                ),
              )
            else
              ...node.choices.map((choice) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: InkWell(
                      onTap: () {
                        ref
                            .read(activeDialogueProvider.notifier)
                            .selectChoice(choice);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: AppColors.gold.withValues(alpha: 0.5),
                          ),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '▸ ${choice.text}',
                          style: const TextStyle(
                            color: AppColors.parchment,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  )),
          ],
        ),
      ),
    );
  }
}
