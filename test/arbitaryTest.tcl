package require tcltest
namespace import ::tcltest::*
package require SpiceGenTcl
namespace import ::SpiceGenTcl::*
importLtspice


###  Basic devices tests 

####  Resistor class tests 
    
test testResistorClass-1 {test Resistor class} -setup {
    set res [Resistor new 1 netp netm -r 1e3 -tc1 1 -temp 25]
} -body {
    set result [$res genSPICEString]
} -result "r1 netp netm 1e3 tc1=1 temp=25" -cleanup {
    unset res result
}

test testResistorClass-2 {test Resistor class} -setup {
    set res [Resistor new 1 netp netm -r 1e3]
} -body {
    set result [$res genSPICEString]
} -result "r1 netp netm 1e3" -cleanup {
    unset res result
}

test testResistorClass-3 {test Resistor class with equation positional parameter} -setup {
    set res [Resistor new 1 netp netm -r {{6*x+y} -eq}]
} -body {
    set result [$res genSPICEString]
} -result "r1 netp netm \{6*x+y\}" -cleanup {
    unset res result
}

test testResistorClass-4 {test Resistor class with equation positional parameter and combination of normal and equation parameters} -setup {
    set res [Resistor new 1 netp netm -r {{6*x+y} -eq} -tc1 7 -tc2 {"x^2" -eq}]
} -body {
    set result [$res genSPICEString]
} -result "r1 netp netm \{6*x+y\} tc1=7 tc2=\{x^2\}" -cleanup {
    unset res result
}

test testRClass-5 {test R alias for Resistor class} -setup {
    set res [R new 1 netp netm -r 1e3 -tc1 1 -temp 25]
} -body {
    set result [$res genSPICEString]
} -result "r1 netp netm 1e3 tc1=1 temp=25" -cleanup {
    unset res result
}  
      
test testRClass-6 {test R alias for Resistor class with model switch} -setup {
    set res [R new 1 netp netm -r 1 -temp 25]
} -body {
    set result [$res genSPICEString]
} -result "r1 netp netm 1 temp=25" -cleanup {
    unset res result
} 

####  Capacitor class tests 
    
test testCapacitorClass-1 {test Capacitor class} -setup {
    set cap [Capacitor new 1 netp netm -c 1e-6 -temp 25]
} -body {
    set result [$cap genSPICEString]
} -result "c1 netp netm 1e-6 temp=25" -cleanup {
    unset cap result
}

test testCapacitorClass-2 {test Capacitor class} -setup {
    set cap [Capacitor new 1 netp netm -c 1e-6]
} -body {
    set result [$cap genSPICEString]
} -result "c1 netp netm 1e-6" -cleanup {
    unset cap result
}

test testCapacitorClass-3 {test Capacitor class witch C behavioural equation} -setup {
    set cap [Capacitor new 1 netp netm -q "V(a)+V(b)+pow(V(c),2)"]
} -body {
    set result [$cap genSPICEString]
} -result "c1 netp netm q={V(a)+V(b)+pow(V(c),2)}" -cleanup {
    unset cap result
}
       
test testCapacitorClass-4 {test Capacitor class with Q behavioural equation} -setup {
    set cap [Capacitor new 1 netp netm -q "V(a)+V(b)+pow(V(c),2)"]
} -body {
    set result [$cap genSPICEString]
} -result "c1 netp netm q={V(a)+V(b)+pow(V(c),2)}" -cleanup {
    unset cap result
}         

test testCapacitorClass-7 {test Capacitor class without capacitance value, error generated} -body {
    catch {Capacitor new 1 netp netm} errorStr
    return $errorStr
} -result "Capacitor value must be specified with '-c value'" -cleanup {
    unset errorStr
} 

####  Inductor class tests 
    
test testInductorClass-1 {test Inductor class} -setup {
    set ind [Inductor new 1 netp netm -l 1e-6 -tc1 1 -temp 25]
} -body {
    set result [$ind genSPICEString]
} -result "l1 netp netm 1e-6 tc1=1 temp=25" -cleanup {
    unset ind result
}

test testInductorClass-2 {test Inductor class} -setup {
    set ind [Inductor new 1 netp netm -l 1e-6]
} -body {
    set result [$ind genSPICEString]
} -result "l1 netp netm 1e-6" -cleanup {
    unset ind result
}

test testInductorClass-5 {test Inductor class with beh switch} -setup {
    set ind [Inductor new 1 netp netm -flux "V(a)+V(b)+pow(V(c),2)" -tc1 1]
} -body {
    set result [$ind genSPICEString]
} -result "l1 netp netm flux={V(a)+V(b)+pow(V(c),2)} tc1=1" -cleanup {
    unset ind result
} 

test testInductorClass-6 {test Inductor class with beh switch with different arguments order} -setup {
    set ind [Inductor new 1 netp netm -tc1 1 -flux "V(a)+V(b)+pow(V(c),2)" ]
} -body {
    set result [$ind genSPICEString]
} -result "l1 netp netm flux={V(a)+V(b)+pow(V(c),2)} tc1=1" -cleanup {
    unset ind result
}

