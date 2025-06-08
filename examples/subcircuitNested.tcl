# source main file
lappend auto_path ../
package require SpiceGenTcl

# import class names to current namespace
namespace import ::SpiceGenTcl::*
importNgspice

# create netlist 
set netlist [Netlist new main_netlist]

# create class that represents RC subcircuit
oo::class create RCnet {
    superclass Subcircuit
    constructor {} {
        # define external pins of subcircuit
        set pins {plus minus}
        # define input parameters of subcircuit
        set params {{r 100} {c 1e-6}}
        # add elements to subcircuit definition
        my add [R new 1 net1 plus -r {-eq r}]
        my add [C new 1 net2 net3 -c {-eq c}]
        my add [R new 5 minus net2 -model res_sem -l 10e-6 -w 100e-6]
        my add [RModel new rsem1mod -tc1 0.1 -tc2 0.4]

        oo::class create RCnetNest {
            superclass Subcircuit
            constructor {} {
                set pins {plus minus}
                set params {{r 100} {c 1e-6}}
                my add [R new 1 net1 plus -r {-eq r}]
                my add [C new 1 net2 net3 -c {-eq c}]
                next rcnetnest $pins $params
            }
        }
        set subcircuitNest [RCnetNest new]
        my add $subcircuitNest
        my add [SubcircuitInstanceAuto new $subcircuitNest 2 {net1 net2} -r 1 -c {-eq cpar}]
        # pass name, list of pins and list of parameters to Subcircuit constructor
        next rcnet $pins $params
    }
}
# create subcircuit definition
set subcircuit [RCnet new]
# add to netslit
$netlist add $subcircuit
# create subcircuit instance
set subInst [SubcircuitInstance new 1 {{plus net1} {minus net2}} rcnet {{r 1} {-eq c cpar}}]
# create subcircuit instance with help of already created subcircuit definition $subcircuit
set subInst1 [SubcircuitInstanceAuto new $subcircuit 2 {net1 net2} -r 1 -c {-eq cpar}]
# add to netslit
$netlist add $subInst 
$netlist add $subInst1 
# create SPICE netlist string from main netlist
puts [$netlist genSPICEString]

