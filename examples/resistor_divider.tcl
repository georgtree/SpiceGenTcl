lappend auto_path /home/georgtree/tcl/
lappend auto_path "../"
package require SpiceGenTcl
package require ticklecharts
namespace import ::SpiceGenTcl::*
importNgspice

# create top-level circuit
set circuit [Circuit new {voltage divider netlist}]
# add elements to circuit
$circuit add [Vdc new 1 in 0 1]
$circuit add [R new 1 in out 1e3]
$circuit add [R new 2 out 0 2e3]
$circuit add [Dc new v1 0 5 0.1]
#set simulator with default 
set simulator [Batch new {batch1} {/usr/local/bin/}]
# attach simulator object to circuit
$circuit attachSimulator $simulator
# run circuit, read log and data
$circuit runAndRead
# get data object
set data [$circuit getDataDict]
set axis [dict get $data v(in)]
set trace [dict get $data v(out)]

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

$chart Render -outfile [file join html_charts $fbasename.html]
