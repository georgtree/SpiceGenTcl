
package require SpiceGenTcl
package require ticklecharts
set ::ticklecharts::theme "dark"
namespace import ::SpiceGenTcl::*
importNgspice

# create top-level circuit
set circuit [Circuit new {diode IV}]
# add elements to circuit
$circuit add [D new 1 anode 0 -model diomod -area 1 -lm 1e-6]
$circuit add [Vdc new a anode 0 -dc 0]
$circuit add [DiodeModel new diomod -is 1e-12 -n 1.2 -rs 0.01 -cj0 1e-9 -trs1 0.001 -xti 5]
$circuit add [Dc new -src va -start 0 -stop 2 -incr 0.01]
set tempSt [Temp new 25]
$circuit add $tempSt
# add temperature sweep
set temps [list -55 25 85 125 175]
#set simulator with default 
set simulator [Batch new {batch1}]
# attach simulator object to circuit
$circuit configure -Simulator $simulator
# run circuit, change temperature, read log and data
foreach temp $temps {
    $tempSt configure -Value $temp
    $circuit runAndRead
    puts [$circuit configure -Log]
    set data [$circuit getDataDict]
    foreach x [dget $data v(anode)] y [dget $data i(va)] {
        set xf [format "%.3f" $x]
        set yf [format "%.3f" [= {-$y}]]
        lappend xydata [list $xf $yf]
    }    
    lappend dataList $xydata
    unset xydata
}


# plot results with ticklecharts
set chart [ticklecharts::chart new]
$chart Xaxis -name "v(anode), V" -minorTick {show "True"}  -type "value"
$chart Yaxis -name "Idiode, A" -minorTick {show "True"}  -type "value"
$chart SetOptions -title {} -tooltip {} -animation "False" -legend  {} -toolbox {feature {dataZoom {yAxisIndex "none"}}} \
        -grid {left "5%" right "15%"} -backgroundColor "#212121"
foreach data $dataList temp $temps {
    $chart Add "lineSeries" -data $data -showAllSymbol "nothing" -name "${temp}°C" -symbolSize "2"
}
set fbasename [file rootname [file tail [info script]]]

$chart Render -outfile [file normalize [file join .. html_charts $fbasename.html]]
