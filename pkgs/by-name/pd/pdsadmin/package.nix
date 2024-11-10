{
  stdenvNoCC,
  fetchFromGitHub,
  bash,
  pds,
  makeWrapper,
  jq,
  curl,
  openssl,
  lib,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "pdsadmin";
  inherit (pds) version src;

  patches = [ ./pdsadmin-offline.patch ];

  nativeBuildInputs = [
    bash
    makeWrapper
  ];

  buildPhase = ''
    runHook preBuild

    patchShebangs . pdsadmin
    substituteInPlace pdsadmin.sh \
      --replace-fail NIXPKGS_PDSADMIN_ROOT $out

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/pds
    install -Dm755 pdsadmin.sh $out/lib/pds
    install -Dm755 pdsadmin/*.sh $out/lib/pds
    makeWrapper "$out/lib/pds/pdsadmin.sh" "$out/bin/pdsadmin" \
      --prefix PATH : "${
        lib.makeBinPath [
          jq
          curl
          openssl
        ]
      }"

    runHook postInstall
  '';

  meta = {
    description = "Admin scripts for Bluesky Personal Data Server (PDS)";
    homepage = "https://github.com/bluesky-social/pds";
    license = with lib.licenses; [
      mit
      asl20
    ];
    maintainers = with lib.maintainers; [ t4ccer ];
    platforms = lib.platforms.unix;
    mainProgram = "pdsadmin";
  };
})
