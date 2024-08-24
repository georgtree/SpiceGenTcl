proc linspace {{from 0} {to 1} {step .1} {prec 1}} {
    if {$step < 0} {
        set op ::tcl::mathop::>
    } else {
        set op ::tcl::mathop::<
    }
    for {set n $from} {[$op $n $to]} {set n [expr {$n + $step}]} {
        lappend res [format %.*f $prec $n]
    }
    return $res 
}