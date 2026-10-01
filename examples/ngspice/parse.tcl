package require SpiceGenTcl
namespace import ::SpiceGenTcl::*
importNgspice
# docs-begin parser-creation-simple-parse
set netlistsLoc [file dirname [info script]]
set parser [::SpiceGenTcl::Ngspice::NgspiceParser new parser1 [file join $netlistsLoc diffpair.cir]]
# docs-end parser-creation-simple-parse
# docs-begin netlist-simple-parse
set netlist [$parser readAndParse]
# docs-end netlist-simple-parse
# docs-begin netlist-puts-simple-parse
puts [$netlist genSPICEString]
# docs-end netlist-puts-simple-parse
#puts [join [$parser configure -definitions] "\n"]
#puts [join [$parser readAndParse -noeval] "\n"]

# docs-begin circuit-creation-and-run-simple-parse
set circuit [Circuit new {diffpair}]
set simulator [BatchLiveLog new {batch1}]
$circuit add $netlist
$circuit configure -simulator $simulator
$circuit runAndRead
set data [$circuit getDataDict]
set vrc1 [dict get $data v(rc1)]
set vrc2 [dict get $data v(rc2)]
puts [format {vrc1=%.3e vrc2=%.3e} $vrc1 $vrc2]
# docs-end circuit-creation-and-run-simple-parse
