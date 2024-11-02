{
  lib,
  aiohttp,
  buildPythonPackage,
  colorlog,
  fetchFromGitHub,
  pint,
  poetry-core,
  pytestCheckHook,
  pythonOlder,
}:

buildPythonPackage rec {
  pname = "aiocomelit";
  version = "0.10.0";
  pyproject = true;

  disabled = pythonOlder "3.10";

  src = fetchFromGitHub {
    owner = "chemelli74";
    repo = "aiocomelit";
    rev = "refs/tags/v${version}";
    hash = "sha256-5XyCc/OMFA99qwVjsVLCA4NedvcDBSSBzG8TvSg4sk0=";
  };

  postPatch = ''
    substituteInPlace pyproject.toml \
      --replace-fail " --cov=aiocomelit --cov-report=term-missing:skip-covered" ""
  '';

  nativeBuildInputs = [ poetry-core ];

  propagatedBuildInputs = [
    aiohttp
    pint
  ];

  nativeCheckInputs = [
    colorlog
    pytestCheckHook
  ];

  pythonImportsCheck = [ "aiocomelit" ];

  meta = with lib; {
    description = "Library to control Comelit Simplehome";
    homepage = "https://github.com/chemelli74/aiocomelit";
    changelog = "https://github.com/chemelli74/aiocomelit/blob/${version}/CHANGELOG.md";
    license = licenses.asl20;
    maintainers = with maintainers; [ fab ];
  };
}
