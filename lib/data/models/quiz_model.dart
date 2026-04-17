import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz_model.freezed.dart';
part 'quiz_model.g.dart';

enum QuizType { multipleChoice, codeFill, oxJudge }

@freezed
abstract class QuizQuestion with _$QuizQuestion {
  const factory QuizQuestion({
    required QuizType type,
    required String prompt,
    required List<String> options,
    required String correctAnswer,
    required String explanation,
  }) = _QuizQuestion;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) =>
      _$QuizQuestionFromJson(json);
}

@freezed
abstract class MixedQuiz with _$MixedQuiz {
  const factory MixedQuiz({
    required List<QuizQuestion> questions,
    @Default(3) int passThreshold,
  }) = _MixedQuiz;

  factory MixedQuiz.fromJson(Map<String, dynamic> json) =>
      _$MixedQuizFromJson(json);
}
