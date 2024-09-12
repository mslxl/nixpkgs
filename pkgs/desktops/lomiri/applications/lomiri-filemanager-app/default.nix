{
  stdenv,
  lib,
  fetchFromGitLab,
  fetchpatch,
  gitUpdater,
  nixosTests,
  biometryd,
  cmake,
  gettext,
  lomiri-content-hub,
  lomiri-thumbnailer,
  lomiri-ui-extras,
  lomiri-ui-toolkit,
  pkg-config,
  python3,
  qtbase,
  qtdeclarative,
  samba,
  wrapQtAppsHook,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "lomiri-filemanager-app";
  version = "1.1.1";

  src = fetchFromGitLab {
    owner = "ubports";
    repo = "development/apps/lomiri-filemanager-app";
    rev = "v${finalAttrs.version}";
    hash = "sha256-KZzkD+h2yUeBvNFn9xLLtc4Iukk6maimFjIdpGCWLOE=";
  };

  patches = [
    # Remove when https://gitlab.com/ubports/development/apps/lomiri-filemanager-app/-/merge_requests/117 merged & in release
    (fetchpatch {
      name = "0001-lomiri-filemanager-app-Install-content-hub-and-url-dispatcher-files.patch";
      url = "https://gitlab.com/ubports/development/apps/lomiri-filemanager-app/-/commit/e15dc7c5b4dd0b9e5df3e4e99da8f28bd760e093.patch";
      hash = "sha256-MXuQXpZcf5fJP4aenl5KDOtdaDFTTnkzIfem9BpE5ig=";
    })
    (fetchpatch {
      name = "0002-lomiri-filemanager-app-Let-desktop-icon-be-found-via-lookup.patch";
      url = "https://gitlab.com/ubports/development/apps/lomiri-filemanager-app/-/commit/8c38f30ac099609379b95079fac771a61d73e7d6.patch";
      hash = "sha256-I3hB+W/5JW08HcLiNrSpZ7rTeQyKNoMNINVrFbF/Uiw=";
    })
  ];

  postPatch = ''
    # Use correct QML install path, don't pull in autopilot test code (we can't run that system)
    # Remove absolute paths from desktop file, https://github.com/NixOS/nixpkgs/issues/308324
    substituteInPlace CMakeLists.txt \
      --replace-fail 'qmake -query QT_INSTALL_QML' 'echo ${placeholder "out"}/${qtbase.qtQmlPrefix}' \
      --replace-fail 'add_subdirectory(tests)' '#add_subdirectory(tests)' \
      --replace-fail 'SPLASH ''${DATA_DIR}/''${SPLASH_FILE}' 'SPLASH lomiri-app-launch/splash/lomiri-filemanager-app.svg'

    # In case this ever gets run, at least point it to a correct-ish path
    substituteInPlace tests/autopilot/CMakeLists.txt \
      --replace-fail 'python3 -c "from distutils.sysconfig import get_python_lib; print(get_python_lib())"' 'echo "${placeholder "out"}/${python3.sitePackages}/lomiri_filemanager_app"'
  '';

  strictDeps = true;

  nativeBuildInputs = [
    cmake
    gettext
    pkg-config
    wrapQtAppsHook
  ];

  buildInputs = [
    qtbase
    qtdeclarative
    samba

    # QML
    biometryd
    lomiri-content-hub
    lomiri-thumbnailer
    lomiri-ui-extras
    lomiri-ui-toolkit
  ];

  cmakeFlags = [
    (lib.cmakeBool "INSTALL_TESTS" false)
    (lib.cmakeBool "CLICK_MODE" false)
  ];

  # No tests we can actually run (just autopilot)
  doCheck = false;

  passthru = {
    tests.vm = nixosTests.lomiri-filemanager-app;
    updateScript = gitUpdater { rev-prefix = "v"; };
  };

  meta = {
    description = "File Manager application for Ubuntu Touch devices";
    homepage = "https://gitlab.com/ubports/development/apps/lomiri-filemanager-app";
    changelog = "https://gitlab.com/ubports/development/apps/lomiri-filemanager-app/-/blob/v${finalAttrs.version}/ChangeLog";
    license = lib.licenses.gpl3Only;
    mainProgram = "lomiri-filemanager-app";
    maintainers = lib.teams.lomiri.members;
    platforms = lib.platforms.linux;
  };
})
