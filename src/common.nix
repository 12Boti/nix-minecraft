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
  inherit (lib) splitString;
  inherit (builtins) concatStringsSep head tail;
in
rec {
  os =
    let
      p = pkgs.stdenv.hostPlatform;
    in
    if p.isLinux then "linux"
    else if p.isWindows then "windows"
    else if p.isMacOS then "osx"
    else throw "unsupported OS";

  isAllowed = rules:
    (
      builtins.elem
        {
          action = "allow";
          os.name = os;
        }
        rules
    )
    || (
      (
        builtins.elem
          {
            action = "allow";
          }
          rules
      ) && (
        !builtins.elem
          {
            action = "disallow";
            os.name = os;
          }
          rules
      )
    );

  filterMap = f: xs: lib.remove null (map f xs);

  fetchJson = { url, sha1 ? "", sha256 ? "", hash ? "" }:
    let
      file = pkgs.fetchurl {
        inherit url sha1 sha256 hash;
      };
      json = builtins.readFile file;
    in
    builtins.fromJSON json;

  mergePkgs = lib.zipAttrsWith
    (
      name: values:
        # concat lists, replace other values
        if lib.all lib.isList values
        then lib.concatLists values
        else if lib.all lib.isAttrs values
        then mergePkgs values
        else lib.head values
    );

  urlPathFromLibraryName = name:
    let parts = splitString ":" name;
    in
    concatStringsSep "/" ((splitString "." (head parts)) ++ (tail parts))
    + "/"
    + concatStringsSep "-" (tail parts)
    + ".jar";

  # Makes a fixed-output derivation from a list of impure derivations, then
  # returns a list of paths to the new files.
  makeFOD = { drvs, hash }:
    let
      name = drv:
        builtins.head (builtins.match "/nix/store/[0-9a-z]+-(.+)" (toString drv));
      FOD = pkgs.runCommand
        "makeFOD"
        {
          outputHashMode = "recursive";
          outputHashAlgo = "sha256";
          outputHash = hash;
        }
        ''
          mkdir -p $out
          ${
            lib.concatMapStringsSep
            "\n"
            (x: "cp ${x} $out/${name x}")
            drvs
          }
        '';
    in
    {
      drv = FOD;
      list = map (x: "${FOD}/${name x}") drvs;
    };

  # Fetches multiple urls with only one hash. Returns a list of files.
  fetchMultiple = { urls, extraDrvs ? [ ], hash }:
    let
      all = makeFOD {
        inherit hash;
        drvs = extraDrvs ++ map (url: builtins.fetchurl { inherit url; }) urls;
      };
      extraCount = builtins.length extraDrvs;
    in
    {
      inherit (all) drv;
      list = lib.drop extraCount all.list;
    };

  fixedLibs = { libs, extraDrvs ? [ ], hash }:
    let
      partitioned = lib.partition (l: l ? sha1 || l ? file) libs;
      withHash = partitioned.right;
      withoutHashFiles = fetchMultiple {
        inherit hash extraDrvs;
        urls = map (l: l.url) partitioned.wrong;
      };
      withoutHash = lib.zipListsWith
        (l: file: l // {
          inherit file;
        })
        partitioned.wrong
        withoutHashFiles.list;
    in
    {
      inherit (withoutHashFiles) drv;
      list = withHash ++ withoutHash;
    };

  fixedPkg = { pkg, extraDrvs ? [ ], hash }:
    let fixed = fixedLibs {
      libs = pkg.libraries;
      inherit extraDrvs hash;
    };
    in
    pkg // {
      libraries = fixed.list;
      extraDeps = (pkg.extraDeps or [ ]) ++ [ fixed.drv ];
    };

  normalizePkg = pkg:
    pkg // {
      libraries = filterMap
        (l:
          if l ? rules && ! isAllowed l.rules
          then null
          else
            (
              if l ? natives
              then
                (
                  if l.natives ? ${os}
                  then
                    let
                      classifier = l.natives.${os};
                      a = l.downloads.classifiers.${classifier};
                    in
                    {
                      name = l.name;
                      type = "native";
                      inherit (a) url sha1;
                    }
                  else null
                )
              else {
                name = l.name;
                type = "jar";
              }
              // lib.optionalAttrs
                (l ? downloads.artifact.url && l.downloads.artifact.url != "")
                {
                  inherit (l.downloads.artifact) url;
                }
              // lib.optionalAttrs
                (l ? url && l.url != "")
                {
                  url = l.url + urlPathFromLibraryName l.name;
                }
              // lib.optionalAttrs
                (l ? downloads.artifact.sha1)
                {
                  inherit (l.downloads.artifact) sha1;
                }
              // lib.optionalAttrs
                (l ? checksums)
                {
                  sha1 = head l.checksums;
                }
              // lib.optionalAttrs
                (l ? file)
                {
                  inherit (l) file;
                }
            )
        )
        pkg.libraries
      ++ lib.optional (pkg ? downloads.client) {
        name = "net.minecraft.client";
        type = "jar";
        inherit (pkg.downloads.client) url sha1;
      };
    };
}
