import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:blight/blight.dart';

void main() {
  // Example: generate mutants from a Dart source string
  const source = '''
int add(int a, int b) {
  return a + b;
}
''';

  final config = BlightConfig.defaults(projectRoot: '.');
  print('Blight config: ${config.operators.length} operators enabled');

  final operator = ArithmeticMutationOperator();
  final unit = parseString(content: source).unit;
  final mutants = operator.generate(unit, 'example.dart', source);

  for (final mutant in mutants) {
    print('  ${mutant.description} at line ${mutant.lineNumber}');
  }
}
