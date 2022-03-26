# This file is part of nix-minecraft.

# nix-minecraft is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.

# nix-minecraft is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with nix-minecraft.  If not, see <https://www.gnu.org/licenses/>.

{ baseModules }:
{ pkgs, config, lib, ... }:
let
  cfg = config.programs.minecraft;
  inherit (lib) mkOption mkDefault mkEnableOption mkOptionType mergeOneOption types;
in
{
  options.programs.minecraft = {
    enable = mkEnableOption "minecraft";
    basePath = mkOption {
      type = types.nonEmptyStr;
      default = ".minecraft";
      example = "games/minecraft";
      description = "Path to store versions of minecraft in. Relative to the home directory.";
    };
    shared = mkOption {
      type = mkOptionType {
        name = "shared-module";
        inherit (types.submodule { }) check;
        merge = lib.options.mergeOneOption;
      };
      default = { };
      description = "The config to be shared between all versions.";
    };
    versions = mkOption {
      default = { };
      description = "Versions of minecraft to install.";
      type = types.attrsOf (types.submodule (
        [
          cfg.shared
          ({ name, ... }:
            {
              gamedir = mkDefault "${config.home.homeDirectory}/${cfg.basePath}/${name}/gamedir";
              _module.args = { inherit pkgs; };
            })
        ] ++ baseModules
      ));
    };
  };

  config.home.file = lib.mapAttrs'
    (name: value:
      {
        name = "${cfg.basePath}/${name}/run";
        value.source = "${value.runners.client}/bin/minecraft";
      })
    cfg.versions;
}
