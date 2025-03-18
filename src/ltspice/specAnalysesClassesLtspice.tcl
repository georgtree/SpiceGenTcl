#  .|'''.|            ||                   ..|'''.|                   |''||''|         '||'
#  ||..  '  ... ...  ...    ....    ....  .|'     '    ....  .. ...      ||      ....   ||
#   ''|||.   ||'  ||  ||  .|   '' .|...|| ||    .... .|...||  ||  ||     ||    .|   ''  ||
# .     '||  ||    |  ||  ||      ||      '|.    ||  ||       ||  ||     ||    ||       ||
# |'....|'   ||...'  .||.  '|...'  '|...'  ''|...'|   '|...' .||. ||.   .||.    '|...' .||.
#            ||
#           ''''
# specAnalysesClassesLtspice.tcl
# Describes Ltspice analyses classes
#
# Copyright (c) 2024 George Yashin, georgtree@gmail.com
#
# MIT License
# See the file "LICENSE.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

namespace eval ::SpiceGenTcl {
    namespace eval Ltspice::Analyses {
        namespace export Dc Ac Tran Op
    }
}

namespace eval ::SpiceGenTcl::Ltspice::Analyses {

###  Dc class

    oo::class create Dc {
        superclass ::SpiceGenTcl::Common::Analyses::Dc
    }

###  Ac class

    oo::class create Ac {
        superclass ::SpiceGenTcl::Common::Analyses::Ac
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
