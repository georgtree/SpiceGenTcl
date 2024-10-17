lappend auto_path "../"
package require tcltest
package require SpiceGenTcl
namespace import ::tcltest::*
namespace import ::SpiceGenTcl::*
set ngspiceNameSpc [namespace children ::SpiceGenTcl::Ngspice]
foreach nameSpc $ngspiceNameSpc {
    namespace import ${nameSpc}::*
}


