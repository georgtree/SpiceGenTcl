# example is from Ngspice example folder (/examples/p-to-n-examples/555-timer-2.cir)

package require SpiceGenTcl
package require ticklecharts
set ::ticklecharts::theme "dark"
namespace import ::SpiceGenTcl::*
importNgspice
set currentDir [file normalize [file dirname [info script]]]

set parser [::SpiceGenTcl::Ngspice::NgspiceParser new parser1 [file join $currentDir c432.net]]
$parser readAndParse
set netlist [$parser configure -topnetlist]

set circuit [Circuit new {c432_test}]

#set simulator with default temporary directory
set simulator [BatchLiveLog new {batch1}]
$circuit add $netlist
# attach simulator object to circuit
$circuit configure -simulator $simulator
# run circuit, read log and data
$circuit runAndRead
# get data object


# set data [$circuit getDataDict]
# set time [dget $data time]
# set vout [dget $data v(osc_out)]
# set imeas [dget $data i(vmeasure)]
# foreach time [dget $data time] vout [dget $data v(osc_out)] imeas [dget $data i(vmeasure)] {
#     lappend timeVout [list $time $vout]
#     lappend timeImeas [list $time $imeas]
# }

# # plot results with ticklecharts
# # chart for output voltage
# set chartVout [ticklecharts::chart new]
# $chartVout Xaxis -name "time, s" -minorTick {show "True"} -type "value" -splitLine {show "True"}
# $chartVout Yaxis -name "Output voltage, V" -minorTick {show "True"} -type "value" -splitLine {show "True"}
# $chartVout SetOptions -title {} -tooltip {trigger "axis"} -animation "False"\
#         -toolbox {feature {dataZoom {yAxisIndex "none"}}} -backgroundColor "#212121"
# $chartVout Add "lineSeries" -data $timeVout -showAllSymbol "nothing" -symbolSize "0"
# # chart for measured current
# set chartImeas [ticklecharts::chart new]
# $chartImeas Xaxis -name "time, s" -minorTick {show "True"} -type "value" -splitLine {show "True"}
# $chartImeas Yaxis -name "Current, I" -minorTick {show "True"} -type "value" -splitLine {show "True"}
# $chartImeas SetOptions -title {} -tooltip {trigger "axis"} -animation "False"\
#         -toolbox {feature {dataZoom {yAxisIndex "none"}}} -backgroundColor "#212121"
# $chartImeas Add "lineSeries" -data $timeImeas -showAllSymbol "nothing" -symbolSize "0"
# # create multiplot
# set layout [ticklecharts::Gridlayout new]
# $layout Add $chartVout -bottom "5%" -height "40%" -width "80%"
# $layout Add $chartImeas -bottom "55%" -height "40%" -width "80%"

# set fbasename [file rootname [file tail [info script]]]
# $layout Render -outfile [file normalize [file join .. html_charts $fbasename.html]] -height 800px
