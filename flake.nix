# nix-minecraft: A Minecraft launcher in nix.
# Copyright (C) 2021, 2022 12Boti

# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <https://www.gnu.org/licenses/>.

{
  description = "A Minecraft launcher in nix";

  inputs = {
    mcversions = {
      url = "github:yushijinhun/minecraft-version-json-history";
      flake = false;
    };
  };

  outputs =
    { self
    , nixpkgs
    , mcversions
    }:
    let
      supportedSystems = [ "x86_64-linux" ];

      forAllSystems = f:
        nixpkgs.lib.genAttrs supportedSystems
          (system: f {
            inherit system;
            pkgs = nixpkgs.legacyPackages.${system};
          });
    in
    {
      nixosModules.home-manager.minecraft =
        import ./home-manager.nix { inherit (self.lib) baseModules; };

      packages = forAllSystems ({ system, pkgs }: {
        docs = pkgs.callPackage ./docs { inherit (self.lib) baseModules; };
      });

      lib =
        (forAllSystems ({ system, pkgs }: {
          mkMinecraft = mod:
            let result =
              pkgs.lib.evalModules {
                modules = [
                  mod
                  { _module.args = { inherit pkgs; }; }
                ] ++ self.lib.baseModules;
              };
            in
            result.config.runners.client;
        }))
        // {
          baseModules = [
            { _module.args = { inherit mcversions; }; }
            (import ./src/internal.nix)
            (import ./src/minecraft.nix)
            (import ./src/forge)
            (import ./src/curseforge.nix)
            (import ./src/modrinth.nix)
            (import ./src/ftb.nix)
            (import ./src/liteloader.nix)
            (import ./src/fabric.nix)
            (import ./src/curseforge-modpack.nix)
          ];
        };

      templates.default = {
        path = ./template;
        description = "A simple flake for vanilla minecraft";
        # https://github.com/NixOS/nix/issues/6321
        # welcomeText = ''
        #   Make sure to change the username and game directory!
        #   For the list of all available options, visit https://12boti.github.io/nix-minecraft/
        # '';
      };

      checks = forAllSystems ({ system, pkgs }:
        import ./checks.nix {
          inherit pkgs;
          inherit (self.lib.${system}) mkMinecraft;
        });
    };
}
