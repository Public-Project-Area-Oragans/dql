import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/quest_model.dart';
import '../../services/wing_quests.dart';
import 'progress_providers.dart';

part 'wing_quests_providers.g.dart';

/// P0-5 NPC-6: 분관별 퀘스트 목록을 PlayerProgress.completedChapters 기준으로
/// 상태 계산하여 반환. wingId가 빈 문자열이면 빈 목록.
@riverpod
List<Quest> wingQuests(Ref ref, String wingId) {
  if (wingId.isEmpty) return const [];
  final progress = ref.watch(progressProvider);
  return WingQuests.withStatus(wingId, progress.completedChapters);
}
