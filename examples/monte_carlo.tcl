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
    # calculate bandwidth of results
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

proc createIntervals {data numOfIntervals} {
    set intervals [::math::statistics::minmax-histogram-limits [tcl::mathfunc::min {*}$data] \
            [tcl::mathfunc::max {*}$data] $numOfIntervals]
    lappend intervalsStrings [format "<=%.2e" [lindex $intervals 0]]
    for {set i 0} {$i<[- [llength $intervals] 1]} {incr i} {
        lappend intervalsStrings [format "%.2e-%.2e" [lindex $intervals $i] [lindex $intervals [+ $i 1]]]
    }
    return [dict create intervals $intervals intervalsStr $intervalsStrings]
}

proc createDist {data intervals} {
    set dist [::math::statistics::histogram $intervals $data]
    return [lrange $dist 0 end-1]
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
set simulator [Batch new {batch1} {/usr/local/bin/}]
# attach simulator object to circuit
$circuit attachSimulator $simulator
# set number of simulations
set mcRuns 500
set numOfIntervals 15
# loop in which we run simulation with uniform distribution
for {set i 0} {$i<$mcRuns} {incr i} {
    #set elements values according to uniform distribution
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
    lappend traceListUni [calcDbMagVec [dict get $data v(out)]]
    lappend bwsUni [findBW $freqRes [lindex $traceListUni end] -10]
}
# get distribution of bandwidths with uniform parameters distribution
set uniIntervals [createIntervals $bwsUni $numOfIntervals]
set uniDist [createDist $bwsUni [dict get $uniIntervals intervals]]


## loop in which we run simulation with normal distribution
for {set i 0} {$i<$mcRuns} {incr i} {
    #set elements values according to normal distribution
    c1 setParamValue c [random-normal 1e-9 [/ 0.1e-9 3] 1]
    l1 setParamValue l [random-normal 10e-6 [/ 1e-6 3] 1]
    c2 setParamValue c [random-normal 1e-9 [/ 0.1e-9 3] 1]
    l2 setParamValue l [random-normal 10e-6 [/ 1e-6 3] 1]
    c3 setParamValue c [random-normal 250e-12 [/ 25e-12 3] 1]
    l3 setParamValue l [random-normal 40e-6 [/ 4e-6 3] 1]
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
    lappend traceListNorm [calcDbMagVec [dict get $data v(out)]]
    lappend bwsNorm [findBW $freqRes [lindex $traceListNorm end] -10]
}
# get distribution of bandwidths with normal parameters distribution
set normIntervals [createIntervals $bwsNorm $numOfIntervals]
set normDist [createDist $bwsNorm [dict get $normIntervals intervals]]

set optionalCommand "set xtics font 'Helvetica,6'"
        

# plot results with gnuplot
gnuplotutil::plotHist [dict get $uniIntervals intervalsStr] -grid -style clustered -fill solid -boxwidth 0.95 -gap 0 -xlabel "Frequency intervals, Hz" \
        -ylabel "Bandwidths per interval" -names [list {Uniform distribution}] -optcmd $optionalCommand \
        -columns $uniDist
gnuplotutil::plotHist [dict get $normIntervals intervalsStr] -grid -style clustered -fill solid -boxwidth 0.95 -gap 0 -xlabel "Frequency intervals, Hz" \
        -ylabel "Bandwidths per interval" -names [list {Normal distribution}] -optcmd $optionalCommand \
        -columns $normDist
        
# find distribution of normal distributed values in uniform intervals       
set normDistWithUniIntervals [createDist $bwsNorm [dict get $uniIntervals intervals]]

gnuplotutil::plotHist [dict get $uniIntervals intervalsStr] -grid -style clustered -fill solid -boxwidth 0.95 -gap 0 -transparent -xlabel "Frequency intervals, Hz" \
        -ylabel "Bandwidths per interval" -names [list {Uniform distribution} {Normal distribution}] \
        -optcmd $optionalCommand -columns $uniDist $normDistWithUniIntervals


