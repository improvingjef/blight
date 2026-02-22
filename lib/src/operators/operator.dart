import 'package:analyzer/dart/ast/ast.dart';

import '../mutant.dart';

/// Abstract base class for mutation operators.
///
/// Each operator knows how to visit an AST and produce [Mutant] instances
/// representing the mutations it can apply.
abstract class MutationOperator {
  /// The unique name of this operator (e.g., "arithmetic", "relational").
  String get name;

  /// Generates a list of [Mutant]s by visiting the given [unit] AST.
  ///
  /// [filePath] is attached to each mutant for reporting purposes.
  /// [source] is the original source code string, used to extract original text.
  List<Mutant> generate(CompilationUnit unit, String filePath, String source);
}
