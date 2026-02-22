import 'dart:io';

import 'package:args/args.dart';
import 'package:blight/blight.dart';
import 'package:path/path.dart' as p;

const String version = '0.1.0';

void main(List<String> arguments) async {
  final parser = ArgParser()
    ..addFlag('help', abbr: 'h', negatable: false, help: 'Show usage help.')
    ..addFlag('version',
        abbr: 'v', negatable: false, help: 'Print the version.')
    ..addOption('config',
        abbr: 'c',
        defaultsTo: 'blight.yaml',
        help: 'Path to config file.')
    ..addOption('parallelism',
        abbr: 'j', help: 'Max concurrent test runners.');

  // Add 'run' subcommand
  final runParser = ArgParser()
    ..addOption('config',
        abbr: 'c',
        defaultsTo: 'blight.yaml',
        help: 'Path to config file.')
    ..addOption('parallelism',
        abbr: 'j', help: 'Max concurrent test runners.');

  parser.addCommand('run', runParser);

  // Add 'init' subcommand
  parser.addCommand('init');

  ArgResults results;
  try {
    results = parser.parse(arguments);
  } on FormatException catch (e) {
    stderr.writeln('Error: ${e.message}');
    stderr.writeln();
    _printUsage(parser);
    exit(64);
  }

  if (results['version'] as bool) {
    stdout.writeln('blight $version');
    exit(0);
  }

  if (results['help'] as bool) {
    _printUsage(parser);
    exit(0);
  }

  final command = results.command;

  if (command != null && command.name == 'init') {
    await _runInit();
    return;
  }

  // Default command is 'run'
  await _runMutationTesting(results, command);
}

void _printUsage(ArgParser parser) {
  stdout.writeln('blight v$version -- mutation testing for Dart');
  stdout.writeln();
  stdout.writeln('Usage: blight [command] [options]');
  stdout.writeln();
  stdout.writeln('Commands:');
  stdout.writeln('  run     Run mutation testing (default)');
  stdout.writeln('  init    Create a blight.yaml config file');
  stdout.writeln();
  stdout.writeln('Options:');
  stdout.writeln(parser.usage);
}

Future<void> _runInit() async {
  final configPath = p.join(Directory.current.path, 'blight.yaml');
  final configFile = File(configPath);

  if (configFile.existsSync()) {
    stderr.writeln('blight.yaml already exists in this directory.');
    exit(1);
  }

  configFile.writeAsStringSync(BlightConfig.generateDefaultYaml());
  stdout.writeln('Created blight.yaml with default configuration.');
}

Future<void> _runMutationTesting(
    ArgResults topLevel, ArgResults? command) async {
  // configPath reserved for future use with custom config file locations
  // final configPath =
  //     (command?['config'] as String?) ??
  //     (topLevel['config'] as String?) ??
  //     'blight.yaml';

  final projectRoot = Directory.current.path;
  final config = BlightConfig.load(projectRoot: projectRoot);

  // Override parallelism if specified on command line
  final parallelismStr =
      (command?['parallelism'] as String?) ??
      (topLevel['parallelism'] as String?);

  final effectiveConfig = parallelismStr != null
      ? BlightConfig(
          include: config.include,
          exclude: config.exclude,
          operators: config.operators,
          testCommand: config.testCommand,
          timeoutMultiplier: config.timeoutMultiplier,
          parallelism: int.parse(parallelismStr),
          projectRoot: config.projectRoot,
        )
      : config;

  final runner = BlightRunner(config: effectiveConfig);
  final mutants = await runner.run();

  // Exit code: 0 if all killed, 1 if any survived
  final survived =
      mutants.where((m) => m.result == MutantResult.survived).length;
  exit(survived > 0 ? 1 : 0);
}
