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

    oo::class create Dc {
        superclass ::SpiceGenTcl::Common::Analyses::Dc
    }

    oo::class create Ac {
        superclass ::SpiceGenTcl::Common::Analyses::Ac
    }

    oo::class create Sp {
        superclass ::SpiceGenTcl::Analysis
        mixin ::SpiceGenTcl::Utility
        constructor {args} {
            # Creates object of class `Sp` that describes s-parameter analysis.
            #  -variation value - parameter that defines frequency scale, could be `dec`, `oct` or `lin`
            #  -n value - number of points
            #  -fstart value - start frequency
            #  -fstop value - start frequency
            #  -name value - name argument, optional
            #  -donoise - activate s-parameter noise
            # ```
            # .ac variation n fstart fstop <donoise>
            # ```
            # Example of class initialization:
            # ```
            # Sp new -variation dec -n 10 -fstart 1 -fstop 1e6 -name sp1 -donoise
            # ```
            # Synopsis: -variation value -n value -fstart value -fstop value ?-name value? ?-donoise?
            set arguments [argparse -inline -help {Creates object of class 'Sp' that describes s-parameter analysis} {
                -name=
                {-variation= -required -enum {dec oct lin} -help {Frequency scale}}
                {-n= -required -help {Number of points}}
                {-fstart= -required -help {Start frequency}}
                {-fstop= -required -help {Stop frequency}}
                {-donoise -help {Activate s-parameter noise}}
            }]
            my NameProcess $arguments [self object]
            lappend params [list -posnocheck variation [dget $arguments variation]]
            set paramsOrder {n fstart fstop}
            my ParamsProcess $paramsOrder $arguments params
            if {[dexist $arguments donoise]} {
                lappend params {-pos donoise 1}
            }
            ##nagelfar variable name
            next sp $params -name $name
        }
    }

    oo::class create SensAc {
        superclass ::SpiceGenTcl::Analysis
        mixin ::SpiceGenTcl::Utility
        constructor {args} {
            # Creates object of class `SensAc` that describes SENS ac analysis.
            #  -outvar value - output variable
            #  -variation value - parameter that defines frequency scale, could be `dec`, `oct` or `lin`
            #  -n value - number of points
            #  -fstart value - start frequency
            #  -fstop value - start frequency
            #  -name value - name argument, optional
            # ```
            # .sens outvar ac variation n fstart fstop
            # ```
            # Example of class initialization:
            # ```
            # SensAc new -outvar v(1,out) -variation dec -n 10 -fstart 1 -fstop 1e6 -name dc1
            # ```
            # Synopsis: -outvar value -variation value -n value -fstart value -fstop value ?-name value?
            set arguments [argparse -inline -help {Creates object of class 'SensAc' that describes SENS ac analysis} {
                -name=
                {-outvar= -required -help {Output variable}}
                {-variation= -required -help {Frequency scale}}
                {-n= -required -help {Number of points}}
                {-fstart= -required -help {Start frequency}}
                {-fstop= -required -help {Stop frequency}}
            }]
            my NameProcess $arguments [self object]
            lappend params [list -posnocheck outvar [dget $arguments outvar]]
            lappend params {-sw ac}
            lappend params [list -posnocheck variation [dget $arguments variation]]
            set paramsOrder {n fstart fstop}
            ##nagelfar variable name
            my ParamsProcess $paramsOrder $arguments params
            next sens $params -name $name
        }
    }

    oo::class create SensDc {
        superclass ::SpiceGenTcl::Analysis
        mixin ::SpiceGenTcl::Utility
        constructor {args} {
            # Creates object of class `SensDc` that describes SENS dc analysis.
            #  -outvar value - output variable
            #  -name value - name argument, optional
            # ```
            # .senc outvar
            # ```
            # Example of class initialization:
            # ```
            # SensDc new -outvar v(1,out) -name sensdc1
            # ```
            # Synopsis: -outvar value ?-name value?
            set arguments [argparse -inline -help {Creates object of class 'SensDc' that describes SENS dc analysis} {
                -name=
                {-outvar= -required -help {Output variable}}
            }]
            ##nagelfar variable name
            my NameProcess $arguments [self object]
            lappend params [list -posnocheck outvar [dget $arguments outvar]]
            next sens $params -name $name
        }
    }

    oo::class create Tran {
        superclass ::SpiceGenTcl::Common::Analyses::Tran
    }

    oo::class create Op {
        superclass ::SpiceGenTcl::Common::Analyses::Op
    }
}
