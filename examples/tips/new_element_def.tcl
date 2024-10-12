# source main file
lappend auto_path "../../"
package require SpiceGenTcl

# import class names to current namespace
namespace import ::SpiceGenTcl::*
importNgspice
        
        
oo::class create Core {
    superclass ::SpiceGenTcl::DeviceModel
    mixin ::SpiceGenTcl::KeyArgsBuilder
    constructor {name pNode nNode modelName args} {
        set paramsNames [list len area ms a k alpha c]
        set paramDefList [my buildArgStr $paramsNames]
        set arguments [argparse -inline "
            $paramDefList
        "]
        set paramList ""
        dict for {paramName value} $arguments {
            lappend paramList "$paramName $value"
        }
        next n$name [list "p $pNode" "n $nNode"] $modelName $paramList
    }
}

set coreInst [Core new 1 p n coreModel -area 1e-4 -len {l*5 -eq}]

puts [$coreInst genSPICEString]