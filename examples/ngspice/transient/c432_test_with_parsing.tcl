# example is from Ngspice example folder (/examples/p-to-n-examples/555-timer-2.cir)
package require rbc::vector
package require SpiceGenTcl
package require ticklecharts
package require math::linearalgebra
namespace import ::math::linearalgebra::transpose
namespace import rbc::vector
namespace import ::tcl::mathop::*
namespace import ::SpiceGenTcl::*
importNgspice
set currentDir [file normalize [file dirname [info script]]]

### create and run parser
# docs-begin parser-creation-c432-parse
set parser [::SpiceGenTcl::Ngspice::NgspiceParser new parser1 [file join $currentDir c432.net]]
set netlist [$parser readAndParse]
# docs-end parser-creation-c432-parse
# docs-begin circuit-run-c432-parse
set circuit [Circuit new {c432_test}]

### set simulator with default
if {[catch {set simulator [Shared new shared1]}]} {
    set simulator [Batch new batch1]
}
$circuit add $netlist
$circuit configure -simulator $simulator
$circuit runAndRead -vector
set data [$circuit getDataDict]
set time [dict get $data time]
set vg429 [dict get $data v(g429)]
set vg430 [dict get $data v(g430)]
set timeVg429 [transpose [list [$time index :] [$vg429 index :]]]
set timeVg430  [transpose [list [$time index :] [$vg430 index :]]]
# docs-end circuit-run-c432-parse
puts [$parser configure -definitions]

### plot results with ticklecharts
# docs-begin plot-ticklecharts-c432-parse
set numberFormat [ticklecharts::jsfunc new {
    function (value) {
        return Number(value).toPrecision(3);
    }
}]
set chartVout [ticklecharts::chart new]
$chartVout Xaxis -name {time, s} -minorTick {show True} -type value -splitLine {show True}
$chartVout Yaxis -name {g429 voltage, V} -minorTick {show True} -type value -splitLine {show True}
$chartVout SetOptions -title {} -tooltip [list trigger axis valueFormatter $numberFormat] -animation False\
        -toolbox {feature {dataZoom {yAxisIndex none}}}
$chartVout Add lineSeries -data $timeVg429 -showAllSymbol nothing -symbolSize 0
set chartImeas [ticklecharts::chart new]
$chartImeas Xaxis -name {time, s} -minorTick {show True} -type value -splitLine {show True}
$chartImeas Yaxis -name {g430 voltage, V} -minorTick {show True} -type value -splitLine {show True}
$chartImeas SetOptions -title {} -tooltip [list trigger axis valueFormatter $numberFormat] -animation False\
        -toolbox {feature {dataZoom {yAxisIndex none}}}
$chartImeas Add lineSeries -data $timeVg430 -showAllSymbol nothing -symbolSize 0
# create multiplot
set layout [ticklecharts::Gridlayout new]
$layout Add $chartVout -bottom 5% -height 40% -width 80%
$layout Add $chartImeas -bottom 55% -height 40% -width 80%

set fbasename [file rootname [file tail [info script]]]
$layout Render -outfile [file normalize [file join .. html_charts $fbasename.html]] -width 800px -height 500px\
        -divid $fbasename -jschartvar chart_$fbasename -jsvar option_$fbasename
# docs-end plot-ticklecharts-c432-parse

### plot results with rbc
# docs-begin plot-rbc-c432-parse
if {![catch {package require rbc}]} {

    set currentDir [file dirname [file normalize [info script]]]
    source [file join $currentDir .. .. common.tcl]
    set graphVg429 [rbc::graphtoolbar .gVg429 -width 700 -height 400 -type graph -controlmode context -zoom -crosshairs\
                       -crosshairsmode closest  -pan -zoomwheel]
    set graphVg430 [rbc::graphtoolbar .gVg430 -width 700 -height 400 -type graph -controlmode context -zoom -crosshairs\
                       -crosshairsmode closest  -pan -zoomwheel]
    $graphVg429 graph grid on
    $graphVg429 graph axis configure x -title {time, s}
    $graphVg429 graph axis configure y -title {v(g429), V}
    $graphVg429 graph element create vg429 -x $time -y $vg429 -symbol {} -label v(g429) -color [lindex $colors 0]\
            -linewidth 2
    $graphVg430 graph grid on
    $graphVg430 graph axis configure x -title {time, s}
    $graphVg430 graph axis configure y -title {v(g430), V}
    $graphVg430 graph element create vg430 -x $time -y $vg430 -symbol {} -label v(g430) -color [lindex $colors 1]\
            -linewidth 2

    # add bindings for axes synchronization
    dict set ::axesStates [$graphVg429 subwidget graph] x [$graphVg429 graph axis limits x]
    dict set ::axesStates [$graphVg430 subwidget graph] x [$graphVg430 graph axis limits x]
    bind [$graphVg429 subwidget graph] <<RbcAxisLimitsChanged>> [list syncAxes %W %d x [$graphVg430 subwidget graph] x]
    bind [$graphVg430 subwidget graph] <<RbcAxisLimitsChanged>> [list syncAxes %W %d x [$graphVg429 subwidget graph] x]

    grid $graphVg429 -row 0 -sticky nsew
    grid $graphVg430 -row 1 -sticky nsew
    grid columnconfigure . 0 -weight 1
    grid rowconfigure . 0 -weight 1
    grid rowconfigure . 1 -weight 1
    $graphVg429 graph svg output\
            [file normalize [file join .. .. .. docs assets img svg_charts ngspice ${fbasename}_vg429.svg]]
    $graphVg430 graph svg output\
            [file normalize [file join .. .. .. docs assets img svg_charts ngspice ${fbasename}_vg430.svg]]
}
# docs-end plot-rbc-c432-parse
