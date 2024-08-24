# source main file
lappend auto_path "../"
package require SpiceGenTcl

# import class names to current namespace
namespace import ::SpiceGenTcl::*
importNgspice

# create netlist 
set netlist [Netlist new main_netlist]

# incrementally build netlist by adding different elements
$netlist add [R new 1 net1 net2 10]
$netlist add [RSem new 5 net1 net2 res_sem -l 10e-6 -w 100e-6]
$netlist add [RSemModel new rsem1mod -tc1 0.1 -tc2 0.4]
$netlist add [R new 2 net1 net2 {{r1+5/10} -eq}]
$netlist add [C new 1 net2 net3 1e-6]
$netlist add [ParamStatement new {{r1 1} {r2 2}} -name ps1]
$netlist add [Comment new {some random comment} -name com1]
$netlist add [Include new {/fold1/fold2/file.lib} -name inc1]
$netlist add [Library new {/fold1/fold2/file.lib} fast -name lib1]
$netlist add [RawString new {*comment in form of raw string} -name raw1]
$netlist add [Vdc new 1 net1 net3 5]
$netlist add [Tran new 1e-6 1e-3 -uic -name tran1]
# generate SPICE netlist
puts [$netlist genSPICEString]
$netlist del c1
puts ""
puts [$netlist genSPICEString]
# get reference of resistor object
set resistor [$netlist getElement r1]
# change the value of resistor in circuit
$resistor setParamValue r 100
$resistor setPinNodeName np net10
# generate SPICE netlist again with different value of resistor
puts "\n"
puts [$netlist genSPICEString]
# get and print all names of elements attached to $netlist
puts [$netlist getAllElemNames]