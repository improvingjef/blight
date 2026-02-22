import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:blight/blight.dart';
import 'package:test/test.dart';

void main() {
  group('ArithmeticMutationOperator', () {
    late ArithmeticMutationOperator operator;

    setUp(() {
      operator = ArithmeticMutationOperator();
    });

    test('has correct name', () {
      expect(operator.name, equals('arithmetic'));
    });

    test('generates + -> - mutation', () {
      const source = '''
int add(int a, int b) {
  return a + b;
}
''';
      final unit = parseString(content: source).unit;
      final mutants = operator.generate(unit, 'test.dart', source);

      expect(mutants, isNotEmpty);
      final plusToMinus =
          mutants.where((m) => m.originalCode == '+' && m.mutatedCode == '-');
      expect(plusToMinus, isNotEmpty);
      expect(plusToMinus.first.operatorName, equals('arithmetic'));
      expect(plusToMinus.first.description, equals('replaced + with -'));
    });

    test('generates - -> + mutation', () {
      const source = '''
int subtract(int a, int b) {
  return a - b;
}
''';
      final unit = parseString(content: source).unit;
      final mutants = operator.generate(unit, 'test.dart', source);

      final minusToPlus =
          mutants.where((m) => m.originalCode == '-' && m.mutatedCode == '+');
      expect(minusToPlus, isNotEmpty);
    });

    test('generates * -> / mutation', () {
      const source = '''
int multiply(int a, int b) {
  return a * b;
}
''';
      final unit = parseString(content: source).unit;
      final mutants = operator.generate(unit, 'test.dart', source);

      final starToSlash =
          mutants.where((m) => m.originalCode == '*' && m.mutatedCode == '/');
      expect(starToSlash, isNotEmpty);
    });

    test('generates / -> * mutation', () {
      const source = '''
double divide(double a, double b) {
  return a / b;
}
''';
      final unit = parseString(content: source).unit;
      final mutants = operator.generate(unit, 'test.dart', source);

      final slashToStar =
          mutants.where((m) => m.originalCode == '/' && m.mutatedCode == '*');
      expect(slashToStar, isNotEmpty);
    });

    test('generates ~/ -> * mutation', () {
      const source = '''
int intDivide(int a, int b) {
  return a ~/ b;
}
''';
      final unit = parseString(content: source).unit;
      final mutants = operator.generate(unit, 'test.dart', source);

      final tildeDivToStar =
          mutants.where((m) => m.originalCode == '~/' && m.mutatedCode == '*');
      expect(tildeDivToStar, isNotEmpty);
    });

    test('generates % -> * mutation', () {
      const source = '''
int modulo(int a, int b) {
  return a % b;
}
''';
      final unit = parseString(content: source).unit;
      final mutants = operator.generate(unit, 'test.dart', source);

      final percentToStar =
          mutants.where((m) => m.originalCode == '%' && m.mutatedCode == '*');
      expect(percentToStar, isNotEmpty);
    });

    test('generates multiple mutations for multiple operators', () {
      const source = '''
int compute(int a, int b, int c) {
  return a + b * c;
}
''';
      final unit = parseString(content: source).unit;
      final mutants = operator.generate(unit, 'test.dart', source);

      // Should have at least 2 mutants: + -> - and * -> /
      expect(mutants.length, greaterThanOrEqualTo(2));
    });

    test('records correct line number', () {
      const source = '''
int foo() {
  var x = 1;
  return x + 2;
}
''';
      final unit = parseString(content: source).unit;
      final mutants = operator.generate(unit, 'test.dart', source);

      expect(mutants, isNotEmpty);
      // The + is on line 3
      expect(mutants.first.lineNumber, equals(3));
    });

    test('records correct offset and length', () {
      const source = 'var x = a + b;';
      final unit = parseString(content: source).unit;
      final mutants = operator.generate(unit, 'test.dart', source);

      expect(mutants, isNotEmpty);
      final mutant = mutants.first;
      expect(source.substring(mutant.offset, mutant.offset + mutant.length),
          equals('+'));
    });

    test('does not generate mutations for non-arithmetic operators', () {
      const source = '''
bool check(int a, int b) {
  return a == b && a > 0;
}
''';
      final unit = parseString(content: source).unit;
      final mutants = operator.generate(unit, 'test.dart', source);

      expect(mutants, isEmpty);
    });
  });
}
