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
{ projectId, fileId, hash }:
pkgs.runCommandLocal
  "curseforge-mod-${toString projectId}-${toString fileId}.jar"
{
  outputHash = hash;
  outputHashAlgo = "sha256";
  buildInputs = [ pkgs.curl pkgs.jq ];
  SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
}
  ''
    url=$(
    curl 'https://addons-ecs.forgesvc.net/api/v2/addon/${toString projectId}/files' \
    | jq -r '.[] | select(.id == ${toString fileId}) | .downloadUrl'
    )
    curl -L -o "$out" "$url"
  ''
