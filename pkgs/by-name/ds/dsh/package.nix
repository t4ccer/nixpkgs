{ lib
, stdenv
, nodejs
, nodejs-slim
, pnpm
, pnpmConfigHook
, fetchFromGitHub
, fetchPnpmDeps
, makeBinaryWrapper
, python3
, node-gyp
}:

let
  # node-addon-require-builtin decodes PrincipalRealm::builtin_module_require and only accepts
  # `mov rax,[rdi+imm]; ret`.
  # GCC's zerocallusedregs adds `xor edi,edi` before `ret`, which the decoder rejects.
    hardeningDisable = (old.hardeningDisable or [ ]) ++ [ "zerocallusedregs" ];
  });
  patchedNodejs = nodejs.override { nodejs-slim = patchedNodejsSlim; };
  patchedPnpm = pnpm.override { nodejs-slim = patchedNodejsSlim; };
  patchedNodeGyp = node-gyp.override { nodejs = patchedNodejs; };

  version = "0.2.0-rc.2";
  # Commit of tag dsh-v${version}; scripts/build.ts embeds it in the client
  commit = "639ed015397290b3745d163aafe02ffee4aa3f84";

  src = fetchFromGitHub {
    name = "deepseek-harness-source";
    owner = "deepseek-ai";
    repo = "deepseek-harness";
    tag = "dsh-v${version}";
    hash = "sha256-ZtO+bdoYbIkIgLTge5Eh7KYwTVh8FpFAAvx58dSY1PI=";
  };

  pnpmDeps = fetchPnpmDeps {
    pname = "deepseek-harness";
    inherit version src;
    pnpm = patchedPnpm;
    fetcherVersion = 4;
    hash = "sha256-eNR512Q1dibXneCmvxUaMXh7Uk3UOL2Z+zIiQKB/gW4=";
  };
in
stdenv.mkDerivation {
  pname = "deepseek-harness";
  inherit version src;

  nativeBuildInputs = [ patchedNodejs patchedPnpm pnpmConfigHook makeBinaryWrapper python3 patchedNodeGyp ];
  inherit pnpmDeps;

  env.DSH_CLIENT_COMMIT_HASH = commit;

  buildPhase = ''
    runHook preBuild
    pnpm install --offline --frozen-lockfile
    (
      cd node_modules/.pnpm/node-pty@*/node_modules/node-pty
      export HOME="$TMPDIR"
      export npm_config_nodedir=${patchedNodejs}
      export npm_config_python=python3
      node-gyp rebuild
    )
    pnpm run build
    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall
    mkdir -p "$out"
    cp -r . "$out/"
    rm -rf "$out/.git" "$out/.github" "$out/website" \
      "$out/.agents" "$out/.claude" \
      "$out/node_modules/.pnpm/node_modules/@deepseek-ai/website" \
      "$out/node_modules/.cache"
    mkdir -p "$out/bin"
    makeBinaryWrapper "${patchedNodejs}/bin/node" "$out/bin/dsh" \
      --add-flags "--expose-internals" \
      --add-flags "$out/apps/cli/lib/bin.js" \
      --append-flags ""
    makeBinaryWrapper "${patchedNodejs}/bin/node" "$out/bin/dsh-acp-demo" \
      --add-flags "--expose-internals" \
      --add-flags "$out/packages/examples/acp-demo/lib/bin.js" \
      --append-flags ""
    runHook postInstall
  '';

  meta = {
    description = "DeepSeek Harness CLI (dsh)";
    homepage = "https://github.com/deepseek-ai/deepseek-harness";
    license = lib.licenses.mit;
    mainProgram = "dsh";
    platforms = lib.platforms.all;
  };
}
