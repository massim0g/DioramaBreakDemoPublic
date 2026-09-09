package massimodin //@nested-tags:_main

//to adjust the CLI flags used when building, see config_build.json at the workspace root

ON_SWITCH :: #config(ON_SWITCH, false)
ON_WINDOWS :: ODIN_OS == .Windows
ON_LINUX :: ODIN_OS == .Linux && !ON_SWITCH
ON_PC :: ON_WINDOWS || ON_LINUX