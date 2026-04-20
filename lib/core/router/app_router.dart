import 'package:go_router/go_router.dart';
import '../../presentation/screens/book_reader_screen.dart';
import '../../presentation/screens/debug_settings_screen.dart';
import '../../presentation/screens/debug_telemetry_screen.dart';
import '../../presentation/screens/game_screen.dart';
import '../../presentation/screens/login_screen.dart';
import '../../presentation/screens/title_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    // art-3: `/` 는 타이틀 씬. LoginScreen 은 `/login` 로 이동.
    GoRoute(
      path: '/',
      builder: (context, state) => const TitleScreen(),
    ),
    GoRoute(
      path: '/login',
      builder: (context, state) => const LoginScreen(),
    ),
    GoRoute(
      path: '/game',
      builder: (context, state) => const GameScreen(),
    ),
    GoRoute(
      path: '/book/:bookId/chapter/:chapterId',
      builder: (context, state) {
        final bookId = state.pathParameters['bookId']!;
        final chapterId = state.pathParameters['chapterId']!;
        return BookReaderScreen(bookId: bookId, chapterId: chapterId);
      },
    ),
    GoRoute(
      path: '/debug/telemetry',
      builder: (context, state) => const DebugTelemetryScreen(),
    ),
    GoRoute(
      path: '/debug/settings',
      builder: (context, state) => const DebugSettingsScreen(),
    ),
  ],
);
