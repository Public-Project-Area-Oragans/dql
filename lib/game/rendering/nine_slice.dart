import 'dart:ui' as ui;

import 'package:flame/components.dart';
import 'package:flutter/material.dart';

import '../../core/rendering/nine_slice_insets.dart';
import 'sprite_registry.dart';

/// 9-slice 박스 프레임 — Flame 측 구현.
///
/// `PIXEL_ART_ASSET_MANIFEST.md` §3.4 대로 128×64 프레임의 8×8 코너를 고정으로
/// 두고, 엣지와 중앙을 임의 크기로 stretch/tile. 내부적으로 `Canvas.drawImageNine`
/// 을 사용해 GPU 가 한 번에 draw 하므로 성능 영향 미미.
///
/// 필요 자산은 `SpriteRegistry.preload(...)` 로 프리로드되어 있어야 함. 미로드
/// 시 placeholder (어두운 보라 사각형) 로 fallback — 개발 중 누락 자산 시각 감지용.
class NineSliceBox extends PositionComponent {
  final String imageId;
  final NineSliceInsets insets;

  /// `FilterQuality.none` 고정. Bible §9.1 준수.
  final Paint _paint = Paint()..filterQuality = FilterQuality.none;

  NineSliceBox({
    required this.imageId,
    this.insets = NineSliceInsets.defaultCorner,
    super.position,
    super.size,
    super.anchor,
    super.priority,
  });

  @override
  void render(Canvas canvas) {
    if (!SpriteRegistry.has(imageId)) {
      _renderPlaceholder(canvas);
      return;
    }
    final img = SpriteRegistry.get(imageId);
    final center = Rect.fromLTRB(
      insets.left,
      insets.top,
      img.width.toDouble() - insets.right,
      img.height.toDouble() - insets.bottom,
    );
    final dst = Rect.fromLTWH(0, 0, size.x, size.y);
    canvas.drawImageNine(img, center, dst, _paint);
  }

  void _renderPlaceholder(Canvas canvas) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()..color = const Color(0xFF3A1A55), // Void Violet
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.x, size.y),
      Paint()
        ..color = const Color(0xFFB8860B) // Dark Goldenrod
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }
}

/// 테스트·디버그 용도로 drawImageNine 결과를 검증할 수 있는 helper —
/// 주어진 image / insets / size 로 CPU 에서 rasterize 된 결과를 만들어
/// 반환. 상세 픽셀 검증용.
Future<ui.Image> rasterizeNineSlice({
  required ui.Image src,
  required NineSliceInsets insets,
  required Size size,
}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final paint = Paint()..filterQuality = FilterQuality.none;
  final center = Rect.fromLTRB(
    insets.left,
    insets.top,
    src.width.toDouble() - insets.right,
    src.height.toDouble() - insets.bottom,
  );
  canvas.drawImageNine(
    src,
    center,
    Rect.fromLTWH(0, 0, size.width, size.height),
    paint,
  );
  final picture = recorder.endRecording();
  return picture.toImage(size.width.toInt(), size.height.toInt());
}
