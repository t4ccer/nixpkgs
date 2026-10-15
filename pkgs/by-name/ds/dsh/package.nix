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
  patchedNodejsSlim = nodejs-slim.overrideAttrs (old: {
    hardeningDisable = (old.hardeningDisable or [ ]) ++ [ "zerocallusedregs" ];
  });
  patchedNodejs = nodejs.override { nodejs-slim = patchedNodejsSlim; };
  patchedPnpm = pnpm.override { nodejs-slim = patchedNodejsSlim; };
  patchedNodeGyp = node-gyp.override { nodejs = patchedNodejs; };
in
stdenv.mkDerivation (finalAttrs: {
  pname = "deepseek-harness";
  version = "0.2.2-rc.2";

  src = fetchFromGitHub {
    name = "deepseek-harness-source";
    owner = "deepseek-ai";
    repo = "deepseek-harness";
    tag = "dsh-v${finalAttrs.version}";
    hash = "sha256-lbRmFifO6+8YKn8kaR7gQzKeUQh9YBFu9wH/dWJ+3MA=";
  };

  nativeBuildInputs = [ patchedNodejs patchedPnpm pnpmConfigHook makeBinaryWrapper python3 patchedNodeGyp ];

  pnpmDeps = fetchPnpmDeps {
    pname = "deepseek-harness";
    inherit (finalAttrs) version src;
    pnpm = patchedPnpm;
    fetcherVersion = 4;
    hash = "sha256-LFZq5Lz6GaRR97D9wfO1b/sFLip6PlL9BjQAW+cXfOc=";
  };

  # Commit of tag dsh-v${version}; scripts/build.ts embeds it in the client
  env.DSH_CLIENT_COMMIT_HASH = "ddac96760b6edf8fa0fe17cbdcf0b512f4c12b2c";

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

  dontCheckForBrokenSymlinks = true;

  meta = {
    description = "DeepSeek Harness CLI (dsh)";
    homepage = "https://github.com/deepseek-ai/deepseek-harness";
    license = lib.licenses.mit;
    mainProgram = "dsh";
    platforms = lib.platforms.all;
  };
})
