{ lib
, stdenv
, fetchFromGitHub
, gettext
, help2man
, meson
, ninja
, pkg-config
, vala
, gtk3
, json-glib
, libgee
, util-linux
, vte
, xapp
}:

stdenv.mkDerivation rec {
  pname = "timeshift";
  version = "24.06.5";

  src = fetchFromGitHub {
    owner = "linuxmint";
    repo = "timeshift";
    rev = version;
    hash = "sha256-2qNLgUZLMcfoemdLvvjdkR7Ln5loSKGqbd402y5Id8k=";
  };

  patches = [
    ./timeshift-launcher.patch
  ];

  postPatch = ''
    for FILE in src/Core/Main.vala src/Utility/Device.vala; do
      substituteInPlace "$FILE" \
        --replace-fail "/sbin/blkid" "${lib.getExe' util-linux "blkid"}"
    done

    substituteInPlace ./src/Utility/IconManager.vala \
      --replace-fail "/usr/share" "$out/share"
  '';

  nativeBuildInputs = [
    gettext
    help2man
    meson
    ninja
    pkg-config
    vala
  ];

  buildInputs = [
    gtk3
    json-glib
    libgee
    vte
    xapp
  ];

  meta = with lib; {
    description = "System restore tool for Linux";
    longDescription = ''
      TimeShift creates filesystem snapshots using rsync+hardlinks or BTRFS snapshots.
      Snapshots can be restored using TimeShift installed on the system or from Live CD or USB.
    '';
    homepage = "https://github.com/linuxmint/timeshift";
    license = licenses.gpl2Plus;
    platforms = platforms.linux;
    maintainers = with maintainers; [ ShamrockLee bobby285271 ];
  };
}
