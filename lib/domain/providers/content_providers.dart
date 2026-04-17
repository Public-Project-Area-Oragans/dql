import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import '../../data/models/book_model.dart';

part 'content_providers.g.dart';

const _bookCategories = ['java-spring', 'dart', 'flutter', 'mysql', 'msa'];

@riverpod
Future<List<Book>> allBooks(Ref ref) async {
  final books = <Book>[];
  for (final cat in _bookCategories) {
    try {
      final jsonStr = await rootBundle.loadString('content/books/$cat/book.json');
      final json = jsonDecode(jsonStr) as Map<String, dynamic>;
      books.add(Book.fromJson(json));
    } catch (_) {
      // 콘텐츠가 아직 빌드되지 않은 경우 스킵
    }
  }
  return books;
}

@riverpod
Book? bookById(Ref ref, String bookId) {
  final books = ref.watch(allBooksProvider).value ?? const [];
  return books.where((b) => b.id == bookId).firstOrNull;
}
