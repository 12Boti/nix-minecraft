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

{ pkgs, config, lib, ... }:
let
  cfg = config.programs.minecraft;
  inherit (lib) mkOption mkEnableOption types;
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
    defaultUsername = mkOption {
      type = types.nonEmptyStr;
      example = "NixDude";
      description = "The username to use if none was specified on launch.";
    };
    versions = mkOption {
      default = { };
      description = "Versions of minecraft to install.";
      type = types.attrsOf types.package;
    };
  };

  config.home.file = lib.mapAttrs'
    (name: value:
      let dir = cfg.basePath + "/" + name + "/";
      in
      {
        name = dir + "run";
        value = {
          source = pkgs.writeShellScript "run-minecraft-${name}" ''
            username="''${1:-${cfg.defaultUsername}}"
            game_directory="''${2:-${dir + "gamedir"}}"
            exec ${value}/bin/minecraft "$username" "$game_directory"
          '';
        };
      })
    cfg.versions;
}
