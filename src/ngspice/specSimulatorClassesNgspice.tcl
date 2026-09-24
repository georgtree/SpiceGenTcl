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

    namespace export Batch BatchLiveLog Shared
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
            #  -nocleanup - if provided, retains RawFile object from the previous simulation
            argparse -help {Creates batch ngspice simulator that can be attached to top-level 'Circuit'} {
                {name -help {Name of simulator object}}
                {runLocation -optional -default . -help {Location at which input netlist is stored and all output files\
                                                                 will be saved}}
                {-nocleanup -boolean -help {Retain RawFile object from previous simulation}}
            }
            my configure -name $name
            my variable Command
            global tcl_platform
            if {[string match -nocase {*windows nt*} $tcl_platform(os)]} { ##nagelfar nocover
                set Command ngspice_con
            } else {
                set Command ngspice
            }
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
            exec {*}[list $Command -b -r $rawFileName -o $logFileName $cirFileName]
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

    oo::configurable create BatchLiveLog {
        # this class represent batch simulation of ngspice
        superclass ::SpiceGenTcl::Ngspice::Simulators::Batch
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
            my variable LastRunFileName
            set firstLine [lindex [split $circuitStr \n] 0]
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
            my readData $vector
            if {![info exists nodelete]} {
                file delete -- $rawFileName
                file delete -- $logFileName
                file delete -- $cirFileName
            }
        }
    }

    ##nagelfar subcmd+ _obj,Shared configure
    oo::configurable create Shared {
        # this class represent batch simulation of ngspice in form of shared library
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
        property liblocation
        variable liblocation
        property simhandle
        variable simhandle
        # the name of last ran file
        variable LastRunFileName
        constructor {args} {
            # Creates batch ngspice simulator that can be attached to top-level Circuit.
            #  name - name of simulator object
            #  liblocation - path to .so/.dll library
            #  -nocleanup - if provided, retains RawFile object from the previous simulation
            package require ngspicetclbridge
            argparse -help {Creates batch ngspice simulator that can be attached to top-level 'Circuit'} {
                {name -help {Name of simulator object}}
                {liblocation -optional -help {Path to .so/.dll library}}
                {-nocleanup -boolean -help {Retain RawFile object from previous simulation}}
            }
            if {![info exists liblocation]} {
                if {{NGSPICE_DLL} in [array names ::env]} {
                    if {$::tcl_platform(platform) eq {unix}} {
                        set liblocation [file join $::env(NGSPICE_DLL) libngspice.so]
                    } elseif {$::tcl_platform(platform) eq {windows}} {
                        set liblocation [file join $::env(NGSPICE_DLL) ngspice.dll]
                    } else {
                        return -code error "Default library name does not exist for platform\
                                '$::tcl_platform(platform)'"
                    }
                } else {
                    if {$::tcl_platform(platform) eq {windows}} {
                        set liblocation [file join C:/ Spice64_dll dll-vs ngspice.dll]
                    } else {
                        set liblocation [file join usr local lib libngspice.so]
                    }
                }
            }
            my configure -name $name -liblocation $liblocation -nocleanup $nocleanup
            my configure -simhandle [ngspicetclbridge::new [file nativename $liblocation]]
        }
        destructor {
            $simhandle destroy
        }
        method runAndRead {args} {
            # Runs circuit.
            #  circuitStr - top-level netlist string
            #  -vector - flag to enable RBC vector storage
            # Synopsis: circuitStr ?-vector?
            argparse -pfirst -help {Runs circuit} {
                {circuitStr -help {Top-level netlist string}}
                {-vector -boolean -help {Flag to enable RBC vector storage}}
            }
            set circuitList [split $circuitStr \n]
            set firstLine [lindex $circuitList 0]
            $simhandle circuit [lappend circuitList .end]
            ngspicetclbridge::run $simhandle
            my readLog
            my readData $vector
        }
        method readLog {args} {
            # Gets log of last simulation and save it's content to Log variable.
            argparse -help {Gets log of last simulation and save it's content to Log variable} {}
            set log [$simhandle messages]
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
                set data [::SpiceGenTcl::RawFile new -vector -shared $simhandle {} * ngspice]
            } else {
                set data [::SpiceGenTcl::RawFile new -shared $simhandle {} * ngspice]
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