test testInductorClass-7 {test Inductor class with l as equation} -setup {
    set ind [Inductor new 1 netp netm -l "l1*l2 -eq" -tc1 1]
} -body {
    set result [$ind genSPICEString]
} -result "l1 netp netm {l1*l2} tc1=1" -cleanup {
    unset ind result
}

test testInductorClass-8 {test Inductor class with l as equation} -setup {
    set ind [Inductor new 1 netp netm -l "l1*l2 -eq" -tc1 1]
} -body {
    set result [$ind genSPICEString]
} -result "l1 netp netm {l1*l2} tc1=1" -cleanup {
    unset ind result
}

test testInductorClass-9 {test Inductor class without specified l, error generated} -setup {
    catch {Inductor new 1 netp netm -tc1 1} errorStr
} -body {
    return $errorStr
} -result "Inductor value must be specified with '-l value'" -cleanup {
    unset errorStr
}

test testInductorClass-9 {test Inductor class with hysteresis} -setup {
    set ind [Inductor new 1 netp netm -hyst -tc1 1 -hc 10 -bs 0.4 -br 0.1 -a 1e-6 -lm 0.02 -lg 0.0007 -n 1000]
} -body {
    set result [$ind genSPICEString]
} -result "l1 netp netm tc1=1 hc=10 bs=0.4 br=0.1 a=1e-6 lm=0.02 lg=0.0007 n=1000" -cleanup {
    unset ind result
}

test testInductorClass-9 {test Inductor class with hysteresis} -body {
    catch {set ind [Inductor new 1 netp netm -tc1 1 -hc 10]} errorStr
    return $errorStr
} -result "-hc requires -hyst" -cleanup {
    unset errorStr
}

####  L class tests

test testLClass-1 {test L alias for Inductor class} -setup {
    set ind [L new 1 netp netm -l 1e-6 -tc1 1 -temp 25]
} -body {
    set result [$ind genSPICEString]
} -result "l1 netp netm 1e-6 tc1=1 temp=25" -cleanup {
    unset ind result
}
  
test testLClass-1 {test L alias for Inductor class with beh switch} -setup {
    set ind [L new 1 netp netm -flux "V(a)+V(b)+pow(V(c),2)" -tc1 1]
} -body {
    set result [$ind genSPICEString]
} -result "l1 netp netm flux={V(a)+V(b)+pow(V(c),2)} tc1=1" -cleanup {
    unset ind result
}

####  VSwitch class tests 
    
test testVSwitchClass-1 {test VSwitch class} -setup {
    set vsw [VSwitch new 1 net1 0 netc 0 -model sw1 -on]
} -body {
    set result [$vsw genSPICEString]
} -result "s1 net1 0 netc 0 sw1 on" -cleanup {
    unset vsw result
}

test testVSwitchClass-2 {test VSwitch class} -setup {
    set vsw [VSwitch new 1 net1 0 netc 0 -model sw1]
} -body {
    set result [$vsw genSPICEString]
} -result "s1 net1 0 netc 0 sw1" -cleanup {
    unset vsw result
}

test testVSwitchClass-3 {test VSwitch class with different arguments order} -setup {
    set vsw [VSwitch new 1 net1 0 netc 0 -on -model sw1]
} -body {
    set result [$vsw genSPICEString]
} -result "s1 net1 0 netc 0 sw1 on" -cleanup {
    unset vsw result
}

test testVSwitchClass-4 {test VSwitch class} -body {
    catch {set vsw [VSwitch new 1 net1 0 netc 0 -model sw1 -on -off]} errorStr
    return $errorStr
} -result "-on conflicts with -off" -cleanup {
    unset errorStr
}

test testVSwitchClass-5 {test VSwitch class} -setup {
    set vsw [VSwitch new 1 net1 0 netc 0 -model sw1 -off]
} -body {
    set result [$vsw genSPICEString]
} -result "s1 net1 0 netc 0 sw1 off" -cleanup {
    unset vsw result
}

####  CSwitch class tests 
    
test testCSwitchClass-1 {test CSwitch class} -setup {
    set csw [CSwitch new 1 net1 0 -icntrl v1 -model sw1 -on]
} -body {
    set result [$csw genSPICEString]
} -result "w1 net1 0 v1 sw1 on" -cleanup {
    unset csw result
}

test testCSwitchClass-2 {test CSwitch class} -setup {
    set csw [CSwitch new 1 net1 0 -icntrl v1 -model sw1]
} -body {
    set result [$csw genSPICEString]
} -result "w1 net1 0 v1 sw1" -cleanup {
    unset csw result
}

test testCSwitchClass-3 {test CSwitch class} -setup {
    set csw [CSwitch new 1 net1 0 -icntrl v1 -model sw1 -off]
} -body {
    set result [$csw genSPICEString]
} -result "w1 net1 0 v1 sw1 off" -cleanup {
    unset csw result
}

