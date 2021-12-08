{ lib, baseModules, runCommand, lowdown, substitute }:
let
  eval = lib.evalModules {
    modules = [{ _module.check = false; }] ++ baseModules;
  };
  options = lib.optionAttrSetToDocList eval.options;
  visibleOptions = builtins.filter (x: x.visible && !x.internal) options;
  htmlContent = lib.concatMapStringsSep "\n"
    (opt: ''
      <div class="option" id="${opt.name}">
        <div class="name">${opt.name}</div>
        <div class="type">${opt.type}</div>
        <div class="desc">${opt.description}</div>
        ${lib.optionalString (opt ? example) ''
        <div class="example">${toString opt.example}</div>
        ''}
      </div>
    '')
    visibleOptions;
  htmlPage = runCommand "nix-minecraft-doc.html"
    {
      inherit htmlContent;
      passAsFile = [ "htmlContent" ];
    }
    ''
      sed -e "/@CONTENT@/{r $htmlContentPath" -e "d}" ${./template.html} > $out
    '';
in
htmlPage
