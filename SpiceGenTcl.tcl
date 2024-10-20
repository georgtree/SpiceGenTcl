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
source [file join $sourceDir specElementsClassesCommon.tcl]
source [file join $sourceDir ngspice specElementsClassesNgspice.tcl]
source [file join $sourceDir ngspice specAnalysesClassesNgspice.tcl]
source [file join $sourceDir ngspice specModelsClassesNgspice.tcl]
source [file join $sourceDir ngspice specSimulatorClassesNgspice.tcl]
source [file join $sourceDir xyce specAnalysesClassesXyce.tcl]
source [file join $sourceDir xyce specElementsClassesXyce.tcl]
source [file join $sourceDir xyce specModelsClassesXyce.tcl]
source [file join $sourceDir xyce specSimulatorClassesXyce.tcl]