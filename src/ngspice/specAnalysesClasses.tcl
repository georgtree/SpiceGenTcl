
namespace eval ::SpiceGenTcl {
    namespace eval Ngspice::Analyses {
        namespace export Dc Ac Tran Op Disto Noise Pz SensAc SensDc Sp Tf
    }
}

namespace eval ::SpiceGenTcl::Ngspice::Analyses {
    
    
    # ________________________ Dc class _________________________ #

    oo::class create Dc {
        superclass ::SpiceGenTcl::Analysis
        constructor {srcnam vstart vstop vincr args} {
            # Creates object of class `Dc` that describes DC analysis. 
            #  srcnam - name of independent voltage or current source, a resistor, or the circuit temperature
            #  vstart - start value
            #  vstop - stop value
            #  vincr - incrementing value
            #  args - optional name argument
            # ```
            # .dc srcnam vstart vstop vincr
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Analyses::Dc new v1 {time1 -eq} 5 0.1 -name dc1
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
            set paramList [list "srcnam $srcnam -posnocheck"]
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
            # ::SpiceGenTcl::Ngspice::Analyses::Ac new dec 10 1 1e6 -name dc1
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

    oo::class create SensAc {
        superclass ::SpiceGenTcl::Analysis
        constructor {outVar variation n fstart fstop args} {
            # Creates object of class `SensAc` that describes SENS ac analysis. 
            #  outVar - output variable
            #  variation - parameter that defines frequency scale, could be dec, oct or lin
            #  n - number of points
            #  fstart - start frequency
            #  fstop - start frequency
            #  args - optional name argument
            # ```
            # .sens outvar ac variation n fstart fstop
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Analyses::SensAc new v(1,out) dec 10 1 1e6 -name dc1
            # ```
            set arguments [argparse {
                -name=
            }]
            if {[info exists name]} {
                set name $name
            } else {
                set name [self object]
            }
            set argsNames [lrange [lindex [info class constructor [self class]] 0] 2 end-1]
            set paramList [list "outvar $outVar -posnocheck" "ac -sw" "$variation -sw"]
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
            next sens $paramList -name $name
        }
    }
    
    # ________________________ SensDc class _________________________ #

    oo::class create SensDc {
        superclass ::SpiceGenTcl::Analysis
        constructor {outVar args} {
            # Creates object of class `SensDc` that describes SENS dc analysis. 
            #  outVar - output variable
            #  args - optional name argument
            # ```
            # .senc variation n fstart fstop
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Analyses::SensDc new v(1,out) -name sensdc1
            # ```
            set arguments [argparse {
                -name=
            }]
            if {[info exists name]} {
                set name $name
            } else {
                set name [self object]
            }
            set params [list "outvar $outVar -posnocheck"]
            next sens $params -name $name
        }
    }
    
    # ________________________ Tran class _________________________ #

    oo::class create Tran {
        superclass ::SpiceGenTcl::Analysis
        constructor {tstep tstop args} {
            # Creates object of class `Tran` that describes TRAN analysis. 
            #  tstep - size of maximum time step
            #  tstop - stop time value
            #  args - optional name argument
            # ```
            # .tran tstep tstop
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Analyses::Tran new 1e-9 10e-6 -name dc1
            # ```
            set arguments [argparse -inline {
                -name=
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
            # ::SpiceGenTcl::Ngspice::Analyses::Op new -name op1
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