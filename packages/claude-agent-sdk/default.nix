{
  buildPythonPackage,
  fetchFromGitHub,
  hatchling,
  anyio,
  typing-extensions,
  mcp,
}:
buildPythonPackage rec {
  pname = "claude-agent-sdk";
  version = "0.1.19";

  pyproject = true;
  build-system = [hatchling];

  src = fetchFromGitHub {
    owner = "anthropics";
    repo = "claude-agent-sdk-python";
    rev = "v${version}";
    hash = "sha256-6AED6IHaBiwI2otCsh2Q8watqKChSUZwHNzlFGBVOXU=";
  };

  propagatedBuildInputs = [
    anyio
    typing-extensions
    mcp
  ];

  # Tests require API access
  doCheck = false;
}
