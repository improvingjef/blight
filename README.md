# blight

**Mutation testing for Dart & Flutter.**

*That which doesn't kill you makes you stronger.*

Blight introduces small, systematic mutations into your Dart source code — flipping operators, swapping conditions, removing statements — then runs your test suite against each mutant. If your tests catch the mutation, the mutant is **killed**. If they don't, it **survives** — exposing a gap in your test coverage that line-coverage tools miss entirely.

## Quick Start

```bash
dart pub global activate blight

# Run from your project root
blight run
```

## How It Works

1. **Parse** — Blight analyzes your Dart source using the `analyzer` package AST
2. **Mutate** — Applies mutation operators one at a time (arithmetic, relational, logical, statement deletion, etc.)
3. **Test** — Runs your test suite against each mutant
4. **Report** — Shows which mutants survived and where your tests are weak

## Mutation Operators

| Operator | Example | Mutation |
|---|---|---|
| Arithmetic | `a + b` | `a - b`, `a * b` |
| Relational | `a > b` | `a >= b`, `a < b` |
| Logical | `a && b` | `a \|\| b` |
| Unary | `!flag` | `flag` |
| Literal | `true` | `false` |
| Statement deletion | `doSomething();` | *(removed)* |
| Return value | `return x;` | `return null;` |
| Conditional boundary | `i < 10` | `i <= 10` |

## Output

```
blight v0.1.0 — mutation testing for Dart

Analyzing lib/src/calculator.dart ...
  Generated 14 mutants
  Running tests ...

  ✗ KILLED   line 12: replaced + with -
  ✗ KILLED   line 12: replaced + with *
  ✓ SURVIVED line 18: replaced > with >=
  ✗ KILLED   line 24: removed statement
  ...

Results: 12 killed, 2 survived (85.7% mutation score)

Survivors — these are your weak spots:
  lib/src/calculator.dart:18  replaced > with >=
  lib/src/calculator.dart:31  replaced true with false
```

## Configuration

Create a `blight.yaml` in your project root:

```yaml
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
parallelism: 4
```

## License

MIT
