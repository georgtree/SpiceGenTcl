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
        superclass ::SpiceGenTcl::Common::Analyses::Dc
    }

###  Ac class

    oo::class create Ac {
        superclass ::SpiceGenTcl::Common::Analyses::Ac
    }

###  Sp class

    oo::class create Sp {
        superclass ::SpiceGenTcl::Analysis
        mixin ::SpiceGenTcl::Utility
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
            # Synopsis: -variation value -n value -fstart value -fstop value ?-name value? ?-donoise?
            set arguments [argparse -inline {
                -name=
                {-variation= -required -enum {dec oct lin}}
                {-n= -required}
                {-fstart= -required}
                {-fstop= -required}
                {-donoise}
            }]
            my NameProcess $arguments [self object]
            lappend params [list variation [dget $arguments variation] -posnocheck]
            set paramsOrder {n fstart fstop}
            my ParamsProcess $paramsOrder $arguments params
            if {[dexist $arguments donoise]} {
                lappend params {donoise 1 -pos}
            }
            ##nagelfar variable name
            next sp $params -name $name
        }
    }

###  SensAc class

    oo::class create SensAc {
        superclass ::SpiceGenTcl::Analysis
        mixin ::SpiceGenTcl::Utility
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
            # Synopsis: -outvar value -variation value -n value -fstart value -fstop value ?-name value?
            set arguments [argparse -inline {
                -name=
                {-outvar= -required}
                {-variation= -required}
                {-n= -required}
                {-fstart= -required}
                {-fstop= -required}
            }]
            my NameProcess $arguments [self object]
            lappend params [list outvar [dget $arguments outvar] -posnocheck]
            lappend params {ac -sw}
            lappend params [list variation [dget $arguments variation] -posnocheck]
            set paramsOrder {n fstart fstop}
            ##nagelfar variable name
            my ParamsProcess $paramsOrder $arguments params
            next sens $params -name $name
        }
    }

###  SensDc class

    oo::class create SensDc {
        superclass ::SpiceGenTcl::Analysis
        mixin ::SpiceGenTcl::Utility
        constructor {args} {
            # Creates object of class `SensDc` that describes SENS dc analysis.
            #  -outvar - output variable
            #  -name - name argument, optional
            # ```
            # .senc outvar
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Analyses::SensDc new -outvar v(1,out) -name sensdc1
            # ```
            # Synopsis: -outvar value ?-name value?
            set arguments [argparse -inline {
                -name=
                {-outvar= -required}
            }]
            ##nagelfar variable name
            my NameProcess $arguments [self object]
            lappend params [list outvar [dget $arguments outvar] -posnocheck]
            next sens $params -name $name
        }
    }

###  Tran class

    oo::class create Tran {
        superclass ::SpiceGenTcl::Common::Analyses::Tran
    }

###  Op class

    oo::class create Op {
        superclass ::SpiceGenTcl::Common::Analyses::Op
    }
}