####  W class tests

test testWClass-2 {test CSwitch class alias} -setup {
    set csw [W new 1 net1 0 -icntrl v1 -model sw1]
} -body {
    set result [$csw genSPICEString]
} -result "w1 net1 0 v1 sw1" -cleanup {
    unset csw result
}

###  Sources classes tests 
    
####  Vdc class test 

test testVdcClass-1 {test Vdc class} -setup {
    set vdc [Vdc new 1 netp netm -dc 10]
} -body {
    set result [$vdc genSPICEString]
} -result "v1 netp netm 10" -cleanup {
    unset vdc result
}

test testVdcClass-2 {test Vdc class} -setup {
    set vdc [Vdc new 1 netp netm -dc {vnom -eq} -rser 0.01]
} -body {
    set result [$vdc genSPICEString]
} -result "v1 netp netm {vnom} rser=0.01" -cleanup {
    unset vdc result
}

####  Vac class test 

test testVacClass-1 {test Vac class} -setup {
    set vac [Vac new 1 netp netm -ac 10 -cpar 1e-12]
} -body {
    set result [$vac genSPICEString]
} -result "v1 netp netm 0 ac 10 cpar=1e-12" -cleanup {
    unset vac result
}

test testVacClass-2 {test Vac class} -setup {
    set vac [Vac new 1 netp netm -dc 1 -ac 10]
} -body {
    set result [$vac genSPICEString]
} -result "v1 netp netm 1 ac 10" -cleanup {
    unset vac result
}

test testVacClass-4 {test Vac class} -setup {
    set vac [Vac new 1 netp netm -ac {acmag -eq}]
} -body {
    set result [$vac genSPICEString]
} -result "v1 netp netm 0 ac {acmag}" -cleanup {
    unset vac result
}

####  Vpulse class test 

test testVpulseClass-1 {test Vpulse class} -setup {
    set vpulse [Vpulse new 1 net1 net2 -voff 0 -von 1 -td 1e-9 -tr 1e-9 -tf 1e-9 -pw 10e-6 -per 20e-6 -np 10]
} -body {
    set result [$vpulse genSPICEString]
} -result "v1 net1 net2 pulse 0 1 1e-9 1e-9 1e-9 10e-6 20e-6 10" -cleanup {
    unset vpulse result
}

test testVpulseClass-2 {test Vpulse class} -setup {
    set vpulse [Vpulse new 1 net1 net2 -voff 0 -von 1 -td 1e-9 -tr 1e-9 -tf 1e-9 -pw 10e-6 -per 20e-6]
} -body {
    set result [$vpulse genSPICEString]
} -result "v1 net1 net2 pulse 0 1 1e-9 1e-9 1e-9 10e-6 20e-6" -cleanup {
    unset vpulse result
}

test testVpulseClass-3 {test Vpulse class} -setup {
    set vpulse [Vpulse new 1 net1 net2 -low 0 -high 1 -td {td -eq} -tr 1e-9 -tf 1e-9 -pw 10e-6 -per 20e-6]
} -body {
    set result [$vpulse genSPICEString]
} -result "v1 net1 net2 pulse 0 1 \{td\} 1e-9 1e-9 10e-6 20e-6" -cleanup {
    unset vpulse result
}

test testVpulseClass-4 {test Vpulse class} -setup {
    set vpulse [Vpulse new 1 net1 net2 -low 0 -high 1 -td {td -eq} -tr 1e-9 -tf 1e-9 -ton 10e-6 -tper 20e-6 -np {np -eq}]
} -body {
    set result [$vpulse genSPICEString]
} -result "v1 net1 net2 pulse 0 1 {td} 1e-9 1e-9 10e-6 20e-6 \{np\}" -cleanup {
    unset vpulse result
}

test testVpulseClass-5 {test Vpulse class with different order} -setup {
    set vpulse [Vpulse new 1 net1 net2 -tf 1e-9 -pw 10e-6 -per 20e-6 -np 10 -low 0 -high 1 -td 1e-9 -tr 1e-9]
} -body {
    set result [$vpulse genSPICEString]
} -result "v1 net1 net2 pulse 0 1 1e-9 1e-9 1e-9 10e-6 20e-6 10" -cleanup {
    unset vpulse result
}

test testVpulseClass-6 {test Vpulse class} -body {
    catch {Vpulse new 1 net1 net2 -tf 1e-9 -pw 10e-6 -per 20e-6 -np 10 -high 1 -td 1e-9 -tr 1e-9} errorStr
    return $errorStr
} -result "-low, -voff or -ioff must be presented" -cleanup {
    unset errorStr
}

test testVpulseClass-7 {test Vpulse class} -body {
    catch {Vpulse new 1 net1 net2 -tf 1e-9 -pw 10e-6 -per 20e-6 -voff 0 -np 10 -td 1e-9 -tr 1e-9} errorStr
    return $errorStr
} -result "-high, -von or -ion must be presented" -cleanup {
    unset errorStr
}
