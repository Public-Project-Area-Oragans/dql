import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/constants/app_colors.dart';
import '../../data/models/telemetry_event.dart';
import '../../domain/providers/telemetry_providers.dart';

/// Phase 2 Task 2-5 뷰어 — 대시보드가 아닌 raw 리스트.
///
/// 주간 회고 시 `/debug/telemetry` 접근 → chapterId별 start/complete
/// 타임스탬프를 눈으로 훑어 "재시도 횟수", "완료 소요 시간" 집계.
class DebugTelemetryScreen extends ConsumerWidget {
  const DebugTelemetryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(telemetryServiceProvider);
    final events = service.readAll();

    return Scaffold(
      backgroundColor: AppColors.darkWalnut,
      appBar: AppBar(
        backgroundColor: AppColors.deepPurple,
        title: const Text(
          '🧪 Telemetry (Phase 2 Task 2-5)',
          style: TextStyle(color: AppColors.brightGold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => context.go('/game'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppColors.gold),
            tooltip: '전체 삭제',
            onPressed: () async {
              await service.clear();
              // build가 다시 실행되게 ref.invalidate 대신 provider 재구독
              // (현 컴포넌트 레벨 rebuild).
              (context as Element).markNeedsBuild();
            },
          ),
        ],
      ),
      body: events.isEmpty
          ? const Center(
              child: Text(
                '수집된 이벤트가 없습니다.',
                style: TextStyle(color: AppColors.parchment),
              ),
            )
          : _buildList(events),
    );
  }

  Widget _buildList(List<TelemetryEvent> events) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: events.length,
      separatorBuilder: (_, _) => const Divider(
        color: AppColors.gold,
        height: 1,
        thickness: 0.3,
      ),
      itemBuilder: (context, index) {
        final e = events[index];
        return ListTile(
          dense: true,
          title: Text(
            '${e.type}  ·  ${e.chapterId}',
            style: const TextStyle(
              color: AppColors.parchment,
              fontFamily: 'JetBrainsMono',
              fontSize: 13,
            ),
          ),
          subtitle: Text(
            e.at.toIso8601String(),
            style: const TextStyle(
              color: AppColors.gold,
              fontFamily: 'JetBrainsMono',
              fontSize: 11,
            ),
          ),
        );
      },
    );
  }
}
