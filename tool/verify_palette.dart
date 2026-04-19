import 'dart:io';

import 'package:image/image.dart';

/// Bible §2.1 16색 잠긴 팔레트 검증 도구.
///
/// 각 PNG 의 모든 불투명 픽셀을 스캔해 Bible 팔레트 외부 색상 비율 + 순흑/순백
/// 사용 여부를 측정. 허용 기준:
///
/// - §7.1: 팔레트 외 색상 비율 ≤ 2%
/// - §2.2: 순흑(`#000000`) / 순백(`#FFFFFF`) 0%
///
/// 위반 시 해당 파일 fail. 하나라도 fail 있으면 exit 1.
///
/// 사용법:
///   dart run tool/verify_palette.dart [path]
///     path 기본 `assets/sprites/`.
///
/// 앵커 (`_anchors/`) 는 PixelLab 생성 결과로 AA 엣지가 일부 섞일 수 있어
/// 2% 허용을 벗어날 가능성이 있음. 앵커가 실패해도 그 자체는 스타일 기준이지
/// 엄격 팔레트 준수 대상은 아님 — 경고만 출력하고 fail 집계에서 제외.
Future<void> main(List<String> args) async {
  final root = args.isNotEmpty ? args[0] : 'assets/sprites';
  final dir = Directory(root);
  if (!dir.existsSync()) {
    stderr.writeln('ERROR: 디렉토리 없음 $root');
    exit(2);
  }

  final files = dir
      .listSync(recursive: true)
      .whereType<File>()
      .where((f) => f.path.toLowerCase().endsWith('.png'))
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  if (files.isEmpty) {
    stdout.writeln('NOTE: $root 에 PNG 없음. 검증 대상 0.');
    return;
  }

  var passed = 0;
  var failed = 0;
  var warnedAnchors = 0;

  for (final f in files) {
    final isAnchor = f.path.replaceAll('\\', '/').contains('/_anchors/');
    final result = _analyze(f);
    if (result == null) {
      stderr.writeln('? $f — 디코딩 실패');
      failed++;
      continue;
    }
    final ratio = result.outOfPalette / (result.totalOpaque == 0
        ? 1
        : result.totalOpaque);
    final ok = ratio <= 0.02 && result.pureBlack == 0 && result.pureWhite == 0;

    if (ok) {
      passed++;
      stdout.writeln(
        '  ✓ ${f.path} — out ${_pct(ratio)}, black ${result.pureBlack}, white ${result.pureWhite}',
      );
    } else if (isAnchor) {
      warnedAnchors++;
      stdout.writeln(
        '  ⚠ ${f.path} — out ${_pct(ratio)}, black ${result.pureBlack}, white ${result.pureWhite} (anchor — warning only)',
      );
    } else {
      failed++;
      stderr.writeln(
        '  ✗ ${f.path} — out ${_pct(ratio)}, black ${result.pureBlack}, white ${result.pureWhite}',
      );
    }
  }

  stdout.writeln(
    '\nDone. passed=$passed, warned(anchor)=$warnedAnchors, failed=$failed',
  );
  if (failed > 0) exit(1);
}

class _Analysis {
  final int totalOpaque;
  final int outOfPalette;
  final int pureBlack;
  final int pureWhite;

  _Analysis({
    required this.totalOpaque,
    required this.outOfPalette,
    required this.pureBlack,
    required this.pureWhite,
  });
}

_Analysis? _analyze(File f) {
  final bytes = f.readAsBytesSync();
  final img = decodeImage(bytes);
  if (img == null) return null;

  var totalOpaque = 0;
  var outOfPalette = 0;
  var pureBlack = 0;
  var pureWhite = 0;

  for (var y = 0; y < img.height; y++) {
    for (var x = 0; x < img.width; x++) {
      final p = img.getPixel(x, y);
      final a = p.a.toInt();
      if (a == 0) continue; // 완전 투명 skip
      totalOpaque++;
      final r = p.r.toInt();
      final g = p.g.toInt();
      final b = p.b.toInt();

      if (r == 0 && g == 0 && b == 0) pureBlack++;
      if (r == 255 && g == 255 && b == 255) pureWhite++;

      if (!_bibleSixteen.contains(_rgbToHex(r, g, b))) {
        outOfPalette++;
      }
    }
  }

  return _Analysis(
    totalOpaque: totalOpaque,
    outOfPalette: outOfPalette,
    pureBlack: pureBlack,
    pureWhite: pureWhite,
  );
}

int _rgbToHex(int r, int g, int b) => (r << 16) | (g << 8) | b;

/// Bible §2.1 16색 잠긴 팔레트 (0x prefix 없이 24-bit hex int).
final Set<int> _bibleSixteen = <int>{
  0x0f0b07, // Midnight Bark
  0x1a130c, // Old Oak
  0x2d2015, // Walnut
  0x4a3620, // Amber Leather
  0x7a5a34, // Warm Brass
  0xb8860b, // Dark Goldenrod
  0xd4a845, // Polished Gold
  0x8b5e1a, // Tarnished Bronze
  0x3a1a55, // Void Violet
  0x7b3ea8, // Arcane Purple
  0xb479e8, // Glowing Lilac
  0x1c3a2e, // Deep Moss
  0x3e7a5a, // Steam Verdigris
  0x7de0a8, // Ectoplasm Green
  0xe8dcc4, // Parchment
  // Bible §2.1 는 15개 명시 색상 + Parchment = 16. 마지막 자리는
  // 프로젝트 확장 여지 — 현재는 빈 슬롯.
};

String _pct(double v) => '${(v * 100).toStringAsFixed(2)}%';
