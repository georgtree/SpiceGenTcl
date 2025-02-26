package require tcltest
namespace import ::tcltest::*
package require SpiceGenTcl
package require math::constants
namespace import ::tcltest::*
::math::constants::constants radtodeg degtorad pi
variable pi

set epsilon 1e-8

namespace import ::SpiceGenTcl::*
set testDir [file dirname [info script]]
set netlistsLoc [file join $testDir ngspice netlists_parser]
importNgspice

test testParserClassIndsources-1 {test Parser class, independent sources parsing} -setup {
    set parser [::SpiceGenTcl::Ngspice::Parser new parser1 [file join $netlistsLoc indsources_test.cir]]
    $parser readFile
    $parser buildNetlist
} -body {
    return [[$parser configure -Netlist] genSPICEString]
} -result "g1 2 0 5 0 0.1 m={m}
g2 2 0 5 0 {value} m={m}
e1 2 3 14 1 2.0
e2 2 3 14 1 {value}
f1 13 5 vsens 5
f2 13 5 vsens {value}
h1 5 17 vz 0.5k
h2 5 17 vz {value}" -cleanup {
    unset parser
}
