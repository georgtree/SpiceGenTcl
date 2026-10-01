package require SpiceGenTcl
package require ticklecharts
package require rbc::vector
package require math::statistics
package require math::constants

namespace import tcl::mathop::*
namespace import ::math::statistics::*
::math::constants::constants radtodeg degtorad pi
namespace import ::SpiceGenTcl::*
namespace import ::tclmeasure::*
namespace import rbc::vector
importNgspice
variable pi

# set seed for random number generator
expr {srand(100)}

# docs-begin proc-calcdbmag-monte-carlo
proc calcDbMag {vector source} {
    $vector expr {10*log(abs($source))}
}
# docs-end proc-calcdbmag-monte-carlo

# docs-begin proc-findbw-monte-carlo
proc findBW {freqs vals trigVal} {
    # calculate bandwidth of results
    set bw [dict get [measure -xname $freqs -trig "-vec $vals -val $trigVal -rise 1"\
                              -targ "-vec $vals -val $trigVal -fall 1"] xdelta]
    return $bw
}
# docs-end proc-findbw-monte-carlo

# docs-begin proc-createintervals-monte-carlo
proc createIntervals {data numOfIntervals} {
    set intervals [::math::statistics::minmax-histogram-limits [tcl::mathfunc::min {*}$data]\
                           [tcl::mathfunc::max {*}$data] $numOfIntervals]
    lappend intervalsStrings [format <=%.2e [lindex $intervals 0]]
    for {set i 0} {$i<[- [llength $intervals] 1]} {incr i} {
        lappend intervalsStrings [format %.2e-%.2e [lindex $intervals $i] [lindex $intervals [+ $i 1]]]
    }
    return [dict create intervals $intervals intervalsStr $intervalsStrings]
}
# docs-end proc-createintervals-monte-carlo

# docs-begin proc-createdist-monte-carlo
proc createDist {data intervals} {
    set dist [::math::statistics::histogram $intervals $data]
    return [lrange $dist 0 end-1]
}
# docs-end proc-createdist-monte-carlo

### create top-level circuit
# docs-begin circuit-creation-and-config-monte-carlo
set circuit [Circuit new {Monte-Carlo}]
# add elements to circuit
$circuit add [Vac new 1 n001 0 -ac 1]
$circuit add [R new 1 n002 n001 -r 141]
$circuit add [R new 2 0 out -r 141]
# docs-begin create-usage-monte-carlo
C create c1 1 out 0 -c 1e-9
# docs-end create-usage-monte-carlo
L create l1 1 out 0 -l 10e-6
C create c2 2 n002 0 -c 1e-9
L create l2 2 n002 0 -l 10e-6
C create c3 3 out n003 -c 250e-12
L create l3 3 n003 n002 -l 40e-6
foreach elem {c1 l1 c2 l2 c3 l3} {
    $circuit add $elem
}
$circuit add [Ac new -variation oct -n 100 -fstart 250e3 -fstop 10e6]

### set simulator with default
if {[catch {set simulator [Shared new batch1]}]} {
    set simulator [Batch new batch1]
}
# attach simulator object to circuit
$circuit configure -simulator $simulator
# docs-end circuit-creation-and-config-monte-carlo

### simulate typical values bandwidth
# docs-begin typical-run-and-plot-monte-carlo
# run simulation
$circuit runAndRead -vector
# get data dictionary
set data [$circuit getDataDict]
puts $data
vector create traceVecInit frequencyInit
calcDbMag traceVecInit [dict get $data v(out)]
frequencyInit expr {real([dict get $data frequency])}

foreach x [frequencyInit index :] y [traceVecInit index :] {
    lappend xydata [list $x $y]
}

set chartTransMag [ticklecharts::chart new]
set numberFormat [ticklecharts::jsfunc new {
    function (value) {
        return Number(value).toPrecision(2);
    }
}]
$chartTransMag Xaxis -name {Frequency, Hz} -minorTick {show True} -type log -splitLine {show True}
$chartTransMag Yaxis -name {Magnitude, dB} -minorTick {show True} -type value -splitLine {show True}
$chartTransMag SetOptions -title {} -tooltip [list trigger axis valueFormatter $numberFormat] -animation False\
        -toolbox {feature {dataZoom {yAxisIndex none}}} -grid {left 10% right 15%}
$chartTransMag Add lineSeries -data $xydata -showAllSymbol nothing -symbolSize 1 -name Magnitude
set fbasename [file rootname [file tail [info script]]]
$chartTransMag Render -outfile [file normalize [file join .. html_charts ${fbasename}_typ.html]] -width 800px\
        -height 500px -divid ${fbasename}_typ -jschartvar chart_${fbasename}_typ -jsvar option_${fbasename}_typ
