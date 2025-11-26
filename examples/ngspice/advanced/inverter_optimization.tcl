package require SpiceGenTcl
package require ticklecharts
package require tclcsv
package require tclopt
package require tclinterp
package require tclmeasure
package require extexpr
package require gnuplotutil

namespace import ::tcl::mathfunc::*
namespace import ::tclinterp::interpolation::*
namespace import ::tclmeasure::*
namespace import ::SpiceGenTcl::*
importNgspice

set scriptPath [file dirname [file normalize [info script]]]
set fileDataPath [file normalize [file join $scriptPath raw_data]]

proc pdPsCalc {width length} {
    return [= {2*$width+2*$length}]
}

# set parameters
set vSupply 2.0
set inpFreq 850e6
set inpPeriod [= {1.0/$inpFreq}]
set noPeriods 4
set tmeasStart [= {($noPeriods-1)*$inpPeriod}]
set tmeasStop [= {$noPeriods*$inpPeriod}]
set tmeas1 [= {$tmeasStop-3.0*$inpPeriod/4.0}]
set tmeas2 [= {$tmeasStop-1.0*$inpPeriod/4.0}]
set initialPWidth 10e-3
set pWidth $initialPWidth
set nWidth [= {$pWidth/3.0}]
set length 0.35e-6
set vLowLim 0.05
set vHighLim 1.95
set pd [pdPsCalc $pWidth $length]
set ps [pdPsCalc $pWidth $length]
set vSupplyVals {2.0 2.1 2.2}

# build circuit
set circuit [Circuit new {Inverter}]
set vdd [Vdc new dd vdd 0 -dc $vSupply]
set vss [Vdc new ss vss 0 -dc 0.0]
set vIn [Vpulse new 1 in vss -low $vSupply -high 0.0 -td [= {$inpPeriod/2.0}] -tr [= {$inpPeriod/1000.0}]\
                 -tf [= {$inpPeriod/1000.0}] -pw [= {$inpPeriod/2.0}] -per $inpPeriod]
set capLoad [C new l out vss -c 3p]
set mp [M new p out in vdd -model pmos -l $length -w $pWidth -n4 vdd -pd $pd -ps $ps]
set mn [M new n out in vss -model nmos -l $length -w $nWidth -n4 vss -pd $pd -ps $ps]
$circuit add $vdd $vss $vIn $capLoad $mp $mn
$circuit add [Tran new -tstep [= {$inpPeriod/1000.0}] -tstop [= {$inpPeriod*$noPeriods}]]
$circuit add [Include new [file join $scriptPath models n.typ]]
$circuit add [Include new [file join $scriptPath models p.typ]]

# set simulator
if {[catch {set simulator [Shared new batch1]}]} {
    set simulator [Batch new batch1]
}
$circuit configure -simulator $simulator

# define cost function
set pdata [dcreate vSupplyVals $vSupplyVals nDevice $mn pDevice $mp vLowLim $vLowLim vHighLim $vHighLim length $length vdd $vdd\
                  tmeas1 $tmeas1 tmeas2 $tmeas2 objWeight 10 constrWeight 10000 circuit $circuit]
proc costFunc {xall pdata args} {
    dict with pdata {}
    set width [@ $xall 0]
    set pdPs [pdPsCalc $width $length]
    $nDevice actOnParam -set l $length w [= {$width/3.0}] pd $pdPs ps $pdPs
    $pDevice actOnParam -set l $length w $width pd $pdPs ps $pdPs
    foreach val $vSupplyVals {
        $vdd actOnParam -set dc $val
        if {[catch {$circuit runAndRead}]} {
            # huge penalty in case of non-convergence
            lappend vlowList 1
            lappend vhighList 1
            lappend psupplyList 1
            continue
        }
        set data [$circuit configure -data]
        set dataDict [$circuit getDataDict]
        lappend vlowList [$data measure -find v(out) -at $tmeas1]
        lappend vhighList [$data measure -find v(out) -at $tmeas2]
        set instantPower [= {mul([dget $dataDict i(vdd)], [dget $dataDict v(vdd)])}]
        lappend psupplyList [measure -xname time -data [dcreate time [dget $dataDict time] instantPower $instantPower]\
                                     -rms "-vec instantPower -from $tmeas1 -to $tmeas2"]
    }
    set costObj 0.0
    set costConstr 0.0
    foreach psupply $psupplyList vlow $vlowList vhigh $vhighList {
        set constrVlow [= {($vlow-$vLowLim)/$vLowLim}]
        if {$constrVlow<0} {
            set constrVlow 0.0
        }
        set constrVhigh [= {($vHighLim-$vhigh)/$vHighLim}]
        if {$constrVhigh<0} {
            set constrVhigh 0.0
        }
        set costObj [= {$costObj+$psupply}]
        set costConstr [= {$costConstr+max($constrVlow, $constrVhigh)}]
    }
    return [= {$objWeight*$costObj+$constrWeight*$costConstr}]
}

# set and run optimizer
set par [::tclopt::Parameter new width $pWidth -lowlim 1e-4 -uplim 10e-3]
set optimizer [::tclopt::DE new -funct costFunc -pdata $pdata -strategy rand-to-best/1/exp -genmax 50 -refresh 1\
                           -np 10 -f 0.5 -cr 1 -seed 3 -debug -abstol 1e-6 -history -histfreq 1]
