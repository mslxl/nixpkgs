{ buildGoModule, fetchFromGitHub, go, lib, makeWrapper }:

buildGoModule rec {
  pname = "revive";
  version = "1.6.0";

  src = fetchFromGitHub {
    owner = "mgechev";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-MiD5b5cLUY+ORrHtyqynM/kdFKIHb/4CMWd6Dq+6TcY=";
    # populate values that require us to use git. By doing this in postFetch we
    # can delete .git afterwards and maintain better reproducibility of the src.
    leaveDotGit = true;
    postFetch = ''
      date -u -d "@$(git -C $out log -1 --pretty=%ct)" "+%Y-%m-%d %H:%M UTC" > $out/DATE
      git -C $out rev-parse HEAD > $out/COMMIT
      rm -rf $out/.git
    '';
  };
  vendorHash = "sha256-KFLnc7PFKbZ8VOUOx0EnRLyMYQzZVFZphDhk2KNRiIc=";

  ldflags = [
    "-s"
    "-w"
    "-X github.com/mgechev/revive/cli.version=${version}"
    "-X github.com/mgechev/revive/cli.builtBy=nix"
  ];

  # ldflags based on metadata from git and source
  preBuild = ''
    ldflags+=" -X github.com/mgechev/revive/cli.commit=$(cat COMMIT)"
    ldflags+=" -X 'github.com/mgechev/revive/cli.date=$(cat DATE)'"
  '';

  allowGoReference = true;

  nativeBuildInputs = [ makeWrapper ];

  postFixup = ''
    wrapProgram $out/bin/revive \
      --prefix PATH : ${lib.makeBinPath [ go ]}
  '';

  meta = with lib; {
    description = "Fast, configurable, extensible, flexible, and beautiful linter for Go";
    mainProgram = "revive";
    homepage = "https://revive.run";
    license = licenses.mit;
    maintainers = with maintainers; [ maaslalani ];
  };
}
