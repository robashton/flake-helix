{
  description = "Rob's helix";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixos-unstable;
    flake-utils.url = github:numtide/flake-utils;
#    hx.url = "github:helix-editor/helix";
#    hx.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
#        hxOverlay = f: p: {
#          hx-bleeding = inputs.hx.packages.${system}.helix;
#        };
        pkgs = import nixpkgs {
          inherit system;
#          overlays = [ hxOverlay ];
        };

        cfg = pkgs.runCommand "helix-config" {} ''
          mkdir -p $out/helix/config
          cp ${./.}/files/config.toml $out/helix/config.toml
          cp ${./.}/files/languages.toml $out/helix/languages.toml
        '';

        hx = pkgs.writeShellScriptBin "hx" ''
          # I would prefer not to use this env var
          # but https://github.com/helix-editor/helix/discussions/8160
          # helix people seem people opinionated and I can't be fucked going in
          # to have a chat about that again
          XDG_CONFIG_HOME=${cfg} ${pkgs.helix}/bin/hx $@
        '';
      in
      rec {

        # leaving this here in case I want to override anything else..
        robs-helix = hx;

        overlays.default = f: p: {
          inherit (pkgs);
        };

        nixosModules.hm = {
          imports = [
            { nixpkgs.overlays = [ overlays.default ]; }
          ];
        };

        packages = {
          default = robs-helix;
        };

        apps = rec {
          helix = {
            type = "app";
            program = "${packages.default}/bin/hx";
          };
          default = helix;
        };

        devShells.default = pkgs.mkShell { 
          buildInputs = [ robs-helix ];
        };
      }
    );
}
