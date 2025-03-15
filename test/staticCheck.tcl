package require SpiceGenTcl

set currentDir [file dirname [file normalize [info script]]]
global env
if {[string match -nocase *linux* $tcl_platform(os)]} {
    set nagelfarPath "/home/$env(USER)/tcl/nagelfar/nagelfar.tcl"
} elseif {[string match -nocase "*windows nt*" $tcl_platform(os)]} {
    set nagelfarPath "C:\\msys64\\home\\georgtree1\\nagelfar\\nagelfar.tcl"
}

set srcList {generalClasses.tcl specElementsClassesCommon.tcl specAnalysesClassesCommon.tcl\
                     {ngspice specAnalysesClassesNgspice.tcl} {ngspice specElementsClassesNgspice.tcl}\
                     {ngspice specModelsClassesNgspice.tcl} {ngspice specSimulatorClassesNgspice.tcl}\
                     {ngspice netlistParserClassNgspice.tcl}\
                     {xyce specAnalysesClassesXyce.tcl} {xyce specElementsClassesXyce.tcl}\
                     {xyce specModelsClassesXyce.tcl} {xyce specSimulatorClassesXyce.tcl}\
                     {ltspice specAnalysesClassesLtspice.tcl} {ltspice specElementsClassesLtspice.tcl}\
                     {ltspice specModelsClassesLtspice.tcl} {ltspice specSimulatorClassesLtspice.tcl}}
set dbPath [file join $currentDir syntaxdb.tcl]
foreach file $srcList {
    lappend paths [file normalize [file join $currentDir .. src {*}$file]]
}

puts [exec {*}[list tclsh $nagelfarPath -s $dbPath {*}$paths]]
