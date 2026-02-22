import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../mutant.dart';
import 'operator.dart';

/// Mutates return values:
/// - return true -> return false (and vice versa)
/// - return 0 -> return 1 (and vice versa for small integers)
/// - return x -> return null (for any expression, useful for nullable returns)
class ReturnValueMutationOperator extends MutationOperator {
  @override
  String get name => 'return_value';

  @override
  List<Mutant> generate(
      CompilationUnit unit, String filePath, String source) {
    final visitor = _ReturnValueVisitor(filePath, source);
    unit.visitChildren(visitor);
    return visitor.mutants;
  }
}

class _ReturnValueVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final String source;
  final List<Mutant> mutants = [];

  _ReturnValueVisitor(this.filePath, this.source);

  @override
  void visitReturnStatement(ReturnStatement node) {
    final expr = node.expression;
    if (expr == null) {
      super.visitReturnStatement(node);
      return;
    }

    // return true -> return false
    if (expr is BooleanLiteral) {
      final mutated = !expr.value;
      mutants.add(Mutant(
        filePath: filePath,
        lineNumber: _lineNumberOf(source, node.offset),
        originalCode:
            source.substring(node.offset, node.offset + node.length),
        mutatedCode: 'return $mutated;',
        operatorName: 'return_value',
        description: 'replaced return ${expr.value} with return $mutated',
        offset: node.offset,
        length: node.length,
      ));
    }
    // return <integer> -> return <integer + 1> or return 0
    else if (expr is IntegerLiteral && expr.value != null) {
      final value = expr.value!;
      final mutatedValue = value == 0 ? 1 : 0;
      mutants.add(Mutant(
        filePath: filePath,
        lineNumber: _lineNumberOf(source, node.offset),
        originalCode:
            source.substring(node.offset, node.offset + node.length),
        mutatedCode: 'return $mutatedValue;',
        operatorName: 'return_value',
        description: 'replaced return $value with return $mutatedValue',
        offset: node.offset,
        length: node.length,
      ));
    }
    // return <expr> -> return null (general case)
    else {
      final originalText =
          source.substring(node.offset, node.offset + node.length);
      // Don't mutate if already returning null
      if (expr is! NullLiteral) {
        mutants.add(Mutant(
          filePath: filePath,
          lineNumber: _lineNumberOf(source, node.offset),
          originalCode: originalText,
          mutatedCode: 'return null;',
          operatorName: 'return_value',
          description: 'replaced return value with null',
          offset: node.offset,
          length: node.length,
        ));
      }
    }

    super.visitReturnStatement(node);
  }
}

int _lineNumberOf(String source, int offset) {
  var line = 1;
  for (var i = 0; i < offset && i < source.length; i++) {
    if (source[i] == '\n') line++;
  }
  return line;
}
