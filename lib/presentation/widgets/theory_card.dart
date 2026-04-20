import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:markdown/markdown.dart' as md;
import '../../core/constants/app_colors.dart';
import '../../data/models/book_model.dart';
import 'blocks/content_block_renderer.dart';

// art-2b: 이론 탭은 R7 fix-10 시리즈(콘텐츠 재구성) 완료 전까지 9-slice
// SteampunkPanel 을 사용하지 않는다. framePanel 중앙부 텍스처가 텍스트와
// 겹쳐 가독성 치명 → 콘텐츠 레이아웃 안정화 후 재도입 예정.
class TheoryCard extends StatelessWidget {
  final TheoryContent theory;

  const TheoryCard({super.key, required this.theory});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in theory.sections) ...[
          _TheorySectionPanel(
            title: section.title,
            child: _sectionBody(context, section),
          ),
          const SizedBox(height: 16),
        ],
        if (theory.codeExamples.isNotEmpty) ...[
          const Text(
            '코드 예제',
            style: TextStyle(
              color: AppColors.brightGold,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          for (final code in theory.codeExamples) ...[
            _TheorySectionPanel(
              title: '${code.language} — ${code.description}',
              child: SelectableText(
                code.code,
                style: const TextStyle(
                  color: AppColors.steamGreen,
                  fontFamily: kMonospaceFamily,
                  fontFamilyFallback: kMonospaceFallback,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ],
    );
  }

  /// `section.blocks`가 비어있지 않으면 각 블록을 `ContentBlockRenderer`로
  /// 순서대로 렌더한다. 비어있는 경우 기존 `content`(markdown) 경로로 폴백
  /// (Phase 1 하위호환).
  Widget _sectionBody(BuildContext context, TheorySection section) {
    if (section.blocks.isEmpty) {
      return MarkdownBody(
        data: section.content,
        selectable: true,
        styleSheet: _markdownStyle(context),
        builders: {'pre': _ScrollablePreBuilder()},
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final block in section.blocks)
          ContentBlockRenderer(
            block: block,
            proseStyle: _markdownStyle(context),
            proseBuilders: {'pre': _ScrollablePreBuilder()},
          ),
      ],
    );
  }

  MarkdownStyleSheet _markdownStyle(BuildContext context) {
    const body = TextStyle(
      color: AppColors.parchment,
      fontSize: 14,
      height: 1.6,
    );
    return MarkdownStyleSheet(
      p: body,
      h1: const TextStyle(
        color: AppColors.brightGold,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
      h2: const TextStyle(
        color: AppColors.brightGold,
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
      h3: const TextStyle(
        color: AppColors.gold,
        fontSize: 14,
        fontWeight: FontWeight.bold,
      ),
      strong: body.copyWith(
        color: AppColors.brightGold,
        fontWeight: FontWeight.bold,
      ),
      em: body.copyWith(fontStyle: FontStyle.italic),
      a: const TextStyle(
        color: AppColors.magicPurple,
        decoration: TextDecoration.underline,
      ),
      listBullet: body,
      code: const TextStyle(
        color: AppColors.steamGreen,
        fontFamily: kMonospaceFamily,
        fontFamilyFallback: kMonospaceFallback,
        fontSize: 13,
        backgroundColor: AppColors.darkWalnut,
      ),
      codeblockDecoration: BoxDecoration(
        color: AppColors.darkWalnut,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      codeblockPadding: const EdgeInsets.all(10),
      blockquote: body.copyWith(color: AppColors.gold),
      blockquoteDecoration: const BoxDecoration(
        color: AppColors.deepPurple,
        border: Border(
          left: BorderSide(color: AppColors.gold, width: 3),
        ),
      ),
      blockquotePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      tableHead: const TextStyle(
        color: AppColors.brightGold,
        fontWeight: FontWeight.bold,
      ),
      tableBody: body,
      tableBorder: TableBorder.all(
        color: AppColors.gold.withValues(alpha: 0.4),
        width: 1,
      ),
      tableColumnWidth: const IntrinsicColumnWidth(),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
    );
  }
}

/// 코드펜스(`<pre>`) 블록을 가로 스크롤 가능한 monospace 박스로 렌더.
/// Task 12 Option B로 삽입된 ASCII 다이어그램이 뷰포트보다 길어도 줄바꿈 없이
/// 정렬을 유지하도록 한다.
class _ScrollablePreBuilder extends MarkdownElementBuilder {
  @override
  Widget visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.darkWalnut,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.all(10),
        child: SelectableText(
          element.textContent,
          style: const TextStyle(
            color: AppColors.steamGreen,
            fontFamily: kMonospaceFamily,
            fontFamilyFallback: kMonospaceFallback,
            fontSize: 13,
            height: 1.4,
          ),
        ),
      ),
    );
  }
}

/// art-2b: 이론 탭 전용 섹션 패널. `SteampunkPanel` (9-slice) 대체.
/// 평평한 darkWalnut 배경 + gold 테두리 + 제목/divider. 텍스처 겹침 없음.
class _TheorySectionPanel extends StatelessWidget {
  final String? title;
  final Widget child;

  const _TheorySectionPanel({required this.child, this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.darkWalnut,
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: const TextStyle(
                color: AppColors.brightGold,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 1,
              color: AppColors.gold.withValues(alpha: 0.4),
            ),
            const SizedBox(height: 8),
          ],
          child,
        ],
      ),
    );
  }
}
