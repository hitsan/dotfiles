# Integration tests for the openspec wrapper
{ pkgs, lib }:

let
  # Import the module to get the openspec derivation
  sddModule = import ./default.nix { inherit pkgs; };
  
  # Extract the openspec package from the module
  openspecPkg = builtins.head sddModule.home.packages;

  # Test that the script exists and is executable
  testScriptExists = pkgs.runCommand "test-openspec-script-exists" {} ''
    if [ -f "${openspecPkg}/bin/openspec" ]; then
      echo "PASS: openspec script exists" > $out
    else
      echo "FAIL: openspec script does not exist" > $out
      exit 1
    fi
  '';

  # Test that the script has correct shebang
  testScriptShebang = pkgs.runCommand "test-openspec-shebang" {} ''
    if head -n1 "${openspecPkg}/bin/openspec" | grep -q "^#!.*bash"; then
      echo "PASS: openspec has bash shebang" > $out
    else
      echo "FAIL: openspec does not have bash shebang" > $out
      exit 1
    fi
  '';

  # Test that nodejs is in the PATH
  testNodejsInPath = pkgs.runCommand "test-openspec-nodejs-path" {} ''
    if grep -q "nodejs.*bin" "${openspecPkg}/bin/openspec"; then
      echo "PASS: nodejs is added to PATH" > $out
    else
      echo "FAIL: nodejs not found in PATH" > $out
      exit 1
    fi
  '';

  # Test that npx command is present
  testNpxCommand = pkgs.runCommand "test-openspec-npx-command" {} ''
    if grep -q "npx -y @fission-ai/openspec" "${openspecPkg}/bin/openspec"; then
      echo "PASS: npx command is present" > $out
    else
      echo "FAIL: npx command not found" > $out
      exit 1
    fi
  '';

  # Test that the correct version is specified
  testCorrectVersion = pkgs.runCommand "test-openspec-version" {} ''
    if grep -q "@fission-ai/openspec@0\.14\.0" "${openspecPkg}/bin/openspec"; then
      echo "PASS: correct version 0.14.0 is specified" > $out
    else
      echo "FAIL: incorrect version or version not specified" > $out
      exit 1
    fi
  '';

  # Test that arguments are passed through
  testArgumentPassing = pkgs.runCommand "test-openspec-args" {} ''
    if grep -q '\$@' "${openspecPkg}/bin/openspec"; then
      echo "PASS: arguments are passed through" > $out
    else
      echo "FAIL: arguments not passed through" > $out
      exit 1
    fi
  '';

  # Test script permissions
  testScriptExecutable = pkgs.runCommand "test-openspec-executable" {} ''
    if [ -x "${openspecPkg}/bin/openspec" ]; then
      echo "PASS: openspec script is executable" > $out
    else
      echo "FAIL: openspec script is not executable" > $out
      exit 1
    fi
  '';

  # Test that exec is used (not just call)
  testExecUsed = pkgs.runCommand "test-openspec-exec" {} ''
    if grep -q "exec.*npx" "${openspecPkg}/bin/openspec"; then
      echo "PASS: exec is used for npx" > $out
    else
      echo "FAIL: exec not used, may create unnecessary process" > $out
      exit 1
    fi
  '';

  # Test the full script structure
  testScriptStructure = pkgs.runCommand "test-openspec-structure" {
    buildInputs = [ pkgs.shellcheck ];
  } ''
    # Check script syntax with shellcheck
    shellcheck "${openspecPkg}/bin/openspec" || {
      echo "FAIL: shellcheck found issues" > $out
      exit 1
    }
    echo "PASS: script passes shellcheck" > $out
  '';

  # Test module structure
  testModuleStructure = pkgs.runCommand "test-sdd-module-structure" {} ''
    # Verify the module returns correct structure
    ${pkgs.lib.generators.toPretty {} sddModule} > /dev/null || {
      echo "FAIL: module structure is invalid" > $out
      exit 1
    }
    echo "PASS: module structure is valid" > $out
  '';

  # Test that home.packages is a list
  testHomePackagesList = pkgs.runCommand "test-home-packages-list" {} ''
    if [ ${builtins.toString (builtins.isList sddModule.home.packages)} = "1" ]; then
      echo "PASS: home.packages is a list" > $out
    else
      echo "FAIL: home.packages is not a list" > $out
      exit 1
    fi
  '';

  # Test that exactly one package is provided
  testPackageCount = pkgs.runCommand "test-package-count" {} ''
    count=${builtins.toString (builtins.length sddModule.home.packages)}
    if [ "$count" = "1" ]; then
      echo "PASS: exactly one package in home.packages" > $out
    else
      echo "FAIL: expected 1 package, got $count" > $out
      exit 1
    fi
  '';

  # Integration test: verify the script can be sourced without errors
  testScriptSyntax = pkgs.runCommand "test-openspec-syntax" {
    buildInputs = [ pkgs.bash ];
  } ''
    bash -n "${openspecPkg}/bin/openspec" || {
      echo "FAIL: script has syntax errors" > $out
      exit 1
    }
    echo "PASS: script has valid syntax" > $out
  '';

  # Test nodejs package is correctly referenced
  testNodejsReference = pkgs.runCommand "test-nodejs-reference" {} ''
    # Check that nodejs path is correctly embedded
    if grep -q "${pkgs.nodejs}" "${openspecPkg}/bin/openspec"; then
      echo "PASS: nodejs is correctly referenced" > $out
    else
      echo "FAIL: nodejs reference not found" > $out
      exit 1
    fi
  '';

  # Test that the derivation has correct metadata
  testDerivationMetadata = pkgs.runCommand "test-openspec-metadata" {} ''
    if [ "${openspecPkg.name}" = "openspec" ]; then
      echo "PASS: derivation has correct name" > $out
    else
      echo "FAIL: derivation name is ${openspecPkg.name}, expected openspec" > $out
      exit 1
    fi
  '';

in {
  # Export all tests
  inherit
    testScriptExists
    testScriptShebang
    testNodejsInPath
    testNpxCommand
    testCorrectVersion
    testArgumentPassing
    testScriptExecutable
    testExecUsed
    testScriptStructure
    testModuleStructure
    testHomePackagesList
    testPackageCount
    testScriptSyntax
    testNodejsReference
    testDerivationMetadata;

  # Combined test that runs all tests
  all = pkgs.runCommand "test-sdd-all" {
    buildInputs = [ pkgs.bash ];
  } ''
    echo "Running all openspec tests..."
    
    tests=(
      "${testScriptExists}"
      "${testScriptShebang}"
      "${testNodejsInPath}"
      "${testNpxCommand}"
      "${testCorrectVersion}"
      "${testArgumentPassing}"
      "${testScriptExecutable}"
      "${testExecUsed}"
      "${testScriptStructure}"
      "${testModuleStructure}"
      "${testHomePackagesList}"
      "${testPackageCount}"
      "${testScriptSyntax}"
      "${testNodejsReference}"
      "${testDerivationMetadata}"
    )
    
    for test in "''${tests[@]}"; do
      cat "$test"
    done
    
    echo "All tests passed!" > $out
  '';
}