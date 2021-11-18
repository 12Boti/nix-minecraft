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
  inherit (import ./common.nix inputs) mergePkgs fixedPkg normalizePkg urlPathFromLibraryName;
in
{ version, mcSha1, hash, mods ? [ ], extraGamedirFiles ? null }:
let
  installer = builtins.fetchurl {
    url = "https://maven.minecraftforge.net/net/minecraftforge/forge/${version}/forge-${version}-installer.jar";
  };

  forgeJar = pkgs.runCommand "forge.jar" { } ''
    ${pkgs.jre}/bin/java -jar ${installer} --extract
    cp *.jar $out
  '';

  forgePkgFile = pkgs.runCommand "forge-pkg.json" { } ''
    files="$(${pkgs.unzip}/bin/unzip -Z -1 ${installer})"
    if [[ "$files" =~ "version.json" ]]
    then
      ${pkgs.unzip}/bin/unzip -p ${installer} version.json > $out
    else
      ${pkgs.unzip}/bin/unzip -p ${forgeJar} version.json > $out
    fi
  '';

  # forge sometimes has wrong hashes for packages, here are the correct ones
  correctHashes = {
    "org.scala-lang.plugins:scala-continuations-library_2.11:1.0.2" =
      "sha1-DlF8U6fprNaxZoxaNezLqjurmqw=";
    "org.scala-lang.plugins:scala-continuations-plugin_2.11.1:1.0.2" =
      "sha1-82GjKDRSxX+jDB7mlEiZXeI8YPc=";
  };

  fixLib = l:
    if lib.hasPrefix "net.minecraftforge:forge" l.name
    then { inherit (l) name; type = "jar"; file = forgeJar; }
    else if ! l ? url
    then
      (
        if lib.any (x: lib.hasPrefix x l.name) [
          "net.minecraft:launchwrapper"
          "lzma:lzma"
          "java3d:vecmath"
        ]
        then {
          url = "https://libraries.minecraft.net/" + urlPathFromLibraryName l.name;
        } // l
        else {
          url = "https://maven.minecraftforge.net/" + urlPathFromLibraryName l.name;
        } // l
      )
    else if correctHashes ? ${l.name}
    then l // { sha1 = correctHashes.${l.name}; }
    else l;

  forgePkgImpure =
    let
      json = builtins.fromJSON (builtins.readFile forgePkgFile);
      pkg = normalizePkg json;
    in
    pkg // { libraries = map fixLib pkg.libraries; };

  forgePkg = fixedPkg {
    pkg = forgePkgImpure;
    extraDrvs = [ installer ];
    inherit hash;
  };

  mcPkg = getMc { version = forgePkg.inheritsFrom; sha1 = mcSha1; };

  pkg = mergePkgs [ forgePkg mcPkg ];
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
