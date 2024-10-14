lappend auto_path "../"
package require tcltest
package require SpiceGenTcl
namespace import ::tcltest::*
namespace import ::SpiceGenTcl::*
set ngspiceNameSpc [namespace children ::SpiceGenTcl::Ngspice]
foreach nameSpc $ngspiceNameSpc {
    namespace import ${nameSpc}::*
}

    
       
    ## ________________________ Inductor class tests _________________________ ##
    
test testInductorClass-1.1 {test Inductor class} -setup {
    set ind [Inductor new 1 netp netm -l 1e-6 -tc1 1 -temp 25]
} -body {
    set result [$ind genSPICEString]
} -result "l1 netp netm 1e-6 tc1=1 temp=25" -cleanup {
    unset ind result
}

test testInductorClass-1.2 {test Inductor class} -setup {
    set ind [Inductor new 1 netp netm -l 1e-6]
} -body {
    set result [$ind genSPICEString]
} -result "l1 netp netm 1e-6" -cleanup {
    unset ind result
}

test testInductorClass-1.3 {test Inductor class with model switch} -setup {
    set ind [Inductor new 1 netp netm -l 1e-6 -model indm]
} -body {
    set result [$ind genSPICEString]
} -result "l1 netp netm 1e-6 indm" -cleanup {
    unset ind result
}

test testInductorClass-1.4 {test Inductor class with model switch} -setup {
    set ind [Inductor new 1 netp netm -model indm]
} -body {
    set result [$ind genSPICEString]
} -result "l1 netp netm indm" -cleanup {
    unset ind result
}

test testInductorClass-1.1 {test Inductor class with beh switch} -setup {
    set ind [Inductor new 1 netp netm -l "V(a)+V(b)+pow(V(c),2)" -beh -tc1 1]
} -body {
    set result [$ind genSPICEString]
} -result "l1 netp netm l={V(a)+V(b)+pow(V(c),2)} tc1=1" -cleanup {
    unset ind result
} 

test testLClass-1.1 {test L alias for Inductor class} -setup {
    set ind [L new 1 netp netm -l 1e-6 -tc1 1 -temp 25]
} -body {
    set result [$ind genSPICEString]
} -result "l1 netp netm 1e-6 tc1=1 temp=25" -cleanup {
    unset ind result
}
  
test testLClass-1.1 {test L alias for Inductor class with beh switch} -setup {
    set ind [L new 1 netp netm -l "V(a)+V(b)+pow(V(c),2)" -beh -tc1 1]
} -body {
    set result [$ind genSPICEString]
} -result "l1 netp netm l={V(a)+V(b)+pow(V(c),2)} tc1=1" -cleanup {
    unset ind result
}

cleanupTests
