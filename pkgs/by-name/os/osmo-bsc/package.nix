{
  lib,
  stdenv,
  fetchFromGitHub,
  autoreconfHook,
  pkg-config,
  libosmocore,
  libosmoabis,
  libosmo-netif,
  libosmo-sccp,
  osmo-mgw,
}:

let
  inherit (stdenv.hostPlatform) isLinux;
in

stdenv.mkDerivation rec {
  pname = "osmo-bsc";
  version = "1.12.2";

  src = fetchFromGitHub {
    owner = "osmocom";
    repo = "osmo-bsc";
    rev = version;
    hash = "sha256-V1URXatXYaItv1X5VAuWpaeTNJjK6qb9DqmecDm2PQ0=";
  };

  postPatch = ''
    echo "${version}" > .tarball-version
  '';

  nativeBuildInputs = [
    autoreconfHook
    pkg-config
  ];

  buildInputs = [
    libosmocore
    libosmoabis
    libosmo-netif
    libosmo-sccp
    osmo-mgw
  ];

  enableParallelBuilding = true;

  meta = {
    description = "GSM Base Station Controller";
    homepage = "https://projects.osmocom.org/projects/osmobsc";
    license = lib.licenses.agpl3Plus;
    maintainers = [ ];
    platforms = lib.platforms.linux;
    mainProgram = "osmo-bsc";
  };
}
