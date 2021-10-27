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

{ pkgs, lib ? pkgs.lib }:
let
  inherit (import ./common.nix { inherit pkgs lib; }) os isAllowed;
in
{
  # downloads the java and native libraries in the list
  downloadLibs = mc:
    let
      libs = mc.libraries;
      javaLibs =
        map
          (
            javaLib:
            let
              a = javaLib.downloads.artifact;
            in
            pkgs.fetchurl
              {
                inherit (a) url sha1;
              }
            // lib.optionalAttrs (a ? path) {
              passthru = {
                path = a.path;
              };
            }

          )
          (
            builtins.filter
              (
                x:
                x ? downloads.artifact
                && x.downloads.artifact.url != ""
                && (x ? rules -> isAllowed x.rules)
              )
              libs
          )
        ++ [ (pkgs.fetchurl { inherit (mc.downloads.client) url sha1; }) ];
      nativeLibs =
        map
          (
            nativeLib:
            let
              classifier = nativeLib.natives.${os};
              a = nativeLib.downloads.classifiers.${classifier};
              zip =
                pkgs.fetchurl {
                  inherit (a) url sha1;
                };
            in
            pkgs.runCommand "unpack-zip" { } ''
              ${pkgs.unzip}/bin/unzip ${zip} -d $out
              rm -rf $out/META-INF
            ''
          )
          (
            builtins.filter
              (
                x: x ? natives.${os} && (x ? rules -> isAllowed x.rules)
              )
              libs
          );
    in
    { inherit javaLibs nativeLibs; };

  downloadAssets = assetIndexInfo:
    let
      assetIndexFile = pkgs.fetchurl { inherit (assetIndexInfo) url sha1; };
      assetIndex = builtins.fromJSON (builtins.readFile assetIndexFile);
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
        ln -s ${assetIndexFile} $out/indexes/${assetIndexInfo.id}.json
      '';
    in
    pkgs.runCommand "symlink-assets" { } script;
}
