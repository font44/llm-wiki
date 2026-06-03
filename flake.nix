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

        agent-browser-wrapped = pkgs.writeShellApplication {
          name = "agent-browser";
          runtimeInputs = [ pkgs.curl ];
          text = ''
            real=${agents.agent-browser}/bin/agent-browser

            for arg in "$@"; do
              case "$arg" in
                --help|-h|--version|-V|help|skills|install|completions)
                  exec "$real" "$@"
                  ;;
              esac
            done

            if ! curl -sf --max-time 1 http://127.0.0.1:9222/json/version >/dev/null; then
              echo "agent-browser: no Chrome on 127.0.0.1:9222 — start Chrome with --remote-debugging-port=9222 and retry." >&2
              exit 1
            fi

            for arg in "$@"; do
              case "$arg" in
                --cdp|--cdp=*|--auto-connect|connect)
                  exec "$real" "$@"
                  ;;
              esac
            done
            exec "$real" --cdp 9222 "$@"
          '';
        };
      in {
        devShells.default = pkgs.mkShell {
          packages = [
            agent-browser-wrapped

            pkgs.defuddle
            pkgs.direnv
            pkgs.fd
            pkgs.git
            pkgs.jq
            pkgs.nodejs
            pkgs.ripgrep
          ];
        };
      });
}
