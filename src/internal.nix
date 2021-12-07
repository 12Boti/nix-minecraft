{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.internal = {
    arguments = mkOption {
      type = types.listOf types.str;
    };

    javaVersion = mkOption {
      type = types.int;
    };

    mainClass = mkOption {
      type = types.nonEmptyStr;
    };

    requiredMinecraftVersion = mkOption {
      default = null;
      type = types.nullOr types.nonEmptyStr;
    };

    assets = {
      id = mkOption {
        type = types.nonEmptyStr;
      };

      url = mkOption {
        type = types.nonEmptyStr;
      };

      sha1 = mkOption {
        type = types.nonEmptyStr;
      };
    };

    libraries = mkOption {
      type = types.listOf (types.submodule {
        options = {
          type = mkOption {
            type = types.enum [ "jar" "native" ];
          };
          name = mkOption {
            type = types.nonEmptyStr;
          };
          sha1 = mkOption {
            default = null;
            type = types.nullOr types.nonEmptyStr;
          };
          url = mkOption {
            default = null;
            type = types.nullOr types.nonEmptyStr;
          };
          path = mkOption {
            default = null;
            type = types.nullOr types.path;
          };
        };
      });
    };
  };
}
