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
        variable LastRunFileName
        constructor {args} {
            # Creates batch ngspice simulator that can be attached to top-level `Circuit`.
            #  name - name of simulator object
            #  runLocation - location at which input netlist is stored and all output files will be saved, default is
            #   current directory
            argparse -help {Creates batch ngspice simulator that can be attached to top-level 'Circuit'} {
                {name -help {Name of simulator object}}
                {runLocation -optional -default . -help {Location at which input netlist is stored and all output files\
                                                                 will be saved}}
            }
            my configure -name $name
            my variable Command
            global tcl_platform
            global env
            if {[string match -nocase *linux* $tcl_platform(os)]} {
                set Command [list wine $env(LTSPICE_PREFIX)]
            } elseif {[string match -nocase {*windows nt*} $tcl_platform(os)]} { ##nagelfar nocover
                set Command LTspice
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
                catch {exec {*}$Command -b $cirFileName} errorStr
                #puts $errorStr
                set falseError {wine: Read access denied for device L"\\??\\Z:\\", FS volume label and serial are not\
                                        available.}
                if {$errorStr ni [list "$falseError\n$falseError\n$falseError" {}]} {
                    error "LTspice failed with error '$errorStr'"
                }
            } elseif {[string match -nocase {*windows nt*} $tcl_platform(os)]} { ##nagelfar nocover
                exec {*}[list $Command -b $cirFileName]
            }
            set LastRunFileName $firstLine
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
            argparse -help {Reads raw data file, create RawFile object and return it's reference name} {}
            my variable data
            set data [::SpiceGenTcl::RawFile new [file join [my configure -runlocation]\
                                                          ${LastRunFileName}.raw] * ltspice]
            return
        }
    }
}
