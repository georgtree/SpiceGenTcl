#  .|'''.|            ||                   ..|'''.|                   |''||''|         '||'
#  ||..  '  ... ...  ...    ....    ....  .|'     '    ....  .. ...      ||      ....   ||  
#   ''|||.   ||'  ||  ||  .|   '' .|...|| ||    .... .|...||  ||  ||     ||    .|   ''  ||  
# .     '||  ||    |  ||  ||      ||      '|.    ||  ||       ||  ||     ||    ||       ||  
# |'....|'   ||...'  .||.  '|...'  '|...'  ''|...'|   '|...' .||. ||.   .||.    '|...' .||. 
#            ||                                                                             
#           ''''                                                                            
# specModelsClassesXyce.tcl
# Describes Xyce models classes
#
# Copyright (c) 2024 George Yashin, georgtree@gmail.com
#
# MIT License
# See the file "LICENSE.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

namespace eval ::SpiceGenTcl::Xyce::BasicDevices {
    
    namespace export RModel CModel LModel VSwitchModel CSwitchModel 

    
###  RModel class 
    
    oo::class create RModel {
        superclass ::SpiceGenTcl::Model
        constructor {name args} {
            # Creates object of class `RModel` that describes semiconductor resistor model.
            #  name - name of the model 
            #  args - keyword instance parameters, for details please refer to Xyce reference manual, 2.3.7 section.
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::BasicDevices::RModel new resmod -tc1 1 -tc2 2
            # ```
            # Synopsis: name ?-option value ...?
            next $name r [my argsPreprocess {defw narrow r rsh tc1 tc2 tce tnom} {*}$args]
        }
    }

###  CModel class 
    
    oo::class create CModel {
        superclass ::SpiceGenTcl::Model
        constructor {name args} {
            # Creates object of class `CModel` that describes semiconductor capacitor model.
            #  name - name of the model 
            #  args - keyword instance parameters, for details please refer to Xyce reference manual, 2.3.4 section.
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::BasicDevices::CModel new capmod -tc1 1 -tc2 2
            # ```
            # Synopsis: name ?-option value ...?
            next $name c [my argsPreprocess {c cj cjsw defw narrow tc1 tc2 tnom} {*}$args]
        }
    }

###  LModel class 
    
    oo::class create LModel {
        superclass ::SpiceGenTcl::Model
        constructor {name args} {
            # Creates object of class `LModel` that describes inductor model.
            #  name - name of the model 
            #  args - keyword instance parameters, for details please refer to Xyce reference manual, 2.3.5 section.
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::BasicDevices::LModel new indmod -tc1 1 -tc2 2
            # ```
            # Synopsis: name ?-option value ...?
            next $name l [my argsPreprocess {ic l tc1 tc2 tnom} {*}$args]
        }
    }    
    
###  VSwitchModel class 
    
    oo::class create VSwitchModel {
        superclass ::SpiceGenTcl::Model
        constructor {name args} {
            # Creates object of class `VSwitchModel` that describes voltage switch model.
            #  name - name of the model 
            #  args - keyword instance parameters, for details please refer to Xyce reference manual, 2.3.22 section.
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::VSwitchModel new swmod -von 1 -voff 0.5 -ron 1 -roff 1e6
            # ```
            # Synopsis: name ?-option value ...?
            next $name vswitch [my argsPreprocess {off on roff ron voff von} {*}$args]
        }
    }

###  CSwitchModel class 
    
    oo::class create CSwitchModel {
        superclass ::SpiceGenTcl::Model
        constructor {name args} {
            # Creates object of class `CSwitchModel` that describes current switch model.
            #  name - name of the model 
            #  args - keyword instance parameters, for details please refer to Xyce reference manual, 2.3.22 section.
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::CSwitchModel new cswmod -ion 1 -ioff 0.5 -ron 1 -roff 1e6
            # ```
            # Synopsis: name ?-option value ...?
            next $name iswitch [my argsPreprocess {ioff ion off on roff ron} {*}$args]
        }
    }
}
    
namespace eval ::SpiceGenTcl::Xyce::SemiconductorDevices {    
    
    namespace export DiodeModel BjtGPModel Jfet1Model Jfet2Model Mesfet1Model
    
###  DiodeModel class 
    
