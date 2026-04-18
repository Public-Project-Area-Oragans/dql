import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:hive/hive.dart';

import '../data/models/qa_message.dart';

/// P0-5 NPC-3: Claude Messages API 래퍼.
///
/// - 개인 P0 한정: API 키는 Hive `Box<String>('auth')`의 `claude_api_key`에
///   평문 저장 (배포 자산에 포함 금지).
/// - Streaming 기본. 실패 시 세계관 유지 fallback 메시지 throw.
/// - 프롬프트 캐싱: system prompt + 길이 긴 컨텍스트 chunk는 `cache_control`
///   블록으로 표시해 동일 NPC 반복 질문 비용 절감.
/// - 모델 기본: `claude-haiku-4-5-20251001` (비용/지연 최적). 옵션으로
///   `claude-sonnet-4-6`.
///
/// 테스트: Dio의 `RequestInterceptor` + `HttpClientAdapter` mock으로 격리.
class ClaudeApiService {
  static const String kApiKeyHiveBox = 'auth';
  static const String kApiKeyHiveKey = 'claude_api_key';
  static const String kDefaultBaseUrl = 'https://api.anthropic.com';
  static const String kApiVersion = '2023-06-01';
  static const String kDefaultModel = 'claude-haiku-4-5-20251001';

  final Dio _dio;
  final String _baseUrl;

  ClaudeApiService({Dio? dio, String? baseUrl})
      : _dio = dio ?? Dio(),
        _baseUrl = baseUrl ?? kDefaultBaseUrl;

  /// Hive에서 API 키를 로드. 없거나 빈 문자열이면 null.
  Future<String?> loadApiKey() async {
    if (!Hive.isBoxOpen(kApiKeyHiveBox)) {
      await Hive.openBox<String>(kApiKeyHiveBox);
    }
    final raw = Hive.box<String>(kApiKeyHiveBox).get(kApiKeyHiveKey);
    if (raw == null || raw.trim().isEmpty) return null;
    return raw.trim();
  }

  Future<void> saveApiKey(String key) async {
    if (!Hive.isBoxOpen(kApiKeyHiveBox)) {
      await Hive.openBox<String>(kApiKeyHiveBox);
    }
    await Hive.box<String>(kApiKeyHiveBox).put(kApiKeyHiveKey, key.trim());
  }

  Future<void> clearApiKey() async {
    if (!Hive.isBoxOpen(kApiKeyHiveBox)) {
      await Hive.openBox<String>(kApiKeyHiveBox);
    }
    await Hive.box<String>(kApiKeyHiveBox).delete(kApiKeyHiveKey);
  }

