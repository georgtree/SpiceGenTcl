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

test testRawFileClass-2 {test creation of RawFile class instance and getDataCsv interface} -setup {
    set circuit [Circuit new {voltage divider netlist}]
    $circuit add [Vdc new 1 in 0 -dc 1]
    $circuit add [R new 1 in out -r 1e3]
    $circuit add [R new 2 out 0 -r 2e3]
    $circuit add [Dc new -src v1 -start 0 -stop 5 -incr 1]
    set simulator [Batch new {batch1}]
    $circuit configure -simulator $simulator
    $circuit runAndRead -vector
    set dataObj [$circuit configure -data]
} -body {
    set vectors  [$dataObj getTracesData]
    puts [[dict get $vectors v(v-sweep)] index :]
    set data [$dataObj getTracesCsv -all -sep ,,]
    return $data
} -result {v(v-sweep),,v(in),,v(out),,i(v1)
0.0,,0.0,,0.0,,0.0
1.0,,1.0,,0.6666666666666666,,-0.0003333333333333334
2.0,,2.0,,1.3333333333333333,,-0.0006666666666666668
3.0,,3.0,,2.0,,-0.001
4.0,,4.0,,2.6666666666666665,,-0.0013333333333333335
5.0,,5.0,,3.333333333333333,,-0.001666666666666667
} -cleanup {
    unset circuit data simulator dataObj
}

test testRawFileClass-9 {} -setup {
    set data [RawFile new -vector "${currentDir}/ngspice/raw_data_ngspice/tran.raw"]
} -body {
    return [$data measure -find v(osc_out) -when {-vec v(osc_out) -val 0.5 -rise 3}]
} -result 0.4999999999999959 -cleanup {
    unset data
}
