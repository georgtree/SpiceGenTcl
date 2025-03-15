#  .|'''.|            ||                   ..|'''.|                   |''||''|         '||' 
#  ||..  '  ... ...  ...    ....    ....  .|'     '    ....  .. ...      ||      ....   ||  
#   ''|||.   ||'  ||  ||  .|   '' .|...|| ||    .... .|...||  ||  ||     ||    .|   ''  ||  
# .     '||  ||    |  ||  ||      ||      '|.    ||  ||       ||  ||     ||    ||       ||  
# |'....|'   ||...'  .||.  '|...'  '|...'  ''|...'|   '|...' .||. ||.   .||.    '|...' .||. 
#            ||                                                                             
#           ''''                                                                            
# codeCoverage.tcl
# File that runs code coverage by tests
#
# Copyright (c) 2024 George Yashin, georgtree@gmail.com
#
# MIT License
# See the file "LICENSE.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

interp alias {} dget {} dict get
interp alias {} @ {} lindex
interp alias {} = {} expr
interp alias {} dexist {} dict exists
interp alias {} dcreate {} dict create
interp alias {} dset {} dict set

global env
if {[string match -nocase *linux* $tcl_platform(os)]} {
    set nagelfarPath "/home/$env(USER)/tcl/nagelfar/nagelfar.tcl"
} elseif {[string match -nocase "*windows nt*" $tcl_platform(os)]} {
    set nagelfarPath "C:\\msys64\\home\\georgtree1\\nagelfar\\nagelfar.tcl"
}

set currentDir [file dirname [file normalize [info script]]]
set srcList {generalClasses.tcl specElementsClassesCommon.tcl specAnalysesClassesCommon.tcl\
                     {ngspice specAnalysesClassesNgspice.tcl} {ngspice specElementsClassesNgspice.tcl}\
                     {ngspice specModelsClassesNgspice.tcl} {ngspice specSimulatorClassesNgspice.tcl}\
                     {ngspice netlistParserClassNgspice.tcl}\
                     {xyce specAnalysesClassesXyce.tcl} {xyce specElementsClassesXyce.tcl}\
                     {xyce specModelsClassesXyce.tcl} {xyce specSimulatorClassesXyce.tcl}\
                     {ltspice specAnalysesClassesLtspice.tcl} {ltspice specElementsClassesLtspice.tcl}\
                     {ltspice specModelsClassesLtspice.tcl} {ltspice specSimulatorClassesLtspice.tcl}}
# instrument all files in src folder
foreach file $srcList {
    exec tclsh $nagelfarPath -instrument [file join $currentDir .. src {*}$file]
}
# rename initial source files, then rename instrument files to the original name of the source file
foreach file $srcList {
    if {[llength $file]>1} {
        file rename [file join $currentDir .. src [@ $file 0] [@ $file 1]]\
                [file join $currentDir .. src [@ $file 0] [@ $file 1]_orig]
        file rename [file join $currentDir .. src [@ $file 0] [@ $file 1]_i]\
                [file join $currentDir .. src [@ $file 0] [@ $file 1]]
    } else {
        file rename [file join $currentDir .. src [@ $file 0]] [file join $currentDir .. src [@ $file 0]_orig]
        file rename [file join $currentDir .. src [@ $file 0]_i] [file join $currentDir .. src [@ $file 0]]
    }
}

# tests run
exec tclsh [file join $currentDir all_codeCoverage.tcl]
# revert renaming
foreach file $srcList {
    if {[llength $file]>1} {
        file rename [file join $currentDir .. src [@ $file 0] [@ $file 1]]\
                [file join $currentDir .. src [@ $file 0] [@ $file 1]_i]
        file rename [file join $currentDir .. src [@ $file 0] [@ $file 1]_orig]\
                [file join $currentDir .. src [@ $file 0] [@ $file 1]]
    } else {
        file rename [file join $currentDir .. src [@ $file 0]] [file join $currentDir .. src [@ $file 0]_i]
        file rename [file join $currentDir .. src [@ $file 0]_orig] [file join $currentDir .. src [@ $file 0]]
    }
}
# create markup files
set coveredSum 0
set totalSum 0
foreach file $srcList {
    set result [exec tclsh $nagelfarPath -markup [file join $currentDir .. src {*}$file]]
    lappend results $result
    if {[regexp {(\d+)/(\d+)\s+(\d+(\.\d+)?)%} $result match num1 num2 num3]} {
        set coveredSum [= {$num1+$coveredSum}]
        set totalSum [= {$num2+$totalSum}]
    }
}
# view results
foreach file $srcList {
    if {[llength $file]>1} {
        exec eskil -noparse [file join $currentDir .. src [@ $file 0] [@ $file 1]]\
                [file join $currentDir .. src [@ $file 0] [@ $file 1]_m]
    } else {
        exec eskil -noparse [file join ${currentDir} .. src [@ $file 0]]\
                [file join $currentDir .. src [@ $file 0]_m]
    }
}
puts [join $results "\n"]
puts "Covered $coveredSum of $totalSum branches, percentage is [= {double($coveredSum)/double($totalSum)*100}]%"
# remove tests files
foreach file $srcList {
    if {[llength $file]>1} {
        file delete [file join $currentDir .. src [@ $file 0] [@ $file 1]_i]
        file delete [file join $currentDir .. src [@ $file 0] [@ $file 1]_log]
        file delete [file join $currentDir .. src [@ $file 0] [@ $file 1]_m]
    } else {
        file delete [file join $currentDir .. src [@ $file 0]_i]
        file delete [file join $currentDir .. src [@ $file 0]_log]
        file delete [file join $currentDir .. src [@ $file 0]_m]
    }
}
