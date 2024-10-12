
namespace eval ::SpiceGenTcl {
    namespace eval Xyce::Analyses {
        namespace export Dc Ac Tran Op Sens
    }
}

namespace eval ::SpiceGenTcl::Xyce::Analyses {
    
    
    # ________________________ Dc class _________________________ #

    oo::class create Dc {
        superclass ::SpiceGenTcl::Analysis
        constructor {varnam start stop incr args} {
            # Creates object of class `Dc` that describes DC analysis. 
            #  varnam - name of independent voltage or current source, a resistor, the circuit temperature or parameter
            #  start - start value
            #  stop - stop value
            #  incr - incrementing value
            #  args - optional name argument
            # ```
            # .dc varnam start stop incr
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Analyses::Xyce::Dc new v1 {time1 -eq} 5 0.1 -name dc1
            # ```
            set arguments [argparse {
                -name=
            }]
            if {[info exists name]} {
                set name $name
            } else {
                set name [self object]
            }
            set argsNames [lrange [lindex [info class constructor [self class]] 0] 1 end-1]
            set paramList [list "varnam $varnam -posnocheck"]
            foreach argName $argsNames {
                set argVal [subst $[subst $argName]]
                if {[llength $argVal]>1} {
                    if {[lindex $argVal 1]=="-eq"} {
                        lappend paramList "$argName [lindex $argVal 0] -poseq"
                    } else {
                        error "Wrong qualificator '[lindex $argVal 1]' for $argName parameter"
                    }
                } else {
                    lappend paramList "$argName $argVal -pos"
                }
            }
            next dc $paramList -name $name
        }
    }

    # ________________________ Ac class _________________________ #

    oo::class create Ac {
        superclass ::SpiceGenTcl::Analysis
        constructor {variation n fstart fstop args} {
            # Creates object of class `Ac` that describes AC analysis. 
            #  variation - parameter that defines frequency scale, could be dec, oct or lin
            #  n - number of points
            #  fstart - start frequency
            #  fstop - start frequency
            #  args - optional name argument
            # ```
            # .ac variation n fstart fstop
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Analyses::Xyce::Ac new dec 10 1 1e6 -name dc1
            # ```
            set arguments [argparse {
                -name=
            }]
            if {[info exists name]} {
                set name $name
            } else {
                set name [self object]
            }
            set argsNames [lrange [lindex [info class constructor [self class]] 0] 1 end-1]
            set paramList [list "$variation -sw"]
            foreach argName $argsNames {
                set argVal [subst $[subst $argName]]
                if {[llength $argVal]>1} {
                    if {[lindex $argVal 1]=="-eq"} {
                        lappend paramList "$argName [lindex $argVal 0] -poseq"
                    } else {
                        error "Wrong qualificator '[lindex $argVal 1]' for $argName parameter"
                    }
                } else {
                    lappend paramList "$argName $argVal -pos"
                }
            }
            next ac $paramList -name $name
        }
    }

    # ________________________ SensAc class _________________________ #

    oo::class create Sens {
        superclass ::SpiceGenTcl::Analysis
        constructor {objfunc param args} {
            # Creates object of class `Sens` that describes SENS ac analysis. 
            #  objfunc - output expression
            #  param - circuit parameter(s)
            #  args - optional name argument
            # ```
            # .sens objfunc=$objfunc param=$param
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Analyses::Xyce::Sens new "0.5*(V(B)-3.0)**2.0" "R1:R,R2:R" -name dc1
            # ```
            set arguments [argparse {
                -name=
            }]
            if {[info exists name]} {
                set name $name
            } else {
                set name [self object]
            }
            set params [list "objfunc {$objfunc} -eq" "param $param -nocheck"]
            next sens $params -name $name
        }
    }
    
    # ________________________ Tran class _________________________ #

    oo::class create Tran {
        superclass ::SpiceGenTcl::Analysis
        constructor {intstep tstop args} {
            # Creates object of class `Tran` that describes TRAN analysis. 
            #  intstep - initial step value
            #  tstop - stop time value
            #  args - optional name argument
            # ```
            # .tran intstep tstop timestart maxstep
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Analyses::Xyce::Tran new 1e-6 {tend -eq} -starttime 0 -maxstep 1e-9
            # ```
            set arguments [argparse -inline {
                -name=
                -starttime=
                {-maxstep= -require {starttime}}
                {-uic -boolean}
            }]
            if {[dict exists $arguments name]} {
                set name [dict get $arguments name]
            } else {
                set name [self object]
            }
            set argsNames [lrange [lindex [info class constructor [self class]] 0] 0 end-1]
            set paramList ""
            foreach argName $argsNames {
                set argVal [subst $[subst $argName]]
                if {[llength $argVal]>1} {
                    if {[lindex $argVal 1]=="-eq"} {
                        lappend paramList "$argName [lindex $argVal 0] -poseq"
                    } else {
                        error "Wrong qualificator '[lindex $argVal 1]' for $argName parameter"
                    }
                } else {
                    lappend paramList "$argName $argVal -pos"
                }
            }
            if {[dict exists $arguments starttime]} {
                lappend paramList "starttime [dict get $arguments starttime] -pos" 
                if {[dict exists $arguments maxstep]} {
                    lappend paramList "maxstep [dict get $arguments maxstep] -pos"
                }
            }
            if {[dict get $arguments uic]==1} {
                lappend paramList "uic -sw"
            }
            next tran $paramList -name $name
        }
    }
    
    # ________________________ Op class _________________________ #

    oo::class create Op {
        superclass ::SpiceGenTcl::Analysis
        constructor {args} {
            # Creates object of class `Op` that describes OP analysis. 
            #  args - optional name argument
            # ```
            # .op
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Analyses::Xyce::Op new -name op1
            # ```
            my variable Name
            set arguments [argparse {
                -name=
            }]
            if {[info exists name]} {
                my configure -Name $name
            } else {
                my configure -Name [self object]
            }
            my configure -Type op
        }
        method genSPICEString {} {
            return ".[my configure -Type]"
        }
    }
}