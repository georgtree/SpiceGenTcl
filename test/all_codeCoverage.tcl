#  .|'''.|            ||                   ..|'''.|                   |''||''|         '||'
#  ||..  '  ... ...  ...    ....    ....  .|'     '    ....  .. ...      ||      ....   ||  
#   ''|||.   ||'  ||  ||  .|   '' .|...|| ||    .... .|...||  ||  ||     ||    .|   ''  ||  
# .     '||  ||    |  ||  ||      ||      '|.    ||  ||       ||  ||     ||    ||       ||  
# |'....|'   ||...'  .||.  '|...'  '|...'  ''|...'|   '|...' .||. ||.   .||.    '|...' .||. 
#            ||                                                                             
#           ''''                                                                            
# all_codeCoverage.tcl
# Run all tests of SpiceGenTcl package
#
# Copyright (c) 2024 George Yashin, georgtree@gmail.com
#
# MIT License
# See the file "LICENSE.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

package require tcltest
namespace import ::tcltest::*
set testDir [file normalize [file dirname [info script]]]
source [file join $testDir .. SpiceGenTcl.tcl]
set testFiles [glob *.test]
lappend testFiles {*}[glob ${testDir}/ngspice/*.test]
lappend testFiles {*}[glob ${testDir}/ltspice/*.test]
lappend testFiles {*}[glob ${testDir}/xyce/*.test]
foreach file $testFiles {
    source $file
}
