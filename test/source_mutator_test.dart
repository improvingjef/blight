import 'package:blight/blight.dart';
import 'package:test/test.dart';

void main() {
  group('SourceMutator', () {
    test('replaces text at correct offset', () {
      const source = 'var x = a + b;';
      final mutant = Mutant(
        filePath: 'test.dart',
        lineNumber: 1,
        originalCode: '+',
        mutatedCode: '-',
        operatorName: 'arithmetic',
        description: 'replaced + with -',
        offset: 10,
        length: 1,
      );

      final result = SourceMutator.apply(source, mutant);
      expect(result, equals('var x = a - b;'));
    });

    test('handles replacement with longer text', () {
      const source = 'if (a > b) {}';
      final mutant = Mutant(
        filePath: 'test.dart',
        lineNumber: 1,
        originalCode: '>',
        mutatedCode: '>=',
        operatorName: 'conditional_boundary',
        description: 'changed > to >=',
        offset: 6,
        length: 1,
      );

      final result = SourceMutator.apply(source, mutant);
      expect(result, equals('if (a >= b) {}'));
    });

    test('handles replacement with shorter text', () {
      const source = 'if (a >= b) {}';
      final mutant = Mutant(
        filePath: 'test.dart',
        lineNumber: 1,
        originalCode: '>=',
        mutatedCode: '>',
        operatorName: 'conditional_boundary',
        description: 'changed >= to >',
        offset: 6,
        length: 2,
      );

      final result = SourceMutator.apply(source, mutant);
      expect(result, equals('if (a > b) {}'));
    });

    test('handles deletion (empty replacement)', () {
      const source = 'doSomething();\nreturn x;';
      final mutant = Mutant(
        filePath: 'test.dart',
        lineNumber: 1,
        originalCode: 'doSomething();',
        mutatedCode: '',
        operatorName: 'statement_deletion',
        description: 'removed statement',
        offset: 0,
        length: 14,
      );

      final result = SourceMutator.apply(source, mutant);
      expect(result, equals('\nreturn x;'));
    });

    test('handles replacement at start of string', () {
      const source = 'true && false';
      final mutant = Mutant(
        filePath: 'test.dart',
        lineNumber: 1,
        originalCode: 'true',
        mutatedCode: 'false',
        operatorName: 'literal',
        description: 'replaced true with false',
        offset: 0,
        length: 4,
      );

      final result = SourceMutator.apply(source, mutant);
      expect(result, equals('false && false'));
    });

    test('handles replacement at end of string', () {
      const source = 'var x = true;';
      final mutant = Mutant(
        filePath: 'test.dart',
        lineNumber: 1,
        originalCode: 'true',
        mutatedCode: 'false',
        operatorName: 'literal',
        description: 'replaced true with false',
        offset: 8,
        length: 4,
      );

      final result = SourceMutator.apply(source, mutant);
      expect(result, equals('var x = false;'));
    });

    test('throws on negative offset', () {
      const source = 'var x = 1;';
      final mutant = Mutant(
        filePath: 'test.dart',
        lineNumber: 1,
        originalCode: '1',
        mutatedCode: '2',
        operatorName: 'literal',
        description: 'replaced 1 with 2',
        offset: -1,
        length: 1,
      );

      expect(() => SourceMutator.apply(source, mutant), throwsRangeError);
    });

    test('throws when mutation extends beyond source', () {
      const source = 'var x = 1;';
      final mutant = Mutant(
        filePath: 'test.dart',
        lineNumber: 1,
        originalCode: '1;',
        mutatedCode: '2;',
        operatorName: 'literal',
        description: 'test',
        offset: 9,
        length: 5,
      );

      expect(() => SourceMutator.apply(source, mutant), throwsRangeError);
    });

    test('preserves multiline source correctly', () {
      const source = '''int compute(int a, int b) {
  var result = a + b;
  return result;
}''';
      // Find the + offset
      final offset = source.indexOf('+');
      final mutant = Mutant(
        filePath: 'test.dart',
        lineNumber: 2,
        originalCode: '+',
        mutatedCode: '-',
        operatorName: 'arithmetic',
        description: 'replaced + with -',
        offset: offset,
        length: 1,
      );

      final result = SourceMutator.apply(source, mutant);
      expect(result, contains('a - b'));
      expect(result, contains('return result;'));
    });
  });
}
