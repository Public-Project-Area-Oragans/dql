import 'package:dol/core/rendering/nine_slice_insets.dart';
import 'package:flutter_test/flutter_test.dart';

/// art-1 — NineSliceInsets 기본 생성자 · Manifest §3.4 기본값 · 최소 크기
/// 계산 회귀 가드.
void main() {
  group('NineSliceInsets', () {
    test('NineSliceInsets.all 은 4면 동일', () {
      const i = NineSliceInsets.all(8);
      expect(i.left, 8);
      expect(i.top, 8);
      expect(i.right, 8);
      expect(i.bottom, 8);
    });

    test('기본값은 Manifest §3.4 의 8×8 코너', () {
      expect(NineSliceInsets.defaultCorner.left, 8);
      expect(NineSliceInsets.defaultCorner.top, 8);
      expect(NineSliceInsets.defaultCorner.right, 8);
      expect(NineSliceInsets.defaultCorner.bottom, 8);
    });

    test('비대칭 생성자 모든 면 독립 지정', () {
      const i = NineSliceInsets(left: 4, top: 6, right: 8, bottom: 10);
      expect([i.left, i.top, i.right, i.bottom], [4, 6, 8, 10]);
    });

    test('minWidth / minHeight 는 코너 합 + 1', () {
      const i = NineSliceInsets(left: 3, top: 5, right: 7, bottom: 11);
      expect(i.minWidth, 11); // 3 + 7 + 1
      expect(i.minHeight, 17); // 5 + 11 + 1
    });

    test('== / hashCode 는 값 동등성', () {
      const a = NineSliceInsets.all(8);
      const b = NineSliceInsets(left: 8, top: 8, right: 8, bottom: 8);
      const c = NineSliceInsets.all(10);
      expect(a, b);
      expect(a.hashCode, b.hashCode);
      expect(a, isNot(c));
    });

    test('toString 디버그 포맷', () {
      const i = NineSliceInsets(left: 1, top: 2, right: 3, bottom: 4);
      expect(i.toString(), 'NineSliceInsets(l=1.0, t=2.0, r=3.0, b=4.0)');
    });
  });
}
