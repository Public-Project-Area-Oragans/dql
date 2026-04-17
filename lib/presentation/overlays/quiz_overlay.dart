import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/quiz_model.dart';

class QuizOverlay extends StatefulWidget {
  final MixedQuiz quiz;
  final VoidCallback onPass;
  final VoidCallback onFail;

  const QuizOverlay({
    super.key,
    required this.quiz,
    required this.onPass,
    required this.onFail,
  });

  @override
  State<QuizOverlay> createState() => _QuizOverlayState();
}

class _QuizOverlayState extends State<QuizOverlay> {
  int _currentIndex = 0;
  int _correctCount = 0;
  String? _selectedAnswer;
  bool _showResult = false;

  QuizQuestion get _current => widget.quiz.questions[_currentIndex];
  bool get _isLast => _currentIndex >= widget.quiz.questions.length - 1;

  void _submit() {
    if (_selectedAnswer == null) return;

    final isCorrect = _selectedAnswer == _current.correctAnswer;
    if (isCorrect) _correctCount++;

    if (_isLast) {
      setState(() => _showResult = true);
      if (_correctCount >= widget.quiz.passThreshold) {
        Future.delayed(const Duration(seconds: 2), widget.onPass);
      } else {
        Future.delayed(const Duration(seconds: 2), widget.onFail);
      }
    } else {
      setState(() {
        _currentIndex++;
        _selectedAnswer = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_showResult) {
      final passed = _correctCount >= widget.quiz.passThreshold;
      return Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: AppColors.deepPurple,
            border: Border.all(
              color: passed ? AppColors.steamGreen : Colors.red,
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                passed ? Icons.check_circle : Icons.cancel,
                color: passed ? AppColors.steamGreen : Colors.red,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                passed ? '통과!' : '재도전 필요',
                style: TextStyle(
                  color: passed ? AppColors.steamGreen : Colors.red,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                '$_correctCount / ${widget.quiz.questions.length} 정답',
                style: const TextStyle(color: AppColors.parchment),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.deepPurple,
          border: Border.all(color: AppColors.gold, width: 2),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '문제 ${_currentIndex + 1} / ${widget.quiz.questions.length}',
              style: const TextStyle(color: AppColors.gold, fontSize: 12),
            ),
            const SizedBox(height: 12),
            Text(
              _current.prompt,
              style: const TextStyle(
                color: AppColors.parchment,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            ..._current.options.map((option) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () => setState(() => _selectedAnswer = option),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: _selectedAnswer == option
                              ? AppColors.brightGold
                              : AppColors.gold.withValues(alpha: 0.3),
                          width: _selectedAnswer == option ? 2 : 1,
                        ),
                        borderRadius: BorderRadius.circular(4),
                        color: _selectedAnswer == option
                            ? AppColors.gold.withValues(alpha: 0.1)
                            : null,
                      ),
                      child: Text(
                        option,
                        style: const TextStyle(color: AppColors.parchment),
                      ),
                    ),
                  ),
                )),
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: ElevatedButton(
                onPressed: _selectedAnswer != null ? _submit : null,
                child: Text(_isLast ? '제출' : '다음'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
