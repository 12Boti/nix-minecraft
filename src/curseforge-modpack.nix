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
  inherit (lib) mkIf mkOption types;
  cfg = config.modpack.curseforge;

  downloaded =
    pkgs.runCommandLocal
      "curseforge-modpack-${toString cfg.projectId}-${toString cfg.fileId}"
      {
        outputHash = cfg.hash;
        outputHashAlgo = "sha256";
        outputHashMode = "recursive";
        nativeBuildInputs = [ pkgs.curl pkgs.jq ];
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      }
      ''
        mkdir -p "$out"
        curl -o "$out/package.json" 'https://api.modpacks.ch/public/curseforge/${toString cfg.projectId}/${toString cfg.fileId}'
        jq -r '.files[] | select(.sha1 == "") | .path + "/" + .name + " " + .url' < "$out/package.json" | \
        while read path url
        do
          mkdir -p "$(dirname "$out/$path")"
          curl -Lo "$out/$path" "$url"
        done
      '';
  json = lib.importJSON "${downloaded}/package.json";

  forgeVersion = (lib.findFirst
    (t: t.name == "forge")
    { version = null; }
    json.targets).version;

  fabricVersion = (lib.findFirst
    (t: t.name == "fabric")
    { version = null; }
    json.targets).version;

  mcVersion = (lib.findFirst
    (t: t.name == "minecraft")
    (throw "minecraft not found in modpack targets")
    json.targets).version;

  normalFiles = map
    (f: {
      path = "${f.path}/${f.name}";
      source = pkgs.fetchurl {
        inherit (f) sha1;
        url = builtins.replaceStrings [ " " ] [ "%20" ] f.url;
        name = lib.strings.sanitizeDerivationName f.name;
        curlOpts = "--globoff"; # do not misinterpret [] brackets
      };
    })
    (builtins.filter (f: f.sha1 != "") json.files);

  lockedFiles = map
    (f: {
      path = "${f.path}/${f.name}";
      source = "${downloaded}/${f.path}/${f.name}";
    })
    (builtins.filter (f: f.sha1 == "" && f.type != "cf-extract") json.files);

  extractedFiles =
    let
      zipfile = lib.findFirst
        (f: f.type == "cf-extract")
        (throw "could not find curseforge modpack files zip")
        json.files;
      extracted = pkgs.runCommand "curseforge-modpack-${toString cfg.projectId}-${toString cfg.fileId}-files"
        { nativeBuildInputs = [ pkgs.unzip ]; }
        ''
          mkdir -p "$out"
          unzip '${downloaded}/${zipfile.path}/${zipfile.name}' -d "$out"
          find "$out/overrides" -type f -fprintf "$out/files.txt" '%P\n'
        '';
    in
    map
      (f: { path = f; source = "${extracted}/overrides/${f}"; })
      (lib.splitString "\n" (lib.fileContents "${extracted}/files.txt"));
in
{
  options.modpack.curseforge = {
    projectId = mkOption {
      example = 256289;
      default = null;
      type = types.nullOr types.ints.unsigned;
      description = ''
        The ID of the modpack you want to install.
        To find it go to https://www.curseforge.com/minecraft/modpacks
        and select the modpack you want. The Project ID will be on the right.
      '';
    };
    fileId = mkOption {
      example = 3590506;
      type = types.ints.unsigned;
      description = ''
        The version ID you want to install.
        To find it go to https://www.curseforge.com/minecraft/modpacks
        and select the modpack you want.
        On the files tab, select the file you want.
        The last part of the URL will be the file's ID.
      '';
    };
    hash = mkOption {
      type = types.str;
      description = ''
        The hash of the modpack.
        Leave it empty to have nix tell you what to use.
      '';
    };
  };

  config = mkIf (cfg.projectId != null) {
    minecraft.version = mcVersion;
    extraGamedirFiles = normalFiles ++ lockedFiles ++ extractedFiles;
    fabric.version = fabricVersion;
    forge.version = forgeVersion;
  };
}
