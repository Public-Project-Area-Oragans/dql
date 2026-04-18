import 'package:dol/data/models/book_model.dart';
import 'package:dol/services/category_context_service.dart';
import 'package:flutter_test/flutter_test.dart';

/// P0-5 NPC-5 — CategoryContextService (RAG-lite) 검증.
void main() {
  Book _book({
    required String id,
    required String category,
    required List<(String chapter, List<(String section, String content)>)>
        sections,
  }) {
    final chapters = sections
        .map((c) => Chapter(
              id: '$id-${c.$1}',
              title: c.$1,
              order: 1,
              theory: TheoryContent(
                sections: c.$2
                    .map((s) => TheorySection(title: s.$1, content: s.$2))
                    .toList(),
                codeExamples: const [],
                diagrams: const [],
              ),
              simulator: const SimulatorConfig.codeStep(
                steps: [],
                completionCriteria: CompletionRule(minStepsCompleted: 0),
              ),
            ))
        .toList();
    return Book(
      id: id,
      title: id,
      category: category,
      chapters: chapters,
    );
  }

  CategoryContextService serviceWith(List<Book> books) {
    return CategoryContextService(loadBooks: () async => books);
  }

  group('fetchRelevantChunks', () {
    test('질문에 해당 카테고리 키워드 있으면 관련 섹션 반환', () async {
      final books = [
        _book(
          id: 'java-spring',
          category: 'java-spring',
          sections: [
            (
              'Bean Lifecycle',
              [
                ('초기화 단계', 'Bean은 생성 후 초기화 콜백이 호출된다'),
                ('소멸 단계', 'Bean은 소멸 시 destroy 콜백이 호출된다'),
              ],
            ),
          ],
        ),
      ];
      final chunks = await serviceWith(books).fetchRelevantChunks(
        categories: ['java-spring'],
        question: 'Spring Bean의 초기화 순서는?',
      );
      expect(chunks, isNotEmpty);
      expect(chunks.first, contains('Bean Lifecycle'));
      expect(chunks.first, contains('초기화 단계'));
    });

    test('카테고리 일치하는 책만 scan (다른 카테고리는 무시)', () async {
      final books = [
        _book(
          id: 'java-spring',
          category: 'java-spring',
          sections: [
            ('A', [('s', 'Spring 관련 내용')])
          ],
        ),
        _book(
          id: 'mysql',
          category: 'mysql',
          sections: [
            ('B', [('s', 'MySQL 인덱스 관련 내용')])
          ],
        ),
      ];
      final chunks = await serviceWith(books).fetchRelevantChunks(
        categories: ['java-spring'],
        question: 'MySQL 인덱스',
      );
      // java-spring에 관련 내용 없음 → 빈 결과.
      // (질문 키워드가 mysql 책과만 overlap 있지만 카테고리 필터로 제외)
      expect(chunks, isEmpty);
    });

    test('overlap score 높은 섹션 우선', () async {
      final books = [
        _book(
          id: 'java-spring',
          category: 'java-spring',
          sections: [
            (
              'ch',
              [
                ('하나 언급', 'transaction'),
                ('여러 번 언급',
                    'transaction isolation transaction propagation transaction rollback'),
              ],
            )
          ],
        ),
      ];
      final chunks = await serviceWith(books).fetchRelevantChunks(
        categories: ['java-spring'],
        question: 'transaction isolation',
        maxChunksPerCategory: 2,
      );
      expect(chunks, hasLength(2));
      expect(chunks.first, contains('여러 번 언급'));
    });

    test('empty categories → empty result', () async {
      final chunks = await serviceWith([]).fetchRelevantChunks(
        categories: [],
        question: '아무거나',
      );
      expect(chunks, isEmpty);
    });

    test('짧은 토큰(1자) 제거 + score 0인 섹션 제외', () async {
      final books = [
        _book(
          id: 'msa',
          category: 'msa',
          sections: [
            ('ch', [('s', '완전히 무관한 내용')])
          ],
        ),
      ];
      final chunks = await serviceWith(books).fetchRelevantChunks(
        categories: ['msa'],
        question: 'a b c',
      );
      expect(chunks, isEmpty);
    });

    test('maxCharsPerChunk로 clip', () async {
      final longContent = 'spring ${'x' * 700}';
      final books = [
        _book(
          id: 'java-spring',
          category: 'java-spring',
          sections: [
            ('ch', [('long', longContent)])
          ],
        ),
      ];
      final chunks = await serviceWith(books).fetchRelevantChunks(
        categories: ['java-spring'],
        question: 'spring',
        maxCharsPerChunk: 100,
      );
      expect(chunks.first, endsWith('…'));
      // 형식: [category] chapter / section\n본문(…)
      // 본문 부분 길이 <= 100 + 1('…')
      final body = chunks.first.split('\n').last;
      expect(body.length, lessThanOrEqualTo(101));
    });
  });
}
