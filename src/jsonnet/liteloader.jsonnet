local lib = import 'lib.libsonnet';
function(orig_str)
  local orig = lib.normalize_pkg(std.parseJson(orig_str).versionInfo);
  local complete = orig {
    libraries: [
      l
      + (if !('url' in l)
         then { url: 'https://libraries.minecraft.net/' + lib.name_to_path(l.name) }
         else {})
      for l in orig.libraries
    ],
  };
  lib.download_pkg(complete)
