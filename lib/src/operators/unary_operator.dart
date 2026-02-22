import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../mutant.dart';
import 'operator.dart';

/// Removes unary negation (!) from prefix expressions.
class UnaryMutationOperator extends MutationOperator {
  @override
  String get name => 'unary';

  @override
  List<Mutant> generate(
      CompilationUnit unit, String filePath, String source) {
    final visitor = _UnaryVisitor(filePath, source);
    unit.visitChildren(visitor);
    return visitor.mutants;
  }
}

class _UnaryVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final String source;
  final List<Mutant> mutants = [];

  _UnaryVisitor(this.filePath, this.source);

  @override
  void visitPrefixExpression(PrefixExpression node) {
    if (node.operator.type == TokenType.BANG) {
      // Remove the ! operator — replace "!expr" with "expr"
      final operand = node.operand;
      final operandSource =
          source.substring(operand.offset, operand.offset + operand.length);

      mutants.add(Mutant(
        filePath: filePath,
        lineNumber: _lineNumberOf(source, node.offset),
        originalCode: source.substring(node.offset, node.offset + node.length),
        mutatedCode: operandSource,
        operatorName: 'unary',
        description: 'removed negation (!)',
        offset: node.offset,
        length: node.length,
      ));
    }

    super.visitPrefixExpression(node);
  }
}

int _lineNumberOf(String source, int offset) {
  var line = 1;
  for (var i = 0; i < offset && i < source.length; i++) {
    if (source[i] == '\n') line++;
  }
  return line;
}
