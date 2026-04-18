import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/telemetry_service.dart';

part 'telemetry_providers.g.dart';

/// Phase 2 Task 2-5. `main.dart`에서 init()이 완료된 상태여야 한다.
@Riverpod(keepAlive: true)
TelemetryService telemetryService(Ref ref) => TelemetryService();
