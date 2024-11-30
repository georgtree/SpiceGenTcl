#  .|'''.|            ||                   ..|'''.|                   |''||''|         '||'
#  ||..  '  ... ...  ...    ....    ....  .|'     '    ....  .. ...      ||      ....   ||  
#   ''|||.   ||'  ||  ||  .|   '' .|...|| ||    .... .|...||  ||  ||     ||    .|   ''  ||  
# .     '||  ||    |  ||  ||      ||      '|.    ||  ||       ||  ||     ||    ||       ||  
# |'....|'   ||...'  .||.  '|...'  '|...'  ''|...'|   '|...' .||. ||.   .||.    '|...' .||. 
#            ||                                                                             
#           ''''                                                                            
# specAnalysesClassesNgspice.tcl
# Describes Ngspice analyses classes
#
# Copyright (c) 2024 George Yashin, georgtree@gmail.com
#
# MIT License
# See the file "LICENSE.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

namespace eval ::SpiceGenTcl {
    namespace eval Ngspice::Analyses {
        namespace export Dc Ac Tran Op SensAc SensDc Sp
    }
}

namespace eval ::SpiceGenTcl::Ngspice::Analyses {
    
    
###  Dc class 

    oo::class create Dc {
        superclass ::SpiceGenTcl::Analysis
        constructor {args} {
            # Creates object of class `Dc` that describes DC analysis. 
            #  -src - name of independent voltage or current source, a resistor, or the circuit temperature
            #  -start - start value
            #  -stop - stop value
            #  -incr - incrementing value
            #  -name - name argument, optional
            # ```
            # .dc src start stop vincr
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Analyses::Dc new -src v1 -start {time1 -eq} -stop 5 -incr 0.1 -name dc1
            # ```
            set arguments [argparse -inline {
                -name=
                {-src= -required}
                {-start= -required}
                {-stop= -required}
                {-incr= -required}
            }]
            if {[dict exists $arguments name]} {
                set name [dict get $arguments name]
            } else {
                set name [self object]
            }
            lappend params "src [dict get $arguments src] -posnocheck"
            set paramsOrder [list start stop incr]
            foreach param $paramsOrder {
                dict append argsOrdered $param [dict get $arguments $param]
            }
            dict for {paramName value} $argsOrdered {
                if {([llength $value]>1) && ([lindex $value 1]=="-eq")} {
                    lappend params "$paramName [lindex $value 0] -poseq"
                } else {
                    lappend params "$paramName $value -pos"
                }
            }
            next dc $params -name $name
        }
    }

###  Ac class 

    oo::class create Ac {
        superclass ::SpiceGenTcl::Analysis
        constructor {args} {
            # Creates object of class `Ac` that describes AC analysis. 
            #  -variation - parameter that defines frequency scale, could be dec, oct or lin
            #  -n - number of points
            #  -fstart - start frequency
            #  -fstop - start frequency
            #  -name - name argument, optional
            # ```
            # .ac variation n fstart fstop
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Analyses::Ac new -variation dec -n 10 -fstart 1 -fstop 1e6 -name dc1
            # ```
            set arguments [argparse -inline {
                -name=
                {-variation= -required}
                {-n= -required}
                {-fstart= -required}
                {-fstop= -required}
            }]
            if {[dict exists $arguments name]} {
                set name [dict get $arguments name]
            } else {
                set name [self object]
            }
            lappend params "variation [dict get $arguments variation] -posnocheck"
            set paramsOrder [list n fstart fstop]
            foreach param $paramsOrder {
                dict append argsOrdered $param [dict get $arguments $param]
            }
            dict for {paramName value} $argsOrdered {
                if {([llength $value]>1) && ([lindex $value 1]=="-eq")} {
                    lappend params "$paramName [lindex $value 0] -poseq"
                } else {
                    lappend params "$paramName $value -pos"
                }
            }
            next ac $params -name $name
        }
    }

###  Sp class 

    oo::class create Sp {
        superclass ::SpiceGenTcl::Analysis
        constructor {args} {
            # Creates object of class `Sp` that describes s-parameter analysis. 
            #  -variation - parameter that defines frequency scale, could be dec, oct or lin
            #  -n - number of points
            #  -fstart - start frequency
            #  -fstop - start frequency
            #  -name - name argument, optional
            #  -donoise - activate s-parameter noise
            # ```
            # .ac variation n fstart fstop <donoise>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Analyses::Sp new -variation dec -n 10 -fstart 1 -fstop 1e6 -name sp1 -donoise
            # ```
            set arguments [argparse -inline {
                -name=
                {-variation= -required}
                {-n= -required}
                {-fstart= -required}
                {-fstop= -required}
                {-donoise}
            }]
            if {[dict exists $arguments name]} {
                set name [dict get $arguments name]
            } else {
                set name [self object]
            }
            lappend params "variation [dict get $arguments variation] -posnocheck"
            set paramsOrder [list n fstart fstop]
            foreach param $paramsOrder {
                dict append argsOrdered $param [dict get $arguments $param]
            }
            dict for {paramName value} $argsOrdered {
                if {([llength $value]>1) && ([lindex $value 1]=="-eq")} {
                    lappend params "$paramName [lindex $value 0] -poseq"
                } else {
                    lappend params "$paramName $value -pos"
                }
            }
            if {[dict exists $arguments donoise]} {
                lappend params "donoise 1 -pos" 
            }
            next sp $params -name $name
        }
    }
    
###  SensAc class 

