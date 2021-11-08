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

{ pkgs, lib ? pkgs.lib }@inputs:
let
  inherit (import ./minecraft.nix inputs) getMc minecraftFromPkg;
  inherit (import ./common.nix inputs) mergePkgs fixOldPkg;
in
{ url, mcSha1, hash, mods ? [ ], extraGamedirFiles ? null }:
let
  installer = pkgs.fetchurl { inherit url hash; };

  liteloaderJar = pkgs.runCommand "liteloader.jar" { } ''
    ${pkgs.unzip}/bin/unzip -p ${installer} 'liteloader*.jar' > $out
  '';
  pkg =
    let
      versionJsonFile = pkgs.runCommand "liteloader-version.json" { } ''
        ${pkgs.unzip}/bin/unzip -p ${installer} install_profile.json > $out
      '';
      liteloader = fixOldPkg (builtins.fromJSON (builtins.readFile versionJsonFile)).versionInfo;
      mc = getMc { version = liteloader.inheritsFrom; sha1 = mcSha1; };
    in
    mergePkgs [ liteloader mc ];
in
minecraftFromPkg {
  inherit pkg;
  extraJars = [ liteloaderJar ];
  extraGamedirFiles = pkgs.symlinkJoin {
    name = "extra-gamedir";
    paths =
      lib.optional (extraGamedirFiles != null) extraGamedirFiles
      ++ [
        (
          pkgs.linkFarm
            "mods"
            (map (m: { name = "mods/${m.name}"; path = m; }) mods)
        )
      ];
  };
}
