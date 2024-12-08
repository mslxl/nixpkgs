{ lib
, buildGoModule
, fetchFromGitHub
}:

buildGoModule rec {
  pname = "auth0-cli";
  version = "1.6.1";

  src = fetchFromGitHub {
    owner = "auth0";
    repo = "auth0-cli";
    rev = "refs/tags/v${version}";
    hash = "sha256-IuL/x7gcZj7RVRI3RhnsYgFo1XJ0CRF7sNvgMlLsPd0=";
  };

  vendorHash = "sha256-Yxjpc/DBt8TQF92RcfMa0IPDlWT9K2fw2cPEfsMOVfw=";

  ldflags = [
    "-s"
    "-w"
    "-X=github.com/auth0/auth0-cli/internal/buildinfo.Version=v${version}"
    "-X=github.com/auth0/auth0-cli/internal/buildinfo.Revision=0000000"
  ];

  preCheck = ''
    # Feed in all tests for testing
    # This is because subPackages above limits what is built to just what we
    # want but also limits the tests
    unset subPackages
    # Test requires network access
    substituteInPlace internal/cli/universal_login_customize_test.go \
      --replace-fail "TestFetchUniversalLoginBrandingData" "SkipFetchUniversalLoginBrandingData"
  '';

  subPackages = [ "cmd/auth0" ];

  meta = with lib; {
    description = "Supercharge your developer workflow";
    homepage = "https://auth0.github.io/auth0-cli";
    changelog = "https://github.com/auth0/auth0-cli/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = with maintainers; [ matthewcroughan ];
    mainProgram = "auth0";
  };
}
