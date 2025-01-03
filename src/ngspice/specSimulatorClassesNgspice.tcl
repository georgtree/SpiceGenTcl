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
        property Log -get {
            if {[info exists Log]!=0} {
                return $Log
            } else {
                return -code error "Log does not exists for simulator '[my configure -Name]'" 
            }
        }
        variable Log
        property Data
        variable Data
        # location at which input netlist is stored and all output files will be saved
        property RunLocation
        variable RunLocation
        # the name of last ran file
        property LastRunFileName
        variable LastRunFileName
        constructor {name {runLocation .}} {
            # Creates batch ngspice simulator that can be attached to top-level Circuit.
            #  name - name of simulator object
            #  runLocation - location at which input netlist is stored and all output files will be saved,
            #   default is current directory
            my configure -Name $name
            global tcl_platform
            if {[string match -nocase *linux* $tcl_platform(os)]} {
                my configure -Command ngspice
            } elseif {[string match -nocase "*windows nt*" $tcl_platform(os)]} {
                my configure -Command ngspice_con
            }
            my configure -RunLocation $runLocation
        }
        method runAndRead {circuitStr args} {
            # Runs netlist circuit file.
            #  circuitStr - top-level netlist string
            #  -nodelete - flag to forbid simulation file deletion
            set arguments [argparse {
                -nodelete
            }]
            set firstLine [@ [split $circuitStr \n] 0]
            set runLocation [my configure -RunLocation]
            set cirFile [open "${runLocation}/${firstLine}.cir" w+]
            puts $cirFile $circuitStr
            close $cirFile
            set rawFileName "${runLocation}/${firstLine}.raw"
            set logFileName "${runLocation}/${firstLine}.log"
            set cirFileName "${runLocation}/${firstLine}.cir"
            exec "[my configure -Command]" -b -r $rawFileName -o $logFileName $cirFileName
            my configure -LastRunFileName ${firstLine}
            my readLog
            my readData
            if {[info exists nodelete]==0} {
                file delete $rawFileName
                file delete $logFileName
                file delete $cirFileName
            }
        }
        method readLog {} {
            # Reads log file of last simulation and save it's content to Log variable.
            set logFile [open "[my configure -RunLocation]/[my configure -LastRunFileName].log" r+]
            set Log [read $logFile]
            close $logFile
            return 
        }
        method clearLog {} {
            # Clear saved log by unsetting Log variable.
            if {[info exists Log]} {
                unset Log
                return
            } else {
                return -code error "Log does not exists for simulator '[my configure -Name]'" 
            }
        }
        method readData {} {
            # Reads raw data file, create RawFile object and return it's reference name.
            my variable Data
            set Data [::SpiceGenTcl::RawFile new "[my configure -RunLocation]/[my configure -LastRunFileName].raw"]
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
            set arguments [argparse {
                -nodelete
            }]
            set firstLine [@ [split $circuitStr \n] 0]
            set runLocation [my configure -RunLocation]
            set cirFile [open "${runLocation}/${firstLine}.cir" w+]
            puts $cirFile $circuitStr
            close $cirFile
            set rawFileName "${runLocation}/${firstLine}.raw"
            set logFileName "${runLocation}/${firstLine}.log"
            set cirFileName "${runLocation}/${firstLine}.cir"
            set command [list [my configure -Command] -b $cirFileName -r $rawFileName]
            set chan [open "|$command 2>@1"]
            set logData ""
            while {[gets $chan line] >= 0} {
                puts $line
                set logData [join [list $logData $line] \n]
                if {[eof $chan]} {
                    close $chan
                }
            }
            close $chan
            my configure -LastRunFileName ${firstLine}
            my configure -Log $logData
            my readData
            if {[info exists nodelete]==0} {
                file delete $rawFileName
                file delete $logFileName
                file delete $cirFileName
            }
        }
    }
}
