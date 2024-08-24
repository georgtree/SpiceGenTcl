
namespace eval SpiceGenTcl {
    namespace eval Ngspice::Analyses {
        namespace export Dc Ac Tran Op Disto Noise Pz SensAc SensDc Sp Tf
    }
}

namespace eval SpiceGenTcl::Ngspice::Analyses {
    
    
    # ________________________ Dc class _________________________ #

    oo::class create Dc {
        superclass SpiceGenTcl::Analysis
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
            # SpiceGenTcl::Analyses::Dc new v1 {time1 -eq} 5 0.1 -name dc1
            # ```
            set arguments [argparse {
                -name=
            }]
            if {[info exists name]} {
                set name $name
            } else {
                set name [self object]
            }
            set params [list "srcnam $srcnam -posnocheck" "vstart $vstart" "vstop $vstop" "vincr $vincr"]
            next dc $params -name $name
        }
    }

    # ________________________ Ac class _________________________ #

    oo::class create Ac {
        superclass SpiceGenTcl::Analysis
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
            # SpiceGenTcl::Analyses::Ac new dec 10 1 1e6 -name dc1
            # ```
            set arguments [argparse {
                -name=
            }]
            if {[info exists name]} {
                set name $name
            } else {
                set name [self object]
            }
            set params [list "$variation -sw" "n $n" "fstart $fstart" "fstop $fstop"]
            next ac $params -name $name
        }
    }

    # ________________________ SensAc class _________________________ #

    oo::class create SensAc {
        superclass SpiceGenTcl::Analysis
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
            # SpiceGenTcl::Analyses::SensAc new v(1,out) dec 10 1 1e6 -name dc1
            # ```
            set arguments [argparse {
                -name=
            }]
            if {[info exists name]} {
                set name $name
            } else {
                set name [self object]
            }
            set params [list "outvar $outVar -posnocheck" "ac -sw" "$variation -sw" "n $n" "fstart $fstart" "fstop $fstop"]
            next sens $params -name $name
        }
    }
    
    # ________________________ SensDc class _________________________ #

    oo::class create SensDc {
        superclass SpiceGenTcl::Analysis
        constructor {outVar args} {
            # Creates object of class `SensDc` that describes SENS dc analysis. 
            #  outVar - output variable
            #  args - optional name argument
            # ```
            # .senc variation n fstart fstop
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Analyses::SensDc new v(1,out) -name sensdc1
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
        superclass SpiceGenTcl::Analysis
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
            # SpiceGenTcl::Analyses::Tran new 1e-9 10e-6 -name dc1
            # ```
            set arguments [argparse {
                -name=
                {-uic -boolean}
            }]
            if {[info exists name]} {
                set name $name
            } else {
                set name [self object]
            }
            if {$uic==1} {
                set params [list "tstep $tstep" "tstop $tstop" "uic -sw"]
            } else {
                set params [list "tstep $tstep" "tstop $tstop"]
            }
            
            next tran $params -name $name
        }
    }
    
    # ________________________ Op class _________________________ #

    oo::class create Op {
        superclass SpiceGenTcl::Analysis
        constructor {args} {
            # Creates object of class `Op` that describes OP analysis. 
            #  args - optional name argument
            # ```
            # .op
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Analyses::Op new -name op1
            # ```
            my variable Name
            set arguments [argparse {
                -name=
            }]
            if {[info exists name]} {
                my SetName $name
            } else {
                my SetName [self object]
            }
            my SetType op
        }
        method genSPICEString {} {
            return ".[my getType]"
        }
    }
}