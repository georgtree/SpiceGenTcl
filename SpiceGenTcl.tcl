package require textutil::split
namespace import ::tcl::mathop::*

package provide SpiceGenTcl 0.1

set dir [file dirname [file normalize [info script]]]
lappend auto_path "${dir}/lib"
package require argparse
set sourceDir "${dir}/src"

#source [file join $sourceDir argparse.tcl]
source [file join $sourceDir generalClasses.tcl]
source [file join $sourceDir ngspice/specElementsClasses.tcl]
source [file join $sourceDir ngspice/specAnalysesClasses.tcl]
source [file join $sourceDir ngspice/specModelsClasses.tcl]
source [file join $sourceDir ngspice/specSimulatorClasses.tcl]