import 'package:flame/components.dart';
import 'package:flame/events.dart';

/// 포인트앤클릭 공통 믹스인
/// 클릭 가능한 모든 게임 컴포넌트에 적용
mixin TappableComponent on PositionComponent, TapCallbacks {
  final bool _isHovered = false;

  bool get isHovered => _isHovered;

  void onTapped();

  @override
  void onTapUp(TapUpEvent event) {
    onTapped();
  }
}
