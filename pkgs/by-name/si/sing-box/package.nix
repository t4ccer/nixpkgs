{
  lib,
  stdenv,
  buildGoModule,
  fetchFromGitHub,
  installShellFiles,
  buildPackages,
  coreutils,
  nix-update-script,
  nixosTests,
}:

buildGoModule rec {
  pname = "sing-box";
  version = "1.11.5";

  src = fetchFromGitHub {
    owner = "SagerNet";
    repo = pname;
    rev = "v${version}";
    hash = "sha256-fU7GnkLGeJVA0YagV4faMRIf8t6t/w6u4OnYMio34Sk=";
  };

  vendorHash = "sha256-PZ4V1R3St7MZ5bH9m6wDa192alLbhpC203lsprn0pNc=";

  tags = [
    "with_quic"
    "with_dhcp"
    "with_wireguard"
    "with_ech"
    "with_utls"
    "with_reality_server"
    "with_acme"
    "with_clash_api"
    "with_gvisor"
  ];

  subPackages = [
    "cmd/sing-box"
  ];

  nativeBuildInputs = [ installShellFiles ];

  ldflags = [
    "-X=github.com/sagernet/sing-box/constant.Version=${version}"
  ];

  postInstall =
    let
      emulator = stdenv.hostPlatform.emulator buildPackages;
    in
    ''
      installShellCompletion --cmd sing-box \
        --bash <(${emulator} $out/bin/sing-box completion bash) \
        --fish <(${emulator} $out/bin/sing-box completion fish) \
        --zsh  <(${emulator} $out/bin/sing-box completion zsh )

      substituteInPlace release/config/sing-box{,@}.service \
        --replace-fail "/usr/bin/sing-box" "$out/bin/sing-box" \
        --replace-fail "/bin/kill" "${coreutils}/bin/kill"
      install -Dm444 -t "$out/lib/systemd/system/" release/config/sing-box{,@}.service
    '';

  passthru = {
    updateScript = nix-update-script { };
    tests = { inherit (nixosTests) sing-box; };
  };

  meta = with lib; {
    homepage = "https://sing-box.sagernet.org";
    description = "Universal proxy platform";
    license = licenses.gpl3Plus;
    maintainers = with maintainers; [ nickcao ];
    mainProgram = "sing-box";
  };
}
