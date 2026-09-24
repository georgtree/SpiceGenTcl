#  .|'''.|            ||                   ..|'''.|                   |''||''|         '||'
#  ||..  '  ... ...  ...    ....    ....  .|'     '    ....  .. ...      ||      ....   ||
#   ''|||.   ||'  ||  ||  .|   '' .|...|| ||    .... .|...||  ||  ||     ||    .|   ''  ||
# .     '||  ||    |  ||  ||      ||      '|.    ||  ||       ||  ||     ||    ||       ||
# |'....|'   ||...'  .||.  '|...'  '|...'  ''|...'|   '|...' .||. ||.   .||.    '|...' .||.
#            ||
#           ''''
# specSimulatorClassesXyce.tcl
# Describes Xyce simulators classes
#
# Copyright (c) 2024 George Yashin, georgtree@gmail.com
#
# MIT License
# See the file "LICENSE.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

namespace eval ::SpiceGenTcl::Xyce::Simulators {

    namespace export Batch

    oo::configurable create Batch {
        # this class represent batch simulation of ngspice
        superclass ::SpiceGenTcl::Simulator
        property log -get {
            if {[info exists log]} {
                return $log
            } else {
                return -code error "Log does not exists for simulator '[my configure -name]'"
            }
        }
        variable log
        property data
        variable data
        # location at which input netlist is stored and all output files will be saved
        property runlocation
        variable runlocation
        # the name of last ran file
        variable LastRunFileName
        constructor {args} {
            # Creates batch ngspice simulator that can be attached to top-level Circuit.
            #  name - name of simulator object
            #  runLocation - location at which input netlist is stored and all output files will be saved,
            #   default is current directory
            #  -nocleanup - if provided, retains RawFile object from the previous simulation
            argparse -help {Creates batch ngspice simulator that can be attached to top-level 'Circuit'} {
                {name -help {Name of simulator object}}
                {runLocation -optional -default . -help {Location at which input netlist is stored and all output files\
                                                                 will be saved}}
                {-nocleanup -boolean -help {Retain RawFile object from previous simulation}}
            }
            my configure -name $name
            my variable Command
            set Command Xyce
            my configure -runlocation $runLocation -nocleanup $nocleanup
        }
        method runAndRead {args} {
            # Runs netlist circuit file.
            #  circuitStr - top-level netlist string
            #  -nodelete - flag to forbid simulation file deletion
            #  -vector - flag to enable RBC vector storage
            # Synopsis: circuitStr ?-nodelete? ?-vector?
            argparse -pfirst -help {Runs netlist circuit file} {
                {circuitStr -help {Top-level netlist string}}
                {-nodelete -help {Flag to forbid simulation file deletion}}
                {-vector -boolean -help {Flag to enable RBC vector storage}}
            }
            my variable Command
            set firstLine [lindex [split $circuitStr \n] 0]
            set runLocation [my configure -runlocation]
            set cirFile [open [file join $runLocation ${firstLine}.cir] w+]
            puts $cirFile $circuitStr
            close $cirFile
            set rawFileName [file join $runLocation ${firstLine}.raw]
            set logFileName [file join $runLocation ${firstLine}.log]
            set cirFileName [file join $runLocation ${firstLine}.cir]
            exec {*}[list $Command -r $rawFileName -l $logFileName $cirFileName]
            set LastRunFileName $firstLine
            my readLog
            my readData $vector
            if {![info exists nodelete]} {
                file delete -- $rawFileName
                file delete -- $logFileName
                file delete -- $cirFileName
            }
        }
        method readLog {args} {
            # Reads log file of last simulation and save it's content to Log variable.
            argparse -help {Reads log file of last simulation and save it's content to Log variable} {}
            set logFile [open [file join [my configure -runlocation] ${LastRunFileName}.log] r+]
            set log [read $logFile]
            close $logFile
            return
        }
        method readData {args} {
            # Reads raw data file, create RawFile object and return it's reference name.
            #  vector - flag to enable RBC vector storage
            # Synopsis: ?vector?
            argparse -help {Reads raw data file, create RawFile object and return it's reference name} {
                {vector -optional -default 0 -help {Flag to enable RBC vector storage}}
            }
            my variable data
            if {[info exists data]} {
                set previousRawFile $data
            }
            if {$vector} {
                set data [::SpiceGenTcl::RawFile new -vector [file join [my configure -runlocation]\
                                                              ${LastRunFileName}.raw] * ngspice]
            } else {
                set data [::SpiceGenTcl::RawFile new [file join [my configure -runlocation]\
                                                              ${LastRunFileName}.raw] * ngspice]
            }
            if {![my configure -nocleanup]} {
                if {[info exists previousRawFile]} {
                    $previousRawFile destroy
                }
            }
            return
        }
    }

}
