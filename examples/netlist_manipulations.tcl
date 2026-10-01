# source main file
lappend auto_path ../
package require SpiceGenTcl

# import class names to current namespace
namespace import ::SpiceGenTcl::*
importNgspice

# create netlist
# docs-begin create-netlist
set netlist [Netlist new main_netlist]

# incrementally build netlist by adding different elements
$netlist add [R new 1 net1 net2 -r 10]
$netlist add [R new 5 net1 net2 -model res_sem -l 10e-6 -w 100e-6]
$netlist add [RModel new rsem1mod -tc1 0.1 -tc2 0.4]
$netlist add [R new 2 net1 net2 -r {-eq {r1+5/10}}]
$netlist add [C new 1 net2 net3 -c 1e-6]
$netlist add [ParamStatement new {{r1 1} {r2 2}} -name ps1]
$netlist add [Comment new {some random comment} -name com1]
$netlist add [Include new {/fold1/fold2/file.lib} -name inc1]
$netlist add [Library new {/fold1/fold2/file.lib} fast -name lib1]
$netlist add [RawString new {*comment in form of raw string} -name raw1]
$netlist add [Vdc new 1 net1 net3 -dc 5]
$netlist add [Tran new -tstep 1e-6 -tstop 1e-3 -uic -name tran1]
# docs-end create-netlist

# generate SPICE netlist
# docs-begin gen-netlist
puts [$netlist genSPICEString]
# docs-end gen-netlist

# docs-begin del-netlist
$netlist del c1
puts [$netlist genSPICEString]
# docs-end del-netlist

# get reference of resistor object
# docs-begin get-element-netlist
set resistor [$netlist getElement r1]
# docs-end get-element-netlist

# change the value of resistor in circuit
# docs-begin change-element-param-netlist
$resistor actOnParam -set r 100
# docs-end change-element-param-netlist

# change the name of connected net to plus pin
# docs-begin change-element-pin-netlist
$resistor actOnPin -set np net10
# docs-end change-element-pin-netlist

# generate SPICE netlist again with different value of resistor
puts [$netlist genSPICEString]

# docs-begin print-all-elems-netlist
# get and print all names of elements attached to $netlist
puts [$netlist getAllElemNames]
# docs-end print-all-elems-netlist

# docs-begin delete-elem-temp-netlist
set r1 [$netlist getElement r1]
$netlist del r1
$netlist add $r1
# docs-end delete-elem-temp-netlist

# docs-begin add_saved_elem-netlist
set r5 [R new 5 net1 net2 -r 10]
$netlist add $r5
# docs-end add_saved_elem-netlist