  /// Claude Messages API 스트리밍 호출.
  /// 응답 토큰이 도착하는 대로 `Stream<String>`으로 yield.
  /// 완료 후 stream이 닫힘.
  ///
  /// 실패 타입:
  /// - [ClaudeApiKeyMissingException]: 키 미설정.
  /// - [ClaudeApiAuthException]: 401/403.
  /// - [ClaudeApiRateLimitException]: 429.
  /// - [ClaudeApiUnavailableException]: 5xx / 네트워크.
  /// - [ClaudeApiResponseException]: 응답 파싱 실패 / 기타 4xx.
  Stream<String> askStream({
    required String systemPrompt,
    required List<QaMessage> history,
    required String userQuestion,
    String model = kDefaultModel,
    int maxTokens = 1024,
    List<String> cachedContextChunks = const [],
  }) async* {
    final apiKey = await loadApiKey();
    if (apiKey == null) {
      throw ClaudeApiKeyMissingException();
    }

    final messages = <Map<String, dynamic>>[
      for (final m in history)
        {
          'role': m.role == QaRole.user ? 'user' : 'assistant',
          'content': m.content,
        },
      {
        'role': 'user',
        'content': userQuestion,
      },
    ];

    // system 블록 + cached chunks: cache_control 표시.
    final systemBlocks = <Map<String, dynamic>>[
      {
        'type': 'text',
        'text': systemPrompt,
        'cache_control': {'type': 'ephemeral'},
      },
      for (final chunk in cachedContextChunks)
        {
          'type': 'text',
          'text': chunk,
          'cache_control': {'type': 'ephemeral'},
        },
    ];

    final payload = <String, dynamic>{
      'model': model,
      'max_tokens': maxTokens,
      'system': systemBlocks,
      'messages': messages,
      'stream': true,
    };

    Response<ResponseBody> response;
    try {
      response = await _dio.request<ResponseBody>(
        '$_baseUrl/v1/messages',
        data: payload,
        options: Options(
          method: 'POST',
          headers: {
            'x-api-key': apiKey,
            'anthropic-version': kApiVersion,
            'content-type': 'application/json',
            'accept': 'text/event-stream',
          },
          responseType: ResponseType.stream,
        ),
      );
    } on DioException catch (e) {
      _throwMappedFailure(e);
    }

    final stream = response.data;
    if (stream == null) {
      throw ClaudeApiResponseException('empty stream');
    }

    // SSE 파싱: `data: {json}` 라인을 읽어 delta.text를 yield.
    final byteStream = stream.stream;
    const decoder = Utf8Decoder(allowMalformed: true);
    var buffer = '';

    await for (final chunk in byteStream) {
      buffer += decoder.convert(chunk);
      var newlineIdx = buffer.indexOf('\n');
      while (newlineIdx >= 0) {
        final line = buffer.substring(0, newlineIdx).trim();
        buffer = buffer.substring(newlineIdx + 1);
        if (line.startsWith('data:')) {
          final jsonStr = line.substring(5).trim();
          if (jsonStr.isEmpty) {
            newlineIdx = buffer.indexOf('\n');
            continue;
          }
          try {
            final event = jsonDecode(jsonStr) as Map<String, dynamic>;
            final type = event['type'] as String?;
            if (type == 'content_block_delta') {
              final delta = event['delta'] as Map<String, dynamic>?;
              final text = delta?['text'] as String?;
              if (text != null && text.isNotEmpty) {
                yield text;
              }
            }
          } catch (_) {
            // 파싱 실패는 무시 (Claude가 keep-alive event 보낼 때).
          }
        }
        newlineIdx = buffer.indexOf('\n');
      }
    }
  }

  Never _throwMappedFailure(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;
    if (status == 401 || status == 403) {
      throw ClaudeApiAuthException(_dataToString(data));
    }
    if (status == 429) {
      throw ClaudeApiRateLimitException(_dataToString(data));
    }
    if (status != null && status >= 500) {
      throw ClaudeApiUnavailableException(_dataToString(data));
    }
    throw ClaudeApiUnavailableException(e.message ?? 'network error');
  }

  String _dataToString(dynamic data) {
    if (data == null) return '';
    if (data is String) return data;
    try {
      return jsonEncode(data);
    } catch (_) {
      // ResponseBody 등 encodable하지 않은 타입은 runtimeType만 기록.
      return data.toString();
    }
  }
}

// ── 예외 타입 ──────────────────────────────────────

class ClaudeApiException implements Exception {
  final String message;
  ClaudeApiException(this.message);
  @override
  String toString() => '$runtimeType: $message';
}

/// Hive에 API 키 없음.
/// UI는 "/debug/settings 에서 주문서를 등록하라" 메시지.
class ClaudeApiKeyMissingException extends ClaudeApiException {
  ClaudeApiKeyMissingException()
      : super('Claude API key not configured');
}

/// 401/403.
class ClaudeApiAuthException extends ClaudeApiException {
  ClaudeApiAuthException(super.message);
}

/// 429.
class ClaudeApiRateLimitException extends ClaudeApiException {
  ClaudeApiRateLimitException(super.message);
}

/// 5xx / 네트워크 실패.
class ClaudeApiUnavailableException extends ClaudeApiException {
  ClaudeApiUnavailableException(super.message);
}

/// 기타 응답 파싱 실패.
class ClaudeApiResponseException extends ClaudeApiException {
  ClaudeApiResponseException(super.message);
}
