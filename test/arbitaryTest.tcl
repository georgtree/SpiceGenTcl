package require tcltest
namespace import ::tcltest::*
package require SpiceGenTcl
package require math::constants
namespace import ::tcltest::*
::math::constants::constants radtodeg degtorad pi
variable pi

namespace import ::SpiceGenTcl::*
set testDir [file dirname [info script]]
set netlistsLoc [file join $testDir ngspice netlists_parser]
importNgspice

set currentDir [file normalize [file dirname [info script]]]
source [file join $currentDir  testUtilities.tcl]

testTemplate testRModelClass-1 {} {RModel new resmod -tc1 1 -tc2 2} {.model resmod r(tc1=1 tc2=2)}
RModel new -help
