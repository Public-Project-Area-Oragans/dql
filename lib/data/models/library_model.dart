import 'package:freezed_annotation/freezed_annotation.dart';
import 'npc_model.dart';
import 'book_model.dart';

part 'library_model.freezed.dart';
part 'library_model.g.dart';

@freezed
abstract class Bookshelf with _$Bookshelf {
  const factory Bookshelf({
    required String id,
    required String category,
    required List<Book> books,
  }) = _Bookshelf;

  factory Bookshelf.fromJson(Map<String, dynamic> json) =>
      _$BookshelfFromJson(json);
}

@freezed
abstract class Wing with _$Wing {
  const factory Wing({
    required String id,
    required String name,
    required String role,
    required NpcModel npc,
    required List<Bookshelf> shelves,
    required List<Spirit> spirits,
  }) = _Wing;

  factory Wing.fromJson(Map<String, dynamic> json) => _$WingFromJson(json);
}

@freezed
abstract class Library with _$Library {
  const factory Library({
    required String id,
    required String name,
    required List<Wing> wings,
  }) = _Library;

  factory Library.fromJson(Map<String, dynamic> json) =>
      _$LibraryFromJson(json);
}
