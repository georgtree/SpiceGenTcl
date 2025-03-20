proc matchList {expected actual} {
    variable epsilon
    set match 1
    set len [llength $expected]
    for {set i 0} {$i<$len} {incr i} {
        set exp [@ $expected $i]
        set act [@ $actual $i]
        if {abs($act-$exp) > $epsilon} {
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
        lappend timeData [@ $data 0]
        lappend traceData [@ $data 1]
    }
    return [list $timeData $traceData]
}

proc stdout2var {var} { 
    set level [info level]
    # we may have called stdout2var before so this allows only one variable at a time
    # and preserves tcls original puts in putsorig 
    if {[string length [info commands putsorig]]==0} { 
        rename ::puts ::putsorig
    } 
    eval [subst -nocommands {proc ::puts {args} { 
        set fd stdout 
        # args check 
        switch -exact -- [llength \$args] {
            1 { 
                set fd stdout
            } 
            2 { 
                if {![string equal \"-nonewline\" [lindex \$args 0]]} {
                    set fd [lindex \$args 0]
                }
            }
            3 {
                set fd [lindex \$args 1]
            }
            default { 
                error \"to many or too few args to puts must be at most 3 ( -nonewline fd message )\" 
            }
        }
        # only put stdout to the var 
        if {[string equal \"stdout\" \$fd ]} {
            # just level and var are subst 
            set message [lindex \$args end]
            uplevel [expr {[info level]-$level+1}] set $var \\\"\$message\\\"
        } else {
            # otherwise evaluate with tcls puts 
            eval ::putsorig \$args 
        }
    }}]
} 

proc restorestdout { } {
    # only do rename if putsorig exists incase restorestdout is call before stdout2var or 
    # if its called multiple times
    if {[string length [info commands putsorig]]!=0} { 
        rename ::puts {}
        rename ::putsorig ::puts 
    } 
}

proc testTemplate {testName descr createStr refStr} {
    test $testName $descr -body {
        if {[catch {set inst [{*}$createStr]} errorStr]} {
            return $errorStr
        } elseif {[catch {set result [$inst genSPICEString]} errorStr]} {
            return $errorStr
        } else {
            return $result
        }
    } -result $refStr
}


