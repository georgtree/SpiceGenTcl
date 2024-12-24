
package require SpiceGenTcl
namespace import ::SpiceGenTcl::*
importNgspice

# create top-level circuit
set circuit [Circuit new {simple differential pair}]
# add elements to circuit
$circuit add [Vdc new cc 8 0 -dc 12]
$circuit add [Vdc new ee 9 0 -dc -12]
$circuit add [Vac new cm 1 0 -ac 1]
$circuit add [Vac new dm 1 11 -ac 1]
$circuit add [Q new 1 4 2 6 -model qnr]
$circuit add [Q new 2 5 3 6 -model qnl]
$circuit add [R new s1 11 2 -r 1e3]
$circuit add [R new s2 3 1 -r 1e3]
$circuit add [R new c1 4 8 -r 10e3]
$circuit add [R new c2 5 8 -r 10e3]
$circuit add [Q new 3 7 7 9 -model qnl]
$circuit add [Q new 4 6 7 9 -model qnr]
$circuit add [R new bias 7 8 -r 20e3]

$circuit add [BjtGPModel new qnl npn -bf 80 -rb 100 -cjc 2e-12 -tf 0.3e-9 -tr 6e-9 -cje 3e-12 -cjc 2e-12 -va 50]
$circuit add [BjtGPModel new qnr npn -bf 80 -rb 100 -cjc 2e-12 -tf 0.3e-9 -tr 6e-9 -cje 3e-12 -cjc 2e-12 -va 50]

$circuit add [SensDc new -outvar v(5,4)]
#set simulator with default 
set simulator [Batch new {batch1}]
# attach simulator object to circuit
$circuit configure -Simulator $simulator
# run circuit, read log and data
$circuit runAndRead
# get data object
set data [$circuit getDataDict]
set vrc1 [dget $data v(rc1)]
set vrc2 [dget $data v(rc2)]
puts [format "vrc1=%.3e vrc2=%.3e" $vrc1 $vrc2]
