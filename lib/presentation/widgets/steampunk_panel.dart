import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class SteampunkPanel extends StatelessWidget {
  final Widget child;
  final String? title;

  const SteampunkPanel({super.key, required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.deepPurple,
        border: Border.all(color: AppColors.gold, width: 1.5),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (title != null)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: AppColors.gold)),
              ),
              child: Text(
                title!,
                style: const TextStyle(
                  color: AppColors.brightGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: child,
          ),
        ],
      ),
    );
  }
}
