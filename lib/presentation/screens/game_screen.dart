import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.darkWalnut,
      body: Center(
        child: Text(
          '중앙 홀 (Task 4에서 구현)',
          style: TextStyle(color: AppColors.parchment),
        ),
      ),
    );
  }
}
