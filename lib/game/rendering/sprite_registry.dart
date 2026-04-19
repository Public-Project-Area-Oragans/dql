import 'dart:ui' as ui;

import 'package:flame/cache.dart';

/// 스프라이트 배치 프리로더 + 로드 완료 조회 유틸.
///
/// `PIXEL_ART_ASSET_MANIFEST.md` §8.1 3-단계 로딩 (Preload / SceneLoad /
/// OnDemand) 중 "Preload" 단계에서 `DolGame.onLoad` 가 호출. Flame `Images`
/// 인스턴스를 받아 대량 preload 하고, 이후 씬 / 위젯은 `has(id)` 로 로드
/// 여부를 확인해 사용 가능하면 스프라이트, 아니면 placeholder 로 분기.
///
/// art-2 ~ art-9 이 점진적으로 자산을 추가함. 미로드 자산은 `has()` → false.
class SpriteRegistry {
  SpriteRegistry._();

  static final Set<String> _loadedIds = <String>{};
  static Images? _images;

  /// `DolGame.onLoad` 등에서 1회 호출. 주어진 asset id 리스트를
  /// Flame `Images.loadAll` 로 일괄 프리로드.
  ///
  /// 실패한 ID 는 console 로깅 후 skip — 누락 자산이 있어도 아직 구현되지
  /// 않은 art-* PR 이 있을 수 있으므로 치명적 오류는 아님.
  static Future<void> preload({
    required Images images,
    required List<String> ids,
  }) async {
    _images = images;
    for (final id in ids) {
      try {
        await images.load(id);
        _loadedIds.add(id);
      } catch (e) {
        // 자산 미존재 / 파일 손상 등. 해당 id 는 has() 에서 false 반환.
        // 프로덕션 씬은 placeholder fallback 으로 안전하게 렌더.
      }
    }
  }

  /// 지정된 자산 id 가 로드되었는가? 씬이 스프라이트 vs placeholder 분기에 사용.
  static bool has(String id) => _loadedIds.contains(id);

  /// 로드된 자산의 실제 ui.Image 반환. 미로드 id 는 `StateError` throw.
  /// 반드시 `has(id)` 로 확인 후 호출.
  static ui.Image get(String id) {
    final img = _images?.fromCache(id);
    if (img == null) {
      throw StateError('Sprite "$id" not loaded. Call preload first.');
    }
    return img;
  }

  /// 테스트·리셋 용도 — 로드 상태 모두 해제.
  static void reset() {
    _loadedIds.clear();
    _images = null;
  }
}
