
package require SpiceGenTcl
package require ticklecharts
namespace import ::SpiceGenTcl::*
importXyce

# create top-level circuit
set circuit [Circuit new {voltage divider netlist}]
# add elements to circuit
$circuit add [Vdc new 1 in 0 -dc 1]
$circuit add [R new 1 in out -r 1e3]
$circuit add [R new 2 out 0 -r 2e3]
$circuit add [Dc new -src v1 -start 0 -stop 5 -incr 0.1]
#set simulator with default 
set simulator [Batch new {batch1}]
# attach simulator object to circuit
$circuit configure -Simulator $simulator
# run circuit, read log and data
$circuit runAndRead
# get data object
set data [$circuit getDataDict]
set axis [dget $data in]
set trace [dget $data out]

# plot results with ticklecharts
foreach x $axis y $trace {
    set x [format "%.3f" $x]
    set y [format "%.3f" $y]
    lappend xydata [list $x $y]
}

set chart [ticklecharts::chart new]
$chart Xaxis -name "v(in), V" -minorTick {show "True"} -min 0 -max 5 -type "value"
$chart Yaxis -name "v(out), V" -minorTick {show "True"} -min 0 -max 3.5 -type "value"
$chart SetOptions -title {} -tooltip {} -animation "False"
$chart Add "lineSeries" -data $xydata -showAllSymbol "nothing"
set fbasename [file rootname [file tail [info script]]]

$chart Render -outfile [file normalize [file join .. html_charts $fbasename.html]]
