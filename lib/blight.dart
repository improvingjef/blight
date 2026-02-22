/// Mutation testing for Dart & Flutter.
///
/// Blight introduces small, systematic mutations into your Dart source code,
/// then runs your test suite against each mutant to find gaps in test coverage.
library;

export 'src/config.dart';
export 'src/mutant.dart';
export 'src/operators/arithmetic_operator.dart';
export 'src/operators/conditional_boundary_operator.dart';
export 'src/operators/literal_operator.dart';
export 'src/operators/logical_operator.dart';
export 'src/operators/operator.dart';
export 'src/operators/relational_operator.dart';
export 'src/operators/return_value_operator.dart';
export 'src/operators/statement_deletion_operator.dart';
export 'src/operators/unary_operator.dart';
export 'src/reporter.dart';
export 'src/runner.dart';
export 'src/source_mutator.dart';
