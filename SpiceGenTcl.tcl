#  .|'''.|            ||                   ..|'''.|                   |''||''|         '||' 
#  ||..  '  ... ...  ...    ....    ....  .|'     '    ....  .. ...      ||      ....   ||  
#   ''|||.   ||'  ||  ||  .|   '' .|...|| ||    .... .|...||  ||  ||     ||    .|   ''  ||  
# .     '||  ||    |  ||  ||      ||      '|.    ||  ||       ||  ||     ||    ||       ||  
# |'....|'   ||...'  .||.  '|...'  '|...'  ''|...'|   '|...' .||. ||.   .||.    '|...' .||. 
#            ||                                                                             
#           ''''                                                                            
# SpiceGenTcl.tcl
# Main file of SpiceGenTcl package
#
# Copyright (c) 2024 George Yashin, georgtree@gmail.com
#
# MIT License
# See the file "LICENSE.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

package require Tcl 9.0-
package require textutil::split
package require struct::tree
package require struct::list
package require csv
namespace import ::tcl::mathop::*

package provide SpiceGenTcl 0.70

set dir [file dirname [file normalize [info script]]]
set libDir [file join $dir lib]
lappend auto_path $libDir
set sourceDir [file join $dir src]

source [file join $libDir argparse argparse.tcl]
source [file join $libDir extexpr extexpr.tcl]
source [file join $libDir measure measure.tcl]
source [file join $sourceDir aliases.tcl]
source [file join $sourceDir generalClasses.tcl]
source [file join $sourceDir specElementsClassesCommon.tcl]
source [file join $sourceDir specAnalysesClassesCommon.tcl]
source [file join $sourceDir ngspice specElementsClassesNgspice.tcl]
source [file join $sourceDir ngspice specAnalysesClassesNgspice.tcl]
source [file join $sourceDir ngspice specModelsClassesNgspice.tcl]
source [file join $sourceDir ngspice specSimulatorClassesNgspice.tcl]
source [file join $sourceDir ngspice specMiscClassesNgspice.tcl]
source [file join $sourceDir ngspice netlistParserClassNgspice.tcl]
source [file join $sourceDir xyce specAnalysesClassesXyce.tcl]
source [file join $sourceDir xyce specElementsClassesXyce.tcl]
source [file join $sourceDir xyce specModelsClassesXyce.tcl]
source [file join $sourceDir xyce specSimulatorClassesXyce.tcl]
source [file join $sourceDir ltspice specAnalysesClassesLtspice.tcl]
source [file join $sourceDir ltspice specElementsClassesLtspice.tcl]
source [file join $sourceDir ltspice specModelsClassesLtspice.tcl]
source [file join $sourceDir ltspice specSimulatorClassesLtspice.tcl]
