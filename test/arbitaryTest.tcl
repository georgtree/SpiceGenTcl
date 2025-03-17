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

test testNgspiceParserClass-5 {} -setup {
    set file [open [file join $netlistsLoc temp1] w+]
    puts $file {}
    puts $file {.subckt }
    close $file
    set parser [::SpiceGenTcl::Ngspice::NgspiceParser new parser1 [file join $netlistsLoc temp1]]
    $parser readFile
} -body {
    if {[catch {[info object namespace $parser]::my GetSubcircuitLines} errorStr]} {
        return $errorStr
    }
    return [[$parser configure -topnetlist] genSPICEString]
} -result {Subcircuit couldn't be defined without a name} -cleanup {
    file delete [file join $netlistsLoc temp1]
    unset parser
}

