# source main file
lappend auto_path ../
package require SpiceGenTcl

# import class names to current namespace
namespace import ::SpiceGenTcl::*
importNgspice

# create netlist
set netlist [Netlist new main_netlist]

# create class that represents RC subcircuit
# docs-begin definition-subcircuit
oo::class create RCnet {
    superclass Subcircuit
    constructor {} {
        # define external pins of subcircuit
        # docs-begin pins-definition-subcircuit
        set pins {plus minus}
        # docs-end pins-definition-subcircuit
        # define input parameters of subcircuit
        # docs-begin params-definition-subcircuit
        set params {{r 100} {c 1e-6}}
        # docs-end params-definition-subcircuit
        # add elements to subcircuit definition
        # docs-begin add-elems-definition-subcircuit
        my add [R new 1 net1 plus -r {-eq r}]
        my add [C new 1 net2 net3 -c {-eq c}]
        my add [R new 5 minus net2 -model res_sem -l 10e-6 -w 100e-6]
        my add [RModel new rsem1mod -tc1 0.1 -tc2 0.4]
        # docs-end add-elems-definition-subcircuit
        # pass name, list of pins and list of parameters to Subcircuit constructor
        # docs-begin next-pass-definition-subcircuit
        next rcnet $pins $params
        # docs-end next-pass-definition-subcircuit
    }
}
# docs-end definition-subcircuit

# docs-begin add-to-netlist-definition-subcircuit
# create subcircuit definition
set subcircuit [RCnet new]
# add to netslit
$netlist add $subcircuit
# docs-end add-to-netlist-definition-subcircuit

# create subcircuit instance
# docs-begin create-subcircuit-instance-definition-subcircuit
set subInst [SubcircuitInstance new 1 {{plus net1} {minus net2}} rcnet {{r 1} {-eq c cpar}}]
# docs-end create-subcircuit-instance-definition-subcircuit

# create subcircuit instance with help of already created subcircuit definition $subcircuit
# docs-begin auto-create-subcircuit-instance-definition-subcircuit
set subInst1 [SubcircuitInstanceAuto new $subcircuit 2 {net1 net2} -r 1 -c {-eq cpar}]
# docs-end auto-create-subcircuit-instance-definition-subcircuit

# add to netslit
$netlist add $subInst
$netlist add $subInst1
# create SPICE netlist string from main netlist
puts [$netlist genSPICEString]

