{
  lib,
  buildPythonPackage,
  fetchPypi,
  setuptools,
  aiohttp,
  google,
  protobuf,
  pycryptodome,
  pytz,
  readerwriterlock,
  requests,
  retry,
  six,
  tenacity,
}:

buildPythonPackage (finalAttrs: {
  pname = "volcengine";
  version = "1.0.229";
  pyproject = true;

  # GitHub tags are not reliably in sync with PyPI releases
  src = fetchPypi {
    inherit (finalAttrs) pname version;
    hash = "sha256-Y9jkUE2Lw17uKZc8ryGkFMG6BbLhFQH70ubL5ssEdlI=";
  };

  build-system = [ setuptools ];

  dependencies = [
    aiohttp
    google
    protobuf
    pycryptodome
    pytz
    readerwriterlock
    requests
    retry
    six
    tenacity
  ];

  pythonRelaxDeps = [ "protobuf" ];

  # No tests in the PyPI sdist
  doCheck = false;

  pythonImportsCheck = [
    "volcengine"
    "volcengine.viking_db"
  ];

  meta = {
    description = "Volcengine SDK for Python";
    homepage = "https://github.com/Volcengine/volc-sdk-python";
    license = lib.licenses.mit;
    maintainers = with lib.maintainers; [ t4ccer ];
  };
})