    oo::class create SensAc {
        superclass ::SpiceGenTcl::Analysis
        constructor {args} {
            # Creates object of class `SensAc` that describes SENS ac analysis. 
            #  -outvar - output variable
            #  -variation - parameter that defines frequency scale, could be dec, oct or lin
            #  -n - number of points
            #  -fstart - start frequency
            #  -fstop - start frequency
            #  -name - name argument, optional
            # ```
            # .sens outvar ac variation n fstart fstop
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Analyses::SensAc new -outvar v(1,out) -variation dec -n 10 -fstart 1 -fstop 1e6 -name dc1
            # ```
            set arguments [argparse -inline {
                -name=
                {-outvar= -required}
                {-variation= -required}
                {-n= -required}
                {-fstart= -required}
                {-fstop= -required}
            }]
            if {[dict exists $arguments name]} {
                set name [dict get $arguments name]
            } else {
                set name [self object]
            }
            lappend params "outvar [dict get $arguments outvar] -posnocheck"
            lappend params "ac -sw"
            lappend params "variation [dict get $arguments variation] -posnocheck"
            set paramsOrder [list n fstart fstop]
            foreach param $paramsOrder {
                dict append argsOrdered $param [dict get $arguments $param]
            }
            dict for {paramName value} $argsOrdered {
                if {([llength $value]>1) && ([lindex $value 1]=="-eq")} {
                    lappend params "$paramName [lindex $value 0] -poseq"
                } else {
                    lappend params "$paramName $value -pos"
                }
            }
            next sens $params -name $name
        }
    }
    
###  SensDc class 

    oo::class create SensDc {
        superclass ::SpiceGenTcl::Analysis
        constructor {args} {
            # Creates object of class `SensDc` that describes SENS dc analysis. 
            #  -outvar - output variable
            #  -name - name argument, optional
            # ```
            # .senc variation n fstart fstop
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Analyses::SensDc new -outvar v(1,out) -name sensdc1
            # ```
            set arguments [argparse -inline {
                -name=
                {-outvar= -required}
            }]
            if {[dict exists $arguments name]} {
                set name [dict get $arguments name]
            } else {
                set name [self object]
            }
            lappend params "outvar [dict get $arguments outvar] -posnocheck"
            next sens $params -name $name
        }
    }
    
###  Tran class 

    oo::class create Tran {
        superclass ::SpiceGenTcl::Analysis
        constructor {args} {
            # Creates object of class `Tran` that describes TRAN analysis. 
            #  -tstep - size of maximum time step for plotting
            #  -tstop - stop time value
            #  -tstart - start time of saving data, optional
            #  -tmax - size of maximum time step in actual simulation, optional, require -tstart
            #  -uic - skip initial operating point solution, optional
            #  -name - name argument, optional
            # ```
            # .tran tstep tstop <tstart<tmax>> <uic>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Analyses::Tran new -tstep 1e-9 -tstop 10e-6 -name dc1
            # ```
            set arguments [argparse -inline {
                -name=
                {-tstep= -required}
                {-tstop= -required}
                -tstart=
                {-tmax= -require {tstart}}
                {-uic -boolean}
            }]
            if {[dict exists $arguments name]} {
                set name [dict get $arguments name]
            } else {
                set name [self object]
            }
            set paramsOrder [list tstep tstop tstart tmax]
            foreach param $paramsOrder {
                if {[dict exists $arguments $param]} {
                    dict append argsOrdered $param [dict get $arguments $param]
                }
            }
            dict for {paramName value} $argsOrdered {
                if {([llength $value]>1) && ([lindex $value 1]=="-eq")} {
                    lappend params "$paramName [lindex $value 0] -poseq"
                } else {
                    lappend params "$paramName $value -pos"
                }
            }
            if {[dict get $arguments uic]==1} {
                lappend params "uic -sw"
            }
            next tran $params -name $name
        }
    }
    
###  Op class 

    oo::class create Op {
        superclass ::SpiceGenTcl::Analysis
        constructor {args} {
            # Creates object of class `Op` that describes OP analysis. 
            #  -name - name argument, optional
            # ```
            # .op
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Analyses::Op new -name op1
            # ```
            set arguments [argparse -inline {
                -name=
            }]
            if {[dict exists $arguments name]} {
                set name [dict get $arguments name]
            } else {
                set name [self object]
            }
            next op "" -name $name
        }
    }
}
