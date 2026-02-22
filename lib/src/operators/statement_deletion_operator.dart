import 'package:analyzer/dart/ast/ast.dart';
import 'package:analyzer/dart/ast/visitor.dart';

import '../mutant.dart';
import 'operator.dart';

/// Removes expression statements (not return, if, for, while, etc.).
///
/// Only targets simple expression statements like `doSomething();`
/// or `x = y;`.
class StatementDeletionMutationOperator extends MutationOperator {
  @override
  String get name => 'statement_deletion';

  @override
  List<Mutant> generate(
      CompilationUnit unit, String filePath, String source) {
    final visitor = _StatementDeletionVisitor(filePath, source);
    unit.visitChildren(visitor);
    return visitor.mutants;
  }
}

class _StatementDeletionVisitor extends RecursiveAstVisitor<void> {
  final String filePath;
  final String source;
  final List<Mutant> mutants = [];

  _StatementDeletionVisitor(this.filePath, this.source);

  @override
  void visitExpressionStatement(ExpressionStatement node) {
    // Only delete expression statements (method calls, assignments, etc.)
    // Skip if it is the only statement in a block (would cause empty body issues).
    final parent = node.parent;
    if (parent is Block && parent.statements.length <= 1) {
      super.visitExpressionStatement(node);
      return;
    }

    final originalText =
        source.substring(node.offset, node.offset + node.length);

    mutants.add(Mutant(
      filePath: filePath,
      lineNumber: _lineNumberOf(source, node.offset),
      originalCode: originalText,
      mutatedCode: '',
      operatorName: 'statement_deletion',
      description: 'removed statement: ${_truncate(originalText, 40)}',
      offset: node.offset,
      length: node.length,
    ));

    super.visitExpressionStatement(node);
  }
}

String _truncate(String s, int maxLength) {
  final singleLine = s.replaceAll('\n', ' ').trim();
  if (singleLine.length <= maxLength) return singleLine;
  return '${singleLine.substring(0, maxLength - 3)}...';
}

int _lineNumberOf(String source, int offset) {
  var line = 1;
  for (var i = 0; i < offset && i < source.length; i++) {
    if (source[i] == '\n') line++;
  }
  return line;
}
