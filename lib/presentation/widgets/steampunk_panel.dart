import 'package:flutter/material.dart';
import '../../core/assets/asset_ids.dart';
import '../../core/constants/app_colors.dart';
import 'pixel_nine_slice.dart';

/// art-2: 9-slice `PixelNineSlice` 기반으로 재구성. 자산 미로드 시
/// placeholder 는 PixelNineSlice 가 담당 (Void Violet + gold outline).
class SteampunkPanel extends StatelessWidget {
  final Widget child;
  final String? title;

  const SteampunkPanel({super.key, required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    return PixelNineSlice(
      assetName: UiAssets.framePanel,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                color: AppColors.brightGold,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 1,
              color: AppColors.gold.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }
}
