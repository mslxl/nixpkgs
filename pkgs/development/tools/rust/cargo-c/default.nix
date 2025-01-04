{
  lib,
  rustPlatform,
  fetchCrate,
  pkg-config,
  curl,
  openssl,
  stdenv,
  CoreFoundation,
  libiconv,
  Security,
  rav1e,
}:

rustPlatform.buildRustPackage rec {
  pname = "cargo-c";
  version = "0.10.2";

  src = fetchCrate {
    inherit pname;
    # this version may need to be updated along with package version
    version = "${version}+cargo-0.80.0";
    hash = "sha256-ltxd4n3oo8ZF/G/zmR4FSVtNOkxwCjDv6PdxkmWxZ+8=";
  };

  cargoHash = "sha256-UfhIz87s0CLUDbIpWMPzGQ7qVmh14GuiFoquauSbTOw=";

  nativeBuildInputs = [
    pkg-config
    (lib.getDev curl)
  ];
  buildInputs =
    [
      openssl
      curl
    ]
    ++ lib.optionals stdenv.hostPlatform.isDarwin [
      CoreFoundation
      libiconv
      Security
    ];

  # Ensure that we are avoiding build of the curl vendored in curl-sys
  doInstallCheck = stdenv.hostPlatform.libc == "glibc";
  installCheckPhase = ''
    runHook preInstallCheck

    ldd "$out/bin/cargo-cbuild" | grep libcurl.so

    runHook postInstallCheck
  '';

  passthru.tests = {
    inherit rav1e;
  };

  meta = with lib; {
    description = "Cargo subcommand to build and install C-ABI compatible dynamic and static libraries";
    longDescription = ''
      Cargo C-ABI helpers. A cargo applet that produces and installs a correct
      pkg-config file, a static library and a dynamic library, and a C header
      to be used by any C (and C-compatible) software.
    '';
    homepage = "https://github.com/lu-zero/cargo-c";
    changelog = "https://github.com/lu-zero/cargo-c/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = with maintainers; [
      cpu
      matthiasbeyer
    ];
  };
}
