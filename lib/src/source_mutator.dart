import 'mutant.dart';

/// Applies a [Mutant] to source code, producing a mutated version.
class SourceMutator {
  /// Applies a single mutation to [source], replacing the text at
  /// [mutant.offset] of [mutant.length] characters with [mutant.mutatedCode].
  ///
  /// Returns the mutated source string.
  static String apply(String source, Mutant mutant) {
    if (mutant.offset < 0 || mutant.offset > source.length) {
      throw RangeError('Mutant offset ${mutant.offset} is out of range '
          'for source of length ${source.length}');
    }
    if (mutant.offset + mutant.length > source.length) {
      throw RangeError('Mutant extends beyond source: '
          'offset=${mutant.offset}, length=${mutant.length}, '
          'source length=${source.length}');
    }

    final before = source.substring(0, mutant.offset);
    final after = source.substring(mutant.offset + mutant.length);
    return '$before${mutant.mutatedCode}$after';
  }
}
