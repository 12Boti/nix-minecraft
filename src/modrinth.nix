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

  download = { projectId, version, hash }:
    pkgs.runCommandLocal
      "modrinth-mod-${projectId}-${version}.jar"
      {
        outputHash = hash;
        outputHashAlgo = "sha256";
        nativeBuildInputs = [ pkgs.curl pkgs.jq ];
        SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
      }
      ''
        url="$(
        curl -L 'https://api.modrinth.com/api/v1/mod/${projectId}/version' \
        | jq -r '.[] | select(.version_number == "${version}") | .files[0].url' \
        | sed 's/ /%20/g'
        )"
        curl -L -o "$out" "$url"
      '';
in
{
  options.mods.modrinth = mkOption {
    example = ''
      <pre><code>
      [
        # Mod Menu
        {
          projectId = "mOgUt4GM";
          version = "1.16.22";
          hash = "sha256-bYP08vpv/HbEGGISW6ij0asnfZk1nhn8HUj/A7EV81A=";
        }
      ]
      </code></pre>
    '';
    description = ''
      List of mods to install from modrinth.
    '';
    default = [ ];
    type = types.listOf (types.submodule {
      options = {
        projectId = mkOption {
          type = types.nonEmptyStr;
          description = ''
            The ID of the mod on modrinth.
            To find it go to https://modrinth.com/mods
            and select the mod you want. The Project ID will be on the right.
          '';
        };
        version = mkOption {
          type = types.nonEmptyStr;
          description = ''
            The version of the mod on modrinth.
            To find it go to https://modrinth.com/mods
            and select the mod you want.
            On the versions tab, copy the wanted version from the VERSION column.
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
      path = "mods/${m.projectId}-${m.version}.jar";
    })
    config.mods.modrinth;
}
