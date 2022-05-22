local lib = import 'lib.libsonnet';
// forge sometimes has wrong hashes for packages, here are the correct ones
local correct_hashes = {
  'org.scala-lang.plugins:scala-continuations-library_2.11:1.0.2':
    'sha1-DlF8U6fprNaxZoxaNezLqjurmqw=',
  'org.scala-lang.plugins:scala-continuations-plugin_2.11.1:1.0.2':
    'sha1-82GjKDRSxX+jDB7mlEiZXeI8YPc=',
};
local without_version = function(libname)
  std.join(':', std.split(libname, ':')[:2]);
local get_url_for = function(libname)
  if std.member([
    'net.minecraft:launchwrapper',
    'lzma:lzma',
    'java3d:vecmath',
  ], without_version(libname))
  then 'https://libraries.minecraft.net/' + lib.name_to_path(libname)
  else 'https://maven.minecraftforge.net/' + lib.name_to_path(libname);

function(orig_str, have_forge_jar)
  local orig = lib.pkg_from_str(orig_str);
  local complete = orig {
    libraries: [
      l
      + (if !('url' in l)
         then { url: get_url_for(l.name) }
         else {})
      + (if l.name in correct_hashes
         then { sha1: correct_hashes[l.name] }
         else {})
      + (if have_forge_jar && without_version(l.name) == 'net.minecraftforge:forge'
         then { path: 'forge.jar' }
         else {})
      for l in orig.libraries
    ],
  };
  lib.download_pkg(complete)
