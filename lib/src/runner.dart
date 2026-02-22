import 'dart:async';
import 'dart:io';

import 'package:analyzer/dart/analysis/utilities.dart';
import 'package:glob/glob.dart';
import 'package:glob/list_local_fs.dart';
import 'package:path/path.dart' as p;

import 'config.dart';
import 'mutant.dart';
import 'operators/arithmetic_operator.dart';
import 'operators/conditional_boundary_operator.dart';
import 'operators/literal_operator.dart';
import 'operators/logical_operator.dart';
import 'operators/operator.dart';
import 'operators/relational_operator.dart';
import 'operators/return_value_operator.dart';
import 'operators/statement_deletion_operator.dart';
import 'operators/unary_operator.dart';
import 'reporter.dart';
import 'source_mutator.dart';

/// Orchestrates a mutation testing run.
class BlightRunner {
  final BlightConfig config;
  final BlightReporter reporter;

  /// All available mutation operators, keyed by name.
  static final Map<String, MutationOperator> _allOperators = {
    'arithmetic': ArithmeticMutationOperator(),
    'relational': RelationalMutationOperator(),
    'logical': LogicalMutationOperator(),
    'unary': UnaryMutationOperator(),
    'literal': LiteralMutationOperator(),
    'statement_deletion': StatementDeletionMutationOperator(),
    'return_value': ReturnValueMutationOperator(),
    'conditional_boundary': ConditionalBoundaryMutationOperator(),
  };

  BlightRunner({required this.config, BlightReporter? reporter})
      : reporter = reporter ?? BlightReporter();

  /// Returns the active operators based on config.
  List<MutationOperator> get _activeOperators {
    return config.operators
        .where((name) => _allOperators.containsKey(name))
        .map((name) => _allOperators[name]!)
        .toList();
  }

  /// Runs the full mutation testing pipeline.
  Future<List<Mutant>> run() async {
    reporter.printHeader();

    // 1. Find source files matching include/exclude globs
    final sourceFiles = _findSourceFiles();
    if (sourceFiles.isEmpty) {
      stdout.writeln('No source files matched the include/exclude patterns.');
      return [];
    }

    // 2. Measure baseline test time
    final baselineTime = await _measureBaselineTestTime();
    if (baselineTime == null) {
      stderr.writeln(
          'Baseline test run failed. Fix your tests before running blight.');
      return [];
    }
    final timeout = Duration(
        milliseconds:
            (baselineTime.inMilliseconds * config.timeoutMultiplier).round());

    // 3. For each file, parse and generate mutants
    final allMutants = <Mutant>[];

    for (final file in sourceFiles) {
      final source = File(file).readAsStringSync();
      final mutants = _generateMutants(file, source);

      if (mutants.isEmpty) continue;

      reporter.printFileStart(
          p.relative(file, from: config.projectRoot), mutants.length);
      allMutants.addAll(mutants);
    }

    if (allMutants.isEmpty) {
      stdout.writeln('No mutants were generated.');
      return [];
    }

    // 4. Run tests against each mutant
    await _runMutantTests(allMutants, timeout);

    // 5. Report results
    reporter.printSummary(allMutants);

    return allMutants;
  }

  /// Finds source files matching the config include/exclude globs.
  List<String> _findSourceFiles() {
    final included = <String>{};

    for (final pattern in config.include) {
      final glob = Glob(pattern);
      final matches = glob.listSync(root: config.projectRoot);
      for (final entity in matches) {
        if (entity is File) {
          included.add(p.normalize(entity.path));
        }
      }
    }

    // Remove excluded files
    final excluded = <String>{};
    for (final pattern in config.exclude) {
      final glob = Glob(pattern);
      final matches = glob.listSync(root: config.projectRoot);
      for (final entity in matches) {
        if (entity is File) {
          excluded.add(p.normalize(entity.path));
        }
      }
    }

    return included.difference(excluded).toList()..sort();
  }

  /// Generates mutants for a single source file.
  List<Mutant> _generateMutants(String filePath, String source) {
    final parseResult = parseString(content: source);
    final unit = parseResult.unit;
    final mutants = <Mutant>[];

    for (final op in _activeOperators) {
      mutants.addAll(op.generate(unit, filePath, source));
    }

    return mutants;
  }

  /// Measures how long the test suite takes to run (baseline).
  /// Returns null if the baseline test run fails.
  Future<Duration?> _measureBaselineTestTime() async {
    stdout.writeln('Running baseline tests ...');
    final stopwatch = Stopwatch()..start();
    final result = await _runTestCommand();
    stopwatch.stop();

    if (result.exitCode != 0) {
      return null;
    }

    stdout.writeln(
        'Baseline tests passed in ${stopwatch.elapsed.inSeconds}s');
    stdout.writeln();
    return stopwatch.elapsed;
  }

  /// Runs all mutant tests, respecting parallelism.
  Future<void> _runMutantTests(
      List<Mutant> mutants, Duration timeout) async {
    final parallelism = config.parallelism.clamp(1, mutants.length);

    // Process mutants in batches for parallelism
    for (var i = 0; i < mutants.length; i += parallelism) {
      final batch = mutants.sublist(
          i, (i + parallelism).clamp(0, mutants.length));

      final futures = batch.map((mutant) async {
        await _testMutant(mutant, timeout);
        reporter.printMutantResult(mutant);
      });

      await Future.wait(futures);
    }
  }

  /// Tests a single mutant by applying the mutation, running tests, and
  /// recording the result.
  Future<void> _testMutant(Mutant mutant, Duration timeout) async {
    final file = File(mutant.filePath);
    final originalSource = file.readAsStringSync();

    try {
      // Apply mutation
      final mutatedSource = SourceMutator.apply(originalSource, mutant);
      file.writeAsStringSync(mutatedSource);

      // Run tests
      final result = await _runTestCommand(timeout: timeout);

      if (result.exitCode == 0) {
        // Tests passed = mutant survived (bad)
        mutant.result = MutantResult.survived;
      } else {
        // Tests failed = mutant killed (good)
        mutant.result = MutantResult.killed;
      }
    } on TimeoutException {
      mutant.result = MutantResult.timeout;
    } catch (e) {
      mutant.result = MutantResult.error;
    } finally {
      // Always restore the original source
      file.writeAsStringSync(originalSource);
    }
  }

  /// Runs the configured test command.
  Future<ProcessResult> _runTestCommand({Duration? timeout}) async {
    final parts = config.testCommand.split(' ');
    final executable = parts.first;
    final args = parts.skip(1).toList();

    final process = await Process.start(
      executable,
      args,
      workingDirectory: config.projectRoot,
    );

    if (timeout != null) {
      final completer = Completer<ProcessResult>();
      final timer = Timer(timeout, () {
        process.kill();
        completer.completeError(TimeoutException(
            'Test timed out after ${timeout.inSeconds}s'));
      });

      final exitCode = await process.exitCode;
      timer.cancel();

      if (!completer.isCompleted) {
        final stdout = await process.stdout.toList();
        final stderr = await process.stderr.toList();
        return ProcessResult(
          process.pid,
          exitCode,
          stdout,
          stderr,
        );
      }

      return completer.future;
    }

    final exitCode = await process.exitCode;
    return ProcessResult(process.pid, exitCode, '', '');
  }
}
