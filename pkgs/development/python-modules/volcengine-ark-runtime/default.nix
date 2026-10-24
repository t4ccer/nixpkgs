{
  lib,
  buildPythonPackage,
  setuptools,
  anyio,
  cryptography,
  httpx,
  pydantic,
  typing-extensions,
  volcenginesdk-ark,
  volcenginesdk-core,
  pytestCheckHook,
}:

buildPythonPackage {
  pname = "volcengine-ark-runtime";
  inherit (volcenginesdk-core) version src;
  pyproject = true;

  # Upstream generates a setup.py per split distribution, see
  # scripts/build_split_packages.py
  postPatch = ''
    rm setup.py setup.cfg
    cat > pyproject.toml <<EOT
    [build-system]
    requires = ["setuptools>=61.0"]
    build-backend = "setuptools.build_meta"

    [project]
    name = "volcengine-ark-runtime"
    version = "${volcenginesdk-core.version}"
    dependencies = [
      "volcenginesdk-ark==${volcenginesdk-core.version}",
      "volcenginesdk-core==${volcenginesdk-core.version}",
      "pydantic>=1.9.0,<3",
      "httpx>=0.23.0,<1",
      "anyio>=3.5.0,<5",
      "typing-extensions>=4.7",
      "cryptography>=44.0.1",
    ]

    [tool.setuptools.packages.find]
    include = ["volcenginesdkarkruntime", "volcenginesdkarkruntime.*"]
    EOT
  '';

  build-system = [ setuptools ];

  dependencies = [
    anyio
    cryptography
    httpx
    pydantic
    typing-extensions
    volcenginesdk-ark
    volcenginesdk-core
  ];

  nativeCheckInputs = [ pytestCheckHook ];

  enabledTestPaths = [ "tests/arkruntime" ];

  pythonImportsCheck = [ "volcenginesdkarkruntime" ];

  meta = volcenginesdk-core.meta // {
    description = "Volcengine Ark runtime SDK for Python";
  };
}
