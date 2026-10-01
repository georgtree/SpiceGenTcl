package require SpiceGenTcl
package require ticklecharts
package require rbc::vector
package require math::constants
package require math::linearalgebra
::math::constants::constants radtodeg degtorad pi
namespace import ::math::linearalgebra::transpose
namespace import ::SpiceGenTcl::*
namespace import rbc::vector
importNgspice
variable pi

### create top-level circuit
# docs-begin circuit-creation-filter
set circuit [Circuit new {filter s-parameters}]
# add elements to circuit
$circuit add [Vport new gen 1 0 -dc 0 -ac 1 -portnum 1]
# lowpass Chebyshev
$circuit add [L new 1 1 2 -l 0.058u] [C new 2 2 0 -c 40.84p] [L new 3 2 3 -l 0.128u] [C new 4 3 0 -c 47.91p]\
        [L new 5 3 4 -l 0.128u] [C new 6 4 0 -c 40.48p] [L new 7 4 5 -l 0.0653u]
# lowpass m-derived
$circuit add [L new a 5 6 -l 0.044u] [L new b 6 a -l 0.078u] [C new b a 0 -c 17.61p]
# highpass m-derived
$circuit add [C new a 6 7 -c 60.6p] [L new c 6 b -l 0.151u] [C new c b 0 -c 34.12p]
# highpass Chebyshev
$circuit add [C new 1 7 8 -c 45.64p] [L new 2 8 0 -l 0.0653u] [C new 3 8 9 -c 20.8p] [L new 4 9 0 -l 0.055u]\
        [C new 5 9 10 -c 20.8p] [L new 6 10 0 -l 0.0653u] [C new 7 10 out -c 45.64p]
$circuit add [Vport new l out 0 -dc 0 -ac 0 -portnum 2]
# docs-begin sp-analysis-setup-filter
$circuit add [Sp new -variation lin -n 500 -fstart 10meg -fstop 200meg]
# docs-end sp-analysis-setup-filter
# docs-end circuit-creation-filter

### set simulator with default
# docs-begin simulation-filter
if {[catch {set simulator [Shared new shared1]}]} {
    set simulator [Batch new batch1]
}
# attach simulator object to circuit
$circuit configure -simulator $simulator
$circuit runAndRead -vector
# get data object
set data [$circuit getDataDict]
# docs-end simulation-filter
# get frequency
# docs-begin calculations-filter
vector create freq
freq expr {real([dict get $data frequency])}
# and calculate magnitude of S11 and S21
vector create s11Mag s21Mag
s11Mag expr {abs([dict get $data s_1_1])}
s21Mag expr {abs([dict get $data s_2_1])}
# docs-end calculations-filter

### plot results with ticklecharts
# docs-begin plot-ticklecharts-filter
set chart [ticklecharts::chart new]
set numberFormat [ticklecharts::jsfunc new {
    function (value) {
        return Number(value).toPrecision(4);
    }
}]
$chart Xaxis -name {Frequency, Hz} -minorTick {show True} -type value -splitLine {show True}
$chart Yaxis -name mag(S) -minorTick {show True} -type value -splitLine {show True}
$chart SetOptions -title {} -tooltip [list trigger axis valueFormatter $numberFormat] -legend {} -animation False\
        -toolbox {feature {dataZoom {yAxisIndex none}}}
$chart Add lineSeries -data [transpose [list [freq index :] [s11Mag index :]]] -showAllSymbol nothing -name S11\
        -symbolSize 0
$chart Add lineSeries -data [transpose [list [freq index :] [s21Mag index :]]] -showAllSymbol nothing -name S21\
        -symbolSize 0
set fbasename [file rootname [file tail [info script]]]
$chart Render -outfile [file normalize [file join .. html_charts $fbasename.html]] -width 800px -height 500px\
        -divid $fbasename -jschartvar chart_$fbasename -jsvar option_$fbasename
# docs-end plot-ticklecharts-filter

### plot results with rbc
# docs-begin plot-rbc-filter
if {![catch {package require rbc}]} {
    set colors {#5470c6 #91cc75}
    set graph [rbc::graphtoolbar .g -width 700 -height 400 -type graph -controlmode context -zoom -crosshairs\
                       -crosshairsmode closest -crosshairsclosestopts {-interpolate no} -pan -zoomwheel -scaletoggle y\
                       -activelegend]
    $graph graph grid on
    $graph graph axis configure x -title {Frequency, Hz}
    $graph graph axis configure y -title mag(S)
    $graph graph element create s11 -x freq -y s11Mag -symbol {} -label S11 -color [lindex $colors 0] -linewidth 2
    $graph graph element create s21 -x freq -y s21Mag -symbol {} -label S21 -color [lindex $colors 1] -linewidth 2
    grid $graph -sticky nsew
    grid columnconfigure . 0 -weight 1
    grid rowconfigure . 0 -weight 1
    $graph graph svg output [file normalize [file join .. svg_charts $fbasename.svg]]
}
# docs-end plot-rbc-filter
