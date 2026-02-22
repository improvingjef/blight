import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

/// Configuration for a blight mutation testing run.
class BlightConfig {
  /// Glob patterns for files to include in mutation testing.
  final List<String> include;

  /// Glob patterns for files to exclude from mutation testing.
  final List<String> exclude;

  /// Names of mutation operators to apply.
  final List<String> operators;

  /// The command to run tests.
  final String testCommand;

  /// Multiplier for test timeout (relative to baseline test run time).
  final double timeoutMultiplier;

  /// Maximum number of concurrent test runners.
  final int parallelism;

  /// The project root directory.
  final String projectRoot;

  BlightConfig({
    required this.include,
    required this.exclude,
    required this.operators,
    required this.testCommand,
    required this.timeoutMultiplier,
    required this.parallelism,
    required this.projectRoot,
  });

  /// Creates a [BlightConfig] with sensible defaults.
  factory BlightConfig.defaults({String? projectRoot}) {
    final root = projectRoot ?? Directory.current.path;
    return BlightConfig(
      include: ['lib/src/**/*.dart'],
      exclude: [
        'lib/src/generated/**',
        '**/*.g.dart',
        '**/*.freezed.dart',
      ],
      operators: [
        'arithmetic',
        'relational',
        'logical',
        'unary',
        'literal',
        'statement_deletion',
        'return_value',
        'conditional_boundary',
      ],
      testCommand: 'dart test',
      timeoutMultiplier: 3.0,
      parallelism: Platform.numberOfProcessors,
      projectRoot: root,
    );
  }

  /// Loads configuration from a `blight.yaml` file in [projectRoot].
  ///
  /// Falls back to defaults for any missing fields.
  factory BlightConfig.load({String? projectRoot}) {
    final root = projectRoot ?? Directory.current.path;
    final configFile = File(p.join(root, 'blight.yaml'));
    final defaults = BlightConfig.defaults(projectRoot: root);

    if (!configFile.existsSync()) {
      return defaults;
    }

    final content = configFile.readAsStringSync();
    final yaml = loadYaml(content);

    if (yaml is! YamlMap) {
      return defaults;
    }

    return BlightConfig(
      include: _parseStringList(yaml['include']) ?? defaults.include,
      exclude: _parseStringList(yaml['exclude']) ?? defaults.exclude,
      operators: _parseStringList(yaml['operators']) ?? defaults.operators,
      testCommand:
          (yaml['test_command'] as String?) ?? defaults.testCommand,
      timeoutMultiplier:
          (yaml['timeout_multiplier'] as num?)?.toDouble() ??
              defaults.timeoutMultiplier,
      parallelism:
          (yaml['parallelism'] as int?) ?? defaults.parallelism,
      projectRoot: root,
    );
  }

  /// Generates the default `blight.yaml` content.
  static String generateDefaultYaml() {
    return '''
# Files to mutate (globs)
include:
  - lib/src/**/*.dart

# Files to skip
exclude:
  - lib/src/generated/**
  - "**/*.g.dart"
  - "**/*.freezed.dart"

# Mutation operators to apply (default: all)
operators:
  - arithmetic
  - relational
  - logical
  - unary
  - literal
  - statement_deletion
  - return_value
  - conditional_boundary

# Test command (default: dart test)
test_command: dart test

# Timeout multiplier for mutant test runs (default: 3.0)
timeout_multiplier: 3.0

# Max concurrent test runners (default: number of CPU cores)
# parallelism: 4
''';
  }

  static List<String>? _parseStringList(dynamic value) {
    if (value is YamlList) {
      return value.map((e) => e.toString()).toList();
    }
    return null;
  }
}
