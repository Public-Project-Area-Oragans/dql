import '../data/models/book_model.dart';

/// P0-5 NPC-5: RAG-lite 카테고리 컨텍스트 추출기.
///
/// 질문 → 해당 카테고리 book.json의 섹션 중 키워드 overlap 상위 N개를
/// 뽑아 Claude prompt의 `cachedContextChunks`로 주입.
///
/// - 정교한 벡터 임베딩은 P2 팀 버전으로 이연.
/// - 현재는 간단 substring overlap (한국어/영어 토큰 2자 이상).
class CategoryContextService {
  final Future<List<Book>> Function() _loadBooks;

  CategoryContextService({
    required Future<List<Book>> Function() loadBooks,
  }) : _loadBooks = loadBooks;

  /// 담당 [categories]와 [question]을 받아 상위 관련 섹션을 문자열 리스트로.
  /// 각 요소는 `[카테고리] 챕터 / 섹션\n본문(…N자 clip)` 형식.
  Future<List<String>> fetchRelevantChunks({
    required List<String> categories,
    required String question,
    int maxChunksPerCategory = 2,
    int maxCharsPerChunk = 500,
  }) async {
    if (categories.isEmpty) return const [];
    final tokens = _tokenize(question);
    if (tokens.isEmpty) return const [];

    final books = await _loadBooks();
    final candidates = <_ScoredChunk>[];
    for (final book in books) {
      if (!categories.contains(book.category)) continue;
      for (final chapter in book.chapters) {
        for (final section in chapter.theory.sections) {
          final score = _overlapScore(tokens, section.content);
          if (score <= 0) continue;
          candidates.add(_ScoredChunk(
            category: book.category,
            chapterTitle: chapter.title,
            sectionTitle: section.title,
            content: section.content,
            score: score,
          ));
        }
      }
    }

    // 카테고리별 상위 N.
    final byCategory = <String, List<_ScoredChunk>>{};
    for (final c in candidates) {
      byCategory.putIfAbsent(c.category, () => <_ScoredChunk>[]).add(c);
    }
    final picks = <_ScoredChunk>[];
    for (final entry in byCategory.entries) {
      final sorted = [...entry.value]
        ..sort((a, b) => b.score.compareTo(a.score));
      picks.addAll(sorted.take(maxChunksPerCategory));
    }
    // 정렬 안정화 (score desc).
    picks.sort((a, b) => b.score.compareTo(a.score));

    return picks
        .map((c) => _formatChunk(c, maxCharsPerChunk))
        .toList(growable: false);
  }

  String _formatChunk(_ScoredChunk c, int maxChars) {
    final body = c.content.length > maxChars
        ? '${c.content.substring(0, maxChars)}…'
        : c.content;
    return '[${c.category}] ${c.chapterTitle} / ${c.sectionTitle}\n$body';
  }

  /// 영문 단어 + 한글 2자 이상 음절 토큰화. 2자 미만 무시.
  List<String> _tokenize(String text) {
    final lowered = text.toLowerCase();
    final replaced = lowered.replaceAll(RegExp(r'[^\w가-힣\s]'), ' ');
    final parts = replaced.split(RegExp(r'\s+'));
    return parts.where((w) => w.length >= 2).toList(growable: false);
  }

  int _overlapScore(List<String> tokens, String text) {
    final lowered = text.toLowerCase();
    var score = 0;
    for (final t in tokens) {
      if (lowered.contains(t)) score++;
    }
    return score;
  }
}

class _ScoredChunk {
  final String category;
  final String chapterTitle;
  final String sectionTitle;
  final String content;
  final int score;

  const _ScoredChunk({
    required this.category,
    required this.chapterTitle,
    required this.sectionTitle,
    required this.content,
    required this.score,
  });
}
