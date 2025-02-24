{
  lib,
  stdenv,
  buildPackages,
  fetchurl,
  perl,
  libintl,
  bashNonInteractive,
  updateAutotoolsGnuConfigScriptsHook,
  gnulib,
  gawk,
  freebsd,
  libiconv,
  xz,

  # we are a dependency of gcc, this simplifies bootstrapping
  interactive ? false,
  ncurses,
  procps,
  meta,
}:

{
  version,
  hash,
  patches ? [ ],
}:

# Note: this package is used for bootstrapping fetchurl, and thus
# cannot use fetchpatch! All mutable patches (generated by GitHub or
# cgit) that are needed here should be included directly in Nixpkgs as
# files.

let
  inherit (lib)
    getBin
    getDev
    getLib
    optional
    optionals
    optionalString
    versionOlder
    ;
  crossBuildTools = stdenv.hostPlatform != stdenv.buildPlatform;
in

stdenv.mkDerivation {
  pname = "texinfo${optionalString interactive "-interactive"}";
  inherit version;

  src = fetchurl {
    url = "mirror://gnu/texinfo/texinfo-${version}.tar.xz";
    inherit hash;
  };

  patches = patches ++ optional crossBuildTools ./cross-tools-flags.patch;

  postPatch =
    ''
      patchShebangs tp/maintain/regenerate_commands_perl_info.pl
    ''
    # This patch is needed for IEEE-standard long doubles on
    # powerpc64; it does not apply cleanly to texinfo 5.x or
    # earlier.  It is merged upstream in texinfo 6.8.
    + optionalString (version == "6.7") ''
      patch -p1 -d gnulib < ${gnulib.passthru.longdouble-redirect-patch}
    '';

  # ncurses is required to build `makedoc'
  # this feature is introduced by the ./cross-tools-flags.patch
  NATIVE_TOOLS_CFLAGS = if crossBuildTools then "-I${getDev buildPackages.ncurses}/include" else null;
  NATIVE_TOOLS_LDFLAGS = if crossBuildTools then "-L${getLib buildPackages.ncurses}/lib" else null;

  strictDeps = true;
  enableParallelBuilding = true;

  # A native compiler is needed to build tools needed at build time
  depsBuildBuild = [
    buildPackages.stdenv.cc
    perl
  ];

  nativeBuildInputs = [ updateAutotoolsGnuConfigScriptsHook ];
  buildInputs =
    [
      bashNonInteractive
      libintl
    ]
    ++ optionals stdenv.hostPlatform.isSunOS [
      libiconv
      gawk
    ]
    ++ optional interactive ncurses;

  configureFlags =
    [ "PERL=${buildPackages.perl}/bin/perl" ]
    # Perl XS modules are difficult to cross-compile and texinfo has pure Perl
    # fallbacks.
    # Also prevent the buildPlatform's awk being used in the texindex script
    ++ optionals crossBuildTools [
      "--enable-perl-xs=no"
      "TI_AWK=${getBin gawk}/bin/awk"
    ]
    ++ optionals (crossBuildTools && lib.versionAtLeast version "7.1") [
      "texinfo_cv_sys_iconv_converts_euc_cn=yes"
    ]
    ++ optional stdenv.hostPlatform.isSunOS "AWK=${gawk}/bin/awk";

  installFlags = [ "TEXMF=$(out)/texmf-dist" ];
  installTargets = [
    "install"
    "install-tex"
  ];

  nativeCheckInputs = [ procps ] ++ optionals stdenv.buildPlatform.isFreeBSD [ freebsd.locale ];

  doCheck = interactive && !stdenv.hostPlatform.isDarwin && !stdenv.hostPlatform.isSunOS; # flaky

  checkFlags = optionals (!stdenv.hostPlatform.isMusl && versionOlder version "7") [
    # Test is known to fail on various locales on texinfo-6.8:
    #   https://lists.gnu.org/r/bug-texinfo/2021-07/msg00012.html
    "XFAIL_TESTS=test_scripts/layout_formatting_fr_icons.sh"
  ];

  postFixup = optionalString crossBuildTools ''
    for f in "$out"/bin/{pod2texi,texi2any}; do
      substituteInPlace "$f" \
        --replace-fail ${buildPackages.perl}/bin/perl ${perl}/bin/perl
    done
  '';

  meta = meta // {
    branch = version;
    # see comment above in patches section
    broken = stdenv.hostPlatform.isPower64 && versionOlder version "6.0";
  };
}
