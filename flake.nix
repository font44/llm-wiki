{
  description = "Personal AI-managed knowledge base";

  inputs = {
    nixpkgs.url     = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
    llm-agents = {
      url = "github:numtide/llm-agents.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { self, nixpkgs, flake-utils, llm-agents }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs   = nixpkgs.legacyPackages.${system};
        agents = llm-agents.packages.${system};
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            agents.claude-code
            agents.qmd
            agents.agent-browser
            agents.openskills

            pkgs.python313Packages.markitdown
            pkgs.nodejs

            pkgs.ripgrep
            pkgs.fd
            pkgs.jq
            pkgs.yq-go
            pkgs.git
            pkgs.direnv
          ];
        };
      });
}
