import 'package:flutter_test/flutter_test.dart';
import 'package:dol/data/models/book_model.dart';

void main() {
  group('Chapter', () {
    test('fromJson creates valid Chapter', () {
      final json = {
        'id': 'java-step01',
        'title': 'Java란 무엇인가',
        'order': 1,
        'theory': {
          'sections': [
            {'title': 'JVM 개요', 'content': 'JVM은...'}
          ],
          'codeExamples': [
            {
              'language': 'java',
              'code': 'public class Main {}',
              'description': '기본 클래스'
            }
          ],
          'diagrams': <Map<String, dynamic>>[],
        },
        'simulator': {
          'type': 'codeStep',
          'steps': [
            {
              'instruction': '변수를 선언하세요',
              'code': 'int x = 10;',
              'expectedState': {'x': 10}
            }
          ],
          'completionCriteria': {'minStepsCompleted': 1},
        },
        'isCompleted': false,
      };

      final chapter = Chapter.fromJson(json);

      expect(chapter.id, 'java-step01');
      expect(chapter.title, 'Java란 무엇인가');
      expect(chapter.order, 1);
      expect(chapter.theory.sections.length, 1);
      expect(chapter.simulator.type, SimulatorType.codeStep);
      expect(chapter.isCompleted, false);
    });

    test('toJson produces correct keys', () {
      final chapter = Chapter(
        id: 'dart-step01',
        title: 'Dart 개요',
        order: 1,
        theory: TheoryContent(
          sections: [TheorySection(title: 'Dart란', content: 'Dart는...')],
          codeExamples: [],
          diagrams: [],
        ),
        simulator: SimulatorConfig(
          type: SimulatorType.codeStep,
          steps: [],
          completionCriteria: CompletionRule(minStepsCompleted: 0),
        ),
        isCompleted: false,
      );

      final json = chapter.toJson();

      expect(json['id'], 'dart-step01');
      expect(json['title'], 'Dart 개요');
      expect(json['order'], 1);
      expect(json['isCompleted'], false);
    });
  });

  group('Book', () {
    test('totalProgress calculates correctly', () {
      final book = Book(
        id: 'java-spring',
        title: 'Java & Spring',
        category: 'java',
        chapters: [
          _makeChapter('ch1', completed: true),
          _makeChapter('ch2', completed: true),
          _makeChapter('ch3', completed: false),
          _makeChapter('ch4', completed: false),
        ],
      );

      expect(book.totalProgress, 0.5);
    });

    test('totalProgress is 0 when no chapters', () {
      final book = Book(
        id: 'empty',
        title: 'Empty',
        category: 'test',
        chapters: [],
      );

      expect(book.totalProgress, 0.0);
    });
  });
}

Chapter _makeChapter(String id, {required bool completed}) {
  return Chapter(
    id: id,
    title: id,
    order: 0,
    theory: TheoryContent(sections: [], codeExamples: [], diagrams: []),
    simulator: SimulatorConfig(
      type: SimulatorType.codeStep,
      steps: [],
      completionCriteria: CompletionRule(minStepsCompleted: 0),
    ),
    isCompleted: completed,
  );
}
