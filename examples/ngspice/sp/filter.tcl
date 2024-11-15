lappend auto_path ../../../
package require SpiceGenTcl
package require ticklecharts
package require math::constants
::math::constants::constants radtodeg degtorad pi
namespace import ::SpiceGenTcl::*
importNgspice

variable pi
# create top-level circuit
set circuit [Circuit new {filter s-parameters}]
# add elements to circuit
$circuit add [Vport new gen 1 0 -dc 0 -ac 1 -portnum 1]
$circuit add [L new 1 1 2 -l 0.058u]
$circuit add [C new 2 2 0 -c 40.84p]
$circuit add [L new 3 2 3 -l 0.128u]
$circuit add [C new 4 3 0 -c 47.91p]
$circuit add [L new 5 3 4 -l 0.128u]
$circuit add [C new 6 4 0 -c 40.48p]
$circuit add [L new 7 4 5 -l 0.058u]
$circuit add [L new a 5 6 -l 0.044u]
$circuit add [L new b 6 a -l 0.078u]
$circuit add [C new b a 0 -c 17.61p]
$circuit add [L new c 6 b -l 0.151u]
$circuit add [C new c b 0 -c 34.12p]
$circuit add [C new 7 6 7 -c 26.035p]
$circuit add [L new 8 7 0 -l 0.0653u]
$circuit add [C new 8 7 8 -c 20.8p]
$circuit add [L new 9 8 0 -l 0.055u]
$circuit add [C new 9 8 9 -c 20.8p]
$circuit add [L new 10 9 0 -l 0.653u]
$circuit add [C new 10 9 out -c 45.64p]
$circuit add [Vport new l out 0 -dc 0 -ac 0 -portnum 2]

$circuit add [Sp new -variation lin -n 500 -fstart 10meg -fstop 200meg]
#set simulator with default 
set simulator [BatchLiveLog new {batch1} {/usr/local/bin/}]
# attach simulator object to circuit
$circuit configure -Simulator $simulator
$circuit runAndRead
# get data object
set data [$circuit getDataDict]
# get real part of S(11)
set freq [dict get $data frequency]
set s11 [dict get $data v(s_1_1)]
set s21 [dict get $data v(s_2_1)]

set freq [lmap val $freq {lindex $val 0}]
set s11Mag [lmap s11Re [lmap val $s11 {lindex $val 0}] s11Im [lmap val $s11 {lindex $val 1}]\
        {expr {sqrt($s11Re**2+$s11Im**2)}}]
set freq_s11Mag [lmap freqVal $freq s11MagVal $s11Mag {list $freqVal $s11MagVal}]
set s21Mag [lmap s21Re [lmap val $s21 {lindex $val 0}] s21Im [lmap val $s21 {lindex $val 1}]\
        {expr {sqrt($s21Re**2+$s21Im**2)}}]
set freq_s21Mag [lmap freqVal $freq s21MagVal $s21Mag {list $freqVal $s21MagVal}]

set chart [ticklecharts::chart new]
$chart Xaxis -name "Frequency, Hz" -minorTick {show "True"} -type "value"
$chart Yaxis -name "mag(S)" -minorTick {show "True"} -type "value"
$chart SetOptions -title {} -tooltip {} -legend {} -animation "False" -toolbox {feature {dataZoom {yAxisIndex "none"}}}
$chart Add "lineSeries" -data $freq_s11Mag -showAllSymbol "nothing" -name "S11" -symbolSize "0"
$chart Add "lineSeries" -data $freq_s21Mag -showAllSymbol "nothing" -name "S21" -symbolSize "0"
set fbasename [file rootname [file tail [info script]]]

$chart Render -outfile [file normalize [file join .. html_charts $fbasename.html]]

