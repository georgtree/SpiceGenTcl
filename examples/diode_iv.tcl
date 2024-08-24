lappend auto_path /home/georgtree/tcl_tools/
lappend auto_path "../"
package require SpiceGenTcl
package require gnuplotutil
package require xyplot
namespace import ::SpiceGenTcl::*
importNgspice

# create top-level circuit
set circuit [Circuit new {diode IV}]
# add elements to circuit
$circuit add [D new 1 anode 0 diomod -area 1 -lm 1e-6]
$circuit add [Vdc new a anode 0 0]
$circuit add [DiodeModel new diomod -is 1e-12 -n 1.2 -rs 0.01 -cj0 1e-9 -trs1 0.001 -xti 5]
$circuit add [Dc new va 0 2 0.01]
set tempSt [Temp new 25]
$circuit add $tempSt
# add temperature sweep
set temps [list -55 25 85 125 175]
#set simulator with default 
set simulator [Batch new {batch1} {/usr/local/bin/}]
# attach simulator object to circuit
$circuit attachSimulator $simulator
# run circuit, change temperature, read log and data
foreach temp $temps {
    $tempSt setValue $temp
    $circuit runAndRead
    puts [$circuit getLog]
    # get data object
    set data [$circuit getDataDict]
    lappend axisList [dict get $data v(anode)]
    lappend traceList [dict get $data i(va)]   
}

#$simulator clearLog


# plot results with plotchart
wm geometry . 600x400
set xyp [xyplot .xyp -xformat "%.2f" -yformat "%.2f" -title "Diode IV curves" -xtext "v(anode,0), V" -ytext "Idiode, A"]
pack $xyp -fill both -expand true
set i 0
set colors [list red blue green black orange]
foreach axis $axisList trace $traceList {
    foreach x $axis y $trace {
        lappend xydata $x [* -1.0 $y]
    }
    $xyp add_data sf$i $xydata -legend "temp=[lindex $temps $i]" -color [lindex $colors $i]
    unset xydata
    incr i
}


