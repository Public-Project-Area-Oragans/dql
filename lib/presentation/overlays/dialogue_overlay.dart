import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/assets/asset_ids.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/qa_message.dart';
import '../../domain/providers/npc_qa_providers.dart';
import '../../domain/providers/quest_providers.dart';
import '../widgets/pixel_nine_slice.dart';

/// P0-5 NPC-4 + fix-5: DialogueOverlay 에 "대화" / "질문" 두 탭.
/// - 대화: 기존 DialogueTree 스크립트 (Phase 1 구현 유지).
/// - 질문: Claude API 기반 Q&A. `ActiveNpcId` 가 null 이어도 탭바는 상시
///   노출하고, 본문에서 NPC 미선택 안내를 한다 (2026-04-19 실사용 요구).
class DialogueOverlay extends ConsumerStatefulWidget {
  final VoidCallback onClose;

  const DialogueOverlay({super.key, required this.onClose});

  @override
  ConsumerState<DialogueOverlay> createState() => _DialogueOverlayState();
}

class _DialogueOverlayState extends ConsumerState<DialogueOverlay> {
  int _tab = 0; // 0 = 대화, 1 = 질문

  @override
  Widget build(BuildContext context) {
    final dialogueState = ref.watch(activeDialogueProvider);
    final npcId = ref.watch(activeNpcIdProvider);

    if (dialogueState == null) {
      return const SizedBox.shrink();
    }

    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: PixelNineSlice(
          assetName: UiAssets.frameDialog,
          child: ColoredBox(
            // art-2: frame 내부 가독성 — 반투명 deepPurple 채움 유지.
            color: AppColors.deepPurple,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // fix-5: 탭바 상시 노출.
                _tabBar(),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: _tab == 0
                      ? _DialogueBody(
                          dialogueState: dialogueState,
                          onEnd: () {
                            ref
                                .read(activeDialogueProvider.notifier)
                                .endDialogue();
                            ref.read(activeNpcIdProvider.notifier).clear();
                            widget.onClose();
                          },
                        )
                      : (npcId != null
                          ? _QaBody(npcId: npcId)
                          : const _QaEmptyState()),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _tabBar() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: AppColors.gold.withValues(alpha: 0.5),
          ),
        ),
      ),
      child: Row(
        children: [
          _tabButton('💬 대화', 0),
          _tabButton('❓ 질문', 1),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index) {
    final selected = _tab == index;
    return InkWell(
      onTap: () => setState(() => _tab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.brightGold : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? AppColors.brightGold : AppColors.parchment,
            fontSize: 13,
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }
}

/// 기존 대화 스크립트 UI. Phase 1 동작 유지.
class _DialogueBody extends ConsumerWidget {
  final DialogueState dialogueState;
  final VoidCallback onEnd;

  const _DialogueBody({
    required this.dialogueState,
    required this.onEnd,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final node = dialogueState.currentNode;
    return Column(
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
              onPressed: onEnd,
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
    );
  }
}

/// Q&A 탭 UI. NPC별 Claude 세션을 사용.
class _QaBody extends ConsumerStatefulWidget {
  final String npcId;

  const _QaBody({required this.npcId});

  @override
  ConsumerState<_QaBody> createState() => _QaBodyState();
}

class _QaBodyState extends ConsumerState<_QaBody> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _controller.text;
    if (text.trim().isEmpty) return;
    _controller.clear();
    await ref.read(npcQaSessionProvider(widget.npcId).notifier).ask(text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(npcQaSessionProvider(widget.npcId));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (state.messages.isEmpty &&
            state.streamingAssistant == null &&
            state.error == null)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Text(
              '담당 분야 안에서 질문을 던져보라. 답변은 이 사서의 전문 범위 안에서만.',
              style: TextStyle(color: AppColors.parchment, fontSize: 13),
            ),
          ),
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 260),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final m in state.messages) _bubble(m),
                if (state.streamingAssistant != null)
                  _bubble(QaMessage(
                    role: QaRole.assistant,
                    content: state.streamingAssistant!,
                    at: DateTime.now(),
                  )),
              ],
            ),
          ),
        ),
        if (state.error != null) ...[
          const SizedBox(height: 8),
          Text(
            state.error!,
            style: const TextStyle(color: Colors.redAccent, fontSize: 12),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                enabled: !state.loading,
                maxLines: 3,
                minLines: 1,
                style: const TextStyle(
                  color: AppColors.parchment,
                  fontSize: 13,
                ),
                decoration: InputDecoration(
                  hintText: '질문을 입력하라',
                  hintStyle: TextStyle(
                    color: AppColors.parchment.withValues(alpha: 0.4),
                  ),
                  filled: true,
                  fillColor: AppColors.darkWalnut,
                  border: OutlineInputBorder(
                    borderSide:
                        BorderSide(color: AppColors.gold.withValues(alpha: 0.5)),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: state.loading ? null : _send,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.gold,
                foregroundColor: AppColors.darkWalnut,
              ),
              child: Text(state.loading ? '…' : '전송'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _bubble(QaMessage m) {
    final isUser = m.role == QaRole.user;
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        constraints: const BoxConstraints(maxWidth: 480),
        decoration: BoxDecoration(
          color: isUser
              ? AppColors.magicPurple.withValues(alpha: 0.3)
              : AppColors.darkWalnut,
          border: Border.all(
            color: isUser
                ? AppColors.magicPurple
                : AppColors.gold.withValues(alpha: 0.6),
          ),
          borderRadius: BorderRadius.circular(4),
        ),
        child: SelectableText(
          m.content,
          style: const TextStyle(
            color: AppColors.parchment,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

/// fix-5: NPC 가 선택되지 않은 상태에서 ❓ 질문 탭을 선택했을 때의 placeholder.
/// 사용자가 Q&A 기능 자체를 인지할 수 있고, 다음 행동을 안내한다.
class _QaEmptyState extends StatelessWidget {
  const _QaEmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 24),
      child: Text(
        '분관의 사서에게 먼저 말을 걸어라. 사서가 곁에 있을 때에만 '
        '그의 전공 분야에 대해 질문할 수 있다.',
        style: TextStyle(
          color: AppColors.parchment,
          fontSize: 13,
          height: 1.5,
        ),
      ),
    );
  }
}
