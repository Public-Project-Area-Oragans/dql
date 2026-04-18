import 'package:dol/app.dart';
import 'package:dol/core/router/app_router.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

/// Phase 2 Task 2-6c: MSA Service Discovery 챕터의 시뮬레이터 완주 E2E.
///
/// 실사용 환경과 가장 근접한 계층에서:
///   1. 실제 번들 assets(content/books/msa/book.json) 로드
///   2. 실제 Riverpod allBooksProvider / bookByIdProvider 해석
///   3. 실제 go_router 라우팅 (/book/:bookId/chapter/:chapterId)
///   4. 실제 Draggable / DragTarget / GraphValidator 경로
///   5. 정답 조립 → ValidationCorrect → onComplete SnackBar
///
/// 중앙 홀 → Flame 월드 → NPC → 책장 내비게이션은 UI 실험이 많아 fragile.
/// 본 테스트는 **직접 챕터 URL로 진입**해 시뮬레이터 자체를 E2E로 가드한다.
/// 향후 Flame 네비 E2E가 필요하면 별도 테스트 파일로 분리.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  void mark(String step) {
    // ignore: avoid_print
    print('[integration-step] $step');
  }

  testWidgets(
    'MSA Service Discovery 챕터 시뮬레이터 완주 → 완료 SnackBar 표시',
    (tester) async {
      mark('begin');

      // 레이아웃이 800x600 뷰포트에 모두 담기지 않으므로 확장. (기본 뷰포트
      // 에서는 판정 버튼이 화면 밖으로 밀린다. 위젯 테스트 2-6b와 동일 전략.)
      tester.view.physicalSize = const Size(1280, 2000);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(const ProviderScope(child: DolApp()));
      mark('DolApp pumped');

      // allBooksProvider(Future)가 rootBundle에서 book.json을 읽어올 시간.
      // 웹 빌드에서는 asset 로드가 네트워크 fetch 수준으로 느릴 수 있어
      // settle 시간을 넉넉히 (위젯 테스트보다 길게).
      await tester.pumpAndSettle(const Duration(seconds: 5));
      mark('initial settle done');

      // 책 상세(챕터) 화면으로 직접 이동.
      appRouter.go(
        '/book/msa/chapter/msa-phase4-step2-service-discovery',
      );
      mark('router.go issued');
      await tester.pumpAndSettle(const Duration(seconds: 5));
      mark('post-navigation settle done');

      // 챕터 제목이 AppBar에 표시되어야 함.
      expect(
        find.textContaining('Service Discovery'),
        findsWidgets,
        reason: 'BookReaderScreen이 해당 챕터를 로드해야 함',
      );
      mark('chapter loaded');

      // 시뮬레이터 탭 진입.
      await tester.tap(find.text('⚡ 시뮬레이터'));
      await tester.pumpAndSettle();
      mark('simulator tab active');

      // Override 스키마가 구조 조립 시뮬레이터로 해석되었는지 확인.
      expect(
        find.text('🪙 조립 과제'),
        findsOneWidget,
        reason: 'StructureAssemblyConfig override가 적용되어야 함',
      );
      mark('assembly header visible');

      // 해법 그래프(override JSON 기준):
      //   client(0,2), registry(2,2), instance1(4,1), instance2(4,3)
      //   edges: client→registry, instance1→registry, instance2→registry,
      //          client→instance1, client→instance2
      Future<void> dropAtCell(String paletteLabel, int col, int row) async {
        final paletteFinder = find.text(paletteLabel).first;
        final targetIndex = row * 5 + col;
        final dragTargets = find.byType(DragTarget);
        final gesture = await tester.startGesture(
          tester.getCenter(paletteFinder),
        );
        await tester.pump(const Duration(milliseconds: 100));
        await gesture.moveBy(const Offset(20, 0));
        await tester.pump();
        await gesture.moveTo(
          tester.getCenter(dragTargets.at(targetIndex)),
        );
        await tester.pump();
        await gesture.up();
        await tester.pumpAndSettle();
      }

      Future<void> connect(String fromLabel, String toLabel) async {
        await tester.tap(find.text(fromLabel).last);
        await tester.pumpAndSettle();
        await tester.tap(find.text(toLabel).last);
        await tester.pumpAndSettle();
      }

      await dropAtCell('호출 클라이언트 (order-service)', 0, 2);
      mark('client placed');
      await dropAtCell('Service Registry', 2, 2);
      mark('registry placed');
      await dropAtCell('서비스 인스턴스 #1', 4, 1);
      mark('instance1 placed');
      await dropAtCell('서비스 인스턴스 #2', 4, 3);
      mark('instance2 placed');

      // 엣지 5개
      await connect(
          '호출 클라이언트 (order-service)', 'Service Registry');
      mark('edge client→registry');
      await connect('서비스 인스턴스 #1', 'Service Registry');
      mark('edge instance1→registry');
      await connect('서비스 인스턴스 #2', 'Service Registry');
      mark('edge instance2→registry');
      await connect(
          '호출 클라이언트 (order-service)', '서비스 인스턴스 #1');
      mark('edge client→instance1');
      await connect(
          '호출 클라이언트 (order-service)', '서비스 인스턴스 #2');
      mark('edge client→instance2');

      expect(find.text('배치 4 / 연결 5'), findsOneWidget,
          reason: '4 노드 + 5 엣지 조립 완료 상태');
      mark('graph assembled');

      // 판정
      final validateBtn = find.text('⚖ 판정');
      await tester.ensureVisible(validateBtn);
      await tester.pumpAndSettle();
      await tester.tap(validateBtn);
      await tester.pumpAndSettle();
      mark('validate tapped');

      expect(find.text('✓ 통과!'), findsOneWidget,
          reason: 'GraphValidator가 정답 그래프로 판정해야 함');
      mark('validation correct');

      // onComplete는 1초 delay 후 SnackBar 표시.
      await tester.pump(const Duration(seconds: 2));
      expect(
        find.text('구조 조립 완료!'),
        findsOneWidget,
        reason: 'BookReaderScreen의 onComplete SnackBar가 표시되어야 함',
      );
      mark('snackbar visible → test complete');
    },
  );
}
