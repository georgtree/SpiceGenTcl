#  .|'''.|            ||                   ..|'''.|                   |''||''|         '||'
#  ||..  '  ... ...  ...    ....    ....  .|'     '    ....  .. ...      ||      ....   ||  
#   ''|||.   ||'  ||  ||  .|   '' .|...|| ||    .... .|...||  ||  ||     ||    .|   ''  ||  
# .     '||  ||    |  ||  ||      ||      '|.    ||  ||       ||  ||     ||    ||       ||  
# |'....|'   ||...'  .||.  '|...'  '|...'  ''|...'|   '|...' .||. ||.   .||.    '|...' .||. 
#            ||                                                                             
#           ''''                                                                            
# specMiscClassesNgspice.tcl
# Describes Ngspice miscellaneous classes
#
# Copyright (c) 2024 George Yashin, georgtree@gmail.com
#
# MIT License
# See the file "LICENSE.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

namespace eval ::SpiceGenTcl {
    namespace eval Ngspice::Misc {
        namespace export OptionsNgspice
    }
}

namespace eval ::SpiceGenTcl::Ngspice::Misc {


###  OptionsNgspice class 

    oo::class create OptionsNgspice {
        superclass ::SpiceGenTcl::Options
        mixin ::SpiceGenTcl::Utility
        constructor {args} {
            # Creates object of class `OptionsNgspice` that describes Ngspice simulation options. 
            #   args - keyword instance parameters 
            # ```
            # .options opt1 opt2 ... (or opt=optval ...)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Misc::OptionsNgspice new -klu -abstol 1e-10 -maxord 6
            # ```
            # Synopsis: ?-key value ...? ?-key ...?
            set swParams {sparse klu acct noacct noinit list nomod nopage node norefvalue opts seedinfo savecurrents\
                                  keepopinfo noopiter noopac autostop interp badmos3 trytocompact}
            set keyValParams {seed temp tnom warn maxwarns abstol gmin gminsteps itl1 itl2 pivrel pivtol reltol rshunt\
                                      vntol rseries cshunt chgtol convstep convabsstep itl3 itl4 itl5 itl6 maxevtiter\
                                      maxopalter maxord method noopalter ramptime srcsteps trtol xmu defad defas defl\
                                      defw scale}
            set arguments [argparse -inline "
                [my buildArgStr $keyValParams]
                [my buildSwArgStr $swParams]
            "]
            my NameProcess $arguments [self object]
            dict for {paramName value} $arguments {
                if {$paramName in $keyValParams} {
                    if {([llength $value]>1) && ([@ $value 1] eq {-eq})} {
                        lappend params [list $paramName [@ $value 0] -eq]
                    } else {
                        lappend params [list $paramName $value]
                    }
                } elseif {$paramName in $swParams} {
                    lappend params [list $paramName -sw]
                }
            }
            next $params -name $name
        }
    }
}
