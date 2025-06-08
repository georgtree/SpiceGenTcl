
package require SpiceGenTcl
package require ticklecharts
set ::ticklecharts::theme "dark"
package require math::statistics
namespace import tcl::mathop::*
package require math::constants
namespace import ::math::statistics::*
::math::constants::constants radtodeg degtorad pi
namespace import ::SpiceGenTcl::*
namespace import ::measure::*
importNgspice

proc calcDbMag {re im} {
    set mag [= {sqrt($re*$re+$im*$im)}]
    set db [= {10*log($mag)}]
    return $db
}

proc calcDbMagVec {vector} {
    foreach value $vector {
        lappend db [calcDbMag [@ $value 0] [@ $value 1]]
    }
    return $db
}

proc findBW {freqs vals trigVal} {
    # calculate bandwidth of results
    set bw [dget [measure -xname freqs -data [dcreate freqs $freqs vals $vals] -trig "-vec vals -val $trigVal -rise 1"\
                          -targ "-vec vals -val $trigVal -fall 1"] xdelta]
    return $bw
}

proc createIntervals {data numOfIntervals} {
    set intervals [::math::statistics::minmax-histogram-limits [tcl::mathfunc::min {*}$data] \
            [tcl::mathfunc::max {*}$data] $numOfIntervals]
    lappend intervalsStrings [format "<=%.2e" [@ $intervals 0]]
    for {set i 0} {$i<[- [llength $intervals] 1]} {incr i} {
        lappend intervalsStrings [format "%.2e-%.2e" [@ $intervals $i] [@ $intervals [+ $i 1]]]
    }
    return [dcreate intervals $intervals intervalsStr $intervalsStrings]
}

proc createDist {data intervals} {
    set dist [::math::statistics::histogram $intervals $data]
    return [lrange $dist 0 end-1]
}

variable pi

# create top-level circuit
set circuit [Circuit new {Monte-Carlo}]
# add elements to circuit
$circuit add [Vac new 1 n001 0 -ac 1]
$circuit add [R new 1 n002 n001 -r 141]
$circuit add [R new 2 0 out -r 141]
C create c1 1 out 0 -c 1e-9
L create l1 1 out 0 -l 10e-6
C create c2 2 n002 0 -c 1e-9
L create l2 2 n002 0 -l 10e-6
C create c3 3 out n003 -c 250e-12
L create l3 3 n003 n002 -l 40e-6
foreach elem [list c1 l1 c2 l2 c3 l3] {
    $circuit add $elem
}
$circuit add [Ac new -variation oct -n 100 -fstart 250e3 -fstop 10e6]
#set simulator with default 
set simulator [Batch new {batch1}]
# attach simulator object to circuit
$circuit configure -simulator $simulator

# simulate typical values bandwidth

# run simulation
$circuit runAndRead
# get data dictionary
set data [$circuit getDataDict]
set trace [calcDbMagVec [dget $data v(out)]]
set freqs [dget $data frequency]
foreach x $freqs y $trace {
    lappend xydata [list [@ $x 0] $y]
}
puts [findBW [lmap freq $freqs {@ $freq 0}] $trace -10]
set chartTransMag [ticklecharts::chart new]
$chartTransMag Xaxis -name "Frequency, Hz" -minorTick {show "True"} -type "log" -splitLine {show "True"}
$chartTransMag Yaxis -name "Magnitude, dB" -minorTick {show "True"} -type "value" -splitLine {show "True"}
$chartTransMag SetOptions -title {} -tooltip {trigger "axis"} -animation "False"\
        -toolbox {feature {dataZoom {yAxisIndex "none"}}} -grid {left "10%" right "15%"} -backgroundColor "#212121"
$chartTransMag Add "lineSeries" -data $xydata -showAllSymbol "nothing" -symbolSize "1"
set fbasename [file rootname [file tail [info script]]]
$chartTransMag Render -outfile [file normalize [file join .. html_charts ${fbasename}_typ.html]] -width 1000px

# set number of simulations
set mcRuns 1000
set numOfIntervals 15
# set parameter's uniform distributions limits
set uniformLimits [dcreate c1 [dcreate min 0.9e-9 max 1.1e-9]\
        l1 [dcreate min 9e-6 max 11e-6]\
        c2 [dcreate min 0.9e-9 max 1.1e-9]\
        l2 [dcreate min 9e-6 max 11e-6]\
        c3 [dcreate min 225e-12 max 275e-12]\
        l3 [dcreate min 36e-6 max 44e-6]]

# loop in which we run simulation with uniform distribution
for {set i 0} {$i<$mcRuns} {incr i} {
    #set elements values according to uniform distribution
    foreach elem [list c1 l1 c2 l2 c3 l3] {
        $elem actOnParam -set [string index $elem 0] [random-uniform {*}[dict values [dget $uniformLimits $elem]] 1]
    }
    # run simulation
    $circuit runAndRead
    # get data dictionary
    set data [$circuit getDataDict]
    # get results
    if {$i==0} {
        set freqs [dget $data frequency]
        foreach freq $freqs {
            lappend freqRes [@ $freq 0]
        }
    }
    # get vout frequency curve
    lappend traceListUni [calcDbMagVec [dget $data v(out)]]
    # calculate bandwidths values
    lappend bwsUni [findBW $freqRes [@ $traceListUni end] -10]
}
unset freqRes
# get distribution of bandwidths with uniform parameters distribution
set uniIntervals [createIntervals $bwsUni $numOfIntervals]
set uniDist [createDist $bwsUni [dget $uniIntervals intervals]]


