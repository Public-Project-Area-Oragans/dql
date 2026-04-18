import 'package:integration_test/integration_test_driver.dart';

/// flutter_driver ↔ integration_test 브릿지. `flutter drive --driver`가
/// 요구하는 기본 엔트리. 웹(-d chrome) 환경에서는 필수.
Future<void> main() => integrationDriver();
