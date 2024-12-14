{
  stdenv,
  fetchFromGitea,
  lcrq,
  lib,
  libsodium,
}:
stdenv.mkDerivation (finalAttrs: {
  pname = "librecast";
  version = "0.9.1";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "librecast";
    repo = "librecast";
    rev = "v${finalAttrs.version}";
    hash = "sha256-pW18yYKzuWNt1+fzb/Y00cBr/gTENxeh7qLFSzFsmN0=";
  };
  buildInputs = [
    lcrq
    libsodium
  ];
  installFlags = [ "PREFIX=$(out)" ];

  meta = {
    changelog = "https://codeberg.org/librecast/librecast/src/tag/v${finalAttrs.version}/CHANGELOG.md";
    description = "IPv6 multicast library";
    homepage = "https://librecast.net/librecast.html";
    license = [
      lib.licenses.gpl2
      lib.licenses.gpl3
    ];
    maintainers = with lib.maintainers; [
      albertchae
      aynish
      DMills27
      jasonodoom
      jleightcap
    ];
    platforms = lib.platforms.gnu;
  };
})
