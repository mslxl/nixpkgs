# generated by zon2nix (https://github.com/Cloudef/zig2nix)

{
  lib,
  linkFarm,
  fetchurl,
  fetchgit,
  runCommandLocal,
  zig,
  name ? "zig-packages",
}:

with builtins;
with lib;

let
  unpackZigArtifact =
    { name, artifact }:
    runCommandLocal name
      {
        nativeBuildInputs = [ zig ];
      }
      ''
        hash="$(zig fetch --global-cache-dir "$TMPDIR" ${artifact})"
        mv "$TMPDIR/p/$hash" "$out"
        chmod 755 "$out"
      '';

  fetchZig =
    {
      name,
      url,
      hash,
    }:
    let
      artifact = fetchurl { inherit url hash; };
    in
    unpackZigArtifact { inherit name artifact; };

  fetchGitZig =
    {
      name,
      url,
      hash,
    }:
    let
      parts = splitString "#" url;
      url_base = elemAt parts 0;
      url_without_query = elemAt (splitString "?" url_base) 0;
      rev_base = elemAt parts 1;
      rev = if match "^[a-fA-F0-9]{40}$" rev_base != null then rev_base else "refs/heads/${rev_base}";
    in
    fetchgit {
      inherit name rev hash;
      url = url_without_query;
      deepClone = false;
    };

  fetchZigArtifact =
    {
      name,
      url,
      hash,
    }:
    let
      parts = splitString "://" url;
      proto = elemAt parts 0;
      path = elemAt parts 1;
      fetcher = {
        "git+http" = fetchGitZig {
          inherit name hash;
          url = "http://${path}";
        };
        "git+https" = fetchGitZig {
          inherit name hash;
          url = "https://${path}";
        };
        http = fetchZig {
          inherit name hash;
          url = "http://${path}";
        };
        https = fetchZig {
          inherit name hash;
          url = "https://${path}";
        };
      };
    in
    fetcher.${proto};
in
linkFarm name [
  {
    name = "1220687c8c47a48ba285d26a05600f8700d37fc637e223ced3aa8324f3650bf52242";
    path = fetchZigArtifact {
      name = "zig-wayland";
      url = "https://codeberg.org/ifreund/zig-wayland/archive/v0.2.0.tar.gz";
      hash = "sha256-gxzkHLCq2NqX3l4nEly92ARU5dqP1SqnjpGMDgx4TXA=";
    };
  }
  {
    name = "1220c90b2228d65fd8427a837d31b0add83e9fade1dcfa539bb56fd06f1f8461605f";
    path = fetchZigArtifact {
      name = "zig-xkbcommon";
      url = "https://codeberg.org/ifreund/zig-xkbcommon/archive/v0.2.0.tar.gz";
      hash = "sha256-f5oEJU5i2qeVN3GBrnQcqzEJCiOT7l4ak7GQ6gw5cH0=";
    };
  }
]
