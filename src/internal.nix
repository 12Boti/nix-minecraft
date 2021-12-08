{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.internal = {
    arguments = mkOption {
      type = types.listOf types.str;
      internal = true;
    };

    javaVersion = mkOption {
      type = types.ints.positive;
      internal = true;
    };

    mainClass = mkOption {
      type = types.nonEmptyStr;
      internal = true;
    };

    requiredMinecraftVersion = mkOption {
      default = null;
      type = types.nullOr types.nonEmptyStr;
      internal = true;
    };

    assets = {
      id = mkOption {
        type = types.nonEmptyStr;
        internal = true;
      };

      url = mkOption {
        type = types.nonEmptyStr;
        internal = true;
      };

      sha1 = mkOption {
        type = types.nonEmptyStr;
        internal = true;
      };
    };

    libraries = mkOption {
      type = types.listOf (types.submodule {
        options = {
          type = mkOption {
            type = types.enum [ "jar" "native" ];
            internal = true;
          };
          name = mkOption {
            type = types.nonEmptyStr;
            internal = true;
          };
          sha1 = mkOption {
            default = null;
            type = types.nullOr types.nonEmptyStr;
            internal = true;
          };
          url = mkOption {
            default = null;
            type = types.nullOr types.nonEmptyStr;
            internal = true;
          };
          path = mkOption {
            default = null;
            type = types.nullOr types.path;
            internal = true;
          };
        };
      });
      internal = true;
    };
  };
}
