{
  lib,
  stdenv,
  buildPythonPackage,
  fetchFromGitHub,
  python,
  pkg-config,
  pango,
  cython,
  AppKit,
  pytestCheckHook,
  pythonOlder,
}:

buildPythonPackage rec {
  pname = "manimpango";
  version = "0.6.0";
  format = "setuptools";

  disabled = pythonOlder "3.8";

  src = fetchFromGitHub {
    owner = "ManimCommunity";
    repo = pname;
    rev = "refs/tags/v${version}";
    hash = "sha256-nN+XOnki8fG7URMy2Fhs2X+yNi8Y7wDo53d61xaRa3w=";
  };

  nativeBuildInputs = [ pkg-config ];

  buildInputs = [ pango ] ++ lib.optionals stdenv.hostPlatform.isDarwin [ AppKit ];

  propagatedBuildInputs = [ cython ];

  nativeCheckInputs = [ pytestCheckHook ];

  postPatch = ''
    substituteInPlace setup.cfg \
      --replace "--cov --no-cov-on-fail" ""
  '';

  preBuild = ''
    ${python.pythonOnBuildForHost.interpreter} setup.py build_ext --inplace
  '';

  pythonImportsCheck = [ "manimpango" ];

  meta = with lib; {
    description = "Binding for Pango";
    homepage = "https://github.com/ManimCommunity/ManimPango";
    changelog = "https://github.com/ManimCommunity/ManimPango/releases/tag/v${version}";
    license = licenses.mit;
    maintainers = with maintainers; [ emilytrau ];
  };
}
