package require SpiceGenTcl
package require rbc::vector
package require ticklecharts
package require tclcsv
package require tclopt
package require tclinterp
package require math::linearalgebra

namespace import ::tcl::mathfunc::*
namespace import ::tclinterp::interpolation::*
namespace import ::math::linearalgebra::transpose
namespace import rbc::vector
namespace import ::tclcsv::*
namespace import ::SpiceGenTcl::*
importNgspice

set scriptPath [file dirname [file normalize [info script]]]
set fileDataPath [file normalize [file join $scriptPath raw_data]]

# docs-begin proc-diodeivcalc-diode-extract
proc diodeIVcalc {xall pdata args} {
    # docs-begin dict-expansion-diode-extract
    dict with pdata {}
    # docs-end dict-expansion-diode-extract
    # docs-begin set-fitting-params-diode-extract
    $model actOnParam -set is [lindex $xall 0] n [lindex $xall 1] rs [lindex $xall 2] ikf [lindex $xall 3]
    # docs-end set-fitting-params-diode-extract
    # docs-begin set-vsrc-params-diode-extract
    $vSrc actOnParam -set start $vMin stop $vMax incr $vStep
    # docs-end set-vsrc-params-diode-extract
    # docs-begin circuit-run-diode-extract
    $circuit runAndRead -vector
    set data [$circuit getDataDict]
    # docs-end circuit-run-diode-extract
    # docs-begin residuals-calc-diode-extract
    set iVa [dict get $data i(va)]
    $iVa expr {-$iVa}
    vector create fvec
    fvec expr {log(abs($i))-log(abs($iVa))}
    # docs-end residuals-calc-diode-extract
    return [dict create fvec [fvec index :] fval [$iVa index :]]
}
# docs-end proc-diodeivcalc-diode-extract

### define circuit, diode model and voltage source
# docs-begin circuit-creaion-diode-extract
set diodeModel [DiodeModel new diomod -is 1e-12 -n 1.0 -rs 30 -cjo 1e-9 -trs1 0.001 -xti 5 -ikf 1e-4]
set vSrc [Dc new -src va -start 0 -stop 2 -incr 0.02]
set circuit [Circuit new {diode IV}]
$circuit add [D new 1 anode 0 -model diomod -area 1]
$circuit add [Vdc new a anode 0 -dc 0]
$circuit add $diodeModel
$circuit add $vSrc
set tempSt [Temp new 25]
$circuit add $tempSt
if {[catch {set simulator [Shared new batch1]}]} {
    set simulator [Batch new batch1]
}
$circuit configure -simulator $simulator
# docs-end circuit-creaion-diode-extract

### load measurement data
# docs-begin load-meas-data-diode-extract
set file [open [file join $fileDataPath iv25.csv]]
set ivTemp25 [csv_read -startline 1 $file]
close $file
vector create vRaw iRaw
vRaw set [lmap elem $ivTemp25 {lindex $elem 0}]
iRaw set [lmap elem $ivTemp25 {lindex $elem 1}]
# docs-end load-meas-data-diode-extract

### define first fitting region
# docs-begin first-region-voltage-setup-diode-extract
set vMin $vRaw(min)
set vMax 0.85
set vStep 0.02
# docs-end first-region-voltage-setup-diode-extract
# interpolate current with irregular voltage grid to evenly spaced one with fixed step
# docs-begin first-region-interp-setup-diode-extract
vector create vInterp
vInterp seq $vMin $vMax $vStep
lin1d -input vector -output vector -x vRaw -y iRaw -xi vInterp -name iInterp
# set data dictionary passed into function
set pdata [dict create v vInterp i iInterp circuit $circuit model $diodeModel vMin $vMin vMax $vMax vStep $vStep\
                   vSrc $vSrc]
