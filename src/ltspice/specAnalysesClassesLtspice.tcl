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

    oo::class create Dc {
        superclass ::SpiceGenTcl::Common::Analyses::Dc
    }

    oo::class create Ac {
        superclass ::SpiceGenTcl::Common::Analyses::Ac
    }

    oo::class create Tran {
        superclass ::SpiceGenTcl::Common::Analyses::Tran
    }

    oo::class create Op {
        superclass ::SpiceGenTcl::Common::Analyses::Op
    }
}
