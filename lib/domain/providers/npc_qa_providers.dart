import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../data/models/qa_message.dart';
import '../../services/claude_api_service.dart';
import '../../services/npc_personas.dart';
import 'claude_api_providers.dart';

part 'npc_qa_providers.g.dart';

/// P0-5 NPC-4: 현재 대화 중인 NPC의 id. 대화 시작 시 set, 종료 시 clear.
@riverpod
class ActiveNpcId extends _$ActiveNpcId {
  @override
  String? build() => null;

  void set(String npcId) => state = npcId;
  void clear() => state = null;
}

/// NPC Q&A 세션 상태.
class NpcQaState {
  final List<QaMessage> messages;
  final bool loading;
  final String? error;

  /// 현재 스트리밍 중인 assistant 답변의 누적 텍스트.
  /// 완료 시 null로 clear되고 messages에 push.
  final String? streamingAssistant;

  const NpcQaState({
    this.messages = const [],
    this.loading = false,
    this.error,
    this.streamingAssistant,
  });

  NpcQaState copyWith({
    List<QaMessage>? messages,
    bool? loading,
    String? error,
    bool clearError = false,
    String? streamingAssistant,
    bool clearStreaming = false,
  }) {
    return NpcQaState(
      messages: messages ?? this.messages,
      loading: loading ?? this.loading,
      error: clearError ? null : (error ?? this.error),
      streamingAssistant: clearStreaming
          ? null
          : (streamingAssistant ?? this.streamingAssistant),
    );
  }
}

/// NPC별 Q&A 세션. npcId를 family key로 사용.
/// AutoDispose로 분관 이탈 시 자동 정리.
@riverpod
class NpcQaSession extends _$NpcQaSession {
  StreamSubscription<String>? _sub;

  @override
  NpcQaState build(String npcId) {
    ref.onDispose(() {
      _sub?.cancel();
    });
    return const NpcQaState();
  }

  Future<void> ask(String question) async {
    if (state.loading) return;
    final trimmed = question.trim();
    if (trimmed.isEmpty) return;

    final persona = NpcPersonas.forNpcId(npcId);
    if (persona == null) {
      state = state.copyWith(
        error: '이 NPC는 아직 Q&A 담당이 지정되지 않았습니다.',
      );
      return;
    }

    final userMsg = QaMessage(
      role: QaRole.user,
      content: trimmed,
      at: DateTime.now(),
    );
    state = state.copyWith(
      messages: [...state.messages, userMsg],
      loading: true,
      clearError: true,
      streamingAssistant: '',
    );

    final service = ref.read(claudeApiServiceProvider);
    final buffer = StringBuffer();
    try {
      final stream = service.askStream(
        systemPrompt: persona,
        history: state.messages
            .where((m) => m.role != QaRole.user || m.content != trimmed)
            .toList(),
        userQuestion: trimmed,
      );
      await _sub?.cancel();
      _sub = stream.listen(
        (chunk) {
          buffer.write(chunk);
          state = state.copyWith(streamingAssistant: buffer.toString());
        },
        onError: (Object e) {
          state = state.copyWith(
            loading: false,
            error: _mapErrorMessage(e),
            clearStreaming: true,
          );
        },
        onDone: () {
          final final_ = buffer.toString();
          final msgs = [
            ...state.messages,
            QaMessage(
              role: QaRole.assistant,
              content: final_,
              at: DateTime.now(),
            ),
          ];
          state = state.copyWith(
            messages: msgs,
            loading: false,
            clearStreaming: true,
          );
        },
        cancelOnError: true,
      );
    } catch (e) {
      state = state.copyWith(
        loading: false,
        error: _mapErrorMessage(e),
        clearStreaming: true,
      );
    }
  }

  void clearHistory() {
    _sub?.cancel();
    state = const NpcQaState();
  }

  String _mapErrorMessage(Object e) {
    if (e is ClaudeApiKeyMissingException) {
      return '도서관의 외부 통신선이 연결되어 있지 않다. '
          '`/debug/settings` 에서 주문서를 등록하라.';
    }
    if (e is ClaudeApiAuthException) {
      return '주문서가 거부되었다. 키를 확인하라.';
    }
    if (e is ClaudeApiRateLimitException) {
      return '오늘 이 마법사의 힘이 한계에 달했다. 잠시 후 다시 시도하라.';
    }
    if (e is ClaudeApiUnavailableException) {
      return '마법 회선이 불안정하다. 잠시 후 다시 시도하라.';
    }
    if (e is ClaudeApiResponseException) {
      return '답변이 흐릿하다. 질문을 다시 해보라. ($e)';
    }
    return '알 수 없는 장애: $e';
  }
}
