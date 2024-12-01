lappend auto_path ../
package require SpiceGenTcl
namespace import ::SpiceGenTcl::*
importNgspice

# create top-level circuit
set circuit [Circuit new {voltage divider netlist}]
# add elements to circuit
$circuit add [Vdc new 1 in 0 -dc 1]
$circuit add [R new 1 in out -r 1e3]
$circuit add [R new 2 out 0 -r 2e3]
$circuit add [Dc new -src v1 -start 0 -stop 5 -incr 1]
#set simulator with default 
set simulator [Batch new {batch1}]
# attach simulator object to circuit
$circuit configure -Simulator $simulator
# run circuit, read log and data
$circuit runAndRead
# get data object
set dataObj [$circuit configure -Data]
set data [$dataObj getTracesCsv -all -sep ,,]
#set data [$dataObj getTracesCsv -traces v(in)]
set file [open file.csv w+]
puts $file $data
close $file

puts $data
