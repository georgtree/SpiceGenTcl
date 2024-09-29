package require Tk

namespace eval SpiceGenTcl::Ngspice::Simulators {
    
    namespace export Batch BatchLiveLog
    
    oo::configurable create Batch {
        # this class represent batch simulation of ngspice
        superclass SpiceGenTcl::Simulator
        property Log -get {
            if {[info exists Log]!=0} {
                return $Log
            } else {
                error "Log does not exists for simulator '[my configure -Name]'" 
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
        constructor {name path {runLocation /tmp}} {
            # Creates batch ngspice simulator that can be attached to top-level Circuit.
            #  name - name of simulator object
            #  path - path of ngspice executable file
            #  runLocation - location at which input netlist is stored and all output files will be saved,
            #   default is system temporary folder at Linux system
            my configure -Name $name
            my configure -Path $path
            my configure -Command ngspice
            my configure -RunLocation $runLocation
        }
        method runAndRead {circuitStr} {
            # Runs netlist circuit file.
            #  circuitStr - top-level netlist string
            set firstLine [lindex [split $circuitStr \n] 0]
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
                error "Log does not exists for simulator '[my configure -Name]'" 
            }
        }
        method readData {} {
            # Reads raw data file, create RawFile object and return it's reference name.
            my variable Data
            set Data [SpiceGenTcl::RawFile new "[my configure -RunLocation]/[my configure -LastRunFileName].raw"]
            return
        }
    }
    
    oo::configurable create BatchLiveLog {
        # this class represent batch simulation of ngspice
        superclass SpiceGenTcl::Ngspice::Simulators::Batch
        method runAndRead {circuitStr} {
            # Runs netlist circuit file.
            #  circuitStr - top-level netlist string
            set firstLine [lindex [split $circuitStr \n] 0]
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
        }
    }
}