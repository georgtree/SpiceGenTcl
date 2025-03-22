package require SpiceGenTcl
namespace import ::SpiceGenTcl::*
importNgspice
set netlistsLoc [file dirname [info script]]
set parser [::SpiceGenTcl::Ngspice::NgspiceParser new parser1 [file join $netlistsLoc diffpair.cir]]
set netlist [$parser readAndParse]
puts [$netlist genSPICEString]
#puts [join [$parser configure -definitions] "\n"]
#puts [join [$parser readAndParse -noeval] "\n"]

set circuit [Circuit new {diffpair}]
set simulator [BatchLiveLog new {batch1}]
$circuit add $netlist
$circuit configure -simulator $simulator
$circuit runAndRead
set data [$circuit getDataDict]
set vrc1 [dget $data v(rc1)]
set vrc2 [dget $data v(rc2)]
puts [format "vrc1=%.3e vrc2=%.3e" $vrc1 $vrc2]
