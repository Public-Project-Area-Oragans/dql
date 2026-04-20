/// 9-slice 프레임 인셋 — 4 모서리 코너 폭/높이.
///
/// `PIXEL_ART_ASSET_MANIFEST.md` §3.4 규정: 기본 128×64 UI 프레임은 코너
/// 8×8 고정. 엣지는 중앙 반복. 본 상수를 Flame `NineSliceBox` 와 Flutter
/// `PixelNineSlice` 가 공유해 단일 진실 소스 유지.
class NineSliceInsets {
  final double left;
  final double top;
  final double right;
  final double bottom;

  const NineSliceInsets({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
  });

  /// 4면 동일 인셋. 일반 UI 프레임에 편리.
  const NineSliceInsets.all(double value)
      : left = value,
        top = value,
        right = value,
        bottom = value;

  /// Manifest §3.4 기본값 — 128×64 프레임 코너 8×8.
  static const defaultCorner = NineSliceInsets.all(8);

  /// 코너 값의 합계. 프레임 최소 크기 계산용
  /// (frame >= corner sum + 1 라인 중앙).
  double get minWidth => left + right + 1;
  double get minHeight => top + bottom + 1;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is NineSliceInsets &&
          other.left == left &&
          other.top == top &&
          other.right == right &&
          other.bottom == bottom;

  @override
  int get hashCode => Object.hash(left, top, right, bottom);

  @override
  String toString() =>
      'NineSliceInsets(l=$left, t=$top, r=$right, b=$bottom)';
}
