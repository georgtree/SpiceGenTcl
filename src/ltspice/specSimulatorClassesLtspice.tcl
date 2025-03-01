#  .|'''.|            ||                   ..|'''.|                   |''||''|         '||'
#  ||..  '  ... ...  ...    ....    ....  .|'     '    ....  .. ...      ||      ....   ||  
#   ''|||.   ||'  ||  ||  .|   '' .|...|| ||    .... .|...||  ||  ||     ||    .|   ''  ||  
# .     '||  ||    |  ||  ||      ||      '|.    ||  ||       ||  ||     ||    ||       ||  
# |'....|'   ||...'  .||.  '|...'  '|...'  ''|...'|   '|...' .||. ||.   .||.    '|...' .||. 
#            ||                                                                             
#           ''''                                                                            
# specSimulatorClassesLtspice.tcl
# Describes LTspice simulators classes
#
# Copyright (c) 2024 George Yashin, georgtree@gmail.com
#
# MIT License
# See the file "LICENSE.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

namespace eval ::SpiceGenTcl::Ltspice::Simulators {
    
    namespace export Batch BatchLiveLog
    
    oo::configurable create Batch {
        # this class represent batch simulation of LTspice
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
            global env
            if {[string match -nocase *linux* $tcl_platform(os)]} {
                my configure -Command [list wine $env(LTSPICE_PREFIX)]
            } elseif {[string match -nocase {*windows nt*} $tcl_platform(os)]} {
                my configure -Command LTspice
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
            global tcl_platform
            set firstLine [@ [split $circuitStr \n] 0]
            set runLocation [my configure -runlocation]
            set cirFile [open [file join $runLocation ${firstLine}.cir] w+]
            puts $cirFile $circuitStr
            close $cirFile
            set rawFileName [file join $runLocation ${firstLine}.raw]
            set logFileName [file join $runLocation ${firstLine}.log]
            set cirFileName [file join $runLocation ${firstLine}.cir]
            if {[string match -nocase *linux* $tcl_platform(os)]} {
                catch {exec {*}[my configure -Command] -b $cirFileName} errorStr
                #puts $errorStr
                set falseError {wine: Read access denied for device L"\\??\\Z:\\", FS volume label and serial are not\
                                        available.}
                if {$errorStr ni [list "$falseError\n$falseError\n$falseError" {}]} {
                    error "LTspice failed with error '$errorStr'"
                }
            } elseif {[string match -nocase {*windows nt*} $tcl_platform(os)]} {
                exec {*}[list [my configure -Command] -b $cirFileName]
            }
            my configure -LastRunFileName $firstLine
            my readLog
            my readData
            if {![info exists nodelete]} {
                file delete $rawFileName
                file delete $logFileName
                file delete $cirFileName
                if {[file exists [file join $runLocation ${firstLine}.op.raw]]} {
                    file delete [file join $runLocation ${firstLine}.op.raw]
                }
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
                                                          [my configure -LastRunFileName].raw] * ltspice]
            return
        }
    }
}
