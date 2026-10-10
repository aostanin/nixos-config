# Missing tools

When a command isn't on `PATH`, run it from nixpkgs instead of installing it,
asking me to, or giving up:

- `nix run nixpkgs#ethtool -- -i eth0`
- `nix shell nixpkgs#dnsutils nixpkgs#jq -c sh -c 'dig +short example.com | jq -R .'`
  when the package name differs from the binary, or for several tools
- Always pass `-c`: shell state doesn't persist between commands.
- Look up package names (nixos MCP server, or `nix search nixpkgs`) rather
  than guessing.
- Works over SSH too. In a repo with a dev shell, prefer `nix develop -c <cmd>`.
