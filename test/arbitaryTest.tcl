lappend auto_path "../"
package require tcltest
package require SpiceGenTcl
namespace import ::tcltest::*
namespace import ::SpiceGenTcl::*
set ngspiceNameSpc [namespace children ::SpiceGenTcl::Ngspice]
foreach nameSpc $ngspiceNameSpc {
    namespace import ${nameSpc}::*
}

set epsilon 1e-8
set rawDataLoc "./raw_data_ngspice"

proc matchList {expected actual} {
    variable epsilon
    set match 1
    set len [llength $expected]
    for {set i 0} {$i<$len} {incr i} {
        set exp [lindex $expected $i]
        set act [lindex $actual $i]
        if {(abs($act-$exp) > $epsilon) || (abs($act-$exp) > $epsilon)} {
            set match 0
            break
        }
    }
    return $match
}
    
    
proc readResultFile {path} {
    set file [open $path r+]
    set lines [split [read $file] "\n"]
    close $file                     
    foreach line $lines {
        set data [textutil::split::splitx [string trim $line]]
        lappend timeData [lindex $data 0]
        lappend traceData [lindex $data 1]
    }
    return [list $timeData $traceData]
}


    set data [RawFile new "${rawDataLoc}/tran_ascii.raw"]
    set traceTime [$data getTrace time]
    set trace [$data getTrace v(osc_out)]
    set refData [readResultFile "${rawDataLoc}/vosc.csv"]
    set timeData [$traceTime getDataPoints]
    set traceData [$trace getDataPoints]
puts $traceData
    set timeMatch [matchList [lrange [lindex $refData 0] 0 end-1] $timeData]
    set traceMatch [matchList [lrange [lindex $refData 1] 0 end-1] $traceData]
    if {$timeMatch && $traceMatch} {
        set result pass
    } else {
        set result fail
    }