# set parameter's normal distributions limits
set normalLimits [dcreate c1 [dcreate mean 1e-9 std [/ 0.1e-9 3]]\
        l1 [dcreate mean 10e-6 std [/ 1e-6 3]]\
        c2 [dcreate mean 1e-9 std [/ 0.1e-9 3]]\
        l2 [dcreate mean 10e-6 std [/ 1e-6 3]]\
        c3 [dcreate mean 250e-12 std [/ 25e-12 3]]\
        l3 [dcreate mean 40e-6 std [/ 4e-6 3]]]

## loop in which we run simulation with normal distribution
for {set i 0} {$i<$mcRuns} {incr i} {
    #set elements values according to normal distribution
    foreach elem [list c1 l1 c2 l2 c3 l3] {
        $elem actOnParam -set [string index $elem 0] [random-normal {*}[dict values [dget $normalLimits $elem]] 1]
    }
    # run simulation
    $circuit runAndRead
    # get data dictionary
    set data [$circuit getDataDict]
    # get results
    if {$i==0} {
        set freqs [dget $data frequency]
        foreach freq $freqs {
            lappend freqRes [@ $freq 0]
        }
    }
    # get vout frequency curve
    lappend traceListNorm [calcDbMagVec [dget $data v(out)]]
    # calculate bandwidths values
    lappend bwsNorm [findBW $freqRes [@ $traceListNorm end] -10]
}
# get distribution of bandwidths with normal parameters distribution
set normIntervals [createIntervals $bwsNorm $numOfIntervals]
set normDist [createDist $bwsNorm [dget $normIntervals intervals]]


# plot results with ticklecharts
# chart for uniformly distributed parameters
set chartUni [ticklecharts::chart new]
$chartUni Xaxis -name "Frequency intervals, Hz" -data [list [dget $uniIntervals intervalsStr]]\
        -axisTick {show "True" alignWithLabel "True"} -axisLabel {interval "0" rotate "45" fontSize "8"}
$chartUni Yaxis -name "Bandwidths per interval" -minorTick {show "True"} -type "value"
$chartUni SetOptions -title {} -tooltip {trigger "axis"} -animation "False"\
        -toolbox {feature {dataZoom {yAxisIndex "none"}}} -backgroundColor "#212121"
$chartUni Add "barSeries" -data [list $uniDist]
# chart for normally distributed parameters
set chartNorm [ticklecharts::chart new]
$chartNorm Xaxis -name "Frequency intervals, Hz" -data [list [dget $normIntervals intervalsStr]]\
        -axisTick {show "True" alignWithLabel "True"} -axisLabel {interval "0" rotate "45" fontSize "8"}
$chartNorm Yaxis -name "Bandwidths per interval" -minorTick {show "True"} -type "value"
$chartNorm SetOptions -title {} -tooltip {trigger "axis"} -animation "False"\
        -toolbox {feature {dataZoom {yAxisIndex "none"}}} -backgroundColor "#212121"
$chartNorm Add "barSeries" -data [list $normDist]
# create multiplot
set layout [ticklecharts::Gridlayout new]
$layout Add $chartNorm -bottom "10%" -height "35%" -width "75%"
$layout Add $chartUni -bottom "60%" -height "35%" -width "75%"

set fbasename [file rootname [file tail [info script]]]
$layout Render -outfile [file normalize [file join .. html_charts $fbasename.html]] -height 800px -width 1200px

# find distribution of normal distributed values in uniform intervals       
set normDistWithUniIntervals [createDist $bwsNorm [dget $uniIntervals intervals]]
set chartCombined [ticklecharts::chart new]
$chartCombined Xaxis -name "Frequency intervals, Hz" -data [list [dget $uniIntervals intervalsStr]]\
        -axisTick {show "True" alignWithLabel "True"} -axisLabel {interval "0" rotate "45" fontSize "8"}
$chartCombined Yaxis -name "Bandwidths per interval" -minorTick {show "True"} -type "value"
$chartCombined SetOptions -title {} -legend {} -tooltip {trigger "axis"} -animation "False"\
        -toolbox {feature {dataZoom {yAxisIndex "none"}}} -grid {left "10%" right "15%"} -backgroundColor "#212121"
$chartCombined Add "barSeries" -data [list $uniDist] -name "Uniform"
$chartCombined Add "barSeries" -data [list $normDistWithUniIntervals] -name "Normal"
$chartCombined Render -outfile [file normalize [file join .. html_charts ${fbasename}_combined.html]]\
        -height 800px -width 1200px
