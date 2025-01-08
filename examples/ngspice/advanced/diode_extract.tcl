package require SpiceGenTcl
package require ticklecharts
package require tclcsv
package require tclopt
package require tclinterp
package require gnuplotutil

namespace import ::tcl::mathfunc::*
namespace import ::tclinterp::interpolation::*
namespace import ::tclopt::*
namespace import ::gnuplotutil::*
set ::ticklecharts::theme "dark"

namespace import ::tclcsv::*
namespace import ::SpiceGenTcl::*
importNgspice

set scriptPath [file dirname [file normalize [info script]]]
set fileDataPath [file normalize [file join $scriptPath raw_data]]

proc diodeIVcalc {xall pdata args} {
    dict with pdata {}
    $model setParamValue is [@ $xall 0] n [@ $xall 1] rs [@ $xall 2] ikf [@ $xall 3]
    $vSrc setParamValue start $vMin stop $vMax incr $vStep
    $circuit runAndRead
    set data [$circuit getDataDict]
    foreach iVal $i iSim [lmap i [dget $data i(va)] {= {-$i}}] {
        lappend fvec [= {(log(abs($iVal))-log(abs($iSim)))}]
        lappend fval $iSim
    }
    return [dcreate fvec $fvec fval $fval]
}

# define circuit, diode model and voltage source
set diodeModel [DiodeModel new diomod -is 1e-12 -n 1.0 -rs 30 -cj0 1e-9 -trs1 0.001 -xti 5 -ikf 1e-4]
set vSrc [Dc new -src va -start 0 -stop 2 -incr 0.02]
set circuit [Circuit new {diode IV}]
$circuit add [D new 1 anode 0 -model diomod -area 1]
$circuit add [Vdc new a anode 0 -dc 0]
$circuit add $diodeModel
$circuit add $vSrc
set tempSt [Temp new 25]
$circuit add $tempSt
$circuit configure -Simulator [Batch new {batch1}]

### load measurement data
set file [open [file join $fileDataPath iv25.csv]]
set ivTemp25 [csv_read -startline 1 $file]
close $file
set vRaw [lmap elem $ivTemp25 {@ $elem 0}]
set iRaw [lmap elem $ivTemp25 {@ $elem 1}]

### define first fitting region
set vMin [min {*}$vRaw]
set vMax 0.85
set vStep 0.02
# interpolate current with irregular voltage grid to evenly spaced one with fixed step
set vInterp [lseq $vMin to $vMax by $vStep]
set iInterp [lin1d -x $vRaw -y $iRaw -xi $vInterp]
set iniPars [list 1e-14 1.0 30 1e-4]
# set data dictionary passed into function
set pdata [dcreate v $vInterp i $iInterp circuit $circuit model $diodeModel vMin $vMin vMax $vMax vStep $vStep\
                   vSrc $vSrc]
# set fitting parameters
set par0 [parCreate -parname is -lowlim 1e-17 -uplim 1e-12]
set par1 [parCreate -parname n -lowlim 0.5 -uplim 2]
set par2 [parCreate -fixed -parname rs -lowlim 1 -uplim 100]
set par3 [parCreate -fixed -parname ikf -lowlim 1e-12 -uplim 0.1]
set pars [list $par0 $par1 $par2 $par3]
# fit in first region
set result [mpfit -funct diodeIVcalc -m [llength $vInterp] -xall $iniPars -pars $pars -pdata $pdata]
set resPars [dget $result x]
puts [format "is=%.3e, n=%.3e, rs=%.3e, ikf=%.3e" {*}[dget $result x]]

### define second fitting region
set vMin 0.85
set vMax [max {*}$vRaw]
set vInterp [lseq $vMin to $vMax by $vStep]
set iInterp [lin1d -x $vRaw -y $iRaw -xi $vInterp]
dset pdata v $vInterp
dset pdata i $iInterp
dset pdata vMin $vMin
dset pdata vMax $vMax
set par0 [parCreate -fixed -parname is -lowlim 1e-17 -uplim 1e-12]
set par1 [parCreate -fixed -parname n -lowlim 0.8 -uplim 2]
set par2 [parCreate -parname rs -lowlim 1 -uplim 100]
set par3 [parCreate -parname ikf -lowlim 1e-12 -uplim 0.1]
set pars [list $par0 $par1 $par2 $par3]
set result [mpfit -funct diodeIVcalc -m [llength $vInterp] -xall $resPars -pars $pars -pdata $pdata]
set fittedIdiode [dget [diodeIVcalc [dget $result x] $pdata] fval]
set resPars [dget $result x]
puts [format "is=%.3e, n=%.3e, rs=%.3e, ikf=%.3e" {*}[dget $result x]]

### define fitting to the whole curve
set vMin [min {*}$vRaw]
set vMax [max {*}$vRaw]
set vInterp [lseq $vMin to $vMax by $vStep]
set iInterp [lin1d -x $vRaw -y $iRaw -xi $vInterp]
dset pdata v $vInterp
dset pdata i $iInterp
dset pdata vMin $vMin
dset pdata vMax $vMax
set par0 [parCreate -parname is -lowlim [= {[@ $resPars 0]*0.9}] -uplim [= {[@ $resPars 0]*1.1}]]
set par1 [parCreate -parname n -lowlim [= {[@ $resPars 1]*0.9}] -uplim [= {[@ $resPars 1]*1.1}]]
set par2 [parCreate -parname rs -lowlim [= {[@ $resPars 2]*0.9}] -uplim [= {[@ $resPars 2]*1.1}]]
set par3 [parCreate -parname ikf -lowlim [= {[@ $resPars 3]*0.9}] -uplim [= {[@ $resPars 3]*1.1}]]
set pars [list $par0 $par1 $par2 $par3]
set result [mpfit -funct diodeIVcalc -m [llength $vInterp] -xall $resPars -pars $pars -pdata $pdata]
set fittedIdiode [dget [diodeIVcalc [dget $result x] $pdata] fval]
puts [format "is=%.3e, n=%.3e, rs=%.3e, ikf=%.3e" {*}[dget $result x]]

### calculate initial curve and fitted curve
set initIdiode [dget [diodeIVcalc $iniPars $pdata] fval]
set fittedVIdiode [lmap vVal $vInterp iVal $fittedIdiode {list $vVal $iVal]}]
set initVIdiode [lmap vVal $vInterp iVal $initIdiode {list $vVal $iVal]}]
set viRaw [lmap vVal $vRaw iVal $iRaw {list $vVal $iVal]}]

# plot results with ticklecharts
set chart [ticklecharts::chart new]
$chart Xaxis -name "v(anode), V" -minorTick {show "True"}  -type "value" -splitLine {show "True"}
$chart Yaxis -name "Idiode, A" -minorTick {show "True"}  -type "log" -splitLine {show "True"} -min "dataMin"\
        -max "dataMax"
$chart SetOptions -title {} -tooltip {} -animation "False" -legend {} -toolbox {feature {dataZoom {yAxisIndex "none"}}}\
        -grid {left "10%" right "15%"} -backgroundColor "#212121"
$chart Add "lineSeries" -data $fittedVIdiode -showAllSymbol "nothing" -name "fitted" -symbolSize "4"
$chart Add "lineSeries" -data $initVIdiode -showAllSymbol "nothing" -name "unfitted" -symbolSize "4"
$chart Add "lineSeries" -data $viRaw -showAllSymbol "nothing" -name "measured" -symbolSize "4"
set fbasename [file rootname [file tail [info script]]]
$chart Render -outfile [file normalize [file join .. html_charts $fbasename.html]]
