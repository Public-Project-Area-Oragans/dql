import 'package:go_router/go_router.dart';
import '../../presentation/screens/book_reader_screen.dart';
import '../../presentation/screens/debug_telemetry_screen.dart';
import '../../presentation/screens/game_screen.dart';
import '../../presentation/screens/login_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
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
  ],
);