# docs-end first-region-interp-setup-diode-extract
# set fitting parameters
# docs-begin first-region-fitting-params-setup-diode-extract
set iniPars [list 1e-14 1.0 30 1e-4]
set par0 [::tclopt::ParameterMpfit new is [lindex $iniPars 0] -lowlim 1e-17 -uplim 1e-12]
set par1 [::tclopt::ParameterMpfit new n [lindex $iniPars 1] -lowlim 0.5 -uplim 2]
set par2 [::tclopt::ParameterMpfit new rs [lindex $iniPars 2] -fixed -lowlim 1e-10 -uplim 100]
set par3 [::tclopt::ParameterMpfit new ikf [lindex $iniPars 3] -fixed -lowlim 1e-12 -uplim 0.1]
# docs-end first-region-fitting-params-setup-diode-extract
# fit in first region
# docs-begin first-region-optimizer-creattion-diode-extract
set optimizer [::tclopt::Mpfit new -funct diodeIVcalc -m [vInterp length] -pdata $pdata]
# docs-end first-region-optimizer-creattion-diode-extract
# docs-begin first-region-add-params-diode-extract
$optimizer addPars $par0 $par1 $par2 $par3
# docs-end first-region-add-params-diode-extract
# docs-begin first-region-run-opt-diode-extract
set result [$optimizer run]
set resPars [dict get $result x]
puts [format {is=%.3e, n=%.3e, rs=%.3e, ikf=%.3e} {*}[dict get $result x]]
# docs-end first-region-run-opt-diode-extract

### define second fitting region
# docs-begin second-region-voltage-setup-diode-extract
set vMin 0.85
set vMax $vRaw(max)
vInterp seq $vMin $vMax $vStep
lin1d -input vector -output vector -ifexists replace -x vRaw -y iRaw -xi vInterp -name iInterp
# docs-end second-region-voltage-setup-diode-extract
# docs-begin second-region-change-pdata-diode-extract
dict set pdata vMin $vMin
dict set pdata vMax $vMax
# docs-end second-region-change-pdata-diode-extract
# docs-begin second-region-set-fitting-params-diode-extract
$par0 configure -fixed 1 -initval [lindex $resPars 0]
$par1 configure -fixed 1 -initval [lindex $resPars 1]
$par2 configure -fixed 0
$par3 configure -fixed 0
# docs-end second-region-set-fitting-params-diode-extract
# docs-begin second-region-optimizer-change-diode-extract
$optimizer configure -m [vInterp length] -pdata $pdata
# docs-end second-region-optimizer-change-diode-extract
# docs-begin second-region-run-opt-diode-extract
set result [$optimizer run]
set fittedIdiode [dict get [diodeIVcalc [dict get $result x] $pdata] fval]
set resPars [dict get $result x]
puts [format {is=%.3e, n=%.3e, rs=%.3e, ikf=%.3e} {*}[dict get $result x]]
# docs-end second-region-run-opt-diode-extract

### define fitting to the whole curve
# docs-begin whole-region-setup-diode-extract
set vMin $vRaw(min)
set vMax $vRaw(max)
vInterp seq $vMin $vMax $vStep
lin1d -input vector -output vector -ifexists replace -x vRaw -y iRaw -xi vInterp -name iInterp
dict set pdata vMin $vMin
dict set pdata vMax $vMax
# docs-end whole-region-setup-diode-extract
# docs-begin whole-region-fitting-params-setup-diode-extract
$par0 configure -fixed 0 -initval [lindex $resPars 0] -lowlim [expr {[lindex $resPars 0]*0.9}]\
        -uplim [expr {[lindex $resPars 0]*1.1}]
$par1 configure -fixed 0 -initval [lindex $resPars 1] -lowlim [expr {[lindex $resPars 1]*0.9}]\
        -uplim [expr {[lindex $resPars 1]*1.1}]
$par2 configure -initval [lindex $resPars 2] -lowlim [expr {[lindex $resPars 2]*0.9}]\
        -uplim [expr {[lindex $resPars 2]*1.1}]
$par3 configure -initval [lindex $resPars 3] -lowlim [expr {[lindex $resPars 3]*0.9}]\
        -uplim [expr {[lindex $resPars 3]*1.1}]
# docs-end whole-region-fitting-params-setup-diode-extract
# docs-begin whole-region-run-opt-diode-extract
$optimizer configure -m [vInterp length] -pdata $pdata
set result [$optimizer run]
set fittedIdiode [dict get [diodeIVcalc [dict get $result x] $pdata] fval]
puts [format {is=%.3e, n=%.3e, rs=%.3e, ikf=%.3e} {*}[dict get $result x]]
# docs-end whole-region-run-opt-diode-extract

