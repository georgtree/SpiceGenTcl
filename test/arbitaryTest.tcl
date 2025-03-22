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
proc testTemplateParse {testName descr location fileName refStr {cleanupList {}}} {
    test $testName $descr -setup {
        set parser [::SpiceGenTcl::Ngspice::NgspiceParser new parser1 [file join $location $fileName]]
        $parser readFile
    } -body {
        if {[catch {$parser buildTopNetlist} errorStr]} {
            return $errorStr
        }
        puts [join [$parser configure -definitions] "\n"]
        return [[$parser configure -topnetlist] genSPICEString]
    } -result $refStr -cleanup {
        if {$cleanupList ne {}} {
            foreach name $cleanupList {
                rename $name {}
            }
        }
    }
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

oo::class create Middle1 {
    superclass ::SpiceGenTcl::Subcircuit
    constructor {} {
        oo::class create Inner1 {
            superclass ::SpiceGenTcl::Subcircuit
            constructor {} {
                oo::class create Innerinner1 {
                    superclass ::SpiceGenTcl::Subcircuit
                    constructor {} {
                        
                        my add [::SpiceGenTcl::Ngspice::BasicDevices::R new 4 in c -r 30 -beh]
                        set pins {in out}
                        set params {}
                        next innerinner1 $pins $params
                    }
                }
                my add [Innerinner1 new]
                my add [::SpiceGenTcl::Ngspice::BasicDevices::R new 3 in c -r 30 -beh]
                set pins {in out}
                set params {}
                next inner1 $pins $params
            }
        }
        my add [Inner1 new]
        my add [::SpiceGenTcl::Ngspice::BasicDevices::R new 2 in b -r 20 -beh]
        my add [::SpiceGenTcl::Ngspice::BasicDevices::R new 5 b out -r 40 -beh]
        set pins {in out}
        set params {}
        next middle1 $pins $params
    }
}
my add [Middle1 new]
oo::class create Middle2 {
    superclass ::SpiceGenTcl::Subcircuit
    constructor {} {
        oo::class create Inner2 {
            superclass ::SpiceGenTcl::Subcircuit
            constructor {} {
                
                my add [::SpiceGenTcl::Ngspice::BasicDevices::R new 7 in e -r 60 -beh]
                set pins {in out}
                set params {}
                next inner2 $pins $params
            }
        }
        my add [Inner2 new]
        oo::class create Inner1 {
            superclass ::SpiceGenTcl::Subcircuit
            constructor {} {
                
                my add [::SpiceGenTcl::Ngspice::BasicDevices::R new 8 in e -r 60 -beh]
                set pins {in out}
                set params {}
                next inner1 $pins $params
            }
        }
        my add [Inner1 new]
        my add [::SpiceGenTcl::Ngspice::BasicDevices::R new 6 in d -r 50 -beh]
        oo::class create R3Model {
            superclass ::SpiceGenTcl::Model
            constructor {name args} {
                set paramsNames [list tc1 tc2]
                next $name R3Model [my argsPreprocess $paramsNames {*}$args]
            }
        }
        my add [R3Model new res3mod -tc1 1 -tc2 2]
        my add [::SpiceGenTcl::Ngspice::BasicDevices::R new 9 d out -r 70 -beh]
        set pins {in out}
        set params {}
        next middle2 $pins $params
    }
}
my add [Middle2 new]
oo::class create Top {
    superclass ::SpiceGenTcl::Subcircuit
    constructor {} {
        oo::class create Middle1 {
            superclass ::SpiceGenTcl::Subcircuit
            constructor {} {
                oo::class create Inner1 {
                    superclass ::SpiceGenTcl::Subcircuit
                    constructor {} {
                        oo::class create Innerinner1 {
                            superclass ::SpiceGenTcl::Subcircuit
                            constructor {} {
                                
                                my add [::SpiceGenTcl::Ngspice::BasicDevices::R new 4 in c -r 30 -beh]
                                set pins {in out}
                                set params {}
                                next innerinner1 $pins $params
                            }
                        }
                        my add [Innerinner1 new]
                        my add [::SpiceGenTcl::Ngspice::BasicDevices::R new 3 in c -r 30 -beh]
                        set pins {in out}
                        set params {}
                        next inner1 $pins $params
                    }
                }
                my add [Inner1 new]
                my add [::SpiceGenTcl::Ngspice::BasicDevices::R new 2 in b -r 20 -beh]
                my add [::SpiceGenTcl::Ngspice::BasicDevices::R new 5 b out -r 40 -beh]
                set pins {in out}
                set params {}
                next middle1 $pins $params
            }
        }
        my add [Middle1 new]
        oo::class create Middle2 {
            superclass ::SpiceGenTcl::Subcircuit
            constructor {} {
                oo::class create Inner2 {
                    superclass ::SpiceGenTcl::Subcircuit
                    constructor {} {
                        
                        my add [::SpiceGenTcl::Ngspice::BasicDevices::R new 7 in e -r 60 -beh]
                        set pins {in out}
                        set params {}
                        next inner2 $pins $params
                    }
                }
                my add [Inner2 new]
                oo::class create Inner1 {
                    superclass ::SpiceGenTcl::Subcircuit
                    constructor {} {
                        
                        my add [::SpiceGenTcl::Ngspice::BasicDevices::R new 8 in e -r 60 -beh]
                        set pins {in out}
                        set params {}
                        next inner1 $pins $params
                    }
                }
                my add [Inner1 new]
                my add [::SpiceGenTcl::Ngspice::BasicDevices::R new 6 in d -r 50 -beh]
                oo::class create R3Model {
                    superclass ::SpiceGenTcl::Model
                    constructor {name args} {
                        set paramsNames [list tc1 tc2]
                        next $name R3Model [my argsPreprocess $paramsNames {*}$args]
                    }
                }
                my add [R3Model new res3mod -tc1 1 -tc2 2]
                my add [::SpiceGenTcl::Ngspice::BasicDevices::R new 9 d out -r 70 -beh]
                set pins {in out}
                set params {}
                next middle2 $pins $params
            }
        }
        my add [Middle2 new]
        my add [::SpiceGenTcl::Ngspice::BasicDevices::R new 1 in a -r 10 -beh]
        my add [::SpiceGenTcl::Ngspice::BasicDevices::R new 10 a out -r 80 -beh]
        set pins {in out}
        set params {}
        next top $pins $params
    }
}
Top new
