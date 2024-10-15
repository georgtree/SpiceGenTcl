lappend auto_path "../"
package require tcltest
package require SpiceGenTcl
namespace import ::tcltest::*
namespace import ::SpiceGenTcl::*
set ngspiceNameSpc [namespace children ::SpiceGenTcl::Ngspice]
foreach nameSpc $ngspiceNameSpc {
    namespace import ${nameSpc}::*
}

    
    ## ________________________ Vpulse class test _________________________ ##

test testVpulseClass-1.1 {test Vpulse class} -setup {
    set vpulse [Vpulse new 1 net1 net2 -low 0 -high 1 -td 1e-9 -tr 1e-9 -tf 1e-9 -pw 10e-6 -per 20e-6 -np 10]
} -body {
    set result [$vpulse genSPICEString]
} -result "v1 net1 net2 pulse 0 1 1e-9 1e-9 1e-9 10e-6 20e-6 10" -cleanup {
    unset vpulse result
}

test testVpulseClass-1.2 {test Vpulse class} -setup {
    set vpulse [Vpulse new 1 net1 net2 -low 0 -high 1 -td 1e-9 -tr 1e-9 -tf 1e-9 -pw 10e-6 -per 20e-6]
} -body {
    set result [$vpulse genSPICEString]
} -result "v1 net1 net2 pulse 0 1 1e-9 1e-9 1e-9 10e-6 20e-6" -cleanup {
    unset vpulse result
}

test testVpulseClass-1.3 {test Vpulse class} -setup {
    set vpulse [Vpulse new 1 net1 net2 -low 0 -high 1 -td {td -eq} -tr 1e-9 -tf 1e-9 -pw 10e-6 -per 20e-6]
} -body {
    set result [$vpulse genSPICEString]
} -result "v1 net1 net2 pulse 0 1 \{td\} 1e-9 1e-9 10e-6 20e-6" -cleanup {
    unset vpulse result
}

test testVpulseClass-1.4 {test Vpulse class} -setup {
    set vpulse [Vpulse new 1 net1 net2 -low 0 -high 1 -td {td -eq} -tr 1e-9 -tf 1e-9 -pw 10e-6 -per 20e-6 -np {np -eq}]
} -body {
    set result [$vpulse genSPICEString]
} -result "v1 net1 net2 pulse 0 1 {td} 1e-9 1e-9 10e-6 20e-6 \{np\}" -cleanup {
    unset vpulse result
}

test testVpulseClass-1.5 {test Vpulse class with different order} -setup {
    set vpulse [Vpulse new 1 net1 net2 -tf 1e-9 -pw 10e-6 -per 20e-6 -np 10 -low 0 -high 1 -td 1e-9 -tr 1e-9]
} -body {
    set result [$vpulse genSPICEString]
} -result "v1 net1 net2 pulse 0 1 1e-9 1e-9 1e-9 10e-6 20e-6 10" -cleanup {
    unset vpulse result
}

    ## ________________________ Vsin class test _________________________ ##


test testVsinClass-1.1 {test Vsin class} -setup {
    set vsin [Vsin new 1 net1 net2 -v0 0 -va 2 -freq 50 -td 1e-6]
} -body {
    set result [$vsin genSPICEString]
} -result "v1 net1 net2 sin 0 2 50 1e-6" -cleanup {
    unset vsin result
}

test testVsinClass-1.2 {test Vsin class} -setup {
    set vsin [Vsin new 1 net1 net2 -v0 0 -va 2 -freq 50 -td 1e-6 -theta {theta -eq}]
} -body {
    set result [$vsin genSPICEString]
} -result "v1 net1 net2 sin 0 2 50 1e-6 \{theta\}" -cleanup {
    unset vsin result
}

