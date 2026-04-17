import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SteampunkButton extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.woodMid,
        foregroundColor: AppColors.gold,
        padding: EdgeInsets.symmetric(
          horizontal: isSmall ? 12 : 20,
          vertical: isSmall ? 6 : 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: const BorderSide(color: AppColors.gold),
        ),
      ),
      child: Text(label, style: TextStyle(fontSize: isSmall ? 12 : 14)),
    );
  }
}
