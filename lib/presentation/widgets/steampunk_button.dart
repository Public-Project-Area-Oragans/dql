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
          child: Stack(
            alignment: Alignment.center,
            children: [
              Image.asset(
                _asset,
                width: width,
                height: height,
                fit: BoxFit.fill,
                filterQuality: FilterQuality.none,
                errorBuilder: (context, error, stack) => _FallbackFace(
                  width: width,
                  height: height,
                  enabled: enabled,
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
    );
  }
}

class _FallbackFace extends StatelessWidget {
  final double width;
  final double height;
  final bool enabled;

  const _FallbackFace({
    required this.width,
    required this.height,
    required this.enabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: AppColors.woodMid,
        border: Border.all(
          color: enabled
              ? AppColors.gold
              : AppColors.gold.withValues(alpha: 0.4),
        ),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
