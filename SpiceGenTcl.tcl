package require Tcl 9.0
package require textutil::split
namespace import ::tcl::mathop::*

package provide SpiceGenTcl 0.1

set dir [file dirname [file normalize [info script]]]
set libDir "${dir}/lib"
lappend auto_path $libDir
set sourceDir "${dir}/src"

source [file join $libDir argparse argparse.tcl]
source [file join $sourceDir generalClasses.tcl]
source [file join $sourceDir ngspice specElementsClasses.tcl]
source [file join $sourceDir ngspice specAnalysesClasses.tcl]
source [file join $sourceDir ngspice specModelsClasses.tcl]
source [file join $sourceDir ngspice specSimulatorClasses.tcl]
#source [file join $sourceDir xyce specAnalysesClasses.tcl]