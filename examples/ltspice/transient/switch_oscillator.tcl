# example is from Ngspice example folder (/examples/p-to-n-examples/switch-oscillators.cir)

package require SpiceGenTcl
package require ticklecharts
set ::ticklecharts::theme "dark"
namespace import ::SpiceGenTcl::*
importLtspice

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
set simulator [Batch new {batch1}]
# attach simulator object to circuit
$circuit configure -simulator $simulator
# run circuit, read log and data
$circuit runAndRead
# get data object
set data [$circuit getDataDict]
set time [dget $data time]
set vout [dget $data v(osc_out)]
set imeas [dget $data i(vmeasure)]
foreach time [dget $data time] vout [dget $data v(osc_out)] imeas [dget $data i(vmeasure)] {
    lappend timeVout [list $time $vout]
    lappend timeImeas [list $time $imeas]
}

# plot results with ticklecharts
# chart for output voltage
set chartVout [ticklecharts::chart new]
$chartVout Xaxis -name "time, s" -minorTick {show "True"} -type "value" -splitLine {show "True"}
$chartVout Yaxis -name "Output voltage, V" -minorTick {show "True"} -type "value" -splitLine {show "True"}
$chartVout SetOptions -title {} -tooltip {trigger "axis"} -animation "False"\
        -toolbox {feature {dataZoom {yAxisIndex "none"}}} -backgroundColor "#212121"
$chartVout Add "lineSeries" -data $timeVout -showAllSymbol "nothing" -symbolSize "0"
# chart for measured current
set chartImeas [ticklecharts::chart new]
$chartImeas Xaxis -name "time, s" -minorTick {show "True"} -type "value" -splitLine {show "True"}
$chartImeas Yaxis -name "Current, I" -minorTick {show "True"} -type "value" -splitLine {show "True"}
$chartImeas SetOptions -title {} -tooltip {trigger "axis"} -animation "False"\
        -toolbox {feature {dataZoom {yAxisIndex "none"}}} -backgroundColor "#212121"
$chartImeas Add "lineSeries" -data $timeImeas -showAllSymbol "nothing" -symbolSize "0"
# create multiplot
set layout [ticklecharts::Gridlayout new]
$layout Add $chartVout -bottom "5%" -height "40%" -width "80%"
$layout Add $chartImeas -bottom "55%" -height "40%" -width "80%"

set fbasename [file rootname [file tail [info script]]]
$layout Render -outfile [file normalize [file join .. html_charts $fbasename.html]] -height 800px
