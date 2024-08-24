lappend auto_path /home/georgtree/tcl_tools/
lappend auto_path "../"
package require SpiceGenTcl
package require gnuplotutil
package require xyplot
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

# plot results with plotchart
wm geometry . 600x400
set xyp [xyplot .xyp -xformat "%5.1f" -yformat "%5.1f" -title "Voltage divider simulation result" -xtext "v(in), V" -ytext "voltage, V"]
pack $xyp -fill both -expand true
foreach x $axis y $trace {
    lappend xydata $x $y
}
set s1 [$xyp add_data sf1 $xydata -legend "v(out)" -color red]