    oo::class create DiodeModel {
        superclass ::SpiceGenTcl::Model
        constructor {name args} {
            # Creates object of class `DiodeModel` that describes semiconductor diode model.
            #  name - name of the model 
            #  args - keyword model parameters, for details please refer to Xyce reference manual, 2.3.8 section.
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::SemiconductorDevices::DiodeModel new diodemod -is 1e-14 -n 1.2 -rs 0.01 -cj0 1e-9
            # ```
            # Synopsis: name ?-option value ...?
            set paramsNames {level af bv cj cj0 cjo cjp cjsw eg fc fcs ibv ibvl ikf is isr js jsw kf m mjsw n nbv nbvl\
                                     nr ns php rs tbv1 tbv2 tikf tnom trs trs1 trs2 tt vb vj vjsw xti}
            next $name d [my argsPreprocess $paramsNames {*}$args]
        }
    }    
    
###  BjtGPModel class 
    
    oo::class create BjtGPModel {
        superclass ::SpiceGenTcl::Model
        constructor {name type args} {
            # Creates object of class `BjtGPModel` that describes Gummel-Poon model of semiconductor bipolar transistor.
            #  name - name of the model 
            #  type - npn or pnp
            #  args - keyword model parameters, for details please refer to Xyce reference manual, 2.3.17 section.
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::SemiconductorDevices::DiodeModel new bjtmod npn -is 1e-15 -bf 200 -vaf 100 -cje 1e-10
            # ```
            # Synopsis: name type ?-option value ...?
            set paramsNames {af bf bfm br brm bv c2 c4 ccs cdis cjc cje cjs csub eg esub fc ik ikf ikr \
                    iob irb is isc ise itf jbf jbr jlc jle jrb jtf kf mc me mjc mje mjs ms nc ne nf nk nkf \
                    nle nr pc pe ps psub pt ptf rb rbm rc re tb tcb tempmodel tf tnom tr va vaf var vb vbf \
                                     vjc vje vjs vrb vtf xcjc xtb xtf xti}
            set params [my argsPreprocess $paramsNames {*}$args]
            next $name $type [linsert $params 0 {level 1}]
        }
    } 
        
###  Jfet1Model class 
    
    oo::class create Jfet1Model {
        superclass ::SpiceGenTcl::Model
        constructor {name type args} {
            # Creates object of class `Jfet1Model` that describes JFET level 1 model with Parker Skellern modification.
            #  name - name of the model 
            #  type - njf or pjf
            #  args - keyword model parameters, for details please refer to Xyce reference manual, 2.3.18 section.
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::SemiconductorDevices::Jfet1Model new jfetmod njf -vto 2 -beta 1e-3 -lambda 1e-4 -cgd 1e-12
            # ```
            # Synopsis: name type ?-option value ...?
            set paramsNames {af b beta cgd cgs delta fc is kf lambda pb rd rs tempmodel theta tnom vto}
            next $name $type [linsert [my argsPreprocess $paramsNames {*}$args] 0 {level 1}]
        }
    }
    
###  Jfet2Model class 
    
    oo::class create Jfet2Model {
        superclass ::SpiceGenTcl::Model
        constructor {name type args} {
            # Creates object of class `Jfet2Model` that describes JFET level 2 model with Parker Skellern modification.
            #  name - name of the model 
            #  type - njf or pjf
            #  args - keyword model parameters, for details please refer to Xyce reference manual, 2.3.18 section.
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::SemiconductorDevices::Jfet2Model new jfetmod njf -vto -2 -beta 10e-4 -rs 1e-4 -vbi 1.2
            # ```
            # Synopsis: name type ?-option value ...?
            set paramsNames {af b beta cgd cgs delta fc is kf lambda pb rd rs tempmodel theta tnom vto}
            next $name $type [linsert [my argsPreprocess $paramsNames {*}$args] 0 {level 2}]
        }
    } 
    
###  Mesfet1Model class 
    
    oo::class create Mesfet1Model {
        superclass ::SpiceGenTcl::Model
        constructor {name type args} {
            # Creates object of class `Mesfet1Model` that describes MESFET model by Statz e.a..
            #  name - name of the model 
            #  type - nmf or pmf
            #  args - keyword model parameters, for details please refer to Xyce reference manual, 2.3.19 section.
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::SemiconductorDevices::Jfet2Model new jfetmod njf -vto -2 -beta 10e-4 -rs 1e-4 -vbi 1.2
            # ```
            # Synopsis: name type ?-option value ...?
            set paramsNames {af alpha b beta cgd cgs fc is kf lambda pb rd rs tempmodel tnom vto}
            next $name $type [linsert [my argsPreprocess $paramsNames {*}$args] 0 {level 1}]
        }
    } 
}
