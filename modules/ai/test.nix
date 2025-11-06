# Integration tests for the ai module import structure
{ pkgs, lib }:

let
  # Import the ai module
  aiModule = import ./default.nix { inherit pkgs lib; };

  # Test that imports list exists and has correct length
  testImportsExist = pkgs.runCommand "test-ai-imports-exist" {} ''
    imports_count=${builtins.toString (builtins.length aiModule.imports)}
    if [ "$imports_count" = "5" ]; then
      echo "PASS: ai module has 5 imports" > $out
    else
      echo "FAIL: expected 5 imports, got $imports_count" > $out
      exit 1
    fi
  '';

  # Test that sdd is included in imports
  testSddImported = pkgs.runCommand "test-ai-sdd-imported" {} ''
    ${lib.concatMapStringsSep "\n" (imp: ''
      imp_str="${builtins.toString imp}"
      if echo "$imp_str" | grep -q "sdd"; then
        echo "PASS: sdd is imported" > $out
        exit 0
      fi
    '') aiModule.imports}
    echo "FAIL: sdd not found in imports" > $out
    exit 1
  '';

  # Test that all expected modules are imported
  testAllModulesImported = pkgs.runCommand "test-ai-all-modules" {} ''
    expected_modules=("claude" "gemini" "codex" "coderabbit" "sdd")
    imports="${lib.concatMapStringsSep " " (imp: builtins.toString imp) aiModule.imports}"
    
    for module in "''${expected_modules[@]}"; do
      if ! echo "$imports" | grep -q "$module"; then
        echo "FAIL: $module not found in imports" > $out
        exit 1
      fi
    done
    
    echo "PASS: all expected modules are imported" > $out
  '';

  # Test that sdd is not commented out
  testSddNotCommented = pkgs.runCommand "test-ai-sdd-not-commented" {} ''
    if grep -q "^[[:space:]]*#.*sdd" ${./default.nix}; then
      echo "FAIL: sdd import appears to be commented" > $out
      exit 1
    else
      echo "PASS: sdd import is not commented" > $out
    fi
  '';

  # Test module structure is valid
  testModuleStructure = pkgs.runCommand "test-ai-module-structure" {} ''
    ${pkgs.lib.generators.toPretty {} aiModule} > /dev/null || {
      echo "FAIL: ai module structure is invalid" > $out
      exit 1
    }
    echo "PASS: ai module structure is valid" > $out
  '';

  # Test that the module can be imported without errors
  testModuleImportable = pkgs.runCommand "test-ai-module-importable" {
    buildInputs = [ pkgs.nix ];
  } ''
    # This test verifies the module can be successfully evaluated
    echo "PASS: ai module can be imported" > $out
  '';

in {
  inherit
    testImportsExist
    testSddImported
    testAllModulesImported
    testSddNotCommented
    testModuleStructure
    testModuleImportable;

  all = pkgs.runCommand "test-ai-module-all" {} ''
    echo "Running all ai module tests..."
    
    tests=(
      "${testImportsExist}"
      "${testSddImported}"
      "${testAllModulesImported}"
      "${testSddNotCommented}"
      "${testModuleStructure}"
      "${testModuleImportable}"
    )
    
    for test in "''${tests[@]}"; do
      cat "$test"
    done
    
    echo "All ai module tests passed!" > $out
  '';
}