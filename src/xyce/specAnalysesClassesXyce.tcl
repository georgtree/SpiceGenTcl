#  .|'''.|            ||                   ..|'''.|                   |''||''|         '||  
#  ||..  '  ... ...  ...    ....    ....  .|'     '    ....  .. ...      ||      ....   ||  
#   ''|||.   ||'  ||  ||  .|   '' .|...|| ||    .... .|...||  ||  ||     ||    .|   ''  ||  
# .     '||  ||    |  ||  ||      ||      '|.    ||  ||       ||  ||     ||    ||       ||  
# |'....|'   ||...'  .||.  '|...'  '|...'  ''|...'|   '|...' .||. ||.   .||.    '|...' .||. 
#            ||                                                                             
#           ''''                                                                            
# specAnalysesClassesXyce.tcl
# Describes Xyce analyses classes
#
# Copyright (c) 2024 George Yashin, georgtree@gmail.com
#
# MIT License
# See the file "LICENSE.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

namespace eval ::SpiceGenTcl {
    namespace eval Xyce::Analyses {
        namespace export Dc Ac Tran Op Sens
    }
}

namespace eval ::SpiceGenTcl::Xyce::Analyses {
    
    
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
            # .DC [LIN] <sweep variable name> <start> <stop> <step>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::Analyses::Dc new -src v1 -start {time1 -eq} -stop 5 -incr 0.1 -name dc1
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
            # .AC <sweep type> <points value>
            # + <start frequency value> <end frequency value>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::Analyses::Ac new -variation dec -n 10 -fstart 1 -fstop 1e6 -name dc1
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
            next ac $params -name $name
        }
    }

###  SensAc class 

    oo::class create Sens {
        superclass ::SpiceGenTcl::Analysis
        constructor {args} {
            # Creates object of class `Sens` that describes SENS ac analysis. 
            #  -objfunc - output expression
            #  -param - circuit parameter(s)
            #  -name - name argument, optional 
            # ```
            # .SENS objfunc=<output expression(s)> param=<circuit parameter(s)>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Analyses::Xyce::Sens new -objfunc "0.5*(V(B)-3.0)**2.0" -param "R1:R,R2:R" -name dc1
            # ```
            set arguments [argparse -inline {
                -name=
                {-objfunc= -required}
                {-param= -required}
            }]
            if {[dict exists $arguments name]} {
                set name [dict get $arguments name]
            } else {
                set name [self object]
            }
            lappend params "objfunc [dict get $arguments objfunc] -eq" 
            lappend params "param [dict get $arguments param] -nocheck"
            next sens $params -name $name
        }
    }
    
###  Tran class 

    oo::class create Tran {
        superclass ::SpiceGenTcl::Analysis
        constructor {args} {
            # Creates object of class `Tran` that describes TRAN analysis. 
            #  -tstep - initial step value
            #  -tstop - final time value
            #  -tstart - start time of saving data, optional
            #  -tstart - size of maximum time step in actual simulation, optional, require -tstart
            #  -uic - skip initial operating point solution, optional
            #  -name - name argument, optional
            # ```
            # .TRAN <initial step value> <final time value>
            # + [<start time value> [<step ceiling value>]] [NOOP] [UIC]
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::Analyses::Tran new -tstep 1e-9 -tstop 10e-6 -name dc1
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
            # ::SpiceGenTcl::Xyce::Analyses::Op new -name op1
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
