import 'package:dol/domain/providers/game_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

/// fix-9 — R6 회귀 가드. 분관 책장 탭 시 `onShelfTappedCallback` 이 수행하는
/// `.set(category)` 직후 `.open()` 호출 시나리오에서, listener 없이도
/// filterCategory state 가 autoDispose 로 재초기화되지 않아야 한다.
///
/// 기존 버그: `@riverpod` 기본값(autoDispose) + `.set()` 호출 후 아직 watcher
/// 가 없는 상태 → Riverpod 이 provider 를 즉시 폐기 → state null 로 reset →
/// QuestBoardOverlay 가 렌더되며 `.watch()` 하면 null 을 관찰해 전체 책 노출.
/// 수정: `@Riverpod(keepAlive: true)` 로 전환하여 listener 와 무관하게 state
/// 보존.
void main() {
  group('game_providers keepAlive (fix-9)', () {
    test('QuestBoardFilterCategory.set 직후 read 가 같은 값 반환', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(questBoardFilterCategoryProvider.notifier)
          .set('msa');

      // 여기까지 watch 한 위젯/리스너 없음. 과거 autoDispose 였다면
      // 다음 read 에서 null 로 reset 되어야 했다.
      expect(
        container.read(questBoardFilterCategoryProvider),
        'msa',
      );
    });

    test('onShelfTapped 시나리오: set(category) 후 open() 하는 사이 state 유지',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // game_screen.dart onShelfTappedCallback 의 두 ref.read 순서 그대로.
      container
          .read(questBoardFilterCategoryProvider.notifier)
          .set('java-spring');
      container.read(questBoardOpenProvider.notifier).open();

      // 그 다음 "UI 가 열리며" watch.
      expect(
        container.read(questBoardFilterCategoryProvider),
        'java-spring',
      );
      expect(container.read(questBoardOpenProvider), isTrue);
    });

    test('CurrentWingId / CurrentScene 도 keepAlive (listener 없이 값 유지)',
        () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(currentSceneProvider.notifier).goTo(GameScene.wing);
      container.read(currentWingIdProvider.notifier).select('msa');

      expect(container.read(currentSceneProvider), GameScene.wing);
      expect(container.read(currentWingIdProvider), 'msa');
    });

    test('clear() 는 null 로 되돌리지만 이후 set() 도 보존', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container
          .read(questBoardFilterCategoryProvider.notifier)
          .set('dart');
      container.read(questBoardFilterCategoryProvider.notifier).clear();
      expect(container.read(questBoardFilterCategoryProvider), isNull);

      container
          .read(questBoardFilterCategoryProvider.notifier)
          .set('flutter');
      expect(
        container.read(questBoardFilterCategoryProvider),
        'flutter',
      );
    });
  });
}
