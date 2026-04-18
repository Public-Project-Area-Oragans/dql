import 'dart:io';

import 'package:dol/data/models/telemetry_event.dart';
import 'package:dol/services/telemetry_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

void main() {
  group('TelemetryService', () {
    late Directory tempDir;
    late TelemetryService service;

    setUp(() async {
      tempDir = Directory.systemTemp.createTempSync('dol_telemetry_test_');
      Hive.init(tempDir.path);
      service = TelemetryService();
      await service.init();
    });

    tearDown(() async {
      await Hive.close();
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('초기 상태는 빈 리스트', () {
      expect(service.readAll(), isEmpty);
    });

    test('append 2회 → readAll이 삽입 순서대로 반환', () async {
      final t1 = DateTime.utc(2026, 4, 18, 10, 0, 0);
      final t2 = DateTime.utc(2026, 4, 18, 10, 5, 0);

      await service.append(TelemetryEvent(
        type: 'chapter_start',
        chapterId: 'msa-step1',
        at: t1,
      ));
      await service.append(TelemetryEvent(
        type: 'chapter_complete',
        chapterId: 'msa-step1',
        at: t2,
      ));

      final events = service.readAll();
      expect(events, hasLength(2));
      expect(events[0].type, 'chapter_start');
      expect(events[0].at.toUtc(), t1);
      expect(events[1].type, 'chapter_complete');
      expect(events[1].at.toUtc(), t2);
    });

    test('clear 후 readAll은 빈 리스트', () async {
      await service.append(TelemetryEvent(
        type: 'chapter_start',
        chapterId: 'msa-step1',
        at: DateTime.now(),
      ));
      expect(service.readAll(), hasLength(1));

      await service.clear();
      expect(service.readAll(), isEmpty);
    });
  });
}
