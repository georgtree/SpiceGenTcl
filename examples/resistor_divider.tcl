lappend auto_path /home/georgtree/tcl_tools/
lappend auto_path /home/georgtree/tcl/
lappend auto_path "../"
package require SpiceGenTcl
package require gnuplotutil
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

# plot results with gnuplot
#gnuplotutil::plotXYN $axis -xlabel "v(in), V" -ylabel "voltage, V" -grid -names [list "Output voltage"] -columns $trace

set chart [ticklecharts::chart new]
$chart Xaxis -data [list $axis]
$chart Yaxis
$chart SetOptions -title {text "Graph on Cartesian"} -tooltip {}
$chart Add "lineSeries" -data [list $trace]
$chart Render