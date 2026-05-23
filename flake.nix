{
  description = "Personal AI-managed knowledge base";

  inputs = {
    nixpkgs.url     = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    llm-agents.url = "github:numtide/llm-agents.nix";
  };

  outputs = { self, nixpkgs, flake-utils, llm-agents }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs   = nixpkgs.legacyPackages.${system};
        agents = llm-agents.packages.${system};
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            agents.agent-browser
            agents.codex
            agents.qmd

            pkgs.defuddle
            pkgs.direnv
            pkgs.fd
            pkgs.git
            pkgs.jq
            pkgs.nodejs
            pkgs.ripgrep
            pkgs.yq-go
          ];
        };
      });
}
