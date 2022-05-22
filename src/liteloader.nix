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
  cfg = config.liteloader;
in
{
  options.liteloader = {
    url = mkOption {
      default = null;
      example = "http://jenkins.liteloader.com/job/LiteLoaderInstaller%201.12.2/lastSuccessfulBuild/artifact/build/libs/liteloader-installer-1.12.2-00-SNAPSHOT.jar";
      description = ''
        The URL to download liteloader from.
        To find it go to https://www.liteloader.com/download
        and copy the URL of the <b>jar file</b>.
      '';
      type = types.nullOr types.nonEmptyStr;
    };
    hash = mkOption {
      description = ''
        The hash of the liteloader version.
        Leave it empty to have nix tell you what to use.
      '';
      type = types.str;
    };
  };

  config.internal = (import ./download-module.nix {
    inherit pkgs lib;
    name = "liteloader";
    enabled = config.liteloader.url != null;
    nativeBuildInputs = with pkgs; [ unzip ];
    hash = config.liteloader.hash;
    jsonnetFile = ./jsonnet/liteloader.jsonnet;
    scriptBefore = ''
      curl -L -o installer.jar '${cfg.url}'
      unzip -p installer.jar install_profile.json > orig.json
    '';
  }).module;
}
