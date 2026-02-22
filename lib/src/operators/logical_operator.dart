import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../mutant.dart';
import 'operator.dart';

/// Mutates logical binary expressions: && <-> ||
class LogicalMutationOperator extends MutationOperator {
  @override
  String get name => 'logical';

  static const Map<TokenType, TokenType> _replacements = {
    TokenType.AMPERSAND_AMPERSAND: TokenType.BAR_BAR,
    TokenType.BAR_BAR: TokenType.AMPERSAND_AMPERSAND,
  };

  @override
  List<Mutant> generate(
      CompilationUnit unit, String filePath, String source) {
    final visitor = _LogicalVisitor(filePath, source);
    unit.visitChildren(visitor);
    return visitor.mutants;
  }
}

class _LogicalVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final String source;
  final List<Mutant> mutants = [];

  _LogicalVisitor(this.filePath, this.source);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final operatorToken = node.operator;
    final replacement =
        LogicalMutationOperator._replacements[operatorToken.type];

    if (replacement != null) {
      final originalLexeme = operatorToken.lexeme;
      final mutatedLexeme = replacement.lexeme;

      mutants.add(Mutant(
        filePath: filePath,
        lineNumber: _lineNumberOf(source, operatorToken.offset),
        originalCode: originalLexeme,
        mutatedCode: mutatedLexeme,
        operatorName: 'logical',
        description: 'replaced $originalLexeme with $mutatedLexeme',
        offset: operatorToken.offset,
        length: operatorToken.length,
      ));
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
