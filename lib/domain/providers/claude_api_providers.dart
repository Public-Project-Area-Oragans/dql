import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/claude_api_service.dart';

part 'claude_api_providers.g.dart';

/// P0-5 NPC-3: 앱 전역 `ClaudeApiService` 싱글턴.
/// 테스트에서 overrideWith로 fake 주입 가능.
@Riverpod(keepAlive: true)
ClaudeApiService claudeApiService(Ref ref) => ClaudeApiService();
