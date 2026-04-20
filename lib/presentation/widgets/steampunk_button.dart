import 'package:flutter/material.dart';
import '../../core/assets/asset_ids.dart';
import '../../core/constants/app_colors.dart';

/// art-2: 3상태 스프라이트 버튼. idle / hover / pressed 각 상태에서 별도
/// 9-slice 프레임을 PNG 로 스위칭. 자산 미로드 시 ElevatedButton fallback.
///
/// 크기:
/// - `isSmall = true` → 64×32 원본.
/// - `isSmall = false` → 128×64 (2× 정수 배율, §9.2 준수).
class SteampunkButton extends StatefulWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isSmall;

  const SteampunkButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isSmall = false,
  });

  @override
  State<SteampunkButton> createState() => _SteampunkButtonState();
}

class _SteampunkButtonState extends State<SteampunkButton> {
  bool _hovering = false;
  bool _pressed = false;

  String get _asset {
    if (_pressed) return UiAssets.buttonPrimaryPressed;
    if (_hovering) return UiAssets.buttonPrimaryHover;
    return UiAssets.buttonPrimaryIdle;
  }

  // art-2b: PixelLab 생성 3-state 스프라이트의 시각 차이가 미미 → 상태 구분을
  // 명확하게 드러내기 위해 밝기 ColorFilter + pressed 1px Y translate 를
  // 오버레이. 스프라이트 스위칭은 유지 (향후 퀄리티 업그레이드 시 그대로 반영).
  ColorFilter get _tint {
    if (_pressed) {
      return const ColorFilter.matrix([
        0.75, 0, 0, 0, 0,
        0, 0.75, 0, 0, 0,
        0, 0, 0.75, 0, 0,
        0, 0, 0, 1, 0,
      ]);
    }
    if (_hovering) {
      return const ColorFilter.matrix([
        1.25, 0, 0, 0, 0,
        0, 1.25, 0, 0, 0,
        0, 0, 1.25, 0, 0,
        0, 0, 0, 1, 0,
      ]);
    }
    return const ColorFilter.mode(Colors.transparent, BlendMode.dst);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null;
    final width = widget.isSmall ? 64.0 : 128.0;
    final height = widget.isSmall ? 32.0 : 64.0;

    return MouseRegion(
      onEnter: enabled ? (_) => setState(() => _hovering = true) : null,
      onExit: enabled ? (_) => setState(() => _hovering = false) : null,
      cursor:
          enabled ? SystemMouseCursors.click : SystemMouseCursors.forbidden,
      child: GestureDetector(
        onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
        onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
        onTapCancel:
            enabled ? () => setState(() => _pressed = false) : null,
        onTap: widget.onPressed,
        child: SizedBox(
          width: width,
          height: height,
          child: Transform.translate(
            offset: _pressed ? const Offset(0, 1) : Offset.zero,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ColorFiltered(
                  colorFilter: _tint,
                  child: Image.asset(
                    _asset,
                    width: width,
                    height: height,
                    fit: BoxFit.fill,
                    filterQuality: FilterQuality.none,
                    errorBuilder: (context, error, stack) => _FallbackFace(
                      width: width,
                      height: height,
                      enabled: enabled,
                      hovering: _hovering,
                      pressed: _pressed,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: enabled
                          ? AppColors.brightGold
                          : AppColors.parchment.withValues(alpha: 0.5),
                      fontSize: widget.isSmall ? 12 : 14,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FallbackFace extends StatelessWidget {
  final double width;
  final double height;
  final bool enabled;
  final bool hovering;
  final bool pressed;

  const _FallbackFace({
    required this.width,
    required this.height,
    required this.enabled,
    this.hovering = false,
    this.pressed = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color bg;
    if (!enabled) {
      bg = AppColors.woodMid.withValues(alpha: 0.4);
    } else if (pressed) {
      bg = AppColors.darkWalnut;
    } else if (hovering) {
      bg = AppColors.woodMid.withValues(alpha: 1.0);
    } else {
      bg = AppColors.woodMid;
    }
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bg,
        border: Border.all(
          color: enabled
              ? (hovering ? AppColors.brightGold : AppColors.gold)
              : AppColors.gold.withValues(alpha: 0.4),
          width: pressed ? 2 : 1,
        ),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
