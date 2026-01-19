{
  description = "Flux2 Image Generation Environment for Apple Silicon Mac";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = { self, nixpkgs, flake-utils }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        pkgs = import nixpkgs {
          inherit system;
          config.allowUnfree = true;
        };

        # Tool versions
        python = pkgs.python312;
        nodejs = pkgs.nodejs_22;

      in
      {
        devShells.default = pkgs.mkShell {
          name = "flux2-dev";

          packages = with pkgs; [
            # === Python ===
            python
            uv

            # === Node.js ===
            nodejs
            pnpm
            nodePackages.npm

            # === Build dependencies ===
            stdenv.cc.cc.lib
            zlib
            libffi
            openssl

            # === Dev tools ===
            just
            direnv
            git
            jq

            # === Browser automation ===
            playwright-driver.browsers

            # === Image viewing (optional) ===
            feh
          ];

          shellHook = ''
            echo "Flux2 Development Environment"
            echo "=============================="
            echo ""
            echo "Tools:"
            echo "  Python: $(python --version)"
            echo "  Node:   $(node --version)"
            echo "  uv:     $(uv --version)"
            echo "  pnpm:   $(pnpm --version)"
            echo ""

            # === Environment Variables ===
            # MPS fallback for PyTorch on macOS
            export PYTORCH_ENABLE_MPS_FALLBACK=1

            # uv uses the correct Python
            export UV_PYTHON=${python}/bin/python

            # Playwright browsers
            export PLAYWRIGHT_BROWSERS_PATH=${pkgs.playwright-driver.browsers}
            export PLAYWRIGHT_SKIP_VALIDATE_HOST_REQUIREMENTS=true

            # === npm global packages ===
            # Install npm packages to local directory
            export NPM_CONFIG_PREFIX="$PWD/.npm-global"
            export PATH="$NPM_CONFIG_PREFIX/bin:$PATH"
            mkdir -p "$NPM_CONFIG_PREFIX"

            # Install global npm packages if not present
            if [ ! -f "$NPM_CONFIG_PREFIX/.installed" ]; then
              echo "Installing npm packages..."
              npm install -g \
                @anthropic-ai/claude-code \
                @openai/codex \
                @google/gemini-cli \
                @antfu/ni \
                playwright \
                2>/dev/null || true
              touch "$NPM_CONFIG_PREFIX/.installed"
              echo ""
            fi

            # === Python venv ===
            if [ -d ".venv" ]; then
              export VIRTUAL_ENV="$PWD/.venv"
              export PATH="$VIRTUAL_ENV/bin:$PATH"
            fi

            echo "Commands:"
            echo "  just setup    - Install Python dependencies"
            echo "  just generate - Generate an image"
            echo "  just help     - Show all commands"
            echo ""
          '';

          # Library paths for native dependencies
          env = {
            LD_LIBRARY_PATH = pkgs.lib.makeLibraryPath [
              pkgs.stdenv.cc.cc.lib
              pkgs.zlib
            ];
          };
        };
      }
    );
}
