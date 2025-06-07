#  .|'''.|            ||                   ..|'''.|                   |''||''|         '||'
#  ||..  '  ... ...  ...    ....    ....  .|'     '    ....  .. ...      ||      ....   ||
#   ''|||.   ||'  ||  ||  .|   '' .|...|| ||    .... .|...||  ||  ||     ||    .|   ''  ||
# .     '||  ||    |  ||  ||      ||      '|.    ||  ||       ||  ||     ||    ||       ||
# |'....|'   ||...'  .||.  '|...'  '|...'  ''|...'|   '|...' .||. ||.   .||.    '|...' .||.
#            ||
#           ''''
# specAnalysesClassesCommon.tcl
# Describes Common analyses classes
#
# Copyright (c) 2024 George Yashin, georgtree@gmail.com
#
# MIT License
# See the file "LICENSE.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

namespace eval ::SpiceGenTcl {
    namespace eval Common::Analyses {
        namespace export Dc Ac Tran Op
    }
}

namespace eval ::SpiceGenTcl::Common::Analyses {

### Dc class
    oo::class create Dc {
        superclass ::SpiceGenTcl::Analysis
        mixin ::SpiceGenTcl::Utility
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
            # ::SpiceGenTcl::Common::Analyses::Dc new -src v1 -start {time1 -eq} -stop 5 -incr 0.1 -name dc1
            # ```
            # Synopsis: -src value -start value -stop value -incr value ?-name value?
            set arguments [argparse -inline -help {Creates object of class `Dc` that describes DC analysis} {
                {-name= -help {Name argument}}
                {-src= -required -help {Name of independent voltage or current source, a resistor, or the circuit\
                                                temperature}}
                {-start= -required -help {Start value}}
                {-stop= -required -help {Stop value}}
                {-incr= -required -help {Incrementing value}}
            }]
            my NameProcess $arguments [self object]
            lappend params [list -posnocheck src [dget $arguments src]]
            set paramsOrder {start stop incr}
            my ParamsProcess $paramsOrder $arguments params
            ##nagelfar variable name
            next dc $params -name $name
        }
    }

###  Ac class
    oo::class create Ac {
        superclass ::SpiceGenTcl::Analysis
        mixin ::SpiceGenTcl::Utility
        constructor {args} {
            # Creates object of class `Ac` that describes AC analysis.
            #  -variation - parameter that defines frequency scale, could be dec, oct or lin
            #  -n - number of points
            #  -fstart - start frequency
            #  -fstop - stop frequency
            #  -name - name argument, optional
            # ```
            # .ac variation n fstart fstop
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Analyses::Ac new -variation dec -n 10 -fstart 1 -fstop 1e6 -name dc1
            # ```
            # Synopsis: -variation value -n value -fstart value -fstop value ?-name value?
            set arguments [argparse -inline -help {Creates object of class `Ac` that describes AC analysis} {
                -name=
                {-variation= -required -enum {dec oct lin} -help {Frequency scale}}
                {-n= -required -help {Number of points}}
                {-fstart= -required -help {Start frequency}}
                {-fstop= -required -help {Stop frequency}}
            }]
            my NameProcess $arguments [self object]
            lappend params [list -posnocheck variation [dget $arguments variation]]
            set paramsOrder {n fstart fstop}
            my ParamsProcess $paramsOrder $arguments params
            ##nagelfar variable name
            next ac $params -name $name
        }
    }

###  Tran class
    oo::class create Tran {
        superclass ::SpiceGenTcl::Analysis
        mixin ::SpiceGenTcl::Utility
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
            # ::SpiceGenTcl::Common::Analyses::Tran new -tstep 1e-9 -tstop 10e-6 -name dc1
            # ```
            # Synopsis: -tstep value -tstop value ?-tstart value ?-tmax value?? ?-uic? ?-name value?
            set arguments [argparse -inline -help {Creates object of class `Tran` that describes TRAN analysis} {
                -name=
                {-tstep= -required -help {Size of maximum time step for plotting}}
                {-tstop= -required -help {Stop time value}}
                {-tstart= -help {Start time of saving data}}
                {-tmax= -require {tstart} -help {Size of maximum time step in actual simulation}}
                {-uic -boolean -help {Skip initial operating point solution}}
            }]
            my NameProcess $arguments [self object]
            set paramsOrder {tstep tstop tstart tmax}
            my ParamsProcess $paramsOrder $arguments params
            if {[dget $arguments uic]} {
                lappend params {-sw uic}
            }
            ##nagelfar variable name
            next tran $params -name $name
        }
    }

###  Op class
    oo::class create Op {
        superclass ::SpiceGenTcl::Analysis
        mixin ::SpiceGenTcl::Utility
        constructor {args} {
            # Creates object of class `Op` that describes OP analysis.
            #  -name - name argument, optional
            # ```
            # .op
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Analyses::Op new -name op1
            # ```
            # Synopsis: ?-name value?
            set arguments [argparse -inline -help {Creates object of class `Op` that describes OP analysis} {
                -name=
            }]
            my NameProcess $arguments [self object]
            ##nagelfar variable name
            next op {} -name $name
        }
    }
}
