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
    example = ''
      <pre><code>
      [
        # JEI
        {
          projectId = 238222;
          fileId = 3043174;
          hash = "sha256-nbwsDsjCiCH91dykh5CQiVAWB+4lwOhHDEPJ/QvRIFM=";
        }
      ]
      </code></pre>
    '';
    description = ''
      List of mods to install from curseforge.
    '';
    default = [ ];
    type = types.listOf (types.submodule {
      options = {
        projectId = mkOption {
          type = types.ints.unsigned;
          description = ''
            The ID of the mod on curseforge.
            To find it go to https://www.curseforge.com/minecraft/mc-mods
            and select the mod you want. The Project ID will be on the right.
          '';
        };
        fileId = mkOption {
          type = types.ints.unsigned;
          description = ''
            The ID of the file on curseforge.
            To find it go to https://www.curseforge.com/minecraft/mc-mods
            and select the mod you want.
            On the files tab, select the file you want.
            The last part of the URL will be the file's ID.
          '';
        };
        hash = mkOption {
          type = types.str;
          description = ''
            The hash of the mod.
            Leave it empty to have nix tell you what to use.
          '';
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
