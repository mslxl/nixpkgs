{ lib, rustPlatform, fetchFromGitHub, pkg-config, openssl, protobuf, stdenv
, darwin }:

rustPlatform.buildRustPackage rec {
  pname = "svix-server";
  version = "1.40.0";

  src = fetchFromGitHub {
    owner = "svix";
    repo = "svix-webhooks";
    rev = "v${version}";
    hash = "sha256-3rUyfFtsDOqJYwTipor1YSCdP+9ORYWmzl5Tt3/Kung=";
  };

  sourceRoot = "${src.name}/server";

  cargoLock = {
    lockFile = ./Cargo.lock;
    outputHashes = {
      "hyper-0.14.28" = "sha256-4HGGpM9Ce3l3EJnu5XsGfqhrD9EykpR+ihEJlSZc03Q=";
      "omniqueue-0.2.1" = "sha256-ab0/WO45m1A56EUY8nLUuxKI9NZqjDar9Y0ua77UCi8=";
    };
  };

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [
    openssl
    protobuf
  ] ++ lib.optionals stdenv.hostPlatform.isDarwin [
    darwin.apple_sdk.frameworks.CoreServices
    darwin.apple_sdk.frameworks.Security
    darwin.apple_sdk.frameworks.SystemConfiguration
  ];

  # needed for internal protobuf c wrapper library
  PROTOC = "${protobuf}/bin/protoc";
  PROTOC_INCLUDE = "${protobuf}/include";

  OPENSSL_NO_VENDOR = 1;

  # disable tests because they require postgres and redis to be running
  doCheck = false;

  meta = with lib; {
    mainProgram = "svix-server";
    description = "Enterprise-ready webhooks service";
    homepage = "https://github.com/svix/svix-webhooks";
    changelog =
      "https://github.com/svix/svix-webhooks/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = with maintainers; [ techknowlogick ];
    broken = stdenv.hostPlatform.isx86_64 && stdenv.hostPlatform.isDarwin; # aws-lc-sys currently broken on darwin x86_64
  };
}