# docs-end typical-run-and-plot-monte-carlo
#puts [findBW frequencyInit traceVecInit -10]

### start monte-carlo simulation setup with uniform distribution
vector create traceVec frequency
# set number of simulations
# docs-begin set-uniform-number-sims-monte-carlo
set mcRuns 1000
set numOfIntervals 15
# docs-end set-uniform-number-sims-monte-carlo

# set parameter's uniform distributions limits
# docs-begin set-uniform-params-dist-monte-carlo
set uniformLimits [dict create c1 [dict create min 0.9e-9 max 1.1e-9] l1 [dict create min 9e-6 max 11e-6]\
                           c2 [dict create min 0.9e-9 max 1.1e-9] l2 [dict create min 9e-6 max 11e-6]\
                           c3 [dict create min 225e-12 max 275e-12] l3 [dict create min 36e-6 max 44e-6]]
# docs-end set-uniform-params-dist-monte-carlo

### loop in which we run simulation with uniform distribution
# docs-begin uniform-loop-monte-carlo
for {set i 0} {$i<$mcRuns} {incr i} {
    #set elements values according to uniform distribution
    foreach elem [list c1 l1 c2 l2 c3 l3] {
        $elem actOnParam -set [string index $elem 0] [random-uniform {*}[dict values [dict get $uniformLimits $elem]] 1]
    }
    # run simulation
    $circuit runAndRead -vector
    # get data dictionary
    set data [$circuit getDataDict]
    # get results
    if {$i==0} {
        frequency expr {real([dict get $data frequency])}
    }
    # get vout frequency curve
    calcDbMag traceVec [dict get $data v(out)]
    # calculate bandwidths values
    lappend bwsUni [findBW frequency traceVec -10]
}
# docs-end uniform-loop-monte-carlo

# get distribution of bandwidths with uniform parameters distribution
# docs-begin create-uni-intervals-monte-carlo
set uniIntervals [createIntervals $bwsUni $numOfIntervals]
# docs-end create-uni-intervals-monte-carlo
# docs-begin create-uni-dist-monte-carlo
set uniDist [createDist $bwsUni [dict get $uniIntervals intervals]]
# docs-end create-uni-dist-monte-carlo

### start monte-carlo simulation setup with normal distribution
# set parameter's normal distributions limits
# docs-begin norm-dist-generation-monte-carlo
set normalLimits [dict create c1 [dict create mean 1e-9 std [/ 0.1e-9 3]] l1 [dict create mean 10e-6 std [/ 1e-6 3]]\
                          c2 [dict create mean 1e-9 std [/ 0.1e-9 3]] l2 [dict create mean 10e-6 std [/ 1e-6 3]]\
                          c3 [dict create mean 250e-12 std [/ 25e-12 3]] l3 [dict create mean 40e-6 std [/ 4e-6 3]]]

#### loop in which we run simulation with normal distribution
set freqRes [list]
for {set i 0} {$i<$mcRuns} {incr i} {
    #set elements values according to normal distribution
    foreach elem [list c1 l1 c2 l2 c3 l3] {
        $elem actOnParam -set [string index $elem 0] [random-normal {*}[dict values [dict get $normalLimits $elem]] 1]
    }
    # run simulation
    $circuit runAndRead -vector
    # get data dictionary
    set data [$circuit getDataDict]
    # get results
    if {$i==0} {
        frequency expr {real([dict get $data frequency])}
    }
    # get vout frequency curve
    calcDbMag traceVec [dict get $data v(out)]
    # calculate bandwidths values
    lappend bwsNorm [findBW frequency traceVec -10]
}
# get distribution of bandwidths with normal parameters distribution
set normIntervals [createIntervals $bwsNorm $numOfIntervals]
set normDist [createDist $bwsNorm [dict get $normIntervals intervals]]
# docs-end norm-dist-generation-monte-carlo

### plot results with ticklecharts
# docs-begin plot-individual-dist-ticklecharts-monte-carlo
# chart for uniformly distributed parameters
set chartUni [ticklecharts::chart new]
$chartUni Xaxis -name {Frequency intervals, Hz} -data [list [dict get $uniIntervals intervalsStr]]\
        -axisTick {show True alignWithLabel True} -axisLabel {interval 0 rotate 45 fontSize 8}
$chartUni Yaxis -name {Bandwidths per interval} -minorTick {show True} -type value
$chartUni SetOptions -title {} -tooltip {trigger axis} -animation False -toolbox {feature {dataZoom {yAxisIndex none}}}
$chartUni Add barSeries -data [list $uniDist]
# chart for normally distributed parameters
set chartNorm [ticklecharts::chart new]
$chartNorm Xaxis -name {Frequency intervals, Hz} -data [list [dict get $normIntervals intervalsStr]]\
        -axisTick {show True alignWithLabel True} -axisLabel {interval 0 rotate 45 fontSize 8}
