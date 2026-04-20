import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/assets/asset_ids.dart';
import '../../core/constants/app_colors.dart';

/// art-3: 타이틀 씬 — Flutter 정적 이미지 (Manifest §1.3).
///
/// 배경 픽셀아트 + 로고 + 깜빡이는 "PRESS TO START" + 탭 시 `/game` 이동.
/// Manifest §3.2 정수 배율 · §9.1 FilterQuality.none 준수.
class TitleScreen extends StatefulWidget {
  const TitleScreen({super.key});

  @override
  State<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends State<TitleScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _blink;

  @override
  void initState() {
    super.initState();
    _blink = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _blink.dispose();
    super.dispose();
  }

  void _start() {
    context.go('/game');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkWalnut,
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _start,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // 배경: cover 로 전체 화면 확대. FilterQuality.none 필수.
            Image.asset(
              EnvironmentAssets.titleBg,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.none,
              errorBuilder: (_, _, _) =>
                  const ColoredBox(color: AppColors.darkWalnut),
            ),
            // 위에서 아래로 암막 그라데이션 — 로고·텍스트 가독성 확보.
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0x66000000),
                    Color(0xCC0F0B07),
                  ],
                  stops: [0.0, 0.55, 1.0],
                ),
              ),
              child: SizedBox.expand(),
            ),
            // 로고 + press to start.
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    UiAssets.logoTitle,
                    filterQuality: FilterQuality.none,
                    width: 512,
                    errorBuilder: (_, _, _) => const Text(
                      'DEV QUEST LIBRARY',
                      style: TextStyle(
                        color: AppColors.brightGold,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '마법 도서관에서 개발을 배우다',
                    style: TextStyle(
                      color: AppColors.parchment,
                      fontSize: 14,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 80),
                  FadeTransition(
                    opacity: _blink,
                    child: const Text(
                      'PRESS TO START',
                      style: TextStyle(
                        color: AppColors.brightGold,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 하단: 로그인 route 진입점 (현재 비활성화된 GitHub 플로우 보존).
            Positioned(
              bottom: 20,
              right: 20,
              child: TextButton(
                onPressed: () => context.go('/login'),
                child: Text(
                  'GitHub 로그인 →',
                  style: TextStyle(
                    color: AppColors.parchment.withValues(alpha: 0.6),
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
