import 'package:dol/data/models/book_model.dart';
import 'package:dol/presentation/simulators/structure_assembly_simulator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Phase 2 Task 2-6b: StructureAssemblySimulator 인터랙션 회귀 가드.
///
/// 기존 `structure_assembly_simulator_test.dart`는 smoke(렌더링) 레벨만
/// 커버한다. 본 파일은 드래그·탭·판정·재시도 흐름의 상태 변화를 검증해
/// 향후 GraphValidator 교체나 onComplete 정책 변경이 UI를 깨뜨리지 않도록 한다.
void main() {
  const gateway = PaletteItem(
    id: 'gateway',
    label: 'API Gateway',
    spriteKey: 'gateway',
  );
  const serviceA = PaletteItem(
    id: 'serviceA',
    label: 'Service A',
    spriteKey: 'service',
  );
  const serviceB = PaletteItem(
    id: 'serviceB',
    label: 'Service B',
    spriteKey: 'service',
  );

  StructureAssemblyConfig config() {
    return const StructureAssemblyConfig(
      gridSize: GridSize(cols: 5, rows: 5),
      palette: [gateway, serviceA, serviceB],
      solution: AssemblySolution(
        nodes: [
          AssemblyNode(id: 'gateway', pos: GridPos(col: 2, row: 0)),
          AssemblyNode(id: 'serviceA', pos: GridPos(col: 1, row: 2)),
          AssemblyNode(id: 'serviceB', pos: GridPos(col: 3, row: 2)),
        ],
        edges: [
          AssemblyEdge(from: 'gateway', to: 'serviceA'),
          AssemblyEdge(from: 'gateway', to: 'serviceB'),
        ],
      ),
      partialFeedback: PartialFeedback(
        missingNodes: 'missing: {names}',
        missingEdges: 'missing edges: {pairs}',
        extraEdges: 'extra edges: {pairs}',
      ),
    );
  }

  Widget harness({VoidCallback? onComplete}) {
    return MaterialApp(
      home: Scaffold(
        body: SingleChildScrollView(
          child: StructureAssemblySimulator(
            config: config(),
            onComplete: onComplete ?? () {},
          ),
        ),
      ),
    );
  }

  /// 팔레트 Draggable과 캔버스 DragTarget 사이의 드래그를 실행한다.
  /// flutter_test의 `tester.drag`는 픽셀 offset을 요구해 그리드 셀 위치
  /// 계산이 필요하다. 여기서는 start/moveTo/up을 직접 써 정확히 원하는 셀로
  /// 보낸다.
  Future<void> dragPaletteToCell(
    WidgetTester tester,
    String paletteLabel,
    int targetDragTargetIndex,
  ) async {
    final paletteFinder = find.text(paletteLabel).first;
    final dragTargets = find.byType(DragTarget<PaletteItem>);
    final gesture = await tester.startGesture(tester.getCenter(paletteFinder));
    // Draggable은 기본 delay 없이 kind=pointer 드래그에 반응한다. 작은 이동으로
    // 먼저 움직임을 감지하게 한 뒤 실제 타깃으로 이동한다.
    await tester.pump(const Duration(milliseconds: 100));
    await gesture.moveBy(const Offset(20, 0));
    await tester.pump();
    await gesture.moveTo(tester.getCenter(dragTargets.at(targetDragTargetIndex)));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();
  }

  int cellIndex(int col, int row, int cols) => row * cols + col;

  /// 액션 버튼(판정/리셋)이 SingleChildScrollView 하단에 위치해 기본 800x600
  /// 테스트 뷰포트 밖으로 밀려나는 경우가 있다. 탭 전에 반드시 가시 영역으로
  /// 스크롤한다.
  Future<void> tapByText(WidgetTester tester, String text) async {
    final finder = find.text(text);
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// 기본 800x600 뷰포트는 시뮬레이터 레이아웃(헤더 + 팔레트/캔버스 + 액션
  /// + 결과 패널)을 모두 수용하지 못해 액션 버튼이 화면 밖으로 밀린다.
  /// 리셋→재배치 시나리오는 scroll 관리가 fragile해지므로 뷰포트를 확장한다.
  Future<void> pumpSimulator(
    WidgetTester tester, {
    VoidCallback? onComplete,
  }) async {
    tester.view.physicalSize = const Size(1200, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpWidget(harness(onComplete: onComplete));
  }

  group('StructureAssemblySimulator 인터랙션', () {
    testWidgets('팔레트→캔버스 드롭이 성공하면 배치 카운터 증가', (tester) async {
      await pumpSimulator(tester);
      expect(find.text('배치 0 / 연결 0'), findsOneWidget);

      await dragPaletteToCell(
          tester, 'API Gateway', cellIndex(2, 0, 5));

      expect(find.text('배치 1 / 연결 0'), findsOneWidget);
      // 캔버스에 배치된 노드 라벨이 렌더되며 팔레트에도 여전히 존재
      expect(find.text('API Gateway'), findsNWidgets(2));
    });

    testWidgets('이미 점유된 셀에는 드롭이 무시된다', (tester) async {
      await pumpSimulator(tester);
      await dragPaletteToCell(
          tester, 'API Gateway', cellIndex(2, 0, 5));
      // 같은 셀에 Service A 드롭 시도 → 점유 중이라 거부
      await dragPaletteToCell(tester, 'Service A', cellIndex(2, 0, 5));

      expect(find.text('배치 1 / 연결 0'), findsOneWidget,
          reason: '점유된 셀은 두 번째 드롭을 거부해야 함');
    });

    testWidgets('첫 노드 탭 시 [연결 모드] 뱃지가 나타난다', (tester) async {
      await pumpSimulator(tester);
      await dragPaletteToCell(
          tester, 'API Gateway', cellIndex(2, 0, 5));

      // 팔레트에도 같은 라벨이 있으므로 placed 노드의 라벨을 찾아 탭
      final placedGateway = find.text('API Gateway').last;
      await tester.tap(placedGateway);
      await tester.pumpAndSettle();

      expect(find.text('[연결 모드]'), findsOneWidget);
    });

    testWidgets('노드 A→B 탭으로 엣지가 생성되고 연결 카운터가 증가', (tester) async {
      await pumpSimulator(tester);
      await dragPaletteToCell(
          tester, 'API Gateway', cellIndex(2, 0, 5));
      await dragPaletteToCell(
          tester, 'Service A', cellIndex(1, 2, 5));

      await tester.tap(find.text('API Gateway').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Service A').last);
      await tester.pumpAndSettle();

      expect(find.text('배치 2 / 연결 1'), findsOneWidget);
      expect(find.text('[연결 모드]'), findsNothing,
          reason: '엣지 생성 후 연결 모드는 자동 해제되어야 함');
    });

    testWidgets('같은 노드를 두 번 탭하면 self-loop 대신 연결 모드가 해제된다',
        (tester) async {
      await pumpSimulator(tester);
      await dragPaletteToCell(
          tester, 'API Gateway', cellIndex(2, 0, 5));

      final placed = find.text('API Gateway').last;
      await tester.tap(placed);
      await tester.pumpAndSettle();
      expect(find.text('[연결 모드]'), findsOneWidget);

      await tester.tap(placed);
      await tester.pumpAndSettle();

      expect(find.text('[연결 모드]'), findsNothing);
      expect(find.text('배치 1 / 연결 0'), findsOneWidget,
          reason: 'self-loop 엣지가 만들어지면 안 됨');
    });

    testWidgets('같은 방향 엣지 재생성 시도는 중복으로 무시된다', (tester) async {
      await pumpSimulator(tester);
      await dragPaletteToCell(
          tester, 'API Gateway', cellIndex(2, 0, 5));
      await dragPaletteToCell(
          tester, 'Service A', cellIndex(1, 2, 5));

      // 첫 연결 A→B
      await tester.tap(find.text('API Gateway').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Service A').last);
      await tester.pumpAndSettle();

      // 동일 방향 두 번째 시도
      await tester.tap(find.text('API Gateway').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Service A').last);
      await tester.pumpAndSettle();

      expect(find.text('배치 2 / 연결 1'), findsOneWidget,
          reason: '이미 존재하는 엣지는 중복 추가되지 않음');
    });

    testWidgets('배치된 노드 long-press 시 노드와 연결된 엣지가 함께 삭제된다',
        (tester) async {
      await pumpSimulator(tester);
      await dragPaletteToCell(
          tester, 'API Gateway', cellIndex(2, 0, 5));
      await dragPaletteToCell(
          tester, 'Service A', cellIndex(1, 2, 5));

      // A→B 엣지 생성
      await tester.tap(find.text('API Gateway').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Service A').last);
      await tester.pumpAndSettle();
      expect(find.text('배치 2 / 연결 1'), findsOneWidget);

      // Gateway long-press로 삭제
      await tester.longPress(find.text('API Gateway').last);
      await tester.pumpAndSettle();

      expect(find.text('배치 1 / 연결 0'), findsOneWidget,
          reason: '노드 삭제 시 그 노드와 연결된 엣지도 함께 제거되어야 함');
    });

    testWidgets('정답 완성 시 ValidationCorrect + onComplete 호출', (tester) async {
      var completeCount = 0;
      await pumpSimulator(tester, onComplete: () => completeCount++);

      // 정답 그래프 조립: Gateway(2,0), ServiceA(1,2), ServiceB(3,2)
      //  + Gateway→ServiceA, Gateway→ServiceB
      await dragPaletteToCell(
          tester, 'API Gateway', cellIndex(2, 0, 5));
      await dragPaletteToCell(
          tester, 'Service A', cellIndex(1, 2, 5));
      await dragPaletteToCell(
          tester, 'Service B', cellIndex(3, 2, 5));

      await tester.tap(find.text('API Gateway').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Service A').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('API Gateway').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Service B').last);
      await tester.pumpAndSettle();

      await tapByText(tester, '⚖ 판정');

      expect(find.text('✓ 통과!'), findsOneWidget);

      // onComplete는 1초 딜레이 후 호출
      await tester.pump(const Duration(seconds: 2));
      expect(completeCount, 1, reason: 'onComplete가 정확히 한 번 호출되어야 함');
    });

    testWidgets('오답 상태에서 판정 시 ValidationPartial 패널과 누락 피드백이 표시된다',
        (tester) async {
      await pumpSimulator(tester);

      // Gateway 하나만 배치 → 정답 그래프 대비 노드 2개, 엣지 2개 누락
      await dragPaletteToCell(
          tester, 'API Gateway', cellIndex(2, 0, 5));

      await tapByText(tester, '⚖ 판정');

      expect(find.text('⚡ 일부 틀림'), findsOneWidget);
      expect(find.textContaining('누락 노드'), findsOneWidget);
    });

    testWidgets('오답 후 리셋하면 상태가 초기화되고 재도전 가능', (tester) async {
      var completeCount = 0;
      await pumpSimulator(tester, onComplete: () => completeCount++);

      // 1차: 오답 (Gateway만 배치)
      await dragPaletteToCell(
          tester, 'API Gateway', cellIndex(2, 0, 5));
      await tapByText(tester, '⚖ 판정');
      expect(find.text('⚡ 일부 틀림'), findsOneWidget);

      // 리셋
      await tapByText(tester, '🔄 리셋');
      expect(find.text('배치 0 / 연결 0'), findsOneWidget);
      expect(find.text('⚡ 일부 틀림'), findsNothing,
          reason: '리셋 시 이전 판정 결과 패널도 제거');

      // 2차: 정답 재도전
      await dragPaletteToCell(
          tester, 'API Gateway', cellIndex(2, 0, 5));
      await dragPaletteToCell(
          tester, 'Service A', cellIndex(1, 2, 5));
      await dragPaletteToCell(
          tester, 'Service B', cellIndex(3, 2, 5));
      await tester.tap(find.text('API Gateway').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Service A').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('API Gateway').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Service B').last);
      await tester.pumpAndSettle();
      await tapByText(tester, '⚖ 판정');

      expect(find.text('✓ 통과!'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
      expect(completeCount, 1);
    });
  });
}
