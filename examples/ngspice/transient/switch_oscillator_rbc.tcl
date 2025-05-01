# example is from Ngspice example folder (/examples/p-to-n-examples/switch-oscillators.cir)

package require SpiceGenTcl
package require rbc
namespace import rbc::*
namespace import ::SpiceGenTcl::*
importNgspice

# create class that represents inverter subcircuit
oo::class create Inverter {
    superclass Subcircuit
    constructor {} {
        # define external pins of subcircuit
        set pins {in out vdd dgnd}
        # define input parameters of subcircuit
        set params {}
        # add elements to subcircuit definition
        my add [C new l out dgnd -c 0.1e-12] [C new 2 out vdd -c 0.1e-12]
        my add [VSwitch new p out vdd vdd in -model swswitch] [VSwitch new n out dgnd in dgnd -model switchn]
        # pass name, list of pins and list of parameters to Subcircuit constructor
        next inverter $pins $params
    }
}

# create subcircuit definition instance
set inverter [Inverter new]

# create top-level circuit
set circuit [Circuit new {switch_oscillator}]
# add elements to circuit
$circuit add [Tran new -tstep 50e-12 -tstop 80e-9]
$circuit add [Options new {{method gear} {maxord 3}}]
$circuit add [RawString new ".ic v(osc_out)=0.25"]
$circuit add $inverter
$circuit add [Vdc new dd vdd2 0 -dc 3]
$circuit add [Vdc new measure vdd2 vdd -dc 0]
$circuit add [C new vdd vdd 0 -c 1e-18]

# add multiple inverters in the cycle
for {set i 1} {$i<16} {incr i} {
    set ip1 [+ $i 1]
    lappend invsList [SubcircuitInstanceAuto new $inverter x${ip1} "n${i} n${ip1} vdd 0"]
}
$circuit add {*}$invsList
$circuit add [SubcircuitInstanceAuto new $inverter x18 {osc_out n1 vdd 0}]
$circuit add [SubcircuitInstanceAuto new $inverter x19 {n16 osc_out vdd 0}]
$circuit add [VSwitchModel new swswitch -vt 1 -vh 0.1 -ron 1e3 -roff 1e12]
$circuit add [VSwitchModel new switchn -vt 1 -vh 0.1 -ron 1e3 -roff 1e12]

#set simulator with default temporary directory
set simulator [BatchLiveLog new {batch1}]
# attach simulator object to circuit
$circuit configure -simulator $simulator
# run circuit, read log and data
$circuit runAndRead
# get data object
set data [$circuit getDataDict]
set time [dget $data time]
set vout [dget $data v(osc_out)]
set imeas [dget $data i(vmeasure)]

vector create timeVec voutVec imeasVec
timeVec set $time
voutVec set $vout
imeasVec set $imeas

set topWin [toplevel .plot]
set graph1 [graph .plot.graph1 -width 800 -height 400]
set graph2 [graph .plot.graph2 -width 800 -height 400]
Rbc_ZoomStack $graph1
Rbc_Crosshairs $graph1
Rbc_ZoomStack $graph2
Rbc_Crosshairs $graph2
grid $graph1 -sticky nsew
grid $graph2 -sticky nsew
grid columnconfigure .plot 0 -weight 1
grid rowconfigure .plot 0 -weight 1
grid rowconfigure .plot 1 -weight 1
$graph1 element create vout -x timeVec -y voutVec -symbol {}
$graph1 grid on
$graph1 axis configure x -title {time, s}
$graph1 axis configure y -title {vout, V}
$graph2 element create imeas -x timeVec -y imeasVec -symbol {}
$graph2 grid on
$graph2 axis configure x -title {time, s}
$graph2 axis configure y -title {imeas, A}
