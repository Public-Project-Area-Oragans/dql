import 'package:freezed_annotation/freezed_annotation.dart';

part 'telemetry_event.freezed.dart';
part 'telemetry_event.g.dart';

/// Phase 2 Task 2-5 계측 이벤트.
///
/// 일주일 실사용 동안 챕터 진입·완료 타임스탬프를 누적해
/// "재시도 횟수 / 완료까지 걸린 시간"을 사후 집계하기 위한 최소 단위.
/// 대시보드 없음 — `/debug/telemetry` 뷰어로 원본 리스트만 확인.
@freezed
abstract class TelemetryEvent with _$TelemetryEvent {
  const factory TelemetryEvent({
    /// 'chapter_start' | 'chapter_complete'
    required String type,
    required String chapterId,
    required DateTime at,
  }) = _TelemetryEvent;

  factory TelemetryEvent.fromJson(Map<String, dynamic> json) =>
      _$TelemetryEventFromJson(json);
}
