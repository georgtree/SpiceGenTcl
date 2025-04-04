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


test testRawFileClass-1 {test creation of RawFile class instance and getDataCsv interface} -setup {
    set circuit [Circuit new {voltage divider netlist}]
    $circuit add [Vdc new 1 in 0 -dc 1]
    $circuit add [R new 1 in out -r 1e3]
    $circuit add [R new 2 out 0 -r 2e3]
    $circuit add [Dc new -src v1 -start 0 -stop 5 -incr 1]
    set simulator [Batch new {batch1}]
    $circuit configure -simulator $simulator
    $circuit runAndRead
    set dataObj [$circuit configure -data]
} -body {
    set data [$dataObj getTracesCsv -all]
    set rawObj [$simulator configure -data]
    $rawObj measure -trig {-vec v(1) -val 2 -rise 1} -targ {-vec v(2) -val 2 -cross 1}
    $rawObj measure -find v(1) -when {-vec v(2) -val 2 -cross 1}
    $rawObj measure -when {-vec v(2) -val 2 -cross 1}
    $rawObj measure -when {-vec1 v(2) -vec2 v(3) -cross 1}
    $rawObj measure -find v(1) -when {-vec1 v(2) -vec2 v(3) -cross 1}
    $rawObj measure -find v(1) -at 1u
    return $data
} -result {v(v-sweep),v(in),v(out),i(v1)
0.0,0.0,0.0,0.0
1.0,1.0,0.6666666666666666,-0.0003333333333333334
2.0,2.0,1.3333333333333333,-0.0006666666666666668
3.0,3.0,2.0,-0.001
4.0,4.0,2.6666666666666665,-0.0013333333333333335
5.0,5.0,3.333333333333333,-0.001666666666666667
} -cleanup {
    unset circuit data simulator dataObj
}
