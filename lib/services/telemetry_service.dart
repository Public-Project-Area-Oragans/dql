import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';

import '../data/models/telemetry_event.dart';

/// 로컬 Hive Box 기반 계측 이벤트 저장소.
///
/// Phase 2 Task 2-5: 일주일 실사용 비교 실험용 최소 수집기.
/// `Box<String>` 하나에 JSON 리스트로 append-only 저장 → `/debug/telemetry`로 조회.
class TelemetryService {
  static const _boxName = 'telemetry';
  static const _key = 'events';

  Future<void> init() async {
    if (!Hive.isBoxOpen(_boxName)) {
      await Hive.openBox<String>(_boxName);
    }
  }

  /// Hive box가 아직 열려 있지 않으면 null. test 환경에서 provider 오버라이드
  /// 없이 프로바이더가 접근될 때 HiveError 대신 no-op으로 동작하도록 하는
  /// 방어층.
  Box<String>? get _box =>
      Hive.isBoxOpen(_boxName) ? Hive.box<String>(_boxName) : null;

  Future<void> append(TelemetryEvent event) async {
    final box = _box;
    if (box == null) return;
    final list = _readRaw();
    list.add(event.toJson());
    await box.put(_key, jsonEncode(list));
  }

  List<TelemetryEvent> readAll() {
    return _readRaw()
        .map((e) => TelemetryEvent.fromJson(e as Map<String, dynamic>))
        .toList(growable: false);
  }

  Future<void> clear() async {
    await _box?.delete(_key);
  }

  List<dynamic> _readRaw() {
    final box = _box;
    if (box == null) return [];
    final json = box.get(_key);
    if (json == null) return [];
    final decoded = jsonDecode(json);
    return decoded is List ? List<dynamic>.from(decoded) : [];
  }
}
