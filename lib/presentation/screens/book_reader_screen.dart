import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';

class BookReaderScreen extends StatelessWidget {
  final String bookId;
  final String chapterId;

  const BookReaderScreen({
    super.key,
    required this.bookId,
    required this.chapterId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('$bookId / $chapterId'),
        backgroundColor: AppColors.deepPurple,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/game'),
        ),
      ),
      body: const Center(
        child: Text(
          '책 열람 화면 (Task 8에서 구현)',
          style: TextStyle(color: AppColors.parchment),
        ),
      ),
    );
  }
}
