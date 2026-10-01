package require SpiceGenTcl
namespace import ::SpiceGenTcl::*
importNgspice

# create top-level circuit
# docs-begin circuit-creation-diffpair-sens
set circuit [Circuit new {simple differential pair}]
# add elements to circuit
$circuit add [Vdc new cc 8 0 -dc 12] [Vdc new ee 9 0 -dc -12] [Vac new cm 1 0 -ac 1] [Vac new dm 1 11 -ac 1]\
        [Q new 1 4 2 6 -model qnr] [Q new 2 5 3 6 -model qnl] [R new s1 11 2 -r 1e3] [R new s2 3 1 -r 1e3]\
        [R new c1 4 8 -r 10e3] [R new c2 5 8 -r 10e3] [Q new 3 7 7 9 -model qnl] [Q new 4 6 7 9 -model qnr]\
        [R new bias 7 8 -r 20e3]
# docs-end circuit-creation-diffpair-sens
# docs-begin add-models-diffpair-sens
$circuit add [BjtGPModel new qnl npn -bf 80 -rb 100 -cjc 2e-12 -tf 0.3e-9 -tr 6e-9 -cje 3e-12 -cjc 2e-12 -vaf 50]
$circuit add [BjtGPModel new qnr npn -bf 80 -rb 100 -cjc 2e-12 -tf 0.3e-9 -tr 6e-9 -cje 3e-12 -cjc 2e-12 -vaf 50]
# docs-end add-models-diffpair-sens
# docs-begin set-analysis-diffpair-sens
$circuit add [SensDc new -outvar v(5,4)]
# docs-end set-analysis-diffpair-sens
# set simulator with default
# docs-begin run-and-read-diffpair-sens
set simulator [Batch new {batch1}]
# attach simulator object to circuit
$circuit configure -simulator $simulator
# run circuit, read log and data
$circuit runAndRead
# get data object
set data [$circuit getDataDict]
set vrc1 [dict get $data v(rc1)]
set vrc2 [dict get $data v(rc2)]
puts [format {vrc1=%.3e vrc2=%.3e} $vrc1 $vrc2]
# docs-end run-and-read-diffpair-sens
