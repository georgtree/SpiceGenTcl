package require Tk

namespace eval SpiceGenTcl::Ngspice::Simulators {
    
    namespace export Batch BatchLiveLog
    
    oo::class create Batch {
        # this class represent batch simulation of ngspice
        superclass SpiceGenTcl::Simulator
        # location at which input netlist is stored and all output files will be saved
        variable RunLocation
        # the name of last ran file
        variable LastRunFileName
        constructor {name path {runLocation /tmp}} {
            # Creates batch ngspice simulator that can be attached to top-level Circuit.
            #  name - name of simulator object
            #  path - path of ngspice executable file
            #  runLocation - location at which input netlist is stored and all output files will be saved,
            #   default is system temporary folder at Linux system
            my SetName $name
            my setPath $path
            my setCommand ngspice
            my setRunLocation $runLocation
        }
        method SetName {name} {
            my variable Name
            set Name $name
            return
        }
        method setCommand {command} {
            my variable Command
            set Command $command
            return
        }
        method getCommand {} {
            my variable Command
            return $Command
        }
        method setLastRunFileName {name} {
            set LastRunFileName $name
            return
        }
        method getLastRunFileName {} {
            return $LastRunFileName
        }
        method setRunLocation {runLocation} {
            set RunLocation $runLocation
            return
        }
        method getRunLocation {} {
            return $RunLocation
        }
        method runAndRead {circuitStr} {
            # Runs netlist circuit file.
            #  circuitStr - top-level netlist string
            set firstLine [lindex [split $circuitStr \n] 0]
            set runLocation [my getRunLocation]
            set cirFile [open "${runLocation}/${firstLine}.cir" w+]
            puts $cirFile $circuitStr
            close $cirFile
            set rawFileName "${runLocation}/${firstLine}.raw"
            set logFileName "${runLocation}/${firstLine}.log"
            set cirFileName "${runLocation}/${firstLine}.cir"
            exec "[my getCommand]" -b -r $rawFileName -o $logFileName $cirFileName
            my setLastRunFileName ${firstLine}
            my readLog
            my readData
        }
        method readLog {} {
            # Reads log file of last simulation and save it's content to Log variable.
            my variable Log
            set logFile [open "[my getRunLocation]/[my getLastRunFileName].log" r+]
            set Log [read $logFile]
            return 
        }
        method getLog {} {
            # Returns saved log file of last simulation.
            my variable Log
            if {[info exists Log]!=0} {
                return $Log
            } else {
                error "Log does not exists for simulator '[my getName]'" 
            }
        }
        method clearLog {} {
            # Clear saved log by unsetting Log variable.
            my variable Log
            if {[info exists Log]} {
                unset Log
                return
            } else {
                error "Log does not exists for simulator '[my getName]'" 
            }
        }
        method readData {} {
            # Reads raw data file, create RawFile object and return it's reference name.
            my variable Data
            set Data [SpiceGenTcl::RawFile new "[my getRunLocation]/[my getLastRunFileName].raw"]
            return
        }
        method getData {} {
            # Returns data of last completed simulation.
            # Returns: object of `RawFile` class
            my variable Data
            return $Data
        }
    }
    
    oo::class create BatchLiveLog {
        # this class represent batch simulation of ngspice
        superclass SpiceGenTcl::Ngspice::Simulators::Batch
        method runAndRead {circuitStr} {
            # Runs netlist circuit file.
            #  circuitStr - top-level netlist string
            my variable Log
            set firstLine [lindex [split $circuitStr \n] 0]
            set runLocation [my getRunLocation]
            set cirFile [open "${runLocation}/${firstLine}.cir" w+]
            puts $cirFile $circuitStr
            close $cirFile
            set rawFileName "${runLocation}/${firstLine}.raw"
            set logFileName "${runLocation}/${firstLine}.log"
            set cirFileName "${runLocation}/${firstLine}.cir"
            set chan [open |[list [my getCommand] -b -r $rawFileName $cirFileName] r]
            chan configure $chan -blocking 1
            set logData ""
            while {[gets $chan line] >= 0} {
                puts $line
                set logData [join [list $logData $line] \n]
                if {[eof $chan]} {
                    close $chan
                }
            }
            my setLastRunFileName ${firstLine}
            my setLog $logData
            my readData
        }
        method setLog {logData} {
            # Sets log files content to Log variable.
            my variable Log
            set Log $logData
            return 
        } 
    }
}