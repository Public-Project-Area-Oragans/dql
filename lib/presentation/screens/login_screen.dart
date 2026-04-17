import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkWalnut,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Dev Quest Library',
              style: Theme.of(context).textTheme.headlineLarge,
            ),
            const SizedBox(height: 8),
            Text(
              '마법 도서관에서 개발을 배우다',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.gold,
                  ),
            ),
            const SizedBox(height: 48),
            ElevatedButton(
              onPressed: () => context.go('/game'),
              child: const Text('GitHub로 로그인'),
            ),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => context.go('/game'),
              child: const Text(
                '로그인 없이 시작',
                style: TextStyle(color: AppColors.parchment),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
