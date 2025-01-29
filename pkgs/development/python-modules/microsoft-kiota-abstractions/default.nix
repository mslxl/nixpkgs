{
  lib,
  buildPythonPackage,
  fetchFromGitHub,
  poetry-core,
  opentelemetry-api,
  opentelemetry-sdk,
  pytest-asyncio,
  pytest-mock,
  pytestCheckHook,
  pythonOlder,
  std-uritemplate,
}:

buildPythonPackage rec {
  pname = "microsoft-kiota-abstractions";
  version = "1.9.1";
  pyproject = true;

  disabled = pythonOlder "3.9";

  src = fetchFromGitHub {
    owner = "microsoft";
    repo = "kiota-python";
    tag = "microsoft-kiota-abstractions-v${version}";
    hash = "sha256-ESRnI8prXG1h5H5RVD4eOQ1sQYSEMMLVHSk8yhzFGVw=";
  };

  sourceRoot = "source/packages/abstractions/";

  build-system = [ poetry-core ];

  dependencies = [
    opentelemetry-api
    opentelemetry-sdk
    std-uritemplate
  ];

  nativeCheckInputs = [
    pytest-asyncio
    pytest-mock
    pytestCheckHook
  ];

  pythonImportsCheck = [ "kiota_abstractions" ];

  meta = with lib; {
    description = "Abstractions library for Kiota generated Python clients";
    homepage = "https://github.com/microsoft/kiota-python/tree/main/packages/abstractions/";
    changelog = "https://github.com/microsoft/kiota-python/releases/tag/microsoft-kiota-abstractions-v${version}";
    license = licenses.mit;
    maintainers = with maintainers; [ fab ];
  };
}
