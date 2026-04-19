import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/rendering/nine_slice_insets.dart';

/// 9-slice 박스 프레임 — Flutter 측 래퍼.
///
/// `Canvas.drawImageNine` 기반으로 임의 크기 박스에 픽셀아트 프레임을 적용.
/// `NineSliceBox` (Flame 측) 와 인셋 상수를 공유해 시각적 일관성 유지.
///
/// 사용 예:
/// ```dart
/// PixelNineSlice(
///   assetName: UiAssets.frameDialog,
///   insets: NineSliceInsets.defaultCorner,
///   child: Padding(padding: EdgeInsets.all(16), child: Text('대화 내용')),
/// )
/// ```
class PixelNineSlice extends StatefulWidget {
  final String assetName;
  final NineSliceInsets insets;
  final Widget? child;
  final EdgeInsetsGeometry padding;

  const PixelNineSlice({
    super.key,
    required this.assetName,
    this.insets = NineSliceInsets.defaultCorner,
    this.child,
    this.padding = EdgeInsets.zero,
  });

  @override
  State<PixelNineSlice> createState() => _PixelNineSliceState();
}

class _PixelNineSliceState extends State<PixelNineSlice> {
  ui.Image? _image;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(PixelNineSlice oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.assetName != widget.assetName) {
      _image = null;
      _loadImage();
    }
  }

  Future<void> _loadImage() async {
    try {
      final data = await rootBundle.load(widget.assetName);
      final bytes = data.buffer.asUint8List();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      if (mounted) {
        setState(() => _image = frame.image);
      }
    } catch (_) {
      // 자산 미존재 등. placeholder 렌더.
    }
  }

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _image == null
          ? _PlaceholderPainter()
          : _NineSlicePainter(image: _image!, insets: widget.insets),
      child: Padding(
        padding: widget.padding,
        child: widget.child,
      ),
    );
  }
}

class _NineSlicePainter extends CustomPainter {
  final ui.Image image;
  final NineSliceInsets insets;

  _NineSlicePainter({required this.image, required this.insets});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..filterQuality = FilterQuality.none;
    final center = Rect.fromLTRB(
      insets.left,
      insets.top,
      image.width.toDouble() - insets.right,
      image.height.toDouble() - insets.bottom,
    );
    canvas.drawImageNine(
      image,
      center,
      Rect.fromLTWH(0, 0, size.width, size.height),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _NineSlicePainter old) =>
      old.image != image || old.insets != insets;
}

class _PlaceholderPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 자산 로드 전 / 미존재 상태의 placeholder. Void Violet + gold outline.
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF3A1A55),
    );
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()
        ..color = const Color(0xFFB8860B)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1,
    );
  }

  @override
  bool shouldRepaint(_) => false;
}
