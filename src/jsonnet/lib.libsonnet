local os = 'linux';
{
  is_allowed(rules)::
    std.member(rules,
               {
                 action: 'allow',
                 os: { name: os },
               })

    || (
      std.member(rules,
                 {
                   action: 'allow',
                 })
      &&
      !std.member(rules,
                  {
                    action: 'disallow',
                    os: { name: os },
                  })
    ),

  has(obj, path, nonempty=true)::
    local parts = std.splitLimit(path, '.', 1);
    parts[0] in obj
    &&
    if std.length(parts) > 1
    then $.has(obj[parts[0]], parts[1])
    else !nonempty || obj[parts[0]] != '',

  name_to_path(name)::
    local parts = std.split(name, ':');
    std.join('/', std.split(parts[0], '.') + parts[1:] + [std.join('-', parts[1:]) + '.jar']),

  normalize_pkg(pkg)::
    {
      libraries: std.filter(function(x) x != null, [
        if 'rules' in l && !$.is_allowed(l.rules)
        then null
        else (
          if 'natives' in l
          then (
            if os in l.natives
            then
              local classifier = l.natives[os];
              local a = l.downloads.classifiers[classifier];
              {
                name: l.name,
                type: 'native',
                url: a.url,
                sha1: a.sha1,
              }
          )
          else {
                 name: l.name,
                 type: 'jar',
               }
               + (if $.has(l, 'downloads.artifact.url')
                  then { url: l.downloads.artifact.url }
                  else {})
               + (if $.has(l, 'url')
                  then { url: l.url + $.name_to_path(l.name) }
                  else {})
               + (if $.has(l, 'downloads.artifact.sha1')
                  then { sha1: l.downloads.artifact.sha1 }
                  else {})
               + (if 'checksums' in l
                  then { sha1: l.checksums[0] }
                  else {})
               + (if $.has(l, 'downloads.artifact.path')
                  then { destPath: l.downloads.artifact.path }
                  else { destPath: $.name_to_path(l.name) })
               + (if $.has(l, 'installerOnly')
                  then { installerOnly: l.installerOnly }
                  else {})
        )
        for l in pkg.libraries
      ]) + (if $.has(pkg, 'downloads.client', false)
            then [{
              name: 'net.minecraft.client',
              type: 'jar',
              url: pkg.downloads.client.url,
              sha1: pkg.downloads.client.sha1,
              destPath:
                'net/minecraft/client/'
                + pkg.id
                + '/client-'
                + pkg.id
                + '.jar',
            }]
            else []),
    }
    + (if 'assetIndex' in pkg
       then {
         assets: {
           id: pkg.assetIndex.id,
           url: pkg.assetIndex.url,
           sha1: pkg.assetIndex.sha1,
         },
       }
       else {})
    + (if 'javaVersion' in pkg
       then { javaVersion: pkg.javaVersion.majorVersion }
       else {})
    + (if 'minecraftArguments' in pkg
       then {
         minecraftArgs: std.split(pkg.minecraftArguments, ' '),
         jvmArgs: [],
         overrideArguments: true,
       }
       else {})
    + (if 'arguments' in pkg
       then
         local string_args = function(args)
           std.filter(function(x) x != null, [
             if std.isString(arg)
             then arg
             else
               (if $.is_allowed(arg.rules)
                then arg.value)
             for arg in args
           ]);
         {
           minecraftArgs: string_args(pkg.arguments.game),
           jvmArgs: string_args(pkg.arguments.jvm),
           overrideArguments: false,
         }
       else {})
    + (if 'inheritsFrom' in pkg
       then { requiredMinecraftVersion: pkg.inheritsFrom }
       else {})
    + (if 'mainClass' in pkg
       then { mainClass: pkg.mainClass }
       else {})
    + (if $.has(pkg, 'downloads.client_mappings', false)
       then { clientMappings: {
         sha1: pkg.downloads.client_mappings.sha1,
         url: pkg.downloads.client_mappings.url,
       } }
       else {}),

  download_pkg(pkg)::
    local get_path = function(name) std.strReplace(name, ':', '__');
    {
      'package.json': pkg {
        libraries: [
          if 'sha1' in l || 'path' in l
          then l
          else l {
            name: l.name,
            type: l.type,
            path: get_path(l.name),
          }
          for l in pkg.libraries
        ],
      },

      'downloads.json': [
        {
          url: l.url,
          path: get_path(l.name),
        }
        for l in pkg.libraries
        if !('sha1' in l || 'path' in l)
      ],
    },

  pkg_from_str(str):: $.normalize_pkg(std.parseJson(str)),
}
