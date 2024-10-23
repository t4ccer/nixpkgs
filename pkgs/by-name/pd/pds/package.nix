{
  fetchFromGitHub,
  nodejs,
  buildNpmPackage,
  vips,
  pkg-config,
  writeShellApplication,
  bash,
  xxd,
  openssl,
  lib,
}:

let
  generateSecrets = writeShellApplication {
    name = "generate-pds-secrets";

    runtimeInputs = [
      xxd
      openssl
    ];

    # Commands from https://github.com/bluesky-social/pds/blob/8b9fc24cec5f30066b0d0b86d2b0ba3d66c2b532/installer.sh
    text = ''
      echo "PDS_JWT_SECRET=$(openssl rand --hex 16)"
      echo "PDS_ADMIN_PASSWORD=$(openssl rand --hex 16)"
      echo "PDS_PLC_ROTATION_KEY_K256_PRIVATE_KEY_HEX=$(openssl ecparam --name secp256k1 --genkey --noout --outform DER | tail --bytes=+8 | head --bytes=32 | xxd --plain --cols 32)"
    '';
  };
in

# NOTE: Package comes with `pnpm-lock.yaml` but we cannot use `pnpm.fetchDeps` here because it
# does not work with `sharp` NPM dependency that needs `vips` and `pkg-config`
# Regenerate `package-lock.json` with `npm i --package-lock-only`
# Next release should have bumped `sharp` with pre-built binaries
buildNpmPackage rec {
  pname = "pds";
  version = "0.4.67";

  src = fetchFromGitHub {
    owner = "bluesky-social";
    repo = "pds";
    rev = "v${version}";
    hash = "sha256-dEB5u++Zx+F4TH5q44AF/tuwAhLEyYT+U5/18viT4sw=";
  };

  sourceRoot = "${src.name}/service";

  npmDepsHash = "sha256-uQKhODaVHLj+JEq6LYiJ/zXuu7kDCLmpxOs/VCc0GqQ=";

  postPatch = ''
    cp ${./package-lock.json} package-lock.json
  '';

  # Required for `sharp` NPM dependency
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ vips ];

  buildPhase = ''
    runHook preBuild

    makeWrapper "${lib.getExe nodejs}" "$out/bin/pds" \
      --add-flags --enable-source-maps                \
      --add-flags "$out/lib/pds/index.js"             \
      --set-default NODE_ENV production

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p $out/{bin,lib/pds}
    mv node_modules $out/lib/pds
    mv index.js $out/lib/pds

    runHook postInstall
  '';

  passthru = {
    inherit generateSecrets;
  };

  meta = {
    description = "Bluesky Personal Data Server (PDS)";
    homepage = "https://bsky.social";
    license = with lib.licenses; [
      mit
      asl20
    ];
    maintainers = with lib.maintainers; [ t4ccer ];
    platforms = lib.platforms.unix;
    mainProgram = "pds";
  };
}
