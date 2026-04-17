import 'package:flutter_test/flutter_test.dart';
import 'package:dol/services/gist_service.dart';

void main() {
  group('GistService', () {
    test('formatProgressToGistContent produces valid JSON', () {
      final content = GistService.formatProgressToJson({
        'playerId': 'test-id',
        'completedChapters': ['ch1', 'ch2'],
        'completedQuests': ['q1'],
        'currentWing': 'backend',
        'lastSavedAt': '2026-04-17T00:00:00.000',
      });

      expect(content, contains('test-id'));
      expect(content, contains('ch1'));
    });
  });
}
