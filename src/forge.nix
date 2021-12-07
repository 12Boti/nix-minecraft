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

{ config, pkgs, lib, ... }:
let
  inherit (lib) mkOption types;
  versionStr = "${config.minecraft.version}-${config.forge.version}";
in
{
  options.forge = {
    version = mkOption {
      default = null;
      example = "14.23.5.2855";
      description = "The version of forge to use.";
      type = types.nullOr types.nonEmptyStr;
    };
    hash = mkOption {
      description = "The hash of the forge version.";
      type = types.str;
    };
  };

  config.internal = import ./download-module.nix {
    inherit pkgs lib;
    name = "forge-${versionStr}";
    enabled = config.forge.version != null;
    nativeBuildInputs = with pkgs; [ jre unzip ];
    hash = config.forge.hash;
    jsonnetFile = ./jsonnet/forge.jsonnet;
    scriptBefore = ''
      curl -L -o installer.jar \
        'https://maven.minecraftforge.net/net/minecraftforge/forge/${versionStr}/forge-${versionStr}-installer.jar'
          
      java -jar installer.jar --extract
      forgeJar="forge-*.jar"

      files="$(unzip -Z -1 installer.jar)"
      if [[ "$files" =~ "version.json" ]]
      then
        unzip -p installer.jar version.json > orig.json
      else
        unzip -p $forgeJar version.json > orig.json
      fi
    '';
    scriptAfter = ''
      cp $forgeJar $out/forge.jar
    '';
  };
}
