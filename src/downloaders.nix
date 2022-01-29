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
in
{
  options.downloaded = {
    jars = mkOption {
      type = types.listOf types.path;
      internal = true;
    };
    natives = mkOption {
      type = types.listOf types.path;
      internal = true;
    };
    assets = mkOption {
      type = types.path;
      internal = true;
    };
  };

  config.downloaded = {
    jars = map
      (
        javaLib:
        let downloaded =
          # check if already downloaded
          if javaLib.path != null
          then
            javaLib.path
          else
            pkgs.fetchurl
              { inherit (javaLib) url sha1; };
        in
        pkgs.runCommandLocal
          "${javaLib.name}"
          { }
          ''
            mkdir -p "$(dirname "$out/${javaLib.destPath}")"
            ln -s '${downloaded}' "$out/${javaLib.destPath}"
          ''
      )
      (builtins.filter (x: x.type == "jar") config.internal.libraries);
    natives = map
      (
        nativeLib:
        # check if already downloaded
        let zip =
          if nativeLib.path != null
          then nativeLib.path
          else pkgs.fetchurl { inherit (nativeLib) url sha1; };
        in
        pkgs.runCommand "unpack-zip" { } ''
          ${pkgs.unzip}/bin/unzip ${zip} -d $out
          rm -rf $out/META-INF
        ''
      )
      (builtins.filter (x: x.type == "native") config.internal.libraries);

    assets =
      let
        assetIndexFile = pkgs.fetchurl { inherit (config.internal.assets) url sha1; };
        assetIndex = lib.importJSON assetIndexFile;
        objectScripts = lib.mapAttrsToList
          (
            object: { hash, size }:
              let
                shorthash = builtins.substring 0 2 hash;
                asset = pkgs.fetchurl {
                  sha1 = hash;
                  url = "https://resources.download.minecraft.net/${shorthash}/${hash}";
                };
              in
              ''
                mkdir -p $out/objects/${shorthash}
                ln -sf ${asset} $out/objects/${shorthash}/${hash}
              ''
          )
          assetIndex.objects;
        script = (lib.concatStringsSep "\n" objectScripts) + ''
          mkdir -p $out/indexes
          ln -s ${assetIndexFile} $out/indexes/${config.internal.assets.id}.json
        '';
      in
      pkgs.runCommand "symlink-assets" { } script;
  };
}
