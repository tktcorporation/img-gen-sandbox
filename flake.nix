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

        # Python 3.12 for Flux2 compatibility
        python = pkgs.python312;

      in
      {
        devShells.default = pkgs.mkShell {
          name = "flux2-dev";

          packages = with pkgs; [
            # Python
            python
            uv

            # Build dependencies (needed for some Python packages)
            stdenv.cc.cc.lib
            zlib
            libffi
            openssl

            # Useful tools
            just
            direnv
            git

            # For image viewing (optional)
            feh
          ];

          shellHook = ''
            echo "Flux2 Development Environment"
            echo "=============================="
            echo ""
            echo "Python: $(python --version)"
            echo "uv: $(uv --version)"
            echo ""
            echo "Commands:"
            echo "  just setup    - Install Python dependencies"
            echo "  just generate - Generate an image"
            echo "  just help     - Show all commands"
            echo ""

            # Set up environment variables for MPS on macOS
            export PYTORCH_ENABLE_MPS_FALLBACK=1

            # Ensure uv uses the correct Python
            export UV_PYTHON=${python}/bin/python

            # Add .venv to PATH if it exists
            if [ -d ".venv" ]; then
              export VIRTUAL_ENV="$PWD/.venv"
              export PATH="$VIRTUAL_ENV/bin:$PATH"
            fi
          '';

          # Required for PyTorch on macOS
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