$chartNorm Yaxis -name {Bandwidths per interval} -minorTick {show True} -type value
$chartNorm SetOptions -title {} -tooltip {trigger axis} -animation False -toolbox {feature {dataZoom {yAxisIndex none}}}
$chartNorm Add barSeries -data [list $normDist]
# create multiplot
set layout [ticklecharts::Gridlayout new]
$layout Add $chartNorm -bottom 10% -height 35% -width 75%
$layout Add $chartUni -bottom 60% -height 35% -width 75%

set fbasename [file rootname [file tail [info script]]]
$layout Render -outfile [file normalize [file join .. html_charts $fbasename.html]] -width 800px -height 500px\
        -divid $fbasename -jschartvar chart_$fbasename -jsvar option_$fbasename
# docs-end plot-individual-dist-ticklecharts-monte-carlo

# docs-begin plot-combined-dists-ticklecharts-monte-carlo
# find distribution of normal distributed values in uniform intervals
set normDistWithUniIntervals [createDist $bwsNorm [dict get $uniIntervals intervals]]
set chartCombined [ticklecharts::chart new]
$chartCombined Xaxis -name {Frequency intervals, Hz} -data [list [dict get $uniIntervals intervalsStr]]\
        -axisTick {show True alignWithLabel True} -axisLabel {interval 0 rotate 45 fontSize 8}
$chartCombined Yaxis -name {Bandwidths per interval} -minorTick {show True} -type value
$chartCombined SetOptions -title {} -legend {} -tooltip {trigger axis} -animation False\
        -toolbox {feature {dataZoom {yAxisIndex none}}} -grid {left 10% right 15%}
$chartCombined Add barSeries -data [list $uniDist] -name Uniform
$chartCombined Add barSeries -data [list $normDistWithUniIntervals] -name Normal
$chartCombined Render -outfile [file normalize [file join .. html_charts ${fbasename}_combined.html]] -width 800px\
        -height 500px -divid ${fbasename}_combined -jschartvar chart_${fbasename}_combined\
        -jsvar option${fbasename}_combined
# docs-end plot-combined-dists-ticklecharts-monte-carlo

### plot results with rbc
# docs-begin plot-rbc-monte-carlo
if {![catch {package require rbc}]} {
    set colors {#5470c6 #91cc75 #fac858 #ee6666 #73c0de #3ba272 #fc8452 #9a60b4 #ea7ccc}
    set graph [rbc::graphtoolbar .g -width 700 -height 400 -type graph -controlmode context -zoom\
                                 -crosshairs -crosshairsmode closest -pan -zoomwheel]
    set barchart [rbc::graphtoolbar .b -width 700 -height 400 -type barchart -controlmode context -zoom\
                                 -crosshairs -crosshairsmode closest -pan -zoomwheel -activelegend]
    # plot typical magnitude
    $graph graph grid on
    $graph graph axis configure x -title {Frequency, Hz}
    $graph graph axis configure x -logscale yes
    $graph graph axis configure y -title {Magnitude, dB}
    $graph graph element create trajectory -x frequencyInit -y traceVecInit -symbol {} -label Magnitude\
            -color [lindex $colors 0] -linewidth 2
    # plot distributions
    vector create index uniDistVec normDistVec
    index seq 0 {[llength $normDistWithUniIntervals]-1}
    uniDistVec set $uniDist
    normDistVec set $normDistWithUniIntervals
    $barchart graph configure -barmode aligned
    proc formatTick {uniIntervals graph label} {
        return [lindex [dict get $uniIntervals intervalsStr] $label]
    }
    $barchart graph axis configure x -title {Frequency intervals, Hz} -command [list formatTick $uniIntervals]\
            -rotate 90  -subdivisions 0
    $barchart graph axis configure y -title {Bandwidths per interval}
    $barchart graph element create uniform -x index -y uniDistVec -label Uniform -foreground [lindex $colors 1]
    $barchart graph element create finalvout -x index -y normDistVec -label Normal -foreground [lindex $colors 2]

    grid $graph -row 0 -sticky nsew
    grid $barchart -row 1 -sticky nsew
    grid columnconfigure . 0 -weight 1
    grid rowconfigure . 0 -weight 1
    grid rowconfigure . 1 -weight 1
    $graph graph svg output [file normalize\
                                     [file join .. .. .. docs assets img svg_charts ngspice ${fbasename}_typ.svg]]
    $barchart graph svg output\
            [file normalize [file join .. .. .. docs assets img svg_charts ngspice ${fbasename}_combined.svg]]
}
# docs-end plot-rbc-monte-carlo
