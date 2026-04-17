import 'package:flutter/material.dart';
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
            child: Text(
              section.content,
              style: const TextStyle(
                color: AppColors.parchment,
                fontSize: 14,
                height: 1.6,
              ),
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
}
