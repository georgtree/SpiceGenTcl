lappend auto_path /home/georgtree/tcl_tools/
lappend auto_path "../"
source ./helperFuncs.tcl
package require SpiceGenTcl
package require gnuplotutil
package require xyplot
package require math::statistics
namespace import tcl::mathop::*
package require math::constants
namespace import ::math::statistics::*
::math::constants::constants radtodeg degtorad pi
namespace import ::SpiceGenTcl::*
importNgspice

proc calcDbMag {re im} {
    set mag [expr {sqrt($re*$re+$im*$im)}]
    set db [expr {10*log($mag)}]
    return $db
}

proc calcDbMagVec {vector} {
    foreach value $vector {
        lappend db [calcDbMag [lindex $value 0] [lindex $value 1]]
    }
    return $db
}

proc findBW {freqs vals trigVal} {
    set freqsLen [llength $freqs]
    for {set i 0} {$i<$freqsLen} {incr i} {
        set iVal [lindex $vals $i]
        set ip1Val [lindex $vals [+ $i 1]]
        if {($iVal<=$trigVal) && ($ip1Val>=$trigVal)} {
            set freqStart [lindex $freqs $i]
        } elseif {($iVal>=$trigVal) && ($ip1Val<=$trigVal)} {
            set freqEnd [lindex $freqs $i]
        }
    }
    set bw [expr {$freqEnd-$freqStart}]
    return $bw
}

variable pi
# create top-level circuit
set circuit [Circuit new {Monte-Carlo}]
# add elements to circuit
$circuit add [Vac new 1 n001 0 1]
$circuit add [R new 1 n002 n001 141]
$circuit add [R new 2 0 out 141]
C create c1 1 out 0 1e-9
L create l1 1 out 0 10e-6
C create c2 2 n002 0 1e-9
L create l2 2 n002 0 10e-6
C create c3 3 out n003 250e-12
L create l3 3 n003 n002 40e-6
foreach elem [list c1 l1 c2 l2 c3 l3] {
    $circuit add $elem
}
$circuit add [Ac new oct 100 250e3 10e6]
#set simulator with default 
set simulator [BatchLiveLog new {batch1} {/usr/local/bin/}]
# attach simulator object to circuit
$circuit attachSimulator $simulator
# set number of simulations
set mcRuns 10
# loop in which we run simulation
for {set i 0} {$i<$mcRuns} {incr i} {
    #set elements values
    c1 setParamValue c [random-uniform 0.9e-9 1.1e-9 1]
    l1 setParamValue l [random-uniform 9e-6 11e-6 1]
    c2 setParamValue c [random-uniform 0.9e-9 1.1e-9 1]
    l2 setParamValue l [random-uniform 9e-6 11e-6 1]
    c3 setParamValue c [random-uniform 225e-12 275e-12 1]
    l3 setParamValue l [random-uniform 36e-6 44e-6 1]
    # run simulation
    $circuit runAndRead
    # get data dictionary
    set data [$circuit getDataDict]
    # get results
    if {$i==0} {
        set freqs [dict get $data frequency]
        foreach freq $freqs {
            lappend freqRes [lindex $freq 0]
        }
    }
    lappend traceList [calcDbMagVec [dict get $data v(out)]]
    lappend bws [findBW $freqRes [lindex $traceList end] -10]
}
# plot results with gnuplot
puts $bws
gnuplotutil::plotXYN $freqRes -xlog -xlabel "x label" -ylabel "y label" -grid -names [list 1 2 3 4 5 6 7 8 9 10] -columns {*}$traceList



