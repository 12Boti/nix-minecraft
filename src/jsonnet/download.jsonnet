local lib = import 'lib.libsonnet';
function(orig_str)
  lib.download_pkg(lib.pkg_from_str(orig_str))
