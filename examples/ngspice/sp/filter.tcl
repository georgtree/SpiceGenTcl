
package require SpiceGenTcl
package require ticklecharts
package require math::constants
::math::constants::constants radtodeg degtorad pi
namespace import ::SpiceGenTcl::*
importNgspice

variable pi
# create top-level circuit
set circuit [Circuit new {filter s-parameters}]
### add elements to circuit
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
$circuit add [Sp new -variation lin -n 500 -fstart 10meg -fstop 200meg]
#set simulator with default 
set simulator [BatchLiveLog new {batch1}]
# attach simulator object to circuit
$circuit configure -simulator $simulator
$circuit runAndRead
# get data object
set data [$circuit getDataDict]
# get frequency
set freq [dget $data frequency]
# get s11
set s11 [dget $data v(s_1_1)]
# get s21
set s21 [dget $data v(s_2_1)]
# extract real/imaginary parts of S11 and S21, and calculate magnitude
set freq [lmap val $freq {@ $val 0}]
set s11Mag [lmap s11Re [lmap val $s11 {@ $val 0}] s11Im [lmap val $s11 {@ $val 1}] {= {sqrt($s11Re**2+$s11Im**2)}}]
set s21Mag [lmap s21Re [lmap val $s21 {@ $val 0}] s21Im [lmap val $s21 {@ $val 1}] {= {sqrt($s21Re**2+$s21Im**2)}}]
# prepare data for ticklecharts
set freq_s11Mag [lmap freqVal $freq s11MagVal $s11Mag {list $freqVal $s11MagVal}]
set freq_s21Mag [lmap freqVal $freq s21MagVal $s21Mag {list $freqVal $s21MagVal}]

set chart [ticklecharts::chart new]
$chart Xaxis -name "Frequency, Hz" -minorTick {show "True"} -type "value" -splitLine {show "True"}
$chart Yaxis -name "mag(S)" -minorTick {show "True"} -type "value" -splitLine {show "True"}
$chart SetOptions -title {} -tooltip {trigger "axis"} -legend {} -animation "False"\
        -toolbox {feature {dataZoom {yAxisIndex "none"}}}
$chart Add "lineSeries" -data $freq_s11Mag -showAllSymbol "nothing" -name "S11" -symbolSize "0"
$chart Add "lineSeries" -data $freq_s21Mag -showAllSymbol "nothing" -name "S21" -symbolSize "0"
set fbasename [file rootname [file tail [info script]]]

$chart Render -outfile [file normalize [file join .. html_charts $fbasename.html]]

