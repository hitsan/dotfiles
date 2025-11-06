# Test Suite Documentation

This repository includes a comprehensive test suite for validating Nix configuration changes.

## Overview

The test suite validates the following changes made in the feature/openspec branch:

1. **modules/ai/sdd/default.nix** - OpenSpec wrapper using `writeShellScriptBin`
2. **modules/lang/default.nix** - Added nodejs package
3. **modules/ai/default.nix** - Uncommented sdd module import

## Test Files

### modules/ai/sdd/test.nix
Tests for the OpenSpec wrapper script (15 tests):
- Script existence and executability
- Correct shebang and shell syntax
- Nodejs PATH configuration
- NPX command structure
- Version pinning (0.14.0)
- Argument passing
- Exec usage (no unnecessary process)
- Shellcheck validation
- Module structure validation
- Derivation metadata

### modules/lang/test.nix
Tests for the lang module (13 tests):
- Package list structure
- Correct package count (3 packages)
- Presence of clang, nodejs, and uv
- Derivation validity
- Binary availability
- Executable permissions
- NPM and NPX inclusion with nodejs
- Module structure validation

### modules/ai/test.nix
Tests for the ai module imports (6 tests):
- Import list structure and count
- SDD module import presence
- All expected modules imported
- SDD not commented out
- Module structure validation
- Import capability verification

### checks.nix
Main test orchestrator that:
- Aggregates all test suites
- Provides granular test access
- Includes integration tests
- Tests nodejs consistency across modules
- Validates backward compatibility
- Runs shellcheck on embedded scripts

## Running Tests

### Run all tests:
```bash
nix build .#checks.x86_64-linux.all
```

### Run specific test suites:
```bash
# SDD module tests
nix build .#checks.x86_64-linux.sdd

# Lang module tests
nix build .#checks.x86_64-linux.lang

# AI module tests
nix build .#checks.x86_64-linux.ai
```

### Run individual tests:
```bash
# Example: Test openspec script exists
nix build .#checks.x86_64-linux.sdd-script-exists

# Example: Test nodejs is included in lang module
nix build .#checks.x86_64-linux.lang-nodejs-included

# Example: Test sdd module is imported
nix build .#checks.x86_64-linux.ai-sdd-imported
```

### Run flake checks:
```bash
nix flake check
```

## Test Coverage

### Happy Path Tests
- Correct module structure and imports
- Package availability and executability
- Script functionality and syntax
- Binary presence and permissions

### Edge Cases
- Argument passing to wrapper scripts
- PATH configuration correctness
- Version pinning validation
- Module import ordering

### Failure Conditions
- Missing or invalid derivations
- Incorrect package counts
- Shellcheck violations
- Missing binaries or non-executable files
- Module structure validation failures

### Integration Tests
- Nodejs consistency across modules
- NPX availability for OpenSpec
- Backward compatibility
- Module interface preservation

## Test Methodology

The tests use Nix's `runCommand` to create derivations that validate specific conditions. Each test:
1. Checks a specific property
2. Outputs "PASS" or "FAIL" with descriptive messages
3. Exits with code 1 on failure
4. Can be run independently or as part of a suite

## Best Practices Validated

1. **Shell Script Quality**: All shell scripts pass shellcheck
2. **Nix Conventions**: Proper use of `writeShellScriptBin`
3. **Explicit Dependencies**: No implicit `with pkgs` in critical modules
4. **Version Pinning**: External dependencies specify versions
5. **Exec Usage**: Scripts use `exec` to avoid unnecessary processes
6. **Argument Passing**: All scripts properly forward arguments

## Continuous Integration

These tests can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Run Nix Checks
  run: nix flake check

- name: Run Full Test Suite
  run: nix build .#checks.x86_64-linux.all
```

## Adding New Tests

To add tests for new modules:

1. Create `modules/<module-name>/test.nix`
2. Import it in `checks.nix`
3. Add individual test exports
4. Update this README

Example test structure:
```nix
{ pkgs, lib }:
let
  module = import ./default.nix { inherit pkgs; };
  
  testExample = pkgs.runCommand "test-example" {} ''
    if [ condition ]; then
      echo "PASS: description" > $out
    else
      echo "FAIL: description" > $out
      exit 1
    fi
  '';
in {
  inherit testExample;
  all = pkgs.runCommand "test-module-all" {} ''
    cat ${testExample} > $out
  '';
}
```

## Troubleshooting

If tests fail:

1. Check the test output for specific failure messages
2. Verify the module structure matches expectations
3. Ensure all dependencies are available in nixpkgs
4. Run individual tests to isolate issues
5. Check that changes haven't introduced regressions

## Test Output Format

Each test outputs:
- **PASS**: Test succeeded with description
- **FAIL**: Test failed with description and reason

The complete test suite provides a summary with all test results.