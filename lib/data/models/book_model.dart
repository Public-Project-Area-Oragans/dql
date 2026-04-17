import 'package:freezed_annotation/freezed_annotation.dart';

part 'book_model.freezed.dart';
part 'book_model.g.dart';

enum SimulatorType {
  codeStep,
  blockAssembly,
  flowTrace,
  sqlLab,
}

@freezed
abstract class TheorySection with _$TheorySection {
  const factory TheorySection({
    required String title,
    required String content,
  }) = _TheorySection;

  factory TheorySection.fromJson(Map<String, dynamic> json) =>
      _$TheorySectionFromJson(json);
}

@freezed
abstract class CodeBlock with _$CodeBlock {
  const factory CodeBlock({
    required String language,
    required String code,
    required String description,
  }) = _CodeBlock;

  factory CodeBlock.fromJson(Map<String, dynamic> json) =>
      _$CodeBlockFromJson(json);
}

@freezed
abstract class DiagramData with _$DiagramData {
  const factory DiagramData({
    required String type,
    required String content,
  }) = _DiagramData;

  factory DiagramData.fromJson(Map<String, dynamic> json) =>
      _$DiagramDataFromJson(json);
}

@freezed
abstract class TheoryContent with _$TheoryContent {
  const factory TheoryContent({
    required List<TheorySection> sections,
    required List<CodeBlock> codeExamples,
    required List<DiagramData> diagrams,
  }) = _TheoryContent;

  factory TheoryContent.fromJson(Map<String, dynamic> json) =>
      _$TheoryContentFromJson(json);
}

@freezed
abstract class SimStep with _$SimStep {
  const factory SimStep({
    required String instruction,
    required String code,
    required Map<String, dynamic> expectedState,
  }) = _SimStep;

  factory SimStep.fromJson(Map<String, dynamic> json) =>
      _$SimStepFromJson(json);
}

@freezed
abstract class CompletionRule with _$CompletionRule {
  const factory CompletionRule({
    required int minStepsCompleted,
  }) = _CompletionRule;

  factory CompletionRule.fromJson(Map<String, dynamic> json) =>
      _$CompletionRuleFromJson(json);
}

@freezed
abstract class SimulatorConfig with _$SimulatorConfig {
  const factory SimulatorConfig({
    required SimulatorType type,
    required List<SimStep> steps,
    required CompletionRule completionCriteria,
  }) = _SimulatorConfig;

  factory SimulatorConfig.fromJson(Map<String, dynamic> json) =>
      _$SimulatorConfigFromJson(json);
}

@freezed
abstract class Chapter with _$Chapter {
  const factory Chapter({
    required String id,
    required String title,
    required int order,
    required TheoryContent theory,
    required SimulatorConfig simulator,
    @Default(false) bool isCompleted,
  }) = _Chapter;

  factory Chapter.fromJson(Map<String, dynamic> json) =>
      _$ChapterFromJson(json);
}

@freezed
abstract class Book with _$Book {
  const Book._();

  const factory Book({
    required String id,
    required String title,
    required String category,
    required List<Chapter> chapters,
  }) = _Book;

  double get totalProgress {
    if (chapters.isEmpty) return 0.0;
    final completed = chapters.where((c) => c.isCompleted).length;
    return completed / chapters.length;
  }

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
}
