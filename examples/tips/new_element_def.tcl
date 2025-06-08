# source main file
lappend auto_path "../../"
package require SpiceGenTcl

# import class names to current namespace
namespace import ::SpiceGenTcl::*
importNgspice
        
        
oo::class create Core {
    superclass Device
    constructor {name pNode nNode args} {
        set arguments [argparse -inline {
            {-model= -required}
            {-len= -default 0.1}
            {-area= -default 1}
        }]
        lappend paramList "model [dget $arguments model] -posnocheck"
        dict for {paramName value} $arguments {
            if {$paramName ni {model}} {
                if {[@ $value 0] eq {-eq}} {
                    lappend params [list -eq $paramName [@ $value 1]]
                } else {
                    lappend params [list $paramName $value]
                }
            }
        }
        next n$name [list "p $pNode" "n $nNode"] $paramList
    }
}

oo::class create CoreModel {
    superclass Model
    constructor {name args} {
        set paramsNames [list ms a k alpha c]
        next $name coreja [my argsPreprocess $paramsNames {*}$args]
    }
}

oo::class create CoreModel1 {
    superclass Model
    constructor {name args} {
        set arguments [argparse -inline {
            -ms=
            {-a= -default 1000}
            -k=
            -alpha=
            -c=
        }]
        dict for {paramName value} $arguments {
            if {[@ $value 0] eq {-eq}} {
                lappend params [list -eq $paramName [@ $value 1]]
            } else {
                lappend params [list $paramName $value]
            }
        }
        next $name coreja $paramList
    }
}

set coreInst [Core new 1 p n -model coremodel -area 1e-4 -len {l*5 -eq}]
set coreModel [CoreModel new coremodel -ms 1.7meg -a 1100 -k 2000 -alpha 1.6m -c 0.2]
set coreModel1 [CoreModel1 new coremodel -ms 1.7meg -a 1100 -k 2000 -alpha 1.6m -c 0.2]

puts [$coreInst genSPICEString]
puts [$coreModel genSPICEString]
puts [$coreModel1 genSPICEString]
