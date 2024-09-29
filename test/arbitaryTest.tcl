lappend auto_path "../"
package require tcltest
package require SpiceGenTcl
namespace import ::tcltest::*
namespace import ::SpiceGenTcl::*
set ngspiceNameSpc [namespace children ::SpiceGenTcl::Ngspice]
foreach nameSpc $ngspiceNameSpc {
    namespace import ${nameSpc}::*
}



test testCSwitchClass-1.1 {test CSwitch class} -setup {
    set csw [CSwitch new 1 net1 0 v1 sw1 -on]
} -body {
    set result [$csw genSPICEString]
} -result "w1 net1 0 v1 sw1 on" -cleanup {
    unset csw result
}

test testCSwitchClass-1.2 {test CSwitch class} -setup {
    set csw [CSwitch new 1 net1 0 v1 sw1]
} -body {
    set result [$csw genSPICEString]
} -result "w1 net1 0 v1 sw1" -cleanup {
    unset csw result
}

cleanupTests
