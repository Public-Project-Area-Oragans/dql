import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../services/category_context_service.dart';
import 'content_providers.dart';

part 'category_context_providers.g.dart';

/// P0-5 NPC-5: 앱 전역 `CategoryContextService` 싱글턴.
/// `allBooksProvider.future`를 loadBooks로 주입.
@Riverpod(keepAlive: true)
CategoryContextService categoryContextService(Ref ref) {
  return CategoryContextService(
    loadBooks: () => ref.read(allBooksProvider.future),
  );
}
