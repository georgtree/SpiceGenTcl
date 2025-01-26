#  .|'''.|            ||                   ..|'''.|                   |''||''|         '||'
#  ||..  '  ... ...  ...    ....    ....  .|'     '    ....  .. ...      ||      ....   ||  
#   ''|||.   ||'  ||  ||  .|   '' .|...|| ||    .... .|...||  ||  ||     ||    .|   ''  ||  
# .     '||  ||    |  ||  ||      ||      '|.    ||  ||       ||  ||     ||    ||       ||  
# |'....|'   ||...'  .||.  '|...'  '|...'  ''|...'|   '|...' .||. ||.   .||.    '|...' .||. 
#            ||                                                                             
#           ''''                                                                            
# specModelsClassesLtspice.tcl
# Describes LTspice models classes
#
# Copyright (c) 2024 George Yashin, georgtree@gmail.com
#
# MIT License
# See the file "LICENSE.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

namespace eval ::SpiceGenTcl::Ltspice::BasicDevices {
    
    namespace export VSwitchModel CSwitchModel 
   
###  VSwitchModel class 
    
    oo::class create VSwitchModel {
        superclass ::SpiceGenTcl::Model
        constructor {name args} {
            # Creates object of class `VSwitchModel` that describes voltage switch model.
            #  name - name of the model 
            #  args - keyword instance parameters 
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::BasicDevices::VSwitchModel new swmod -vt 1 -vh 0.5 -ron 1 -roff 1e6
            # ```
            # Synopsis: name ?-option value ...?
            next $name sw [my argsPreprocess [list vt vh ron roff lser vser ilimit] {*}$args]
        }
    }

###  CSwitchModel class 
    
    oo::class create CSwitchModel {
        superclass ::SpiceGenTcl::Model
        constructor {name args} {
            # Creates object of class `CSwitchModel` that describes current switch model.
            #  name - name of the model 
            #  args - keyword instance parameters 
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::BasicDevices::CSwitchModel new cswmod -it 1 -ih 0.5 -ron 1 -roff 1e6
            # ```
            # Synopsis: name ?-option value ...?
            next $name csw [my argsPreprocess [list it ih ron roff] {*}$args]
        }
    }
}
    
namespace eval ::SpiceGenTcl::Ltspice::SemiconductorDevices {    
    
    namespace export DiodeModel BjtGPModel JfetModel MesfetModel
    
###  DiodeModel class 
    
    oo::class create DiodeModel {
        superclass ::SpiceGenTcl::Model
        constructor {name args} {
            # Creates object of class `DiodeModel` that describes semiconductor diode model.
            #  name - name of the model 
            #  args - keyword model parameters, for details please see LTspice manual.
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::SemiconductorDevices::DiodeModel new diodemod -is 1e-14 -n 1.2 -rs 0.01 -cjo 1e-9
            # ```
            # Synopsis: name ?-option value ...?
            set paramsNames [list is rs n tt cjo vj m eg xti kf af fc bv nbv ibv ibvl nbvl tnom isr nr ikf tikf trs1\
                                     trs2 tbv1 tbv2 perim isw ns rsw cjsw vjsw mjsw fcs vp]
            next $name d [my argsPreprocess $paramsNames {*}$args]
        }
    }

###  DiodeIdealModel class 
    
    oo::class create DiodeIdealModel {
        superclass ::SpiceGenTcl::Model
        constructor {name args} {
            # Creates object of class `DiodeIdealModel` that describes semiconductor diode model.
            #  name - name of the model 
            #  args - keyword model parameters, for details please see LTspice manual.
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::SemiconductorDevices::DiodeIdealModel new diodemod -ron 1e-2 -roff 1e8
            # ```
            # Synopsis: name ?-option value ...?
            set paramsNames [list ron roff vfwd vrev rrev ilimit revilimit epsilon revepsilon]
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
            #  args - keyword model parameters, for details please see LTspice manual.
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::SemiconductorDevices::DiodeModel new bjtmod npn -is 1e-15 -bf 200 -vaf 100 -cje 1e-10
            # ```
            # Synopsis: name type ?-option value ...?
            set paramsNames [list is ibc ibe bf nf vaf ikf nk ise ne br nr var ikr isc nc rb irb rbm re rc cje vje mje\
                                    tf xtf vtf itf ptf cjc vjc mjc xcjc xcjc2 extsub tr cjs xcjs vjs mjs xtb eg xti kf\
                                    af fc subs bvcbo nbvcbo bvbe ibvbe nbvbe tnom cn d gamma qco quasimod rco vg vo tre1\
                                    tre2 trb1 trb2 trc1 trc2 trm1 trm2 iss ns tvaf1 tvaf2 tvar1 tvar2 tikf1 tikf2 trbm1\
                                    trbm2 tbvcbo1 tbvcbo2]
            set params [my argsPreprocess $paramsNames {*}$args]
            next $name $type $params
        }
    } 
        
###  Jfet1Model class 
    
    oo::class create JfetModel {
        superclass ::SpiceGenTcl::Model
        constructor {name type args} {
            # Creates object of class `JfetModel` that describes JFET level 1 model with Parker Skellern modification.
            #  name - name of the model 
            #  type - njf or pjf
            #  args - keyword model parameters, for details please see LTspice manual.
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::SemiconductorDevices::JfetModel new jfetmod njf -vto 2 -beta 1e-3 -lambda 1e-4 -cgd 1e-12
            # ```
            # Synopsis: name type ?-option value ...?
            set paramsNames [list vto beta lambda rd rs cgs cgd pb m is b kf af nlev gdsnoi fc tnom vtotc n isr nr alpha\
                                     vk xti mfg]
            next $name $type [my argsPreprocess $paramsNames {*}$args]
        }
    }
    
###  Mesfet1Model class 
    
    oo::class create MesfetModel {
        superclass ::SpiceGenTcl::Model
        constructor {name type args} {
            # Creates object of class `MesfetModel` that describes MESFET model by Statz e.a..
            #  name - name of the model 
            #  type - nmf or pmf
            #  args - keyword model parameters, for details please see LTspice manual, chapter 10.
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::SemiconductorDevices::Jfet2Model new jfetmod njf -vto -2 -beta 10e-4 -rs 1e-4 -vbi 1.2
            # ```
            # Synopsis: name type ?-option value ...?
            set params [my argsPreprocess [list vto beta b alpha lambda rd rs cgs cgd pb kf af fc is] {*}$args]
            next $name $type $params
        }
    } 
}
