import 'dart:io';

import 'mutant.dart';

/// ANSI color codes for terminal output.
class _Ansi {
  static bool get supportsColor =>
      stdout.hasTerminal && stdout.supportsAnsiEscapes;

  static String _wrap(String text, String code) =>
      supportsColor ? '\x1B[${code}m$text\x1B[0m' : text;

  static String red(String text) => _wrap(text, '31');
  static String green(String text) => _wrap(text, '32');
  static String yellow(String text) => _wrap(text, '33');
  static String cyan(String text) => _wrap(text, '36');
  static String bold(String text) => _wrap(text, '1');
  static String dim(String text) => _wrap(text, '2');
}

/// Formats and reports mutation testing results to the console.
class BlightReporter {
  /// Whether to use color output.
  final bool useColor;

  BlightReporter({this.useColor = true});

  /// Prints the header banner.
  void printHeader() {
    stdout.writeln(
        _Ansi.bold('blight v0.1.0 -- mutation testing for Dart'));
    stdout.writeln();
  }

  /// Prints progress for a file being analyzed.
  void printFileStart(String filePath, int mutantCount) {
    stdout.writeln('Analyzing ${_Ansi.cyan(filePath)} ...');
    stdout.writeln('  Generated ${_Ansi.bold('$mutantCount')} mutants');
    stdout.writeln('  Running tests ...');
    stdout.writeln();
  }

  /// Prints the result of a single mutant test.
  void printMutantResult(Mutant mutant) {
    final symbol = switch (mutant.result) {
      MutantResult.killed => _Ansi.green('  KILLED  '),
      MutantResult.survived => _Ansi.red('  SURVIVED'),
      MutantResult.timeout => _Ansi.yellow('  TIMEOUT '),
      MutantResult.error => _Ansi.yellow('  ERROR   '),
      null => _Ansi.dim('  PENDING '),
    };

    stdout.writeln(
        '  $symbol line ${mutant.lineNumber}: ${mutant.description}');
  }

  /// Prints the full summary report.
  void printSummary(List<Mutant> mutants) {
    stdout.writeln();
    stdout.writeln(_Ansi.bold('--- Results ---'));
    stdout.writeln();

    final killed =
        mutants.where((m) => m.result == MutantResult.killed).length;
    final survived =
        mutants.where((m) => m.result == MutantResult.survived).length;
    final timedOut =
        mutants.where((m) => m.result == MutantResult.timeout).length;
    final errors =
        mutants.where((m) => m.result == MutantResult.error).length;
    final total = mutants.length;

    final score =
        total > 0 ? (killed / total * 100).toStringAsFixed(1) : '0.0';

    stdout.writeln(
        '  ${_Ansi.green("Killed")}: $killed  '
        '${_Ansi.red("Survived")}: $survived  '
        '${timedOut > 0 ? "${_Ansi.yellow("Timeout")}: $timedOut  " : ""}'
        '${errors > 0 ? "${_Ansi.yellow("Errors")}: $errors  " : ""}'
        'Total: $total');
    stdout.writeln();

    final scoreColor = double.parse(score) >= 80.0
        ? _Ansi.green
        : double.parse(score) >= 60.0
            ? _Ansi.yellow
            : _Ansi.red;

    stdout.writeln(
        '  Mutation score: ${scoreColor("$score%")}');
    stdout.writeln();

    // List survivors
    final survivors =
        mutants.where((m) => m.result == MutantResult.survived).toList();

    if (survivors.isNotEmpty) {
      stdout.writeln(
          _Ansi.bold('Survivors -- these are your weak spots:'));
      stdout.writeln();
      for (final mutant in survivors) {
        stdout.writeln(
            '  ${_Ansi.red("${mutant.filePath}:${mutant.lineNumber}")}  '
            '${mutant.description}');
      }
      stdout.writeln();
    } else if (total > 0) {
      stdout.writeln(
          _Ansi.green('All mutants were killed. Your tests are strong.'));
      stdout.writeln();
    }
  }
}