test testVsinClass-1.3 {test Vsin class} -setup {
    set vsin [Vsin new 1 net1 net2 -v0 0 -va 2 -freq {freq -eq} -td 1e-6 -theta {theta -eq}]
} -body {
    set result [$vsin genSPICEString]
} -result "v1 net1 net2 sin 0 2 \{freq\} 1e-6 \{theta\}" -cleanup {
    unset vsin result
}

test testVsinClass-1.4 {test Vsin class} -setup {
    set vsin [Vsin new 1 net1 net2 -v0 0 -va 2 -freq 50]
} -body {
    set result [$vsin genSPICEString]
} -result "v1 net1 net2 sin 0 2 50" -cleanup {
    unset vsin result
}

test testVsinClass-1.5 {test Vsin class with different order} -setup {
    set vsin [Vsin new 1 net1 net2 -v0 0 -theta {theta -eq} -va 2 -freq 50 -td 1e-6 ]
} -body {
    set result [$vsin genSPICEString]
} -result "v1 net1 net2 sin 0 2 50 1e-6 \{theta\}" -cleanup {
    unset vsin result
}

    ## ________________________ Vexp class test _________________________ ##

test testVexpClass-1.1 {test Vexp class} -setup {
    set vexp [Vexp new 1 net1 net2 -v1 0 -v2 1 -td1 1e-9 -tau1 1e-9 -td2 1e-9 -tau2 10e-6]
} -body {
    set result [$vexp genSPICEString]
} -result "v1 net1 net2 exp 0 1 1e-9 1e-9 1e-9 10e-6" -cleanup {
    unset vexp result
}
    
test testVexpClass-1.2 {test Vexp class} -setup {
    set vexp [Vexp new 1 net1 net2 -v1 0 -v2 1 -td1 1e-9 -tau1 1e-9 -td2 {td2 -eq} -tau2 10e-6]
} -body {
    set result [$vexp genSPICEString]
} -result "v1 net1 net2 exp 0 1 1e-9 1e-9 \{td2\} 10e-6" -cleanup {
    unset vexp result
}

test testVexpClass-1.3 {test Vexp class with different order} -setup {
    set vexp [Vexp new 1 net1 net2 -v1 0 -tau1 1e-9 -v2 1 -td2 1e-9 -td1 1e-9 -tau2 10e-6]
} -body {
    set result [$vexp genSPICEString]
} -result "v1 net1 net2 exp 0 1 1e-9 1e-9 1e-9 10e-6" -cleanup {
    unset vexp result
}
    
    ## ________________________ Vpwl class test _________________________ ##

test testVpwlClass-1.1 {test Vpwl class} -setup {
    set vpwl [Vpwl new 1 npNode nmNode -seq {0 0 {t1 -eq} 1 2 2 3 3 4 4}]
} -body {
    set result [$vpwl genSPICEString]
} -result "v1 npnode nmnode pwl 0 0 \{t1\} 1 2 2 3 3 4 4" -cleanup {
    unset vpwl result
}  
    
test testVpwlClass-1.2 {test Vpwl class} -setup {
    catch {Vpwl new 1 npNode nmNode -seq {0 0 {t1 -eq} 1 2 2 3 3 4}} errorStr
} -body {
    return $errorStr
} -result "Number of elements '9' in pwl sequence is odd in element 'v1', must be even" -cleanup {
    unset errorStr
}

test testVpwlClass-1.3 {test Vpwl class} -setup {
    catch {Vpwl new 1 npNode nmNode -seq {0 0}} errorStr
} -body {
    return $errorStr
} -result "Number of elements '2' in pwl sequence in element 'v1' must be >=4" -cleanup {
    unset errorStr
}

    ## ________________________ Vsffm class test _________________________ ##
                
test testVsffmClass-1.1 {test Vsffm class} -setup {
    set vsffm [Vsffm new 1 net1 net2 -v0 0 -va 1 -fc 1e6 -mdi 0 -fs 1e3 -phasec 45]
} -body {
    set result [$vsffm genSPICEString]
} -result "v1 net1 net2 sffm 0 1 1e6 0 1e3 45" -cleanup {
    unset vsffm result
}

