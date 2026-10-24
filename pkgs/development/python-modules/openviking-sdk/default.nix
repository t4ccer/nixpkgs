{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  setuptools-scm,
  httpx,
  pytestCheckHook,
  pytest-asyncio,
}:

buildPythonPackage (finalAttrs: {
  pname = "openviking-sdk";
  version = "0.1.16";
  pyproject = true;

  src = fetchPypi {
    pname = "openviking_sdk";
    inherit (finalAttrs) version;
    hash = "sha256-IiwQzMfIdYofuJTremgjFcbgz8m2uaiBaToanHKilZE=";
  };

  build-system = [
    setuptools
    setuptools-scm
  ];

  dependencies = [ httpx ];

  nativeCheckInputs = [
    pytest-asyncio
    pytestCheckHook
  ];

  disabledTestPaths = [
    # Require the openviking package, which depends on this package
    "tests/test_legacy_shims.py"
    "tests/test_main_package_exports.py"
  ];

  pythonImportsCheck = [ "openviking_sdk" ];

  meta = {
    description = "Lightweight Python HTTP SDK for OpenViking";
    homepage = "https://github.com/volcengine/OpenViking/tree/main/sdk/python";
    license = lib.licenses.agpl3Only;
    maintainers = with lib.maintainers; [ t4ccer ];
  };
})
