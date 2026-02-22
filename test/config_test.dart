import 'dart:io';

import 'package:blight/blight.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('BlightConfig', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('blight_test_');
    });

    tearDown(() {
      tempDir.deleteSync(recursive: true);
    });

    test('defaults() provides sensible default values', () {
      final config = BlightConfig.defaults(projectRoot: tempDir.path);

      expect(config.include, equals(['lib/src/**/*.dart']));
      expect(config.exclude, contains('**/*.g.dart'));
      expect(config.exclude, contains('**/*.freezed.dart'));
      expect(config.operators, contains('arithmetic'));
      expect(config.operators, contains('relational'));
      expect(config.operators, contains('logical'));
      expect(config.operators, contains('unary'));
      expect(config.operators, contains('literal'));
      expect(config.operators, contains('statement_deletion'));
      expect(config.operators, contains('return_value'));
      expect(config.operators, contains('conditional_boundary'));
      expect(config.testCommand, equals('dart test'));
      expect(config.timeoutMultiplier, equals(3.0));
      expect(config.parallelism, greaterThan(0));
      expect(config.projectRoot, equals(tempDir.path));
    });

    test('load() returns defaults when no config file exists', () {
      final config = BlightConfig.load(projectRoot: tempDir.path);

      expect(config.include, equals(['lib/src/**/*.dart']));
      expect(config.testCommand, equals('dart test'));
    });

    test('load() reads from blight.yaml', () {
      final configFile = File(p.join(tempDir.path, 'blight.yaml'));
      configFile.writeAsStringSync('''
include:
  - lib/**/*.dart
  - bin/**/*.dart

exclude:
  - lib/generated/**

operators:
  - arithmetic
  - logical

test_command: flutter test
timeout_multiplier: 5.0
parallelism: 2
''');

      final config = BlightConfig.load(projectRoot: tempDir.path);

      expect(config.include, equals(['lib/**/*.dart', 'bin/**/*.dart']));
      expect(config.exclude, equals(['lib/generated/**']));
      expect(config.operators, equals(['arithmetic', 'logical']));
      expect(config.testCommand, equals('flutter test'));
      expect(config.timeoutMultiplier, equals(5.0));
      expect(config.parallelism, equals(2));
    });

    test('load() uses defaults for missing fields', () {
      final configFile = File(p.join(tempDir.path, 'blight.yaml'));
      configFile.writeAsStringSync('''
test_command: flutter test --no-pub
''');

      final config = BlightConfig.load(projectRoot: tempDir.path);

      // Overridden field
      expect(config.testCommand, equals('flutter test --no-pub'));
      // Default fields
      expect(config.include, equals(['lib/src/**/*.dart']));
      expect(config.timeoutMultiplier, equals(3.0));
    });

    test('load() handles empty YAML file gracefully', () {
      final configFile = File(p.join(tempDir.path, 'blight.yaml'));
      configFile.writeAsStringSync('');

      final config = BlightConfig.load(projectRoot: tempDir.path);

      expect(config.include, equals(['lib/src/**/*.dart']));
      expect(config.testCommand, equals('dart test'));
    });

    test('load() handles invalid YAML content gracefully', () {
      final configFile = File(p.join(tempDir.path, 'blight.yaml'));
      configFile.writeAsStringSync('just a plain string');

      final config = BlightConfig.load(projectRoot: tempDir.path);

      // Should fall back to defaults
      expect(config.include, equals(['lib/src/**/*.dart']));
    });

    test('generateDefaultYaml() produces valid YAML', () {
      final yaml = BlightConfig.generateDefaultYaml();

      expect(yaml, contains('include:'));
      expect(yaml, contains('exclude:'));
      expect(yaml, contains('operators:'));
      expect(yaml, contains('test_command: dart test'));
      expect(yaml, contains('timeout_multiplier: 3.0'));
    });

    test('generateDefaultYaml() round-trips through load()', () {
      final configFile = File(p.join(tempDir.path, 'blight.yaml'));
      configFile.writeAsStringSync(BlightConfig.generateDefaultYaml());

      final config = BlightConfig.load(projectRoot: tempDir.path);

      expect(config.include, equals(['lib/src/**/*.dart']));
      expect(config.testCommand, equals('dart test'));
      expect(config.timeoutMultiplier, equals(3.0));
      expect(config.operators.length, equals(8));
    });
  });
}
