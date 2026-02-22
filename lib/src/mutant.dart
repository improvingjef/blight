/// Result of testing a single mutant.
enum MutantResult {
  /// Test suite caught the mutation (test failed) — good.
  killed,

  /// Test suite did NOT catch the mutation (tests passed) — bad.
  survived,

  /// Test suite timed out while running against this mutant.
  timeout,

  /// An error occurred while testing this mutant.
  error,
}

/// A single mutation applied to source code.
class Mutant {
  /// The path to the source file being mutated.
  final String filePath;

  /// The line number in the source file where the mutation occurs.
  final int lineNumber;

  /// The original source text that will be replaced.
  final String originalCode;

  /// The mutated source text that replaces the original.
  final String mutatedCode;

  /// The name of the mutation operator that generated this mutant.
  final String operatorName;

  /// A human-readable description of the mutation.
  final String description;

  /// The offset in the source string where the original code starts.
  final int offset;

  /// The length of the original code in the source string.
  final int length;

  /// The result of testing this mutant, if it has been tested.
  MutantResult? result;

  Mutant({
    required this.filePath,
    required this.lineNumber,
    required this.originalCode,
    required this.mutatedCode,
    required this.operatorName,
    required this.description,
    required this.offset,
    required this.length,
    this.result,
  });

  @override
  String toString() =>
      'Mutant($operatorName: "$originalCode" -> "$mutatedCode" at $filePath:$lineNumber)';
}
