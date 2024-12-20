{
  lib,
  stdenv,
  fetchFromGitHub,
  nix-update-script,
  rustPlatform,
  vimUtils,
}:
let
  version = "0-unstable-2024-09-26";
  src = fetchFromGitHub {
    owner = "vyfor";
    repo = "cord.nvim";
    rev = "a26b00d58c42174aadf975917b49cec67650545f";
    hash = "sha256-jUxBvWnj0+axuw2SZ2zLzlhZS0tu+Bk8+wHtXENofkw=";
  };
  extension = if stdenv.hostPlatform.isDarwin then "dylib" else "so";
  cord-nvim-rust = rustPlatform.buildRustPackage {
    pname = "cord.nvim-rust";
    inherit version src;

    cargoHash = "sha256-M5mTdBACTaUVZhPpMOf1KQ3BcQpEoD2isAKRn+iAWjc=";

    installPhase =
      let
        cargoTarget = stdenv.hostPlatform.rust.cargoShortTarget;
      in
      ''
        install -D target/${cargoTarget}/release/libcord.${extension} $out/lib/cord.${extension}
      '';
  };
in
vimUtils.buildVimPlugin {
  pname = "cord.nvim";
  inherit version src;

  nativeBuildInputs = [
    cord-nvim-rust
  ];

  buildPhase = ''
    runHook preBuild

    install -D ${cord-nvim-rust}/lib/cord.${extension} cord.${extension}

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -D cord $out/lua/cord.${extension}

    runHook postInstall
  '';

  doInstallCheck = true;
  nvimRequireCheck = "cord";

  passthru = {
    updateScript = nix-update-script {
      extraArgs = [ "--version=branch" ];
      attrPath = "vimPlugins.cord-nvim.cord-nvim-rust";
    };

    # needed for the update script
    inherit cord-nvim-rust;
  };

  meta = {
    homepage = "https://github.com/vyfor/cord.nvim";
    license = lib.licenses.asl20;
  };
}
