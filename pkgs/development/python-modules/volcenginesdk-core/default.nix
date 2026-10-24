{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  setuptools,
  certifi,
  python-dateutil,
  six,
  urllib3,
}:

buildPythonPackage (finalAttrs: {
  pname = "volcenginesdk-core";
  version = "5.0.54";
  pyproject = true;

  # The repository contains the SDKs of all Volcengine services (several
  # hundred MB), only fetch the parts that are split into separate
  # distributions and packaged in nixpkgs.
  src = fetchFromGitHub {
    owner = "volcengine";
    repo = "volcengine-python-sdk";
    tag = finalAttrs.version;
    sparseCheckout = [
      "tests"
      "volcenginesdkark"
      "volcenginesdkarkruntime"
      "volcenginesdkcore"
    ];
    hash = "sha256-KFamwxlgiPmAqJFWDck1FW+zTr3DUpRXRG4NZHkd5zc=";
  };

  # Upstream generates a setup.py per split distribution, see
  # scripts/build_split_packages.py
  postPatch = ''
    rm setup.py setup.cfg
    cat > pyproject.toml <<EOT
    [build-system]
    requires = ["setuptools>=61.0"]
    build-backend = "setuptools.build_meta"

    [project]
    name = "volcenginesdk-core"
    version = "${finalAttrs.version}"
    dependencies = [
      "certifi>=2017.4.17",
      "python-dateutil>=2.1",
      "six>=1.16",
      "urllib3>=1.26.5",
    ]

    [tool.setuptools.packages.find]
    include = ["volcenginesdkcore", "volcenginesdkcore.*"]
    EOT
  '';

  build-system = [ setuptools ];

  dependencies = [
    certifi
    python-dateutil
    six
    urllib3
  ];

  # The only test requires volcenginesdkbilling, which is not packaged
  doCheck = false;

  pythonImportsCheck = [ "volcenginesdkcore" ];

  meta = {
    description = "Core of the Volcengine SDK for Python";
    homepage = "https://github.com/volcengine/volcengine-python-sdk";
    license = lib.licenses.asl20;
    maintainers = with lib.maintainers; [ t4ccer ];
  };
})
