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
  inherit (import ./common.nix inputs) mergePkgs normalizePkg fixedPkg;
in
{ mcVersion, fabricVersion, mcSha1, hash, mods ? [ ], extraGamedirFiles ? null }:
let
  fabricJsonFile = builtins.fetchurl {
    url = "https://meta.fabricmc.net/v2/versions/loader/${mcVersion}/${fabricVersion}/profile/json";
  };

  fabricPkgImpure = lib.pipe fabricJsonFile [
    builtins.readFile
    builtins.fromJSON
    normalizePkg
  ];

  fabricPkg = fixedPkg {
    pkg = fabricPkgImpure;
    extraDrvs = [ fabricJsonFile ];
    inherit hash;
  };

  mcPkg = getMc { version = fabricPkg.inheritsFrom; sha1 = mcSha1; };

  pkg = mergePkgs [ fabricPkg mcPkg ];
in
minecraftFromPkg {
  inherit pkg;
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