$optimizer addPars $par

# get results and history
set results [$optimizer run]
set width [dget $results x]
set trajectory [dict get $results besttraj]
set bestf [dict get $results history]
foreach genTr $trajectory genF $bestf {
    lappend optData [list {*}[dict get $genTr x] [dict get $genF bestf]]
    lappend functionTrajectory [list [dict get $genTr gen] [dict get $genTr x]]
}

# plot 2D trajectory
set chart [ticklecharts::chart new]
$chart Xaxis -name "Generation" -minorTick {show "True"} -type "value" -splitLine {show "True"}
$chart Yaxis -name "Width" -minorTick {show "True"}  -splitLine {show "True"}
$chart SetOptions -title {} -tooltip {trigger "axis"} -animation "False" -toolbox {feature {dataZoom {yAxisIndex "none"}}}
$chart Add "lineSeries" -name "Best trajectory" -data $functionTrajectory -showAllSymbol "nothing"
set fbasename [file rootname [file tail [info script]]]
$chart Render -outfile [file normalize [file join .. html_charts ${fbasename}_plot.html]]

# calculate initial waveforms the highest supply voltage
set pdPs [pdPsCalc $initialPWidth $length]
$mn actOnParam -set l $length w [= {$initialPWidth/3.0}] pd $pdPs ps $pdPs
$mp actOnParam -set l $length w $initialPWidth pd $pdPs ps $pdPs
$vdd actOnParam -set dc [@ $vSupplyVals 2]
$circuit runAndRead
set data [$circuit configure -data]
set dataDict [$circuit getDataDict]
foreach timeVal [dget $dataDict time] voutVal [dget $dataDict v(out)] {
    lappend initialWaveform [list $timeVal $voutVal]
}
set vlowInitial [$data measure -find v(out) -at $tmeas1]
set vhighInitial [$data measure -find v(out) -at $tmeas2]
set instantPower [= {mul([dget $dataDict i(vdd)], [dget $dataDict v(vdd)])}]
set psupplyInitial [measure -xname time -data [dcreate time [dget $dataDict time] instantPower $instantPower]\
                            -rms "-vec instantPower -from $tmeas1 -to $tmeas2"]

# calculate final waveform for the highest supply voltage
set pdPs [pdPsCalc $width $length]
$mn actOnParam -set l $length w [= {$width/3.0}] pd $pdPs ps $pdPs
$mp actOnParam -set l $length w $width pd $pdPs ps $pdPs
$vdd actOnParam -set dc [@ $vSupplyVals 2]
$circuit runAndRead
set data [$circuit configure -data]
set dataDict [$circuit getDataDict]
foreach timeVal [dget $dataDict time] voutVal [dget $dataDict v(out)] {
    lappend finalWaveform [list $timeVal $voutVal]
}
set vlowFinal [$data measure -find v(out) -at $tmeas1]
set vhighFinal [$data measure -find v(out) -at $tmeas2]
set instantPower [= {mul([dget $dataDict i(vdd)], [dget $dataDict v(vdd)])}]
set psupplyFinal [measure -xname time -data [dcreate time [dget $dataDict time] instantPower $instantPower]\
                          -rms "-vec instantPower -from $tmeas1 -to $tmeas2"]

# plot waveforms
set chart [ticklecharts::chart new]
$chart Xaxis -name "Time, s" -minorTick {show "True"} -type "value" -splitLine {show "True"}
$chart Yaxis -name "v(out)" -minorTick {show "True"}  -splitLine {show "True"}
$chart SetOptions -title {} -legend {} -tooltip {trigger "axis"} -animation "False"\
        -toolbox {feature {dataZoom {yAxisIndex "none"}}}
$chart Add "lineSeries" -name "initial, vdd=[@ $vSupplyVals 2]" -data $initialWaveform -showAllSymbol "nothing"\
        -symbolSize "0"
$chart Add "lineSeries" -name "final, vdd=[@ $vSupplyVals 2]" -data $finalWaveform -showAllSymbol "nothing"\
        -symbolSize "0"


set fbasename [file rootname [file tail [info script]]]
$chart Render -outfile [file normalize [file join .. html_charts ${fbasename}_waveforms_plot.html]]

# print resulted values for the highest supply voltage
puts "Optimization succesfully finished at generation [dget $results generation], total number of function evaluations\
      - [dget $results nfev]"
puts "Convergence info: [dget $results info]"
puts "Best value of cost function is [format "%3e" [dget $results objfunc]]"
puts "Final width of PMOS is [format "%.3f" [= {$width/1e-3}]]mm, from initial value\
        [format "%.3f" [= {$initialPWidth/1e-3}]]mm"
puts "For VDD=[@ $vSupplyVals 2]V,\
        VLOW: [format "%.3f" $vlowInitial]V → [format "%.3f" $vlowFinal]V<[format "%.3f" $vLowLim]V,\
        VHIGH: [format "%.3f" $vhighInitial]V → [format "%.3f" $vhighFinal]V>[format "%.3f" $vHighLim]V,\
        PSUPPLY: [format "%.3f" $psupplyInitial]W → [format "%.3f" $psupplyFinal]W"
