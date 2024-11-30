lappend auto_path "../"
package require tcltest
package require SpiceGenTcl
namespace import ::tcltest::*
namespace import ::SpiceGenTcl::*
set ngspiceNameSpc [namespace children ::SpiceGenTcl::Ngspice]
foreach nameSpc $ngspiceNameSpc {
    namespace import ${nameSpc}::*
}

test testDcClass-2 {test Dc class} -setup {
    set res [Dc new -src v1 -start 0 -stop 5 -incr 0.1]
} -body {
    set result [$res genSPICEString]
} -result ".dc v1 0 5 0.1" -cleanup {
    unset res result
}
