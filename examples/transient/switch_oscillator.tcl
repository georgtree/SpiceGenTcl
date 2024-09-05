# example is from Ngspice example folder (/examples/p-to-n-examples/switch-oscillators.cir)
lappend auto_path /home/georgtree/tcl/
lappend auto_path "../../"
package require SpiceGenTcl
package require ticklecharts
namespace import ::SpiceGenTcl::*
set ngspiceNameSpc [namespace children ::SpiceGenTcl::Ngspice]
foreach nameSpc $ngspiceNameSpc {
    namespace import ${nameSpc}::*
}

# create class that represents inverter subcircuit
oo::class create Inverter {
    superclass Subcircuit
    constructor {} {
        # define external pins of subcircuit
        set pins {in out vdd dgnd}
        # define input parameters of subcircuit
        set params {}
        # add elements to subcircuit definition
        my add [C new l out dgnd 0.1e-12]
        my add [C new 2 out vdd 0.1e-12]
        my add [VSwitch new p out vdd vdd in swswitch]
        my add [VSwitch new n out dgnd in dgnd switchn]
        # pass name, list of pins and list of parameters to Subcircuit constructor
        next inverter $pins $params
    }
}

# create subcircuit definition instance
set inverter [Inverter new]

# create top-level circuit
set circuit [Circuit new {switch_oscillator}]
# add elements to circuit
$circuit add [Tran new 50e-12 80e-9]
$circuit add [Options new {{method gear} {maxord 3}}]
$circuit add [RawString new ".ic v(osc_out)=0.25"]
$circuit add $inverter
$circuit add [Vdc new dd vdd2 0 3]
$circuit add [Vdc new measure vdd2 vdd 0]
$circuit add [C new vdd vdd 0 1e-18]

# add multiple inverters in the cycle
for {set i 1} {$i<16} {incr i} {
    set ip1 [+ $i 1]
    $circuit add [SubcircuitInstanceAuto new $inverter x${ip1} "n${i} n${ip1} vdd 0"]
}
$circuit add [SubcircuitInstanceAuto new $inverter x18 {osc_out n1 vdd 0}]
$circuit add [SubcircuitInstanceAuto new $inverter x19 {n16 osc_out vdd 0}]
$circuit add [VSwitchModel new swswitch -vt 1 -vh 0.1 -ron 1e3 -roff 1e12]
$circuit add [VSwitchModel new switchn -vt 1 -vh 0.1 -ron 1e3 -roff 1e12]

#set simulator with default temporary directory
set simulator [BatchLiveLog new {batch1} {/usr/local/bin/}]
# attach simulator object to circuit
$circuit attachSimulator $simulator
# run circuit, read log and data
$circuit runAndRead
# get data object
set data [$circuit getDataDict]
set time [dict get $data time]
set vout [dict get $data v(osc_out)]
set imeas [dict get $data i(vmeasure)]
foreach time [dict get $data time] vout [dict get $data v(osc_out)] imeas [dict get $data i(vmeasure)] {
    lappend timeVout [list $time $vout]
    lappend timeImeas [list $time $imeas]
}
# plot results with gnuplot
#set plot1 [list -xlabel time,s -ylabel "v(out), V" -grid -names [list "v(out)"] -columns $time $vout]
#set plot2 [list -xlabel time,s -ylabel "i(vmeasure), V" -grid -names [list "i(vmeasure)"] -columns $time $imeas]
#gnuplotutil::multiplotXNYN {2 1} -plots $plot1 $plot2

# plot results with ticklecharts
# chart for output voltage
set chartVout [ticklecharts::chart new]
$chartVout Xaxis -name "time, s" -minorTick {show "True"} -type "value"
$chartVout Yaxis -name "Output voltage, V" -minorTick {show "True"} -type "value"
$chartVout SetOptions -title {} -tooltip {} -animation "False" -toolbox {feature {dataZoom {yAxisIndex "none"}}}
$chartVout Add "lineSeries" -data $timeVout -showAllSymbol "nothing"
# chart for measured current
set chartImeas [ticklecharts::chart new]
$chartImeas Xaxis -name "time, s" -minorTick {show "True"} -type "value"
$chartImeas Yaxis -name "Current, I" -minorTick {show "True"} -type "value"
$chartImeas SetOptions -title {} -tooltip {} -animation "False" -toolbox {feature {dataZoom {yAxisIndex "none"}}}
$chartImeas Add "lineSeries" -data $timeImeas -showAllSymbol "nothing"

set layout [ticklecharts::Gridlayout new]
$layout Add $chartVout -bottom "5%" -height "40%" -width "80%"
$layout Add $chartImeas -bottom "55%" -height "40%" -width "80%"

set fbasename [file rootname [file tail [info script]]]
$layout Render -outfile [file join .. html_charts $fbasename.html] -height 800px