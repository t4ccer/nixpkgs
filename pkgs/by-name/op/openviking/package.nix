{
  lib,
  fetchFromGitHub,
  buildNpmPackage,
  python3Packages,
  rustPlatform,
  cargo,
  rustc,
  cmake,
  maturin,
  perl,
  versionCheckHook,
}:

python3Packages.buildPythonApplication (finalAttrs: {
  pname = "openviking";
  version = "0.5.2";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "volcengine";
    repo = "OpenViking";
    tag = "v${finalAttrs.version}";
    hash = "sha256-CtGwejt97b3Cq/jLaxfl8yhnyiuEO+v2PwWI2f42K+s=";
  };

  cargoDeps = rustPlatform.fetchCargoVendor {
    inherit (finalAttrs) pname version src;
    hash = "sha256-I9RMJQOeJKC9PMaKKhBCsTOZIr1vV6pcLjB6XxFUzFE=";
  };

  webStudio = buildNpmPackage {
    pname = "openviking-web-studio";
    inherit (finalAttrs) version src;

    sourceRoot = "${finalAttrs.src.name}/web-studio";

    npmDepsHash = "sha256-bQ8RlJ6Lir/0GkbeNnjzXzdwFOlrr9B1UyM0lN+IXqU=";

    # `prebuild` runs lint and tests
    npmBuildScript = "build";
    npmBuildFlags = [
      "--ignore-scripts"
      "--"
      "--base=/studio/"
    ];

    installPhase = ''
      runHook preInstall
      cp -r dist $out
      runHook postInstall
    '';
  };

  postPatch = ''
    # maturin is provided as an executable, not as a Python module
    substituteInPlace setup.py \
      --replace-fail 'importlib.util.find_spec("maturin") is None' 'shutil.which("maturin") is None' \
      --replace-fail 'sys.executable,' "" \
      --replace-fail '"-m",' ""

    # cmake and maturin are provided as executables
    substituteInPlace pyproject.toml \
      --replace-fail '"cmake>=3.15",' "" \
      --replace-fail '"maturin>=1.0,<2.0",' ""
  '';

  build-system = with python3Packages; [
    setuptools
    setuptools-scm
    wheel
  ];

  nativeBuildInputs = [
    cargo
    cmake
    maturin
    perl # vendored openssl
    rustc
    rustPlatform.cargoSetupHook
  ];

  # cmake is invoked by setup.py
  dontUseCmakeConfigure = true;

  # The C++ engine is built with -Wno-format, which conflicts with -Werror=format-security
  hardeningDisable = [ "format" ];

  env = {
    OPENVIKING_VERSION = finalAttrs.version;
    SETUPTOOLS_SCM_PRETEND_VERSION = finalAttrs.version;
    OV_REQUIRE_RAGFS_BUILD = "1";
    OV_SKIP_STUDIO_BUILD = "1";
  };

  preBuild = ''
    mkdir -p openviking/web_studio
    cp -r ${finalAttrs.webStudio} openviking/web_studio/dist
    chmod -R u+w openviking/web_studio/dist
  '';

  pythonRelaxDeps = true;

  pythonRemoveDeps = [
    # Meta package of all Volcengine services, only the Ark runtime
    # (volcengine-ark-runtime) is used
    "volcengine-python-sdk"
    # Only used by the language pack, which bundles its own grammars
    "tree-sitter-java"
    "tree-sitter-cpp"
    "tree-sitter-go"
    "tree-sitter-php"
    "tree-sitter-lua"
  ];

  dependencies = with python3Packages; [
    aiohttp
    apscheduler
    argon2-cffi
    async-timeout
    cairosvg
    charset-normalizer
    cryptography
    defusedxml
    fastapi
    feedparser
    firecrawl-anydoc
    grep-ast
    httpx
    jinja2
    json-repair
    lark-oapi
    litellm
    loguru
    mcp
    openai
    openviking-sdk
    opentelemetry-api
    opentelemetry-exporter-otlp-proto-grpc
    opentelemetry-exporter-otlp-proto-http
    opentelemetry-instrumentation-asyncio
    opentelemetry-sdk
    orjson
    packaging
    pathspec
    pdfminer-six
    pdfplumber
    protobuf
    pydantic
    python-multipart
    pyyaml
    rapidfuzz
    requests
    scrapy
    tabulate
    trafilatura
    tree-sitter
    tree-sitter-c-sharp
    tree-sitter-javascript
    tree-sitter-language-pack
    tree-sitter-python
    tree-sitter-rust
    tree-sitter-typescript
    typer
    typing-extensions
    urllib3
    uvicorn
    volcengine
    volcengine-ark-runtime
    xxhash
  ];

  postInstall = ''
    # Requires the dependencies of the `bot` extra, many of which are not packaged
    rm $out/bin/vikingbot
  '';

  pythonImportsCheck = [
    "openviking"
    "openviking.storage.vectordb.engine"
    "openviking_cli"
  ];

  postInstallCheck = ''
    $out/bin/openviking-server --help > /dev/null
    PYTHONPATH=$out/${python3Packages.python.sitePackages}:$PYTHONPATH ${python3Packages.python.interpreter} -c 'from openviking.pyagfs import get_binding_client; get_binding_client()'
  '';

  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgram = "${placeholder "out"}/bin/ov";

  meta = {
    description = "Context database for AI agents";
    homepage = "https://github.com/volcengine/OpenViking";
    changelog = "https://github.com/volcengine/OpenViking/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ t4ccer ];
    mainProgram = "ov";
  };
})
