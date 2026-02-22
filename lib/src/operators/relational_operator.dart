import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../mutant.dart';
import 'operator.dart';

/// Mutates relational binary expressions:
/// > <-> >=, < <-> <=, == <-> !=
class RelationalMutationOperator extends MutationOperator {
  @override
  String get name => 'relational';

  static const Map<TokenType, List<TokenType>> _replacements = {
    TokenType.GT: [TokenType.GT_EQ],
    TokenType.GT_EQ: [TokenType.GT],
    TokenType.LT: [TokenType.LT_EQ],
    TokenType.LT_EQ: [TokenType.LT],
    TokenType.EQ_EQ: [TokenType.BANG_EQ],
    TokenType.BANG_EQ: [TokenType.EQ_EQ],
  };

  @override
  List<Mutant> generate(
      CompilationUnit unit, String filePath, String source) {
    final visitor = _RelationalVisitor(filePath, source);
    unit.visitChildren(visitor);
    return visitor.mutants;
  }
}

class _RelationalVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final String source;
  final List<Mutant> mutants = [];

  _RelationalVisitor(this.filePath, this.source);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final operatorToken = node.operator;
    final replacements =
        RelationalMutationOperator._replacements[operatorToken.type];

    if (replacements != null) {
      for (final replacement in replacements) {
        final originalLexeme = operatorToken.lexeme;
        final mutatedLexeme = replacement.lexeme;

        mutants.add(Mutant(
          filePath: filePath,
          lineNumber: _lineNumberOf(source, operatorToken.offset),
          originalCode: originalLexeme,
          mutatedCode: mutatedLexeme,
          operatorName: 'relational',
          description: 'replaced $originalLexeme with $mutatedLexeme',
          offset: operatorToken.offset,
          length: operatorToken.length,
        ));
      }
    }

    super.visitBinaryExpression(node);
  }
}

int _lineNumberOf(String source, int offset) {
  var line = 1;
  for (var i = 0; i < offset && i < source.length; i++) {
    if (source[i] == '\n') line++;
  }
  return line;
}
