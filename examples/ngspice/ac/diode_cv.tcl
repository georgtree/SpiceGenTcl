lappend auto_path ../../../
package require SpiceGenTcl
package require ticklecharts
package require math::constants
::math::constants::constants radtodeg degtorad pi
namespace import ::SpiceGenTcl::*
importNgspice

variable pi
# create top-level circuit
set circuit [Circuit new {diode CV}]
# add elements to circuit
$circuit add [D new 1 0 c -model diomod -area 1 -lm 1e-6]
set vdc [Vdc new a c nin -dc 0]
$circuit add $vdc
$circuit add [Vac new b nin 0 -ac 1]
$circuit add [DiodeModel new diomod -is 1e-12 -n 1.2 -rs 0.01 -cj0 1e-9 -trs1 0.001 -xti 5]
$circuit add [Ac new -variation lin -n 1 -fstart 1e5 -fstop 1e5]
# add voltage sweep
set voltSweep [lseq 0 20.0 0.1]
#set simulator with default 
set simulator [BatchLiveLog new {batch1} {/usr/local/bin/}]
# attach simulator object to circuit
$circuit configure -Simulator $simulator
# loop in which we run simulation, change reverse bias and read the results
foreach volt $voltSweep {
    #set reverse voltage bias
    $vdc setParamValue dc $volt
    # run simulation
    $circuit runAndRead
    # get data object
    set data [$circuit getDataDict]
    set x $volt
    # get imaginary part of current
    set y [lindex [dict get $data i(va)] 0 1]
    set xf [format "%.3e" $x]
    set yf [format "%.2e" [expr {-$y/(2*$pi*1e5*1e-9)}]]
    lappend xydata [list $xf $yf]
}

# plot results with ticklecharts
set chart [ticklecharts::chart new]
$chart Xaxis -name "v(0,c), V" -minorTick {show "True"} -type "value"
$chart Yaxis -name "Diode capacitance, nF" -minorTick {show "True"} -type "value"
$chart SetOptions -title {} -tooltip {} -animation "False" -toolbox {feature {dataZoom {yAxisIndex "none"}}}
$chart Add "lineSeries" -data $xydata -showAllSymbol "nothing"
set fbasename [file rootname [file tail [info script]]]

$chart Render -outfile [file normalize [file join .. html_charts $fbasename.html]]

