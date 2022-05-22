{ lib, ... }:
let
  inherit (lib) mkOption types;
in
{
  options.internal = {
    minecraftArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
      internal = true;
    };

    jvmArgs = mkOption {
      type = types.listOf types.str;
      default = [ ];
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

    clientMappings = {
      url = mkOption {
        type = types.nonEmptyStr;
        internal = true;
        default = null;
      };

      sha1 = mkOption {
        type = types.nonEmptyStr;
        internal = true;
        default = null;
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
          destPath = mkOption {
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
          installerOnly = mkOption {
            default = false;
            type = types.bool;
            internal = true;
          };
        };
      });
      internal = true;
    };
  };
}
