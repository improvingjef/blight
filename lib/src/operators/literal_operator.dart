import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../mutant.dart';
import 'operator.dart';

/// Mutates literal values:
/// - true <-> false
/// - integer n -> n+1, and n -> 0 (if n != 0)
/// - string s -> empty string (if non-empty)
class LiteralMutationOperator extends MutationOperator {
  @override
  String get name => 'literal';

  @override
  List<Mutant> generate(
      CompilationUnit unit, String filePath, String source) {
    final visitor = _LiteralVisitor(filePath, source);
    unit.visitChildren(visitor);
    return visitor.mutants;
  }
}

class _LiteralVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final String source;
  final List<Mutant> mutants = [];

  _LiteralVisitor(this.filePath, this.source);

  @override
  void visitBooleanLiteral(BooleanLiteral node) {
    final original = node.value;
    final mutated = !original;

    mutants.add(Mutant(
      filePath: filePath,
      lineNumber: _lineNumberOf(source, node.offset),
      originalCode: '$original',
      mutatedCode: '$mutated',
      operatorName: 'literal',
      description: 'replaced $original with $mutated',
      offset: node.offset,
      length: node.length,
    ));

    super.visitBooleanLiteral(node);
  }

  @override
  void visitIntegerLiteral(IntegerLiteral node) {
    final value = node.value;
    if (value == null) {
      super.visitIntegerLiteral(node);
      return;
    }

    final originalText =
        source.substring(node.offset, node.offset + node.length);

    // n -> n + 1
    mutants.add(Mutant(
      filePath: filePath,
      lineNumber: _lineNumberOf(source, node.offset),
      originalCode: originalText,
      mutatedCode: '${value + 1}',
      operatorName: 'literal',
      description: 'replaced $value with ${value + 1}',
      offset: node.offset,
      length: node.length,
    ));

    // n -> 0 (if n != 0)
    if (value != 0) {
      mutants.add(Mutant(
        filePath: filePath,
        lineNumber: _lineNumberOf(source, node.offset),
        originalCode: originalText,
        mutatedCode: '0',
        operatorName: 'literal',
        description: 'replaced $value with 0',
        offset: node.offset,
        length: node.length,
      ));
    }

    super.visitIntegerLiteral(node);
  }

  @override
  void visitSimpleStringLiteral(SimpleStringLiteral node) {
    if (node.value.isNotEmpty) {
      final originalText =
          source.substring(node.offset, node.offset + node.length);

      // Detect the quote style used
      String emptyString;
      if (originalText.startsWith("'''") || originalText.startsWith('"""')) {
        final quote = originalText.substring(0, 3);
        emptyString = '$quote$quote';
      } else if (originalText.startsWith("'")) {
        emptyString = "''";
      } else {
        emptyString = '""';
      }

      mutants.add(Mutant(
        filePath: filePath,
        lineNumber: _lineNumberOf(source, node.offset),
        originalCode: originalText,
        mutatedCode: emptyString,
        operatorName: 'literal',
        description: 'replaced string with empty string',
        offset: node.offset,
        length: node.length,
      ));
    }

    super.visitSimpleStringLiteral(node);
  }
}

int _lineNumberOf(String source, int offset) {
  var line = 1;
  for (var i = 0; i < offset && i < source.length; i++) {
    if (source[i] == '\n') line++;
  }
  return line;
}
