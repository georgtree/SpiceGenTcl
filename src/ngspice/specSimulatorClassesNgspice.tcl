#  .|'''.|            ||                   ..|'''.|                   |''||''|         '||'
#  ||..  '  ... ...  ...    ....    ....  .|'     '    ....  .. ...      ||      ....   ||  
#   ''|||.   ||'  ||  ||  .|   '' .|...|| ||    .... .|...||  ||  ||     ||    .|   ''  ||  
# .     '||  ||    |  ||  ||      ||      '|.    ||  ||       ||  ||     ||    ||       ||  
# |'....|'   ||...'  .||.  '|...'  '|...'  ''|...'|   '|...' .||. ||.   .||.    '|...' .||. 
#            ||                                                                             
#           ''''                                                                            
# specSimulatorClassesNgspice.tcl
# Describes Ngspice simulators classes
#
# Copyright (c) 2024 George Yashin, georgtree@gmail.com
#
# MIT License
# See the file "LICENSE.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

namespace eval ::SpiceGenTcl::Ngspice::Simulators {
    
    namespace export Batch BatchLiveLog
    
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
        property LastRunFileName
        variable LastRunFileName
        constructor {name {runLocation .}} {
            # Creates batch ngspice simulator that can be attached to top-level Circuit.
            #  name - name of simulator object
            #  runLocation - location at which input netlist is stored and all output files will be saved,
            #   default is current directory
            my configure -name $name
            global tcl_platform
            if {[string match -nocase *linux* $tcl_platform(os)]} {
                my configure -Command ngspice
            } elseif {[string match -nocase {*windows nt*} $tcl_platform(os)]} {
                my configure -Command ngspice_con
            }
            my configure -runlocation $runLocation
        }
        method runAndRead {circuitStr args} {
            # Runs netlist circuit file.
            #  circuitStr - top-level netlist string
            #  -nodelete - flag to forbid simulation file deletion
            # Synopsis: circuitStr ?-nodelete?
            set arguments [argparse {
                -nodelete
            }]
            set firstLine [@ [split $circuitStr \n] 0]
            set runLocation [my configure -runlocation]
            set cirFile [open [file join $runLocation ${firstLine}.cir] w+]
            puts $cirFile $circuitStr
            close $cirFile
            set rawFileName [file join $runLocation ${firstLine}.raw]
            set logFileName [file join $runLocation ${firstLine}.log]
            set cirFileName [file join $runLocation ${firstLine}.cir]
            exec {*}[list [my configure -Command] -b -r $rawFileName -o $logFileName $cirFileName]
            my configure -LastRunFileName $firstLine
            my readLog
            my readData
            if {![info exists nodelete]} {
                file delete $rawFileName
                file delete $logFileName
                file delete $cirFileName
            }
        }
        method readLog {} {
            # Reads log file of last simulation and save it's content to Log variable.
            set logFile [open [file join [my configure -runlocation] [my configure -LastRunFileName].log] r+]
            set log [read $logFile]
            close $logFile
            return 
        }
        method clearLog {} {
            # Clear saved log by unsetting Log variable.
            if {[info exists Log]} {
                unset log
                return
            } else {
                return -code error "Log does not exists for simulator '[my configure -name]'" 
            }
        }
        method readData {} {
            # Reads raw data file, create RawFile object and return it's reference name.
            my variable data
            set data [::SpiceGenTcl::RawFile new [file join [my configure -runlocation]\
                                                          [my configure -LastRunFileName].raw] * ngspice]
            return
        }
    }
    
    oo::configurable create BatchLiveLog {
        # this class represent batch simulation of ngspice
        superclass ::SpiceGenTcl::Ngspice::Simulators::Batch
        method runAndRead {circuitStr args} {
            # Runs netlist circuit file.
            #  circuitStr - top-level netlist string
            #  -nodelete - flag to forbid simulation file deletion
            # Synopsis: circuitStr ?-nodelete?
            set arguments [argparse {
                -nodelete
            }]
            set firstLine [@ [split $circuitStr \n] 0]
            set runLocation [my configure -runlocation]
            set cirFile [open [file join $runLocation ${firstLine}.cir] w+]
            puts $cirFile $circuitStr
            close $cirFile
            set rawFileName [file join $runLocation ${firstLine}.raw]
            set logFileName [file join $runLocation ${firstLine}.log]
            set cirFileName [file join $runLocation ${firstLine}.cir]
            set command [list [my configure -Command] -b $cirFileName -r $rawFileName]
            set chan [open "|$command 2>@1"]
            set logData {}
            while {[gets $chan line] >= 0} {
                puts $line
                set logData [join [list $logData $line] \n]
                if {[eof $chan]} {
                    close $chan
                }
            }
            close $chan
            my configure -LastRunFileName ${firstLine}
            my configure -log $logData
            my readData
            if {![info exists nodelete]} {
                file delete $rawFileName
                file delete $logFileName
                file delete $cirFileName
            }
        }
    }
}
