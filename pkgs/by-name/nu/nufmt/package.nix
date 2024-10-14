{
  lib,
  stdenv,
  fetchFromGitHub,
  rustPlatform,
  darwin,
  ...
}:
rustPlatform.buildRustPackage rec {
  pname = "nufmt";
  version = "unstable-2023-09-25";

  src = fetchFromGitHub {
    owner = "nushell";
    repo = "nufmt";
    rev = "796ee834c1e31ead4c5479bf2827a4339c5d61d1";
    hash = "sha256-BwKLl8eMCrqVt9PA5SHAXxu3ypP2ePcSuljKL+wSkvw=";
  };

  buildInputs = lib.optionals stdenv.hostPlatform.isDarwin (
    with darwin.apple_sdk.frameworks;
    [
      IOKit
    ]
  );

  cargoHash = "sha256-16Z20opeZpoa7h258um+grL3ktPmY4P0M/tqMTr5hYc=";

  meta = {
    description = "Nushell formatter";
    homepage = "https://github.com/nushell/nufmt";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ iogamaster ];
    mainProgram = "nufmt";
  };
}
