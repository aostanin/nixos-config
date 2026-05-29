{pkgs}: let
  claude-agent-sdk = pkgs.python3Packages.callPackage ./claude-agent-sdk {};
in {
  inherit claude-agent-sdk;
  claude-code-openai-wrapper = pkgs.python3Packages.callPackage ./claude-code-openai-wrapper {
    inherit claude-agent-sdk;
  };
  vfio-isolate = pkgs.python3Packages.callPackage ./vfio-isolate {};
  virtwold = pkgs.callPackage ./virtwold {};
}
