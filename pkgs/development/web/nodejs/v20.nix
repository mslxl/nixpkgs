{ callPackage, fetchpatch2, openssl, python3, enableNpm ? true }:

let
  buildNodejs = callPackage ./nodejs.nix {
    inherit openssl;
    python = python3;
  };

  gypPatches = callPackage ./gyp-patches.nix { } ++ [
    ./gyp-patches-pre-v22-import-sys.patch
  ];
in
buildNodejs {
  inherit enableNpm;
  version = "20.18.0";
  sha256 = "7d9433e91fd88d82ba8de86e711ec41907638e227993d22e95126b02f6cd714a";
  patches = [
    ./configure-emulator.patch
    ./configure-armv6-vfpv2.patch
    ./disable-darwin-v8-system-instrumentation-node19.patch
    ./bypass-darwin-xcrun-node16.patch
    ./node-npm-build-npm-package-logic.patch
    ./use-correct-env-in-tests.patch

    # Patches for OpenSSL 3.2
    # Patches not yet released
    (fetchpatch2 {
      url = "https://github.com/nodejs/node/commit/f8b7a171463e775da304bccf4cf165e634525c7e.patch?full_index=1";
      hash = "sha256-imptUwt2oG8pPGKD3V6m5NQXuahis71UpXiJm4C0E6o=";
    })
    (fetchpatch2 {
      url = "https://github.com/nodejs/node/commit/6dfa3e46d3d2f8cfba7da636d48a5c41b0132cd7.patch?full_index=1";
      hash = "sha256-ITtGsvZI6fliirCKvbMH9N2Xoy3001bz+hS3NPoqvzg=";
    })
    (fetchpatch2 {
      url = "https://github.com/nodejs/node/commit/29b9c72b05786061cde58a5ae11cfcb580ab6c28.patch?full_index=1";
      hash = "sha256-xaqtwsrOIyRV5zzccab+nDNG8kUgO6AjrVYJNmjeNP0=";
    })
    (fetchpatch2 {
      url = "https://github.com/nodejs/node/commit/cfe58cfdc488da71e655d3da709292ce6d9ddb58.patch?full_index=1";
      hash = "sha256-9GblpbQcYfoiE5R7fETsdW7v1Mm2Xdr4+xRNgUpLO+8=";
    })
    (fetchpatch2 {
      url = "https://github.com/nodejs/node/commit/2cec716c48cea816dcd5bf4997ae3cdf1fe4cd90.patch?full_index=1";
      hash = "sha256-ExIkAj8yRJEK39OfV6A53HiuZsfQOm82/Tvj0nCaI8A=";
    })
    (fetchpatch2 {
      url = "https://github.com/nodejs/node/commit/0f7bdcc17fbc7098b89f238f4bd8ecad9367887b.patch?full_index=1";
      hash = "sha256-lXx6QyD2anlY9qAwjNMFM2VcHckBshghUF1NaMoaNl4=";
    })
    # Remove unused `fdopen` in vendored zlib, which causes compilation failures with clang 18 on Darwin.
    (fetchpatch2 {
      url = "https://github.com/madler/zlib/commit/4bd9a71f3539b5ce47f0c67ab5e01f3196dc8ef9.patch?full_index=1";
      extraPrefix = "deps/v8/third_party/zlib/";
      stripLen = 1;
      hash = "sha256-WVxsoEcJu0WBTyelNrVQFTZxJhnekQb1GrueeRBRdnY=";
    })
    # Backport V8 fixes for LLVM 19.
    (fetchpatch2 {
      url = "https://chromium.googlesource.com/v8/v8/+/182d9c05e78b1ddb1cb8242cd3628a7855a0336f%5E%21/?format=TEXT";
      decode = "base64 -d";
      extraPrefix = "deps/v8/";
      stripLen = 1;
      hash = "sha256-bDTwFbATPn5W4VifWz/SqaiigXYDWHq785C64VezuUE=";
    })
    (fetchpatch2 {
      url = "https://chromium.googlesource.com/v8/v8/+/1a3ecc2483b2dba6ab9f7e9f8f4b60dbfef504b7%5E%21/?format=TEXT";
      decode = "base64 -d";
      extraPrefix = "deps/v8/";
      stripLen = 1;
      hash = "sha256-6y3aEqxNC4iTQEv1oewodJrhOHxjp5xZMq1P1QL94Rg=";
    })
  ] ++ gypPatches;
}
