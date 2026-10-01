package require SpiceGenTcl
package require ticklecharts
package require rbc::vector
package require math::linearalgebra
namespace import ::math::linearalgebra::transpose
namespace import rbc::vector
namespace import ::SpiceGenTcl::*
importNgspice

### create top-level circuit
# docs-begin circuit-creation-diode-iv
set circuit [Circuit new {diode IV}]
# add elements to circuit
$circuit add [D new 1 anode 0 -model diomod -area 1 -lm 1e-6]
$circuit add [Vdc new a anode 0 -dc 0]
$circuit add [DiodeModel new diomod -is 1e-12 -n 1.2 -rs 0.01 -cjo 1e-9 -trs1 0.001 -xti 5 -ikf 100]
$circuit add [Dc new -src va -start 0 -stop 2 -incr 0.01]
# docs-end circuit-creation-diode-iv
# docs-begin temp-add-diode-iv
set tempSt [Temp new 25]
$circuit add $tempSt
# docs-end temp-add-diode-iv
#puts [$circuit genSPICEString]
# docs-begin temp-setup-simadd-diode-iv
# add temperature sweep
set temps {-55 25 85 125 175}

### set simulator with default
if {[catch {set simulator [Shared new -nocleanup shared1]}]} {
    set simulator [Batch new -nocleanup batch1]
}
# attach simulator object to circuit
$circuit configure -simulator $simulator
# docs-end temp-setup-simadd-diode-iv

### run circuit, change temperature and read data
# docs-begin run-loop-diode-iv
foreach temp $temps {
    $tempSt configure -value $temp
    $circuit runAndRead -vector
    set data [$circuit getDataDict]
    lappend xVecs [dict get $data v(anode)]
    set yVec [dict get $data i(va)]
    $yVec expr {-$yVec}
    lappend yVecs $yVec
}
# docs-end run-loop-diode-iv

### plot results with ticklecharts
# docs-begin plot-ticklecharts-diode-iv
set chart [ticklecharts::chart new]
set numberFormat [ticklecharts::jsfunc new {
    function (value) {
        return Number(value).toPrecision(4);
    }
}]
$chart Xaxis -name {v(anode), V} -minorTick {show True} -type value -splitLine {show True}
$chart Yaxis -name {Idiode, A} -minorTick {show True} -type value -splitLine {show True}
$chart SetOptions -title {} -tooltip [list trigger axis valueFormatter $numberFormat] -animation False -legend {}\
        -toolbox {feature {dataZoom {yAxisIndex none}}} -grid {left 5% right 15%}
foreach xVec $xVecs yVec $yVecs temp $temps {
    $chart Add lineSeries -data [transpose [list [$xVec index :] [$yVec index :]]] -showAllSymbol nothing\
            -name ${temp}°C -symbolSize 2
}
set fbasename [file rootname [file tail [info script]]]
$chart Render -outfile [file normalize [file join .. html_charts $fbasename.html]] -width 800px -height 500px\
        -divid $fbasename -jschartvar chart_$fbasename -jsvar option_$fbasename
# docs-end plot-ticklecharts-diode-iv

### plot results with rbc
# docs-begin plot-rbc-diode-iv
if {![catch {package require rbc}]} {
    set colors {#5470c6 #91cc75 #fac858 #ee6666 #73c0de #3ba272 #fc8452 #9a60b4 #ea7ccc}
    set graph [rbc::graphtoolbar .g -width 700 -height 400 -type graph -controlmode context -zoom -crosshairs\
                       -crosshairsmode closest -crosshairsclosestopts {-interpolate no} -pan -zoomwheel -scaletoggle y\
                       -activelegend]
    $graph graph grid on
    $graph graph axis configure x -title {v(anode), V}
    $graph graph axis configure y -title {Idiode, A}
    set i -1
    foreach xVec $xVecs yVec $yVecs temp $temps {
        $graph graph element create temp$temp -x $xVec -y $yVec -symbol circle -pixels 2 -label ${temp}°C\
                -color [lindex $colors [incr i]]
    }
    grid $graph -sticky nsew
    grid columnconfigure . 0 -weight 1
    grid rowconfigure . 0 -weight 1
    $graph graph svg output [file normalize [file join .. svg_charts $fbasename.svg]]
}
# docs-end plot-rbc-diode-iv
