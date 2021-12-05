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

  download = { projectId, fileId, hash }:
    pkgs.runCommandLocal
      "curseforge-mod-${toString projectId}-${toString fileId}.jar"
      {
        outputHash = hash;
        outputHashAlgo = "sha256";
        nativeBuildInputs = [ pkgs.curl pkgs.jq ];
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      }
      ''
        url=$(
        curl -L 'https://addons-ecs.forgesvc.net/api/v2/addon/${toString projectId}/files' \
        | jq -r '.[] | select(.id == ${toString fileId}) | .downloadUrl'
        )
        curl -L -o "$out" "$url"
      '';
in
{
  options.mods.curseforge = mkOption {
    default = [ ];
    type = types.listOf (types.submodule {
      options = {
        projectId = mkOption {
          type = types.int;
        };
        fileId = mkOption {
          type = types.int;
        };
        hash = mkOption {
          type = types.str;
        };
      };
    });
  };

  config.extraGamedirFiles = map
    (m: {
      source = download m;
      path = "mods/${toString m.projectId}-${toString m.fileId}.jar";
    })
    config.mods.curseforge;
}
