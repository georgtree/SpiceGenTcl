# example is from Ngspice example folder (/examples/p-to-n-examples/555-timer-2.cir)

package require SpiceGenTcl
package require ticklecharts
namespace import ::SpiceGenTcl::*
importNgspice
set currentDir [file normalize [file dirname [info script]]]

set parser [::SpiceGenTcl::Ngspice::NgspiceParser new parser1 [file join $currentDir c432.net]]
set netlist [$parser readAndParse]
set circuit [Circuit new {c432_test}]
set simulator [BatchLiveLog new {batch1}]
$circuit add $netlist
$circuit configure -simulator $simulator
$circuit runAndRead
set data [$circuit getDataDict]
set time [dget $data time]
foreach time [dget $data time] vg429 [dget $data v(g429)] vg430 [dget $data v(g430)] {
    lappend timeVg429 [list $time $vg429]
    lappend timeVg430 [list $time $vg430]
}
puts [$parser configure -definitions]
# plot results with ticklecharts
set chartVout [ticklecharts::chart new]
$chartVout Xaxis -name "time, s" -minorTick {show "True"} -type "value" -splitLine {show "True"}
$chartVout Yaxis -name "g429 voltage, V" -minorTick {show "True"} -type "value" -splitLine {show "True"}
$chartVout SetOptions -title {} -tooltip {trigger "axis"} -animation "False"\
        -toolbox {feature {dataZoom {yAxisIndex "none"}}}
$chartVout Add "lineSeries" -data $timeVg429 -showAllSymbol "nothing" -symbolSize "0"
set chartImeas [ticklecharts::chart new]
$chartImeas Xaxis -name "time, s" -minorTick {show "True"} -type "value" -splitLine {show "True"}
$chartImeas Yaxis -name "g430 voltage, V" -minorTick {show "True"} -type "value" -splitLine {show "True"}
$chartImeas SetOptions -title {} -tooltip {trigger "axis"} -animation "False"\
        -toolbox {feature {dataZoom {yAxisIndex "none"}}}
$chartImeas Add "lineSeries" -data $timeVg430 -showAllSymbol "nothing" -symbolSize "0"
# create multiplot
set layout [ticklecharts::Gridlayout new]
$layout Add $chartVout -bottom "5%" -height "40%" -width "80%"
$layout Add $chartImeas -bottom "55%" -height "40%" -width "80%"

set fbasename [file rootname [file tail [info script]]]
$layout Render -outfile [file normalize [file join .. html_charts $fbasename.html]] -height 800px
