package require tcltest
namespace import ::tcltest::*
package require SpiceGenTcl
package require math::constants
namespace import ::tcltest::*
::math::constants::constants radtodeg degtorad pi
variable pi
set testDir [file dirname [info script]]
set netlistsLoc [file join $testDir ngspice netlists_parser]
set epsilon 1e-8
proc testTemplateParse {testName descr location fileName refStr} {
    test $testName $descr -setup {
        set parser [::SpiceGenTcl::Ngspice::NgspiceParser new parser1 [file join $location $fileName]]
        $parser readFile
    } -body {
        if {[catch {$parser buildTopNetlist} errorStr]} {
            return $errorStr
        }
        return [[$parser configure -topnetlist] genSPICEString]
    } -result $refStr
}
namespace import ::SpiceGenTcl::*
set testDir [file dirname [info script]]
set netlistsLoc [file join $testDir ngspice netlists_parser]
importNgspice

set currentDir [file normalize [file dirname [info script]]]
source [file join $currentDir  testUtilities.tcl]

testTemplateParse testNgspiceParserClassSubcircuitsDefinition-2 {} $netlistsLoc deeply_nested_subckt.cir\
{.subckt top in out
.subckt middle1 in out
.subckt inner1 in out
.subckt innerinner1 in out
r4 in c r={30}
.ends innerinner1
r3 in c r={30}
.ends inner1
r2 in b r={20}
r5 b out r={40}
.ends middle1
.subckt middle2 in out
.subckt inner2 in out
r7 in e r={60}
.ends inner2
.subckt inner1 in out
r8 in e r={60}
.ends inner1
r6 in d r={50}
r9 d out r={70}
.ends middle2
r1 in a r={10}
r10 a out r={80}
.ends top}

