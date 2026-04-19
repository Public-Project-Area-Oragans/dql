import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/book_model.dart';
import '../../data/models/quest_model.dart';
import '../../domain/providers/content_providers.dart';
import '../../domain/providers/game_providers.dart';
import '../../domain/providers/wing_quests_providers.dart';

class QuestBoardOverlay extends ConsumerWidget {
  final VoidCallback onClose;
  final void Function(String bookId, String chapterId) onChapterSelected;

  const QuestBoardOverlay({
    super.key,
    required this.onClose,
    required this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final booksAsync = ref.watch(allBooksProvider);
    // NPC-1: 분관 책장에서 열렸으면 해당 카테고리로 필터링.
    final filterCategory = ref.watch(questBoardFilterCategoryProvider);
    // NPC-6: 현재 분관의 샘플 퀘스트를 상단 섹션으로 표시.
    final wingId = ref.watch(currentWingIdProvider) ?? '';
    final wingQuests = ref.watch(wingQuestsProvider(wingId));

    return Center(
      child: Container(
        width: 500,
        height: 460,
        decoration: BoxDecoration(
          color: AppColors.deepPurple,
          border: Border.all(color: AppColors.gold, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.gold)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '📋 퀘스트 게시판',
                    style: TextStyle(
                      color: AppColors.brightGold,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, color: AppColors.gold),
                    onPressed: onClose,
                  ),
                ],
              ),
            ),
            Expanded(
              child: booksAsync.when(
                data: (rawBooks) {
                  final books = filterCategory == null
                      ? rawBooks
                      : rawBooks
                          .where((Book b) => b.category == filterCategory)
                          .toList();
                  return ListView(
                    padding: const EdgeInsets.all(8),
                    children: [
                      if (wingQuests.isNotEmpty) ...[
                        const Padding(
                          padding: EdgeInsets.fromLTRB(8, 4, 8, 6),
                          child: Text(
                            '✦ 이번 분관 퀘스트',
                            style: TextStyle(
                              color: AppColors.brightGold,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        for (final q in wingQuests) _QuestTile(quest: q),
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 8),
                          child: Divider(color: AppColors.gold, height: 1),
                        ),
                      ],
                      if (books.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            filterCategory == null
                                ? '콘텐츠가 빌드되지 않았습니다.\n'
                                    'dart run tools/content_builder.dart <docs-source>'
                                : '$filterCategory 카테고리에 책이 없습니다.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppColors.parchment),
                          ),
                        )
                      else if (filterCategory != null)
                        // fix-6: 분관 책장에서 열린 경우 — 해당 분관의 모든
                        // 책의 모든 챕터를 책 타이틀 헤더 없이 flat 으로
                        // 노출. 책과 책 사이에는 얇은 gold alpha divider 만.
                        ..._buildFlatChapters(books, onChapterSelected)
                      else
                        for (final book in books)
                          // 중앙 홀 경로: 5 카테고리 동시 노출이라 세로 길이
                          // 제어 위해 ExpansionTile 유지.
                          ExpansionTile(
                            title: Text(
                              book.title,
                              style: const TextStyle(
                                  color: AppColors.parchment),
                            ),
                            subtitle: Text(
                              '${(book.totalProgress * 100).toInt()}% 완료',
                              style: TextStyle(
                                color:
                                    AppColors.gold.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                            children: book.chapters
                                .map((ch) => _ChapterRow(
                                      book: book,
                                      chapter: ch,
                                      onChapterSelected: onChapterSelected,
                                    ))
                                .toList(),
                          ),
                    ],
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: AppColors.gold),
                ),
                error: (e, _) => Center(
                  child: Text(
                    '콘텐츠 로드 실패: $e',
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuestTile extends StatelessWidget {
  final Quest quest;

  const _QuestTile({required this.quest});

  @override
  Widget build(BuildContext context) {
    final done = quest.status == QuestStatus.completed;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.darkWalnut,
        border: Border.all(
          color: done
              ? AppColors.steamGreen
              : AppColors.gold.withValues(alpha: 0.6),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                done ? Icons.check_circle : Icons.flag_outlined,
                size: 16,
                color: done ? AppColors.steamGreen : AppColors.brightGold,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  quest.title,
                  style: TextStyle(
                    color:
                        done ? AppColors.steamGreen : AppColors.brightGold,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '+${quest.reward.xp} XP',
                style: const TextStyle(
                  color: AppColors.gold,
                  fontSize: 11,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            quest.description,
            style: const TextStyle(
              color: AppColors.parchment,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          if (quest.requiredChapters.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              '필요 챕터: ${quest.requiredChapters.join(", ")}',
              style: TextStyle(
                color: AppColors.parchment.withValues(alpha: 0.6),
                fontSize: 11,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// fix-6: 분관 책장에서 열린 QuestBoard 의 챕터 평탄 렌더링.
///
/// 입력된 책 리스트의 모든 챕터를 **책 타이틀 헤더 없이** 순서대로 flat 으로
/// 쌓고, 책 경계에 얇은 gold alpha divider 한 줄만 삽입한다. 사용자의
/// 2026-04-19 요구사항: "언어(책) 에 묶여서 전체가 한눈에 안 보임" → 책
/// 타이틀·이모지·진행률 헤더 제거. 단 책 구분감은 divider 로 유지.
List<Widget> _buildFlatChapters(
  List<Book> books,
  void Function(String bookId, String chapterId) onChapterSelected,
) {
  final result = <Widget>[];
  for (var i = 0; i < books.length; i++) {
    final book = books[i];
    for (final ch in book.chapters) {
      result.add(_ChapterRow(
        book: book,
        chapter: ch,
        onChapterSelected: onChapterSelected,
      ));
    }
    if (i < books.length - 1) {
      result.add(Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        child: Divider(
          height: 1,
          thickness: 1,
          color: AppColors.gold.withValues(alpha: 0.25),
        ),
      ));
    }
  }
  return result;
}

class _ChapterRow extends StatelessWidget {
  final Book book;
  final Chapter chapter;
  final void Function(String bookId, String chapterId) onChapterSelected;

  const _ChapterRow({
    required this.book,
    required this.chapter,
    required this.onChapterSelected,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      visualDensity: VisualDensity.compact,
      title: Text(
        chapter.title,
        style: TextStyle(
          color: chapter.isCompleted
              ? AppColors.steamGreen
              : AppColors.parchment,
          fontSize: 13,
        ),
      ),
      leading: Icon(
        chapter.isCompleted ? Icons.check_circle : Icons.circle_outlined,
        color:
            chapter.isCompleted ? AppColors.steamGreen : AppColors.gold,
        size: 18,
      ),
      onTap: () => onChapterSelected(book.id, chapter.id),
    );
  }
}
