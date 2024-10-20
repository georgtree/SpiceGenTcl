lappend auto_path "../"
package require tcltest
package require SpiceGenTcl
namespace import ::tcltest::*
namespace import ::SpiceGenTcl::*
set ngspiceNameSpc [namespace children ::SpiceGenTcl::Xyce]
foreach nameSpc $ngspiceNameSpc {
    namespace import ${nameSpc}::*
}


test testBjtClass-1.2 {test Bjt class} -setup {
    set bjt [Bjt new 1 netc netb nete -model bjtmod -ns nets -area 1e-3]
} -body {
    set result [$bjt genSPICEString]
} -result "q1 netc netb nete nets bjtmod area=1e-3 temp=25" -cleanup {
    unset bjt result
}