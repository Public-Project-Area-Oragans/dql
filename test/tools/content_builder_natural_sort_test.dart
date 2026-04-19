import 'package:flutter_test/flutter_test.dart';

import '../../tools/content_builder.dart';

void main() {
  group('compareNatural', () {
    test('phase1 < phase2 < phase10 (MSA 챕터 핵심 케이스)', () {
      final names = [
        'phase10-step1-auth',
        'phase1-step1-network-os',
        'phase2-step1-docker',
        'phase3-step1-monolithic',
        'phase11-step1-caching',
      ]..sort(compareNatural);

      expect(names, [
        'phase1-step1-network-os',
        'phase2-step1-docker',
        'phase3-step1-monolithic',
        'phase10-step1-auth',
        'phase11-step1-caching',
      ]);
    });

    test('동일 phase 안에서 step 숫자도 자연정렬', () {
      final names = [
        'phase12-step10-chaos',
        'phase12-step2-modular',
        'phase12-step1-monolithic',
      ]..sort(compareNatural);

      expect(names, [
        'phase12-step1-monolithic',
        'phase12-step2-modular',
        'phase12-step10-chaos',
      ]);
    });

    test('순수 숫자 문자열 비교', () {
      expect(compareNatural('2', '10') < 0, isTrue);
      expect(compareNatural('10', '2') > 0, isTrue);
      expect(compareNatural('10', '10'), 0);
    });

    test('prefix 가 다른 경우 문자 순서 우선', () {
      expect(compareNatural('a1', 'b1') < 0, isTrue);
      expect(compareNatural('alpha10', 'beta1') < 0, isTrue);
    });

    test('leading zero 수가 다른 동일 숫자는 더 짧은 쪽 먼저', () {
      // phase01 vs phase1 — 값은 같지만 길이 차이로 안정적 순서.
      expect(compareNatural('phase1', 'phase01') < 0, isTrue);
      expect(compareNatural('phase01', 'phase001') < 0, isTrue);
    });

    test('full path 에 대한 자연정렬 (실제 호출 형태)', () {
      final paths = [
        '/tmp/MSA/phase10-step1.md',
        '/tmp/MSA/phase1-step1.md',
        '/tmp/MSA/phase2-step1.md',
      ]..sort(compareNatural);

      expect(paths.first, '/tmp/MSA/phase1-step1.md');
      expect(paths.last, '/tmp/MSA/phase10-step1.md');
    });

    test('동일 문자열은 0', () {
      expect(compareNatural('phase1-step1', 'phase1-step1'), 0);
    });
  });
}
