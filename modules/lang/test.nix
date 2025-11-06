# Integration tests for the lang module
{ pkgs, lib }:

let
  # Import the module
  langModule = import ./default.nix { inherit pkgs; };
  
  # Get the list of packages
  packages = langModule.home.packages;

  # Test that home.packages exists and is a list
  testHomePackagesList = pkgs.runCommand "test-lang-packages-list" {} ''
    if [ ${builtins.toString (builtins.isList packages)} = "1" ]; then
      echo "PASS: home.packages is a list" > $out
    else
      echo "FAIL: home.packages is not a list" > $out
      exit 1
    fi
  '';

  # Test that the expected number of packages is present
  testPackageCount = pkgs.runCommand "test-lang-package-count" {} ''
    count=${builtins.toString (builtins.length packages)}
    if [ "$count" = "3" ]; then
      echo "PASS: correct number of packages (3)" > $out
    else
      echo "FAIL: expected 3 packages, got $count" > $out
      exit 1
    fi
  '';

  # Test that clang is included
  testClangIncluded = pkgs.runCommand "test-lang-clang" {} ''
    found=0
    ${lib.concatMapStringsSep "\n" (pkg: ''
      if [ "${pkg.pname or pkg.name or ""}" = "clang" ] || [ "${pkg.pname or pkg.name or ""}" = "clang-wrapper" ]; then
        found=1
      fi
    '') packages}
    
    if [ "$found" = "1" ]; then
      echo "PASS: clang is included" > $out
    else
      echo "FAIL: clang not found in packages" > $out
      exit 1
    fi
  '';

  # Test that nodejs is included
  testNodejsIncluded = pkgs.runCommand "test-lang-nodejs" {} ''
    found=0
    ${lib.concatMapStringsSep "\n" (pkg: ''
      if [ "${pkg.pname or pkg.name or ""}" = "nodejs" ]; then
        found=1
      fi
    '') packages}
    
    if [ "$found" = "1" ]; then
      echo "PASS: nodejs is included" > $out
    else
      echo "FAIL: nodejs not found in packages" > $out
      exit 1
    fi
  '';

  # Test that uv is included
  testUvIncluded = pkgs.runCommand "test-lang-uv" {} ''
    found=0
    ${lib.concatMapStringsSep "\n" (pkg: ''
      if [ "${pkg.pname or pkg.name or ""}" = "uv" ]; then
        found=1
      fi
    '') packages}
    
    if [ "$found" = "1" ]; then
      echo "PASS: uv is included" > $out
    else
      echo "FAIL: uv not found in packages" > $out
      exit 1
    fi
  '';

  # Test that all packages are derivations
  testAllAreDerivations = pkgs.runCommand "test-lang-derivations" {} ''
    ${lib.concatMapStringsSep "\n" (pkg: ''
      if ! [ -d "${pkg}" ]; then
        echo "FAIL: package ${pkg.name or "unknown"} is not a valid derivation" > $out
        exit 1
      fi
    '') packages}
    echo "PASS: all packages are valid derivations" > $out
  '';

  # Test that packages have binaries
  testPackagesHaveBinaries = pkgs.runCommand "test-lang-binaries" {} ''
    missing=""
    ${lib.concatMapStringsSep "\n" (pkg: ''
      if ! [ -d "${pkg}/bin" ]; then
        missing="$missing ${pkg.name or pkg.pname or "unknown"}"
      fi
    '') packages}
    
    if [ -z "$missing" ]; then
      echo "PASS: all packages have /bin directories" > $out
    else
      echo "FAIL: packages missing /bin: $missing" > $out
      exit 1
    fi
  '';

  # Test clang binary exists
  testClangBinary = pkgs.runCommand "test-clang-binary" {} ''
    clang_pkg=""
    ${lib.concatMapStringsSep "\n" (pkg: ''
      if [ "${pkg.pname or pkg.name or ""}" = "clang" ] || [ "${pkg.pname or pkg.name or ""}" = "clang-wrapper" ]; then
        clang_pkg="${pkg}"
      fi
    '') packages}
    
    if [ -n "$clang_pkg" ] && [ -x "$clang_pkg/bin/clang" ]; then
      echo "PASS: clang binary is executable" > $out
    else
      echo "FAIL: clang binary not found or not executable" > $out
      exit 1
    fi
  '';

  # Test nodejs binary exists
  testNodejsBinary = pkgs.runCommand "test-nodejs-binary" {} ''
    nodejs_pkg=""
    ${lib.concatMapStringsSep "\n" (pkg: ''
      if [ "${pkg.pname or pkg.name or ""}" = "nodejs" ]; then
        nodejs_pkg="${pkg}"
      fi
    '') packages}
    
    if [ -n "$nodejs_pkg" ] && [ -x "$nodejs_pkg/bin/node" ]; then
      echo "PASS: nodejs binary is executable" > $out
    else
      echo "FAIL: nodejs binary not found or not executable" > $out
      exit 1
    fi
  '';

  # Test that npm is included with nodejs
  testNpmIncluded = pkgs.runCommand "test-npm-included" {} ''
    nodejs_pkg=""
    ${lib.concatMapStringsSep "\n" (pkg: ''
      if [ "${pkg.pname or pkg.name or ""}" = "nodejs" ]; then
        nodejs_pkg="${pkg}"
      fi
    '') packages}
    
    if [ -n "$nodejs_pkg" ] && [ -x "$nodejs_pkg/bin/npm" ]; then
      echo "PASS: npm is included with nodejs" > $out
    else
      echo "FAIL: npm not found with nodejs" > $out
      exit 1
    fi
  '';

  # Test that npx is included with nodejs
  testNpxIncluded = pkgs.runCommand "test-npx-included" {} ''
    nodejs_pkg=""
    ${lib.concatMapStringsSep "\n" (pkg: ''
      if [ "${pkg.pname or pkg.name or ""}" = "nodejs" ]; then
        nodejs_pkg="${pkg}"
      fi
    '') packages}
    
    if [ -n "$nodejs_pkg" ] && [ -x "$nodejs_pkg/bin/npx" ]; then
      echo "PASS: npx is included with nodejs" > $out
    else
      echo "FAIL: npx not found with nodejs" > $out
      exit 1
    fi
  '';

  # Test uv binary exists
  testUvBinary = pkgs.runCommand "test-uv-binary" {} ''
    uv_pkg=""
    ${lib.concatMapStringsSep "\n" (pkg: ''
      if [ "${pkg.pname or pkg.name or ""}" = "uv" ]; then
        uv_pkg="${pkg}"
      fi
    '') packages}
    
    if [ -n "$uv_pkg" ] && [ -x "$uv_pkg/bin/uv" ]; then
      echo "PASS: uv binary is executable" > $out
    else
      echo "FAIL: uv binary not found or not executable" > $out
      exit 1
    fi
  '';

  # Test module structure is valid
  testModuleStructure = pkgs.runCommand "test-lang-module-structure" {} ''
    ${pkgs.lib.generators.toPretty {} langModule} > /dev/null || {
      echo "FAIL: module structure is invalid" > $out
      exit 1
    }
    echo "PASS: module structure is valid" > $out
  '';

in {
  # Export all tests
  inherit
    testHomePackagesList
    testPackageCount
    testClangIncluded
    testNodejsIncluded
    testUvIncluded
    testAllAreDerivations
    testPackagesHaveBinaries
    testClangBinary
    testNodejsBinary
    testNpmIncluded
    testNpxIncluded
    testUvBinary
    testModuleStructure;

  # Combined test
  all = pkgs.runCommand "test-lang-all" {} ''
    echo "Running all lang module tests..."
    
    tests=(
      "${testHomePackagesList}"
      "${testPackageCount}"
      "${testClangIncluded}"
      "${testNodejsIncluded}"
      "${testUvIncluded}"
      "${testAllAreDerivations}"
      "${testPackagesHaveBinaries}"
      "${testClangBinary}"
      "${testNodejsBinary}"
      "${testNpmIncluded}"
      "${testNpxIncluded}"
      "${testUvBinary}"
      "${testModuleStructure}"
    )
    
    for test in "''${tests[@]}"; do
      cat "$test"
    done
    
    echo "All lang module tests passed!" > $out
  '';
}