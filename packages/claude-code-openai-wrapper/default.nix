{
  buildPythonPackage,
  fetchFromGitHub,
  poetry-core,
  fastapi,
  uvicorn,
  pydantic,
  python-dotenv,
  httpx,
  sse-starlette,
  python-multipart,
  slowapi,
  claude-agent-sdk,
}:
buildPythonPackage rec {
  pname = "claude-code-openai-wrapper";
  version = "2.2.0";

  pyproject = true;
  build-system = [poetry-core];

  src = fetchFromGitHub {
    owner = "RichardAtCT";
    repo = "claude-code-openai-wrapper";
    rev = "v${version}";
    hash = "sha256-rI7xLlBq+vCKhnakmSZtEDNI2ssvMyflJyn4a1XxGfo=";
  };

  # Relax version constraints to work with nixpkgs versions
  preConfigure = ''
    sed -i \
      -e 's/fastapi = "^0.115.0"/fastapi = ">=0.115.0"/' \
      -e 's/uvicorn = {extras = \["standard"\], version = "^0.32.0"}/uvicorn = ">=0.32.0"/' \
      -e 's/httpx = "^0.27.2"/httpx = ">=0.27.2"/' \
      -e 's/sse-starlette = "^2.1.3"/sse-starlette = ">=2.1.3"/' \
      -e 's/python-multipart = "^0.0.18"/python-multipart = ">=0.0.18"/' \
      pyproject.toml
  '';

  propagatedBuildInputs = [
    fastapi
    uvicorn
    pydantic
    python-dotenv
    httpx
    sse-starlette
    python-multipart
    slowapi
    claude-agent-sdk
  ];

  # Tests require API access
  doCheck = false;

  meta.mainProgram = "claude-wrapper";
}