### calculate initial curve and fitted curve
# docs-begin final-curves-calculation-diode-extract
set initIdiode [dict get [diodeIVcalc $iniPars $pdata] fval]
set fittedVIdiode [transpose [list [vInterp index :] $fittedIdiode]]
set initVIdiode [transpose [list [vInterp index :] $initIdiode]]
set viRaw [transpose [list [vRaw index :] [iRaw index :]]]
# docs-end final-curves-calculation-diode-extract

### plot results with ticklecharts
# docs-begin plot-ticklecharts-diode-extract
set numberFormat [ticklecharts::jsfunc new {
    function (value) {
        return Number(value).toPrecision(3);
    }
}]
set chart [ticklecharts::chart new]
$chart Xaxis -name {v(anode), V} -minorTick {show True}  -type value -splitLine {show True} -min 0.4 -max 1.6
$chart Yaxis -name {Idiode, A} -minorTick {show True}  -type value -splitLine {show True} -min 0.0 -max dataMax
$chart SetOptions -title {} -tooltip [list trigger axis valueFormatter $numberFormat] -animation False -legend {}\
        -grid {left 10% right 15%} -toolbox {feature {dataZoom {yAxisIndex none}}}
$chart Add lineSeries -data $fittedVIdiode -showAllSymbol nothing -name fitted -symbolSize 4
$chart Add lineSeries -data $initVIdiode -showAllSymbol nothing -name unfitted -symbolSize 4
$chart Add lineSeries -data $viRaw -showAllSymbol nothing -name measured -symbolSize 4
set chartLog [ticklecharts::chart new]
$chartLog Xaxis -name {v(anode), V} -minorTick {show True}  -type value -splitLine {show True} -min 0.4 -max 1.6
$chartLog Yaxis -name {Idiode, A} -minorTick {show True}  -type log -splitLine {show True} -min dataMin -max 0.1
$chartLog SetOptions -title {} -tooltip [list trigger axis valueFormatter $numberFormat] -animation False -legend {}\
        -grid {left 10% right 15%} -toolbox {feature {dataZoom {yAxisIndex none}}}
$chartLog Add lineSeries -data $fittedVIdiode -showAllSymbol nothing -name fitted -symbolSize 4
$chartLog Add lineSeries -data $initVIdiode -showAllSymbol nothing -name unfitted -symbolSize 4
$chartLog Add lineSeries -data $viRaw -showAllSymbol nothing -name measured -symbolSize 4

set layout [ticklecharts::Gridlayout new]
$layout Add $chartLog -bottom 5% -height 40% -width 80%
$layout Add $chart -bottom 55% -height 40% -width 80%

set fbasename [file rootname [file tail [info script]]]
$layout Render -outfile [file normalize [file join .. html_charts $fbasename.html]] -width 800px -height 500px\
        -divid $fbasename -jschartvar chart_$fbasename -jsvar option_$fbasename
# docs-end plot-ticklecharts-diode-extract

### plot results with rbc
# docs-begin plot-rbc-diode-extract
if {![catch {package require rbc::graphtoolbar}]} {
    set colors {#5470c6 #91cc75 #fac858 #ee6666 #73c0de #3ba272 #fc8452 #9a60b4 #ea7ccc}
    set graph [rbc::graphtoolbar .g -width 700 -height 400 -type graph -controlmode context -zoom -crosshairs\
                       -crosshairsmode closest -crosshairsclosestopts {-interpolate no} -pan -zoomwheel -scaletoggle y\
                       -activelegend]
    $graph graph grid on
    $graph graph axis configure x -title {v(anode), V}
    $graph graph axis configure y -title {Idiode, A}
    $graph graph element create initIdiode -x vInterp -y $initIdiode -symbol circle -pixels 2 -label unfitted\
            -color [lindex $colors 0]
    $graph graph element create rawIdiode -x vRaw -y iRaw -symbol circle -pixels 2 -label measured\
            -color [lindex $colors 1]
    $graph graph element create fittedIdiode -x vInterp -y $fittedIdiode -symbol circle -pixels 2 -label fitted\
            -color [lindex $colors 2]
    grid $graph -sticky nsew
    grid columnconfigure . 0 -weight 1
    grid rowconfigure . 0 -weight 1
    $graph graph svg output [file normalize [file join .. .. .. docs assets img svg_charts ngspice $fbasename.svg]]
}
# docs-end plot-rbc-diode-extract
