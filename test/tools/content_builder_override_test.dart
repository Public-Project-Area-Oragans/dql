import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

// tools/ 스크립트의 top-level 함수를 상대 경로로 직접 import.
// parseMdToChapter는 content_builder_test.dart에 중복 정의되어 있으나,
// override 로직은 File 시스템 접근이 필요해 원본 함수를 그대로 사용해야 한다.
import '../../tools/content_builder.dart';

void main() {
  group('applyOverride (content_builder)', () {
    late Directory tempDir;
    late String originalCwd;

    setUp(() {
      originalCwd = Directory.current.path;
      tempDir = Directory.systemTemp.createTempSync('dol_override_test_');
      Directory.current = tempDir.path;
    });

    tearDown(() {
      Directory.current = originalCwd;
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    Map<String, dynamic> _defaultChapter(String id) {
      return <String, dynamic>{
        'id': id,
        'title': 'Sample',
        'order': 1,
        'theory': {
          'sections': <Map<String, dynamic>>[],
          'codeExamples': <Map<String, dynamic>>[],
          'diagrams': <Map<String, dynamic>>[],
        },
        'simulator': <String, dynamic>{
          'type': 'codeStep',
          'steps': <Map<String, dynamic>>[],
          'completionCriteria': {'minStepsCompleted': 0},
        },
        'isCompleted': false,
      };
    }

    void _writeOverride(
        String categoryId, String chapterId, String jsonContent) {
      final dir = Directory('content/overrides/$categoryId');
      dir.createSync(recursive: true);
      File('${dir.path}/$chapterId.json').writeAsStringSync(jsonContent);
    }

    test('override 파일이 없으면 기본 simulator 유지', () {
      final chapter = _defaultChapter('msa-phase4-step1-api-gateway');

      final result = applyOverride(
        chapter,
        'msa',
        'msa-phase4-step1-api-gateway',
      );

      expect(result['simulator']['type'], 'codeStep',
          reason: 'override 부재 시 codeStep 기본값이 유지되어야 함');
      expect(result['simulator']['steps'], isEmpty);
    });

    test('override 파일의 simulator 필드로 교체', () {
      _writeOverride(
        'msa',
        'msa-phase4-step2-service-discovery',
        '''
        {
          "chapterId": "msa-phase4-step2-service-discovery",
          "simulator": {
            "type": "structureAssembly",
            "gridSize": {"cols": 5, "rows": 5},
            "palette": [{"id": "x", "label": "X", "spriteKey": "x"}],
            "solution": {"nodes": [], "edges": []},
            "partialFeedback": {
              "missingNodes": "m", "missingEdges": "m", "extraEdges": "e"
            }
          }
        }
        ''',
      );

      final chapter = _defaultChapter('msa-phase4-step2-service-discovery');

      final result = applyOverride(
        chapter,
        'msa',
        'msa-phase4-step2-service-discovery',
      );

      expect(result['simulator']['type'], 'structureAssembly');
      expect(result['simulator']['gridSize'], {'cols': 5, 'rows': 5});
      expect(result['simulator']['palette'], hasLength(1));
    });

    test('override JSON 파싱 실패 시 빌드 중단 (Exception throw)', () {
      _writeOverride(
        'msa',
        'msa-broken-chapter',
        '{ this is not valid json ]',
      );

      final chapter = _defaultChapter('msa-broken-chapter');

      expect(
        () => applyOverride(chapter, 'msa', 'msa-broken-chapter'),
        throwsA(isA<Exception>()),
        reason: 'JSON 파싱 실패는 CI 빌드를 중단시켜야 함',
      );
    });

    test('override 파일 존재하지만 simulator 필드 없으면 기본값 유지', () {
      _writeOverride(
        'msa',
        'msa-only-metadata',
        '{"chapterId": "msa-only-metadata", "note": "simulator 키 없음"}',
      );

      final chapter = _defaultChapter('msa-only-metadata');

      final result = applyOverride(chapter, 'msa', 'msa-only-metadata');

      expect(result['simulator']['type'], 'codeStep',
          reason: 'simulator 키가 없으면 기본값이 그대로 유지됨');
    });
  });
}
