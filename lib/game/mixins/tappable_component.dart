import 'dart:ui';

import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// 포인트앤클릭 공통 믹스인.
///
/// art-2b 확장: `HoverCallbacks` 를 제약에 추가하고 hover/pressed 상태를
/// 스프라이트/도형 전체에 밝기 ColorFilter 로 오버레이. Flutter 측
/// `SteampunkButton` 과 동일한 ±25~30% 밝기 규칙을 공유.
mixin TappableComponent on PositionComponent, TapCallbacks, HoverCallbacks {
  bool _pressed = false;

  bool get isPressed => _pressed;

  /// 서브클래스 훅 — 탭 완료(onTapUp) 시 호출.
  void onTapped();

  Paint? _tintPaint() {
    if (_pressed) {
      return Paint()
        ..colorFilter = const ColorFilter.matrix([
          0.7, 0, 0, 0, 0,
          0, 0.7, 0, 0, 0,
          0, 0, 0.7, 0, 0,
          0, 0, 0, 1, 0,
        ]);
    }
    if (isHovered) {
      return Paint()
        ..colorFilter = const ColorFilter.matrix([
          1.3, 0, 0, 0, 0,
          0, 1.3, 0, 0, 0,
          0, 0, 1.3, 0, 0,
          0, 0, 0, 1, 0,
        ]);
    }
    return null;
  }

  @override
  void renderTree(Canvas canvas) {
    final tint = _tintPaint();
    if (tint == null) {
      super.renderTree(canvas);
      return;
    }
    // bounds 는 부모 좌표계. null 을 넘기면 전체 캔버스 대상(성능 hint 만 잃음).
    // component 가 position 으로 변환되는 영역에 정확히 맞추려면 toRect() 이
    // 필요하지만 자식·텍스트가 size 밖으로 나갈 수 있어 null 이 가장 안전.
    canvas.saveLayer(null, tint);
    super.renderTree(canvas);
    canvas.restore();
  }

  @override
  void onTapDown(TapDownEvent event) {
    _pressed = true;
  }

  @override
  void onTapUp(TapUpEvent event) {
    _pressed = false;
    onTapped();
  }

  @override
  void onTapCancel(TapCancelEvent event) {
    _pressed = false;
  }
}
