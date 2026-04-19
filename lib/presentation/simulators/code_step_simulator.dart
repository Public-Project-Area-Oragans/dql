import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../data/models/book_model.dart';
import '../widgets/steampunk_panel.dart';
import '../widgets/steampunk_button.dart';

class CodeStepSimulator extends StatefulWidget {
  final CodeStepConfig config;
  final VoidCallback onComplete;

  const CodeStepSimulator({
    super.key,
    required this.config,
    required this.onComplete,
  });

  @override
  State<CodeStepSimulator> createState() => _CodeStepSimulatorState();
}

class _CodeStepSimulatorState extends State<CodeStepSimulator> {
  int _currentStep = 0;
  final Map<String, dynamic> _state = {};
  bool _stepExecuted = false;

  SimStep get _step => widget.config.steps[_currentStep];
  bool get _isLast => _currentStep >= widget.config.steps.length - 1;

  void _executeStep() {
    setState(() {
      _state.addAll(_step.expectedState);
      _stepExecuted = true;
    });
  }

  void _nextStep() {
    if (_isLast) {
      widget.onComplete();
      return;
    }
    setState(() {
      _currentStep++;
      _stepExecuted = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '스텝 ${_currentStep + 1} / ${widget.config.steps.length}',
          style: const TextStyle(color: AppColors.gold, fontSize: 12),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: (_currentStep + (_stepExecuted ? 1 : 0)) /
              widget.config.steps.length,
          backgroundColor: AppColors.woodDark,
          valueColor: const AlwaysStoppedAnimation(AppColors.steamGreen),
        ),
        const SizedBox(height: 16),
        SteampunkPanel(
          title: '지시사항',
          child: Text(
            _step.instruction,
            style: const TextStyle(color: AppColors.parchment, fontSize: 14),
          ),
        ),
        const SizedBox(height: 12),
        SteampunkPanel(
          title: '코드',
          child: SelectableText(
            _step.code,
            style: const TextStyle(
              color: AppColors.steamGreen,
              fontFamily: 'JetBrainsMono',
              fontSize: 14,
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (_state.isNotEmpty)
          SteampunkPanel(
            title: '메모리 상태',
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              children: _state.entries.map((e) {
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.darkWalnut,
                    border: Border.all(color: AppColors.steamGreen),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    '${e.key} = ${e.value}',
                    style: const TextStyle(
                      color: AppColors.steamGreen,
                      fontFamily: 'JetBrainsMono',
                      fontSize: 13,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            if (!_stepExecuted)
              SteampunkButton(
                label: '▶ 실행',
                onPressed: _executeStep,
              )
            else
              SteampunkButton(
                label: _isLast ? '✓ 완료' : '다음 →',
                onPressed: _nextStep,
              ),
          ],
        ),
      ],
    );
  }
}
