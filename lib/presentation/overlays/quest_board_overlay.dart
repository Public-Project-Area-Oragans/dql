import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/book_model.dart';
import '../../domain/providers/content_providers.dart';
import '../../domain/providers/game_providers.dart';

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

    return Center(
      child: Container(
        width: 500,
        height: 400,
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
                  if (books.isEmpty) {
                    return Center(
                      child: Text(
                        filterCategory == null
                            ? '콘텐츠가 빌드되지 않았습니다.\n'
                                'dart run tools/content_builder.dart <docs-source>'
                            : '$filterCategory 카테고리에 책이 없습니다.',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: AppColors.parchment),
                      ),
                    );
                  }
                  return ListView.builder(
                        padding: const EdgeInsets.all(8),
                        itemCount: books.length,
                        itemBuilder: (context, i) {
                          final book = books[i];
                          return ExpansionTile(
                            title: Text(
                              book.title,
                              style: const TextStyle(color: AppColors.parchment),
                            ),
                            subtitle: Text(
                              '${(book.totalProgress * 100).toInt()}% 완료',
                              style: TextStyle(
                                color: AppColors.gold.withValues(alpha: 0.7),
                                fontSize: 12,
                              ),
                            ),
                            children: book.chapters.map((ch) {
                              return ListTile(
                                title: Text(
                                  ch.title,
                                  style: TextStyle(
                                    color: ch.isCompleted
                                        ? AppColors.steamGreen
                                        : AppColors.parchment,
                                    fontSize: 13,
                                  ),
                                ),
                                leading: Icon(
                                  ch.isCompleted
                                      ? Icons.check_circle
                                      : Icons.circle_outlined,
                                  color: ch.isCompleted
                                      ? AppColors.steamGreen
                                      : AppColors.gold,
                                  size: 18,
                                ),
                                onTap: () => onChapterSelected(book.id, ch.id),
                              );
                            }).toList(),
                          );
                        },
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
