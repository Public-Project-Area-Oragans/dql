import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:dol/data/models/qa_message.dart';
import 'package:dol/services/claude_api_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';

/// P0-5 NPC-3: ClaudeApiService 검증.
///
/// Dio의 `HttpClientAdapter`를 fake로 교체해 실제 네트워크 없이 SSE
/// 응답을 흉내낸다.
void main() {
  late Directory tempDir;
  late ClaudeApiService service;

  setUp(() async {
    tempDir = Directory.systemTemp.createTempSync('claude_test_');
    Hive.init(tempDir.path);
    service = ClaudeApiService();
  });

  tearDown(() async {
    try {
      await Hive.deleteFromDisk();
    } catch (_) {}
    try {
      await Hive.close();
    } catch (_) {}
    if (tempDir.existsSync()) tempDir.deleteSync(recursive: true);
  });

  group('API 키 CRUD', () {
    test('초기 상태에 키 없음 → loadApiKey null', () async {
      expect(await service.loadApiKey(), isNull);
    });

    test('saveApiKey 후 loadApiKey', () async {
      await service.saveApiKey('sk-ant-xxxxx');
      expect(await service.loadApiKey(), 'sk-ant-xxxxx');
    });

    test('clearApiKey 후 null', () async {
      await service.saveApiKey('sk-ant-yyy');
      await service.clearApiKey();
      expect(await service.loadApiKey(), isNull);
    });

    test('빈 문자열 키는 null로 취급', () async {
      await service.saveApiKey('');
      expect(await service.loadApiKey(), isNull);
    });
  });

  group('askStream 에러 매핑', () {
    test('키 미설정 → ClaudeApiKeyMissingException', () {
      expect(
        () => service
            .askStream(
              systemPrompt: 'sp',
              history: const [],
              userQuestion: 'q',
            )
            .toList(),
        throwsA(isA<ClaudeApiKeyMissingException>()),
      );
    });

    test('401 → ClaudeApiAuthException', () async {
      await service.saveApiKey('sk-ant-xxxxx');
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter(statusCode: 401, body: '{}');
      final svc = ClaudeApiService(dio: dio);

      expect(
        () => svc
            .askStream(
              systemPrompt: 'sp',
              history: const [],
              userQuestion: 'q',
            )
            .toList(),
        throwsA(isA<ClaudeApiAuthException>()),
      );
    });

    test('429 → ClaudeApiRateLimitException', () async {
      await service.saveApiKey('sk-ant-xxxxx');
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter(statusCode: 429, body: '{}');
      final svc = ClaudeApiService(dio: dio);

      expect(
        () => svc
            .askStream(
              systemPrompt: 'sp',
              history: const [],
              userQuestion: 'q',
            )
            .toList(),
        throwsA(isA<ClaudeApiRateLimitException>()),
      );
    });

    test('503 → ClaudeApiUnavailableException', () async {
      await service.saveApiKey('sk-ant-xxxxx');
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter(statusCode: 503, body: '{}');
      final svc = ClaudeApiService(dio: dio);

      expect(
        () => svc
            .askStream(
              systemPrompt: 'sp',
              history: const [],
              userQuestion: 'q',
            )
            .toList(),
        throwsA(isA<ClaudeApiUnavailableException>()),
      );
    });
  });

  group('askStream SSE 파싱', () {
    test('content_block_delta 텍스트들을 차례로 yield', () async {
      await service.saveApiKey('sk-ant-xxxxx');
      final sse = [
        'event: message_start',
        'data: {"type":"message_start","message":{"id":"msg_1"}}',
        '',
        'event: content_block_delta',
        'data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"안녕"}}',
        '',
        'event: content_block_delta',
        'data: {"type":"content_block_delta","delta":{"type":"text_delta","text":"하세요"}}',
        '',
        'event: message_stop',
        'data: {"type":"message_stop"}',
        '',
      ].join('\n');

      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter(
          statusCode: 200,
          body: sse,
          streaming: true,
        );
      final svc = ClaudeApiService(dio: dio);

      final chunks = <String>[];
      await for (final c in svc.askStream(
        systemPrompt: '너는 아르카누스',
        history: const [],
        userQuestion: '반갑다',
      )) {
        chunks.add(c);
      }

      expect(chunks, ['안녕', '하세요']);
    });

    test('keep-alive / 비JSON 라인은 무시', () async {
      await service.saveApiKey('sk-ant-xxxxx');
      final sse = [
        ': keep-alive',
        'data: not-json-junk',
        'data: {"type":"content_block_delta","delta":{"text":"OK"}}',
        '',
      ].join('\n');

      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter(
          statusCode: 200,
          body: sse,
          streaming: true,
        );
      final svc = ClaudeApiService(dio: dio);

      final chunks = <String>[];
      await for (final c in svc.askStream(
        systemPrompt: 'sp',
        history: const [],
        userQuestion: 'q',
      )) {
        chunks.add(c);
      }
      expect(chunks, ['OK']);
    });

    test('history와 userQuestion이 messages 배열에 user 순서대로 포함',
        () async {
      await service.saveApiKey('sk-ant-xxxxx');
      final adapter = _FakeAdapter(
        statusCode: 200,
        body: 'data: {"type":"content_block_delta","delta":{"text":"x"}}\n',
        streaming: true,
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final svc = ClaudeApiService(dio: dio);

      final history = [
        QaMessage(
          role: QaRole.user,
          content: '첫 질문',
          at: DateTime.utc(2026, 4, 18),
        ),
        QaMessage(
          role: QaRole.assistant,
          content: '이전 답변',
          at: DateTime.utc(2026, 4, 18),
        ),
      ];

      await svc
          .askStream(
            systemPrompt: 'sp',
            history: history,
            userQuestion: '새 질문',
          )
          .drain<void>();

      final payload = jsonDecode(adapter.capturedBody!) as Map<String, dynamic>;
      final messages = payload['messages'] as List;
      expect(messages, hasLength(3));
      expect(messages[0]['role'], 'user');
      expect(messages[0]['content'], '첫 질문');
      expect(messages[1]['role'], 'assistant');
      expect(messages[1]['content'], '이전 답변');
      expect(messages[2]['role'], 'user');
      expect(messages[2]['content'], '새 질문');
    });

    test('system 블록에 cache_control ephemeral 태깅', () async {
      await service.saveApiKey('sk-ant-xxxxx');
      final adapter = _FakeAdapter(
        statusCode: 200,
        body: 'data: {"type":"content_block_delta","delta":{"text":"y"}}\n',
        streaming: true,
      );
      final dio = Dio()..httpClientAdapter = adapter;
      final svc = ClaudeApiService(dio: dio);

      await svc
          .askStream(
            systemPrompt: 'PERSONA',
            history: const [],
            userQuestion: 'q',
            cachedContextChunks: ['CHUNK1', 'CHUNK2'],
          )
          .drain<void>();

      final payload = jsonDecode(adapter.capturedBody!) as Map<String, dynamic>;
      final system = payload['system'] as List;
      expect(system, hasLength(3));
      for (final s in system) {
        expect((s as Map)['cache_control'], {'type': 'ephemeral'});
      }
      expect(system[0]['text'], 'PERSONA');
      expect(system[1]['text'], 'CHUNK1');
      expect(system[2]['text'], 'CHUNK2');
    });
  });
}

/// Dio HttpClientAdapter stub.
class _FakeAdapter implements HttpClientAdapter {
  final int statusCode;
  final String body;
  final bool streaming;
  String? capturedBody;

  _FakeAdapter({
    required this.statusCode,
    required this.body,
    this.streaming = false,
  });

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    if (requestStream != null) {
      final bytes = <int>[];
      await for (final chunk in requestStream) {
        bytes.addAll(chunk);
      }
      capturedBody = utf8.decode(bytes);
    }

    final bytes = Uint8List.fromList(utf8.encode(body));
    if (streaming) {
      final controller = StreamController<Uint8List>();
      controller.add(bytes);
      // ignore: unawaited_futures
      Future.microtask(() => controller.close());
      return ResponseBody(
        controller.stream,
        statusCode,
        headers: const {},
      );
    }
    return ResponseBody.fromBytes(bytes, statusCode);
  }
}
