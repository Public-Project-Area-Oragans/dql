import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/book_model.dart';
import '../../data/models/telemetry_event.dart';
import '../../domain/providers/content_providers.dart';
import '../../domain/providers/telemetry_providers.dart';
import '../simulators/code_step_simulator.dart';
import '../simulators/structure_assembly_simulator.dart';
import '../widgets/steampunk_button.dart';
import '../widgets/theory_card.dart';

class BookReaderScreen extends ConsumerStatefulWidget {
  final String bookId;
  final String chapterId;

  const BookReaderScreen({
    super.key,
    required this.bookId,
    required this.chapterId,
  });

  @override
  ConsumerState<BookReaderScreen> createState() => _BookReaderScreenState();
}

class _BookReaderScreenState extends ConsumerState<BookReaderScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    // Phase 2 Task 2-5: 챕터 진입 시점 계측.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(telemetryServiceProvider).append(
            TelemetryEvent(
              type: 'chapter_start',
              chapterId: widget.chapterId,
              at: DateTime.now(),
            ),
          );
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _recordComplete() {
    ref.read(telemetryServiceProvider).append(
          TelemetryEvent(
            type: 'chapter_complete',
            chapterId: widget.chapterId,
            at: DateTime.now(),
          ),
        );
  }

  @override
  Widget build(BuildContext context) {
    final book = ref.watch(bookByIdProvider(widget.bookId));

    if (book == null) {
      return Scaffold(
        backgroundColor: AppColors.darkWalnut,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '책을 찾을 수 없습니다',
                style: TextStyle(color: AppColors.parchment),
              ),
              const SizedBox(height: 16),
              SteampunkButton(
                label: '돌아가기',
                onPressed: () => context.go('/game'),
              ),
            ],
          ),
        ),
      );
    }

    final chapter =
        book.chapters.where((c) => c.id == widget.chapterId).firstOrNull;

    if (chapter == null) {
      return Scaffold(
        backgroundColor: AppColors.darkWalnut,
        body: Center(
          child: Text(
            '챕터를 찾을 수 없습니다: ${widget.chapterId}',
            style: const TextStyle(color: AppColors.parchment),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.darkWalnut,
      appBar: AppBar(
        backgroundColor: AppColors.deepPurple,
        title: Text(
          chapter.title,
          style: const TextStyle(color: AppColors.brightGold, fontSize: 16),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.gold),
          onPressed: () => context.go('/game'),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.gold,
          labelColor: AppColors.brightGold,
          unselectedLabelColor: AppColors.parchment,
          tabs: const [
            Tab(text: '📖 이론'),
            Tab(text: '⚡ 시뮬레이터'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: TheoryCard(theory: chapter.theory),
          ),
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: switch (chapter.simulator) {
              CodeStepConfig(:final steps) when steps.isNotEmpty =>
                CodeStepSimulator(
                  config: chapter.simulator as CodeStepConfig,
                  onComplete: () {
                    _recordComplete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('시뮬레이터 완료!'),
                        backgroundColor: AppColors.steamGreen,
                      ),
                    );
                  },
                ),
              StructureAssemblyConfig() => StructureAssemblySimulator(
                  config: chapter.simulator as StructureAssemblyConfig,
                  onComplete: () {
                    _recordComplete();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('구조 조립 완료!'),
                        backgroundColor: AppColors.steamGreen,
                      ),
                    );
                  },
                ),
              _ => const Center(
                  child: Text(
                    '이 챕터의 시뮬레이터는 준비 중입니다',
                    style: TextStyle(color: AppColors.parchment),
                  ),
                ),
            },
          ),
        ],
      ),
    );
  }
}
