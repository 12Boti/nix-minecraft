let
  inherit (import ./default.nix {}) minecraftForge curseforgeMod;
in
minecraftForge {
  version = "1.12.2-14.23.5.2855";
  mcSha1 = "f07e0f1228f79b9b04313fc5640cd952474ba6f5";
  hash = "";
}
