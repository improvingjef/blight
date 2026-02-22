import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/token.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../mutant.dart';
import 'operator.dart';

/// Mutates arithmetic binary expressions:
/// + <-> -, * <-> /, ~/ <-> *, % <-> *
class ArithmeticMutationOperator extends MutationOperator {
  @override
  String get name => 'arithmetic';

  static const Map<TokenType, List<TokenType>> _replacements = {
    TokenType.PLUS: [TokenType.MINUS],
    TokenType.MINUS: [TokenType.PLUS],
    TokenType.STAR: [TokenType.SLASH],
    TokenType.SLASH: [TokenType.STAR],
    TokenType.TILDE_SLASH: [TokenType.STAR],
    TokenType.PERCENT: [TokenType.STAR],
  };

  @override
  List<Mutant> generate(
      CompilationUnit unit, String filePath, String source) {
    final visitor = _ArithmeticVisitor(filePath, source);
    unit.visitChildren(visitor);
    return visitor.mutants;
  }
}

class _ArithmeticVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final String source;
  final List<Mutant> mutants = [];

  _ArithmeticVisitor(this.filePath, this.source);

  @override
  void visitBinaryExpression(BinaryExpression node) {
    final operatorToken = node.operator;
    final replacements =
        ArithmeticMutationOperator._replacements[operatorToken.type];

    if (replacements != null) {
      for (final replacement in replacements) {
        final originalLexeme = operatorToken.lexeme;
        final mutatedLexeme = replacement.lexeme;

        final lineInfo = node.thisOrAncestorOfType<CompilationUnit>();
        final lineNumber = lineInfo != null
            ? _lineNumberOf(source, operatorToken.offset)
            : 0;

        mutants.add(Mutant(
          filePath: filePath,
          lineNumber: lineNumber,
          originalCode: originalLexeme,
          mutatedCode: mutatedLexeme,
          operatorName: 'arithmetic',
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
