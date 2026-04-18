import 'dart:convert';
import 'dart:io';

import 'package:dol/data/models/book_model.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Characterization: 실제 프로덕션 book.json 로드 (sealed union 리팩터 회귀 가드)', () {
    const categories = ['java-spring', 'dart', 'flutter', 'mysql', 'msa'];
    const expectedChapterCounts = {
      'java-spring': 48,
      'dart': 24,
      'flutter': 32,
      'mysql': 31,
      'msa': 46,
    };

    for (final category in categories) {
      test('$category book.json 파싱 + 챕터 개수 일치', () {
        final file = File('content/books/$category/book.json');
        expect(file.existsSync(), isTrue,
            reason: '$category book.json 파일 존재해야 함');

        final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final book = Book.fromJson(json);

        expect(book.id, category);
        expect(book.chapters.length, expectedChapterCounts[category],
            reason: '$category 챕터 개수가 예상과 다름');
      });
    }

    // Phase 2 Task 2-1: 대조군 설계에 따라 MSA Phase 4 3챕터 중
    //  - step1-api-gateway는 대조군(시뮬레이터 없음, CodeStepConfig 유지)
    //  - step2-service-discovery, step4-resilience-patterns는 StructureAssemblyConfig
    const structureAssemblyChapters = {
      'msa-phase4-step2-service-discovery',
      'msa-phase4-step4-resilience-patterns',
    };
    const controlGroupChapter = 'msa-phase4-step1-api-gateway';

    test('override 비적용 챕터는 CodeStepConfig (Phase 1 하위호환)', () {
      for (final category in categories) {
        final file = File('content/books/$category/book.json');
        if (!file.existsSync()) continue;
        final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
        final book = Book.fromJson(json);

        for (final chapter in book.chapters) {
          if (structureAssemblyChapters.contains(chapter.id)) continue;
          expect(chapter.simulator, isA<CodeStepConfig>(),
              reason: '${chapter.id}의 simulator가 CodeStepConfig가 아님');
        }
      }
    });

    test('대조군 챕터($controlGroupChapter)는 CodeStepConfig 유지', () {
      final file = File('content/books/msa/book.json');
      if (!file.existsSync()) {
        markTestSkipped('msa book.json 없음');
        return;
      }
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final book = Book.fromJson(json);

      final chapter = book.chapters
          .firstWhere((c) => c.id == controlGroupChapter, orElse: () {
        fail('대조군 챕터 $controlGroupChapter 가 msa book.json에 없음');
      });
      expect(chapter.simulator, isA<CodeStepConfig>(),
          reason:
              '$controlGroupChapter는 대조군이므로 override 미적용 상태여야 함 (CodeStepConfig)');
    });

    test('override 적용된 2 MSA 챕터는 StructureAssemblyConfig', () {
      final file = File('content/books/msa/book.json');
      if (!file.existsSync()) {
        markTestSkipped('msa book.json 없음');
        return;
      }
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final book = Book.fromJson(json);

      for (final id in structureAssemblyChapters) {
        final chapter =
            book.chapters.firstWhere((c) => c.id == id, orElse: () {
          fail('챕터 $id 가 msa book.json에 없음');
        });
        expect(chapter.simulator, isA<StructureAssemblyConfig>(),
            reason: '$id가 StructureAssemblyConfig 아님 — override merge 실패?');
      }
    });

    test('Chapter.toJson round-trip 안정성 (jsonEncode 경유)', () {
      final file = File('content/books/msa/book.json');
      if (!file.existsSync()) {
        markTestSkipped('msa book.json 없음');
        return;
      }
      final json = jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;
      final book = Book.fromJson(json);

      // 첫 챕터로 round-trip. freezed toJson은 nested 객체를 그대로 두므로
      // 실제 직렬화 경로(jsonEncode → jsonDecode)를 재현해야 정확함.
      final firstChapter = book.chapters.first;
      final encoded = jsonEncode(firstChapter.toJson());
      final roundTrip = Chapter.fromJson(
        jsonDecode(encoded) as Map<String, dynamic>,
      );

      expect(roundTrip.id, firstChapter.id);
      expect(roundTrip.title, firstChapter.title);
      expect(roundTrip.simulator.runtimeType,
          firstChapter.simulator.runtimeType);
      expect(roundTrip.theory.sections.length,
          firstChapter.theory.sections.length);
    });
  });
}
