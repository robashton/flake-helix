{
  description = "Rob's helix";

  inputs = {
    nixpkgs.url = github:nixos/nixpkgs/nixos-unstable;
    flake-utils.url = github:numtide/flake-utils;
    hx.url = "github:helix-editor/helix";
    hx.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, flake-utils, ... }:
    flake-utils.lib.eachDefaultSystem (system:
      let
        helix = f: p: {
          helix = inputs.hx.packages.${system}.helix;
        };

        pkgs = import nixpkgs {
          inherit system;
          overlays = [helix];
        };

        cfg = pkgs.runCommand "helix-config" {} ''
          mkdir -p $out
          cp ${./.}/files/config.toml $out/config.toml
        '';

        _languages = pkgs.runCommand "helix-languages" {} ''
          mkdir -p $out/config/
          cp ${./.}/files/languages.toml $out/config/languages.toml
        '';

        hx = pkgs.writeShellScriptBin "hx" ''
          ${pkgs.helix}/bin/hx --config ${cfg}/config.toml $@
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