test testVsffmClass-1.2 {test Vsffm class} -setup {
    set vsffm [Vsffm new 1 net1 net2 -v0 0 -va 1 -fc 1e6 -mdi 0 -fs 1e3 -phasec {phase -eq}]
} -body {
    set result [$vsffm genSPICEString]
} -result "v1 net1 net2 sffm 0 1 1e6 0 1e3 \{phase\}" -cleanup {
    unset vsffm result
}

test testVsffmClass-1.3 {test Vsffm class} -setup {
    set vsffm [Vsffm new 1 net1 net2 -v0 0 -va 1 -fc {freq -eq} -mdi 0 -fs 1e3 -phasec {phase -eq}]
} -body {
    set result [$vsffm genSPICEString]
} -result "v1 net1 net2 sffm 0 1 \{freq\} 0 1e3 \{phase\}" -cleanup {
    unset vsffm result
}

test testVsffmClass-1.4 {test Vsffm class} -setup {
    set vsffm [Vsffm new 1 net1 net2 -v0 0 -va 1 -fc 1e6 -mdi 0 -fs 1e3]
} -body {
    set result [$vsffm genSPICEString]
} -result "v1 net1 net2 sffm 0 1 1e6 0 1e3" -cleanup {
    unset vsffm result
}

test testVsffmClass-1.5 {test Vsffm class with different order} -setup {
    set vsffm [Vsffm new 1 net1 net2 -v0 0 -fs 1e3 -phasec {phase -eq} -va 1 -fc {freq -eq} -mdi 0]
} -body {
    set result [$vsffm genSPICEString]
} -result "v1 net1 net2 sffm 0 1 \{freq\} 0 1e3 \{phase\}" -cleanup {
    unset vsffm result
}

    ## ________________________ Vam class test _________________________ ##
                
test testVamClass-1.1 {test Vam class} -setup {
    set vam [Vam new 1 net1 net2 -v0 0 -va 2 -mf 1e3 -fc 5e3 -td 1e-6 -phases 45]
} -body {
    set result [$vam genSPICEString]
} -result "v1 net1 net2 am 0 2 1e3 5e3 1e-6 45" -cleanup {
    unset vam result
}

test testVamClass-1.2 {test Vam class} -setup {
    set vam [Vam new 1 net1 net2 -v0 0 -va 2 -mf 1e3 -fc 5e3 -td 1e-6 -phases {phase -eq}]
} -body {
    set result [$vam genSPICEString]
} -result "v1 net1 net2 am 0 2 1e3 5e3 1e-6 \{phase\}" -cleanup {
    unset vam result
}

test testVamClass-1.3 {test Vam class} -setup {
    set vam [Vam new 1 net1 net2 -v0 0 -va 2 -mf 1e3 -fc {freq -eq} -td 1e-6 -phases {phase -eq}]
} -body {
    set result [$vam genSPICEString]
} -result "v1 net1 net2 am 0 2 1e3 \{freq\} 1e-6 \{phase\}" -cleanup {
    unset vam result
}

test testVamClass-1.4 {test Vam class} -setup {
    set vam [Vam new 1 net1 net2 -v0 0 -va 2 -mf 1e3 -fc 5e3 -td 1e-6]
} -body {
    set result [$vam genSPICEString]
} -result "v1 net1 net2 am 0 2 1e3 5e3 1e-6" -cleanup {
    unset vam result
} 

test testVamClass-1.5 {test Vam class with different order} -setup {
    set vam [Vam new 1 net1 net2 -v0 0 -phases 45 -va 2 -mf 1e3 -td 1e-6 -fc 5e3]
} -body {
    set result [$vam genSPICEString]
} -result "v1 net1 net2 am 0 2 1e3 5e3 1e-6 45" -cleanup {
    unset vam result
}

cleanupTests
