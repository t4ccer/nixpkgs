{
  lib,
  buildPythonPackage,
  fetchFromGitHub,

  # build-system
  uv-build,

  # dependencies
  bibtexparser,
  feedparser,
  httpx,
  whenever,
  pytest-asyncio,

  # tests
  pytest-cov-stub,
  pytestCheckHook,
  python-dateutil,
  pytz,
}:

buildPythonPackage (finalAttrs: {
  pname = "pyzotero";
  version = "1.14.0";
  pyproject = true;

  src = fetchFromGitHub {
    owner = "urschrei";
    repo = "pyzotero";
    tag = "v${finalAttrs.version}";
    hash = "sha256-1CnGiE94WvoY73wSmtaDH3G+31dl2QjsV6o6jcpAFKc=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail "uv_build>=0.8.14,<0.12.0" "uv-build"
  '';

  build-system = [
    uv-build
  ];

  dependencies = [
    bibtexparser
    feedparser
    httpx
    whenever
  ];

  nativeCheckInputs = [
    pytest-asyncio
    pytest-cov-stub
    pytestCheckHook
    python-dateutil
    pytz
  ];

  pythonImportsCheck = [ "pyzotero" ];

  meta = {
    description = "Python client for the Zotero API";
    homepage = "https://pyzotero.readthedocs.io/en/latest/";
    downloadPage = "https://pyzotero.readthedocs.io/en/latest/";
    changelog = "https://github.com/urschrei/pyzotero/releases/tag/${finalAttrs.src.tag}";
    license = lib.licenses.blueOak100;
    maintainers = with lib.maintainers; [ ethancedwards8 ];
  };
})
