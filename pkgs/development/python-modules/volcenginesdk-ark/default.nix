{
  lib,
  buildPythonPackage,
  setuptools,
  six,
  volcenginesdk-core,
}:

buildPythonPackage {
  pname = "volcenginesdk-ark";
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
    name = "volcenginesdk-ark"
    version = "${volcenginesdk-core.version}"
    dependencies = [
      "volcenginesdk-core==${volcenginesdk-core.version}",
      "six>=1.16",
    ]

    [tool.setuptools.packages.find]
    include = ["volcenginesdkark", "volcenginesdkark.*"]
    EOT
  '';

  build-system = [ setuptools ];

  dependencies = [
    six
    volcenginesdk-core
  ];

  # No tests
  doCheck = false;

  pythonImportsCheck = [ "volcenginesdkark" ];

  meta = volcenginesdk-core.meta // {
    description = "Volcengine Ark management SDK for Python";
  };
}
