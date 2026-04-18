import 'package:freezed_annotation/freezed_annotation.dart';

part 'qa_message.freezed.dart';
part 'qa_message.g.dart';

/// P0-5 NPC-3: NPC Q&A 한 턴의 메시지.
///
/// Claude Messages API 구조에 매핑:
/// - `user`: 사용자 질문
/// - `assistant`: NPC(모델) 응답
/// - (system은 ClaudeApiService 내부에서 system 블록으로 전달, 이 모델엔
///    저장하지 않는다.)
///
/// `at`은 기록용 timestamp. tokensUsed는 선택 (비용 추적).
enum QaRole { user, assistant }

@freezed
abstract class QaMessage with _$QaMessage {
  const factory QaMessage({
    required QaRole role,
    required String content,
    required DateTime at,
    int? tokensUsed,
  }) = _QaMessage;

  factory QaMessage.fromJson(Map<String, dynamic> json) =>
      _$QaMessageFromJson(json);
}
