import 'package:flutter_test/flutter_test.dart';
import 'package:dol/data/models/book_model.dart';

void main() {
  group('SimulatorConfig step progression', () {
    test('tracks current step index', () {
      const config = SimulatorConfig(
        type: SimulatorType.codeStep,
        steps: [
          SimStep(instruction: 'Step 1', code: 'int x = 1;', expectedState: {'x': 1}),
          SimStep(instruction: 'Step 2', code: 'int y = 2;', expectedState: {'y': 2}),
          SimStep(instruction: 'Step 3', code: 'int z = x + y;', expectedState: {'z': 3}),
        ],
        completionCriteria: CompletionRule(minStepsCompleted: 3),
      );

      expect(config.steps.length, 3);
      expect(config.completionCriteria.minStepsCompleted, 3);
    });
  });
}
