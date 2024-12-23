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

global env
set nagelfarPath "/home/$env(USER)/tcl/nagelfar/"
set currentDir [file dirname [file normalize [info script]]]
#cd $nagelfarPath
set srcList [list generalClasses.tcl specElementsClassesCommon.tcl\
                     [list ngspice specAnalysesClassesNgspice.tcl]\
                     [list ngspice specElementsClassesNgspice.tcl]\
                     [list ngspice specModelsClassesNgspice.tcl]\
                     [list ngspice specSimulatorClassesNgspice.tcl]\
                     [list xyce specAnalysesClassesXyce.tcl]\
                     [list xyce specElementsClassesXyce.tcl]\
                     [list xyce specModelsClassesXyce.tcl]\
                     [list xyce specSimulatorClassesXyce.tcl]]
# instrument all files in src folder
foreach file $srcList {
    exec [file join ${nagelfarPath} nagelfar.tcl] -instrument [file join ${currentDir} .. src {*}$file]
}
# rename initial source files, then rename instrument files to the original name of the source file
foreach file $srcList {
    if {[llength $file]>1} {
        file rename [file join ${currentDir} .. src [lindex $file 0] "[lindex $file 1]"]\
                [file join ${currentDir} .. src [lindex $file 0] "[lindex $file 1]_orig"]
        file rename [file join ${currentDir} .. src [lindex $file 0] "[lindex $file 1]_i"]\
                [file join ${currentDir} .. src [lindex $file 0] "[lindex $file 1]"]
    } else {
        file rename [file join ${currentDir} .. src "[lindex $file 0]"]\
                [file join ${currentDir} .. src "[lindex $file 0]_orig"]
        file rename [file join ${currentDir} .. src "[lindex $file 0]_i"]\
                [file join ${currentDir} .. src "[lindex $file 0]"]
    }
}

# tests run
exec tclsh [file join ${currentDir} all_codeCoverage.tcl]
# revert renaming
foreach file $srcList {
    if {[llength $file]>1} {
        file rename [file join ${currentDir} .. src [lindex $file 0] "[lindex $file 1]"]\
                [file join ${currentDir} .. src [lindex $file 0] "[lindex $file 1]_i"]
        file rename [file join ${currentDir} .. src [lindex $file 0] "[lindex $file 1]_orig"]\
                [file join ${currentDir} .. src [lindex $file 0] "[lindex $file 1]"]
    } else {
        file rename [file join ${currentDir} .. src "[lindex $file 0]"]\
                [file join ${currentDir} .. src "[lindex $file 0]_i"]
        file rename [file join ${currentDir} .. src "[lindex $file 0]_orig"]\
                [file join ${currentDir} .. src "[lindex $file 0]"]
    }
}
# create markup files
foreach file $srcList {
    lappend results [exec [file join ${nagelfarPath} nagelfar.tcl] -markup [file join ${currentDir} .. src {*}$file]]
}
# view results
foreach file $srcList {
    if {[llength $file]>1} {
        exec eskil -noparse [file join ${currentDir} .. src [lindex $file 0] "[lindex $file 1]"]\
                [file join ${currentDir} .. src [lindex $file 0] "[lindex $file 1]_m"]
    } else {
        exec eskil -noparse [file join ${currentDir} .. src [lindex $file 0]]\
                [file join ${currentDir} .. src "[lindex $file 0]_m"]
    }
}
puts [join $results "\n"]
# remove tests files
foreach file $srcList {
    if {[llength $file]>1} {
        file delete [file join ${currentDir} .. src [lindex $file 0] "[lindex $file 1]_i"]
        file delete [file join ${currentDir} .. src [lindex $file 0] "[lindex $file 1]_log"]
        file delete [file join ${currentDir} .. src [lindex $file 0] "[lindex $file 1]_m"]
    } else {
        file delete [file join ${currentDir} .. src "[lindex $file 0]_i"]
        file delete [file join ${currentDir} .. src "[lindex $file 0]_log"]
        file delete [file join ${currentDir} .. src "[lindex $file 0]_m"]
    }
}
