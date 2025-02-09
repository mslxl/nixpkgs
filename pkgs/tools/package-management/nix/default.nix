{ lib
, config
, stdenv
, aws-sdk-cpp
, boehmgc
, libgit2
, callPackage
, fetchFromGitHub
, fetchpatch2
, runCommand
, Security
, pkgs
, pkgsi686Linux
, pkgsStatic
, nixosTests

, storeDir ? "/nix/store"
, stateDir ? "/nix/var"
, confDir ? "/etc"
}:
let
  boehmgc-nix_2_3 = boehmgc.override { enableLargeConfig = true; };

  boehmgc-nix = boehmgc-nix_2_3.overrideAttrs (drv: {
    patches = (drv.patches or [ ]) ++ [
      # Part of the GC solution in https://github.com/NixOS/nix/pull/4944
      ./patches/boehmgc-coroutine-sp-fallback.patch
    ];
  });

  # old nix fails to build with newer aws-sdk-cpp and the patch doesn't apply
  aws-sdk-cpp-old-nix = (aws-sdk-cpp.override {
    apis = [ "s3" "transfer" ];
    customMemoryManagement = false;
  }).overrideAttrs (args: rec {
    # intentionally overriding postPatch
    version = "1.9.294";

    src = fetchFromGitHub {
      owner = "aws";
      repo = "aws-sdk-cpp";
      rev = version;
      hash = "sha256-Z1eRKW+8nVD53GkNyYlZjCcT74MqFqqRMeMc33eIQ9g=";
    };
    postPatch = ''
      # Avoid blanket -Werror to evade build failures on less
      # tested compilers.
      substituteInPlace cmake/compiler_settings.cmake \
        --replace '"-Werror"' ' '

      # Missing includes for GCC11
      sed '5i#include <thread>' -i \
        aws-cpp-sdk-cloudfront-integration-tests/CloudfrontOperationTest.cpp \
        aws-cpp-sdk-cognitoidentity-integration-tests/IdentityPoolOperationTest.cpp \
        aws-cpp-sdk-dynamodb-integration-tests/TableOperationTest.cpp \
        aws-cpp-sdk-elasticfilesystem-integration-tests/ElasticFileSystemTest.cpp \
        aws-cpp-sdk-lambda-integration-tests/FunctionTest.cpp \
        aws-cpp-sdk-mediastore-data-integration-tests/MediaStoreDataTest.cpp \
        aws-cpp-sdk-queues/source/sqs/SQSQueue.cpp \
        aws-cpp-sdk-redshift-integration-tests/RedshiftClientTest.cpp \
        aws-cpp-sdk-s3-crt-integration-tests/BucketAndObjectOperationTest.cpp \
        aws-cpp-sdk-s3-integration-tests/BucketAndObjectOperationTest.cpp \
        aws-cpp-sdk-s3control-integration-tests/S3ControlTest.cpp \
        aws-cpp-sdk-sqs-integration-tests/QueueOperationTest.cpp \
        aws-cpp-sdk-transfer-tests/TransferTests.cpp
      # Flaky on Hydra
      rm aws-cpp-sdk-core-tests/aws/auth/AWSCredentialsProviderTest.cpp
      # Includes aws-c-auth private headers, so only works with submodule build
      rm aws-cpp-sdk-core-tests/aws/auth/AWSAuthSignerTest.cpp
      # TestRandomURLMultiThreaded fails
      rm aws-cpp-sdk-core-tests/http/HttpClientTest.cpp
    '' + lib.optionalString aws-sdk-cpp.stdenv.hostPlatform.isi686 ''
      # EPSILON is exceeded
      rm aws-cpp-sdk-core-tests/aws/client/AdaptiveRetryStrategyTest.cpp
    '';

    patches = (args.patches or [ ]) ++ [ ./patches/aws-sdk-cpp-TransferManager-ContentEncoding.patch ];

    # only a stripped down version is build which takes a lot less resources to build
    requiredSystemFeatures = [ ];
  });

  aws-sdk-cpp-nix = (aws-sdk-cpp.override {
    apis = [ "s3" "transfer" ];
    customMemoryManagement = false;
  }).overrideAttrs {
    # only a stripped down version is build which takes a lot less resources to build
    requiredSystemFeatures = [ ];
  };

  common = args:
    callPackage
      (import ./common.nix ({ inherit lib fetchFromGitHub; } // args))
      {
        inherit Security storeDir stateDir confDir;
        boehmgc = boehmgc-nix;
        aws-sdk-cpp = if lib.versionAtLeast args.version "2.12pre" then aws-sdk-cpp-nix else aws-sdk-cpp-old-nix;
      };

  # https://github.com/NixOS/nix/pull/7585
  patch-monitorfdhup = fetchpatch2 {
    name = "nix-7585-monitor-fd-hup.patch";
    url = "https://github.com/NixOS/nix/commit/1df3d62c769dc68c279e89f68fdd3723ed3bcb5a.patch";
    hash = "sha256-f+F0fUO+bqyPXjt+IXJtISVr589hdc3y+Cdrxznb+Nk=";
  };

  # Intentionally does not support overrideAttrs etc
  # Use only for tests that are about the package relation to `pkgs` and/or NixOS.
  addTestsShallowly = tests: pkg: pkg // {
    tests = pkg.tests // tests;
    # In case someone reads the wrong attribute
    passthru.tests = pkg.tests // tests;
  };

  addFallbackPathsCheck = pkg: addTestsShallowly
    { nix-fallback-paths =
        runCommand "test-nix-fallback-paths-version-equals-nix-stable" {
          paths = lib.concatStringsSep "\n" (builtins.attrValues (import ../../../../nixos/modules/installer/tools/nix-fallback-paths.nix));
        } ''
          # NOTE: name may contain cross compilation details between the pname
          #       and version this is permitted thanks to ([^-]*-)*
          if [[ "" != $(grep -vE 'nix-([^-]*-)*${lib.strings.replaceStrings ["."] ["\\."] pkg.version}$' <<< "$paths") ]]; then
            echo "nix-fallback-paths not up to date with nixVersions.stable (nix-${pkg.version})"
            echo "The following paths are not up to date:"
            grep -v 'nix-${pkg.version}$' <<< "$paths"
            echo
            echo "Fix it by running in nixpkgs:"
            echo
            echo "curl https://releases.nixos.org/nix/nix-${pkg.version}/fallback-paths.nix >nixos/modules/installer/tools/nix-fallback-paths.nix"
            echo
            exit 1
          else
            echo "nix-fallback-paths versions up to date"
            touch $out
          fi
        '';
    }
    pkg;

in lib.makeExtensible (self: ({
  nix_2_3 = ((common {
    version = "2.3.18";
    hash = "sha256-jBz2Ub65eFYG+aWgSI3AJYvLSghio77fWQiIW1svA9U=";
    patches = [
      patch-monitorfdhup
    ];
    self_attribute_name = "nix_2_3";
    maintainers = with lib.maintainers; [ flokli ];
  }).override { boehmgc = boehmgc-nix_2_3; }).overrideAttrs {
    # https://github.com/NixOS/nix/issues/10222
    # spurious test/add.sh failures
    enableParallelChecking = false;
  };

  nix_2_24 = common {
    version = "2.24.12";
    hash = "sha256-lPiheE0D146tstoUInOUf1451stezrd8j6H6w7+RCv8=";
    self_attribute_name = "nix_2_24";
  };

  nix_2_25 = common {
    version = "2.25.5";
    hash = "sha256-9xrQhrqHCSqWsQveykZvG/ZMu0se66fUQw3xVSg6BpQ=";
    self_attribute_name = "nix_2_25";
  };

  nix_2_26 = (callPackage ./2_26/componentized.nix { }).overrideAttrs (this: old: {
    passthru = old.passthru or {} // {
      tests =
        old.passthru.tests or {}
        // import ./tests.nix {
          inherit runCommand lib stdenv pkgs pkgsi686Linux pkgsStatic nixosTests;
          inherit (old) version src;
          nix = this.finalPackage;
          self_attribute_name = "nix_2_26";
        };
    };
  });

  git = common rec {
    version = "2.25.0";
    suffix = "pre20241101_${lib.substring 0 8 src.rev}";
    src = fetchFromGitHub {
      owner = "NixOS";
      repo = "nix";
      rev = "2e5759e3778c460efc5f7cfc4cb0b84827b5ffbe";
      hash = "sha256-E1Sp0JHtbD1CaGO3UbBH6QajCtOGqcrVfPSKL0n63yo=";
    };
    self_attribute_name = "git";
  };

  latest = self.nix_2_25;

  # The minimum Nix version supported by Nixpkgs
  # Note that some functionality *might* have been backported into this Nix version,
  # making this package an inaccurate representation of what features are available
  # in the actual lowest minver.nix *patch* version.
  minimum =
    let
      minver = import ../../../../lib/minver.nix;
      major = lib.versions.major minver;
      minor = lib.versions.minor minver;
      attribute = "nix_${major}_${minor}";
      nix = self.${attribute};
    in
    if ! self ? ${attribute} then
      throw "The minimum supported Nix version is ${minver} (declared in lib/minver.nix), but pkgs.nixVersions.${attribute} does not exist."
    else
      nix;

  # Read ./README.md before bumping a major release
  stable = addFallbackPathsCheck self.nix_2_24;
} // lib.optionalAttrs config.allowAliases (
  lib.listToAttrs (map (
    minor:
    let
      attr = "nix_2_${toString minor}";
    in
    lib.nameValuePair attr (throw "${attr} has been removed")
  ) (lib.range 4 23))
  // {
    unstable = throw "nixVersions.unstable has been removed. For bleeding edge (Nix master, roughly weekly updated) use nixVersions.git, otherwise use nixVersions.latest.";
  }
)))
