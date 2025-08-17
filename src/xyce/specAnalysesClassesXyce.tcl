#  .|'''.|            ||                   ..|'''.|                   |''||''|         '||'
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
        superclass ::SpiceGenTcl::Common::Analyses::Dc
    }

###  Ac class
    oo::class create Ac {
        superclass ::SpiceGenTcl::Common::Analyses::Ac
    }

###  SensAc class
    oo::class create Sens {
        superclass ::SpiceGenTcl::Analysis
        mixin ::SpiceGenTcl::Utility
        constructor {args} {
            # Creates object of class `Sens` that describes SENS ac analysis.
            #  -objfunc value - output expression
            #  -param value - circuit parameter(s)
            #  -name value - name argument, optional
            # ```
            # .SENS objfunc=<output =ession(s)> param=<circuit parameter(s)>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Analyses::Xyce::Sens new -objfunc "0.5*(V(B)-3.0)**2.0" -param "R1:R,R2:R" -name dc1
            # ```
            # Synopsis: -objfunc value -param value ?-name value?
            set arguments [argparse -inline -help {Creates object of class 'Sens' that describes SENS ac analysis} {
                -name=
                {-objfunc= -required -help {Output expression}}
                {-param= -required -help {Circuit parameter(s)}}
            }]
            my NameProcess $arguments [self object]
            lappend params [list -eq objfunc [dget $arguments objfunc]]
            lappend params [list -nocheck param [dget $arguments param]]
            ##nagelfar variable name
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
