lappend auto_path /home/georgtree/tcl_tools/
lappend auto_path "../"
source ./helperFuncs.tcl
package require SpiceGenTcl
package require gnuplotutil
package require math::constants
::math::constants::constants radtodeg degtorad pi
namespace import ::SpiceGenTcl::*
importNgspice

variable pi
# create top-level circuit
set circuit [Circuit new {diode CV}]
# add elements to circuit
$circuit add [D new 1 0 c diomod -area 1 -lm 1e-6]
set vdc [Vdc new a c nin 0]
$circuit add $vdc
$circuit add [Vac new b nin 0 1]
$circuit add [DiodeModel new diomod -is 1e-12 -n 1.2 -rs 0.01 -cj0 1e-9 -trs1 0.001 -xti 5]
$circuit add [Ac new lin 1 1e5 1e5]
# add voltage sweep
set voltSweep [linspace 0 20.1 0.1]
#set simulator with default 
set simulator [BatchLiveLog new {batch1} {/usr/local/bin/}]
# attach simulator object to circuit
$circuit attachSimulator $simulator
# loop in which we run simulation, change reverse biad and read the results
foreach volt $voltSweep {
    #set reverse voltage bias
    $vdc setParamValue dc $volt
    # run simulation
    $circuit runAndRead
    # get data object
    set data [$circuit getDataDict]
    lappend axisList [dict get $data v(c)]
    # get imaginary part of current
    lappend traceList [lindex [dict get $data i(va)] 0 1]
}
# calculate capacitance
foreach x $voltSweep y $traceList {
    lappend xdata $x
    lappend ydata [expr {-$y/(2*$pi*1e5)}] 
}
# plot results with gnuplot
gnuplotutil::plotXYN $xdata -xlabel "v(0,c), V"  -ylabel "C, C" -grid -names C -columns $ydata



