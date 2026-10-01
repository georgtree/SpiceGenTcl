package require SpiceGenTcl
package require ticklecharts
package require rbc::vector
package require math::constants
package require math::linearalgebra
::math::constants::constants radtodeg degtorad pi
namespace import ::math::linearalgebra::transpose
namespace import rbc::vector
namespace import ::SpiceGenTcl::*
importXyce
variable pi

### create top-level circuit
set circuit [Circuit new {diode CV}]
# add elements to circuit
$circuit add [D new 1 0 c -model diomod -area 1]
set vdc [Vdc new a c nin -dc 0]
$circuit add $vdc
$circuit add [Vac new b nin 0 -ac 1]
$circuit add [DiodeModel new diomod -is 1e-12 -n 1.2 -rs 0.01 -cj0 1e-9 -trs1 0.001 -xti 5]
$circuit add [Ac new -name ac -variation lin -n 1 -fstart 1e5 -fstop 1e5]
# add voltage sweep
set voltSweep [lseq 0 20.0 0.1]

### set simulator with default
set simulator [Batch new {batch1}]
# attach simulator object to circuit
$circuit configure -simulator $simulator

### loop in which we run simulation, change reverse bias and read the results
vector create y -type complex
vector create voltage
foreach volt $voltSweep {
    #set reverse voltage bias
    $vdc actOnParam -set dc $volt
    # run simulation
    $circuit runAndRead
    # get data object
    set data [$circuit getDataDict]
    # append data to vectors
    voltage append $volt
    y append [dict get $data va#branch]
}

vector create capacitance
set freq [[$circuit getElement ac] actOnParam -get fstart]
capacitance expr {-imag(y)/(2*$pi*$freq*1e-9)}
set xydata [transpose [list [voltage index :] [capacitance index :]]]

### plot results with ticklecharts
set chart [ticklecharts::chart new]
set numberFormat [ticklecharts::jsfunc new {
    function (value) {
        return Number(value).toPrecision(2);
    }
}]
$chart Xaxis -name {v(0,c), V} -minorTick {show True} -type value -splitLine {show True}
$chart Yaxis -name {Diode capacitance, nF} -minorTick {show True} -type value -splitLine {show True}
$chart SetOptions -title {} -tooltip [list trigger axis valueFormatter $numberFormat] -animation False\
        -toolbox {feature {dataZoom {yAxisIndex none}}}
$chart Add lineSeries -name Capacitance -data $xydata -showAllSymbol nothing
set fbasename [file rootname [file tail [info script]]]
$chart Render -outfile [file normalize [file join .. html_charts $fbasename.html]] -width 800px -height 500px\
        -divid $fbasename -jschartvar chart_$fbasename -jsvar option_$fbasename

### plot results with rbc
if {![catch {package require rbc}]} {
    set graph [rbc::graphtoolbar .g -width 700 -height 400 -type graph -controlmode context -zoom -crosshairs\
                       -crosshairsmode closest -crosshairsclosestopts {-interpolate no} -pan -zoomwheel]
    $graph graph legend configure -hide yes
    $graph graph grid on
    $graph graph axis configure x -title {v(0,c), V}
    $graph graph axis configure y -title {Diode capacitance, nF}
    $graph graph element create current -x voltage -y capacitance -symbol circle -pixels 2
    grid $graph -sticky nsew
    grid columnconfigure . 0 -weight 1
    grid rowconfigure . 0 -weight 1
    $graph graph svg output [file normalize [file join .. .. .. docs assets img svg_charts xyce $fbasename.svg]]
}

