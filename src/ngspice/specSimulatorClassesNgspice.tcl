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
    ##nagelfar subcmd+ _obj,Batch configure
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
            argparse -help {Creates batch ngspice simulator that can be attached to top-level 'Circuit'} {
                {name -help {Name of simulator object}}
                {runLocation -optional -default . -help {Location at which input netlist is stored and all output files\
                                                                 will be saved}}
            }
            my configure -name $name
            my variable Command
            global tcl_platform
            if {[string match -nocase {*windows nt*} $tcl_platform(os)]} { ##nagelfar nocover
                set Command ngspice_con
            } else {
                set Command ngspice
            }
            my configure -runlocation $runLocation
        }
        method runAndRead {args} {
            # Runs netlist circuit file.
            #  circuitStr - top-level netlist string
            #  -nodelete - flag to forbid simulation file deletion
            # Synopsis: circuitStr ?-nodelete?
            argparse -pfirst -help {Runs netlist circuit file} {
                {circuitStr -help {Top-level netlist string}}
                {-nodelete -help {Flag to forbid simulation file deletion}}
            }
            my variable Command
            set firstLine [@ [split $circuitStr \n] 0]
            set runLocation [my configure -runlocation]
            set cirFile [open [file join $runLocation ${firstLine}.cir] w+]
            puts $cirFile $circuitStr
            close $cirFile
            set rawFileName [file join $runLocation ${firstLine}.raw]
            set logFileName [file join $runLocation ${firstLine}.log]
            set cirFileName [file join $runLocation ${firstLine}.cir]
            exec {*}[list $Command -b -r $rawFileName -o $logFileName $cirFileName]
            set LastRunFileName $firstLine
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
            set logFile [open [file join [my configure -runlocation] ${LastRunFileName}.log] r+]
            set log [read $logFile]
            close $logFile
            return
        }
        method readData {} {
            # Reads raw data file, create RawFile object and return it's reference name.
            my variable data
            set data [::SpiceGenTcl::RawFile new [file join [my configure -runlocation]\
                                                          ${LastRunFileName}.raw] * ngspice]
            return
        }
    }

    oo::configurable create BatchLiveLog {
        # this class represent batch simulation of ngspice
        superclass ::SpiceGenTcl::Ngspice::Simulators::Batch
        method runAndRead {args} {
            # Runs netlist circuit file.
            #  circuitStr - top-level netlist string
            #  -nodelete - flag to forbid simulation file deletion
            # Synopsis: circuitStr ?-nodelete?
            argparse -pfirst -help {Runs netlist circuit file} {
                {circuitStr -help {Top-level netlist string}}
                {-nodelete -help {Flag to forbid simulation file deletion}}
            }
            my variable Command
            my variable LastRunFileName
            set firstLine [@ [split $circuitStr \n] 0]
            set runLocation [my configure -runlocation]
            set cirFile [open [file join $runLocation ${firstLine}.cir] w+]
            puts $cirFile $circuitStr
            close $cirFile
            set rawFileName [file join $runLocation ${firstLine}.raw]
            set logFileName [file join $runLocation ${firstLine}.log]
            set cirFileName [file join $runLocation ${firstLine}.cir]
            set command [list $Command -b $cirFileName -r $rawFileName]
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
            set LastRunFileName ${firstLine}
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
