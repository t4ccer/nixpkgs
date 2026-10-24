{
  buildPythonPackage,
  hatchling,
  opentelemetry-api,
  opentelemetry-instrumentation,
  opentelemetry-semantic-conventions,
  opentelemetry-test-utils,
  pytest-asyncio,
  pytestCheckHook,
  wrapt,
}:

buildPythonPackage {
  inherit (opentelemetry-instrumentation) version src;
  pname = "opentelemetry-instrumentation-asyncio";
  pyproject = true;

  sourceRoot = "${opentelemetry-instrumentation.src.name}/instrumentation/opentelemetry-instrumentation-asyncio";

  build-system = [ hatchling ];

  dependencies = [
    opentelemetry-api
    opentelemetry-instrumentation
    opentelemetry-semantic-conventions
    wrapt
  ];

  nativeCheckInputs = [
    opentelemetry-test-utils
    pytest-asyncio
    pytestCheckHook
  ];

  pythonImportsCheck = [ "opentelemetry.instrumentation.asyncio" ];

  meta = opentelemetry-instrumentation.meta // {
    description = "OpenTelemetry instrumentation for asyncio";
    homepage = "https://github.com/open-telemetry/opentelemetry-python-contrib/blob/main/instrumentation/opentelemetry-instrumentation-asyncio";
  };
}
