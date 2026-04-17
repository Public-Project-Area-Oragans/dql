import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/quest_model.dart';

part 'quest_providers.g.dart';

class DialogueState {
  final DialogueTree tree;
  final DialogueNode currentNode;
  final List<String> history;

  const DialogueState({
    required this.tree,
    required this.currentNode,
    required this.history,
  });

  bool get isEnd => currentNode.choices.isEmpty;
}

@riverpod
class ActiveDialogue extends _$ActiveDialogue {
  @override
  DialogueState? build() => null;

  void startDialogue(DialogueTree tree) {
    final startNode = tree.nodes.firstWhere((n) => n.id == tree.startNodeId);
    state = DialogueState(tree: tree, currentNode: startNode, history: []);
  }

  void selectChoice(DialogueChoice choice) {
    final current = state;
    if (current == null) return;
    final nextNode = current.tree.nodes.firstWhere(
      (n) => n.id == choice.nextNodeId,
      orElse: () => current.currentNode,
    );
    state = DialogueState(
      tree: current.tree,
      currentNode: nextNode,
      history: [...current.history, current.currentNode.id],
    );
  }

  void endDialogue() => state = null;
}
