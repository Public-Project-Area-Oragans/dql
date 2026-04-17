import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/book_model.dart';
import 'steampunk_panel.dart';

class TheoryCard extends StatelessWidget {
  final TheoryContent theory;

  const TheoryCard({super.key, required this.theory});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final section in theory.sections) ...[
          SteampunkPanel(
            title: section.title,
            child: MarkdownBody(
              data: section.content,
              selectable: true,
              styleSheet: _markdownStyle(context),
            ),
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
            SteampunkPanel(
              title: '${code.language} — ${code.description}',
              child: SelectableText(
                code.code,
                style: const TextStyle(
                  color: AppColors.steamGreen,
                  fontFamily: 'monospace',
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
        fontFamily: 'monospace',
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
