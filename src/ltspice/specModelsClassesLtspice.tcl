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
    
    namespace export DiodeModel BjtGPModel Jfet1Model Jfet2Model Mesfet1Model
    
###  DiodeModel class 
    
    oo::class create DiodeModel {
        superclass ::SpiceGenTcl::Model
        constructor {name args} {
            # Creates object of class `DiodeModel` that describes semiconductor diode model.
            #  name - name of the model 
            #  args - keyword model parameters, for details please see Ngspice manual, chapter 7.
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::SemiconductorDevices::DiodeModel new diodemod -is 1e-14 -n 1.2 -rs 0.01 -cj0 1e-9
            # ```
            # Synopsis: name ?-option value ...?
            set paramsNames [list level jws n rs bv ibv nbv ikr jtun jtunsw ntun xtitun keg isr nr \
                    fc fcs mjsw php tt lm lp wm wp xom xoi xm xp eg trs2 tm1 tm2 ttt1 ttt2 \
                    xti tlev tlevc ctp tcv {is js} {ikf ik} {cjo cj0} {cjp cjsw} {m mj} {vj pb} \
                    {tnom tref} {trs1 trs} {cta ctc}]
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
            set paramsNames [list subs is ibe ibc iss bf nf {vaf va} ikf {nkf nk} ise ne br \
                    nr {var vb} ikr isc nc rb irb rbm re rc cje {vje pe} {mje me} tf xtf \
                    vtf itf ptf cjc {vjc pc} mjc xcjc tr cjs {vjs ps} {mjs ms} xtb eg \
                    xti kf af fc {tnom tref} tlev tlevc tre1 tre2 trc1 trc2 trb1 trb2 \
                    trbm1 trbm2 tbf1 tbf2 tbr1 tbr2 tikf1 tikf2 tikr1 tikr2 tirb1 tirb2 \
                    tnc1 tnc2 tne1 tne2 tnf1 tnf2 tnr1 tnr2 tvaf1 tvaf2 tvar1 tvar2 ctc \
                    cte cts tvjc tvje titf1 titf2 ttf1 ttf2 ttr1 ttr2 tmje1 tmje2 tmjc1 tmjc2 \
                    rco gamma qco vg cn d]
            set params [my argsPreprocess $paramsNames {*}$args]
            next $name $type [linsert $params 0 [list level 1]]
        }
    } 
        
###  Jfet1Model class 
    
    oo::class create Jfet1Model {
        superclass ::SpiceGenTcl::Model
        constructor {name type args} {
            # Creates object of class `Jfet1Model` that describes JFET level 1 model with Parker Skellern modification.
            #  name - name of the model 
            #  type - njf or pjf
            #  args - keyword model parameters, for details please see LTspice manual.
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::SemiconductorDevices::Jfet1Model new jfetmod njf -vto 2 -beta 1e-3 -lambda 1e-4 -cgd 1e-12
            # ```
            # Synopsis: name type ?-option value ...?
            set paramsNames [list vto beta lambda rd rs cgs cgd pb is b kf af nlev gdsnoi fc tnom tcv vtotc bex betatce\
                                     xti eg]
            next $name $type [linsert [my argsPreprocess $paramsNames {*}$args] 0 [list level 1]]
        }
    }
    
###  Jfet2Model class 
    
    oo::class create Jfet2Model {
        superclass ::SpiceGenTcl::Model
        constructor {name type args} {
            # Creates object of class `Jfet2Model` that describes JFET level 2 model with Parker Skellern modification.
            #  name - name of the model 
            #  type - njf or pjf
            #  args - keyword model parameters, for details please see LTspice manual.
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::SemiconductorDevices::Jfet2Model new jfetmod njf -vto -2 -beta 10e-4 -rs 1e-4 -vbi 1.2
            # ```
            # Synopsis: name type ?-option value ...?
            set paramsNames [list acgam beta cgd cgs delta fc hfeta hfe1 hfe2 hfgam hfg1 hfg2 ibd is lfgam lfg1 lfg2\
                                     mvst n p q rs rd  taud taug vbd vbi vst vto xc xi z rg lg ls ld cdss afac nfing\
                                     tnom temp]
            next $name $type [linsert [my argsPreprocess $paramsNames {*}$args] 0 [list level 2]]
        }
    } 
    
###  Mesfet1Model class 
    
    oo::class create Mesfet1Model {
        superclass ::SpiceGenTcl::Model
        constructor {name type args} {
            # Creates object of class `Mesfet1Model` that describes MESFET model by Statz e.a..
            #  name - name of the model 
            #  type - nmf or pmf
            #  args - keyword model parameters, for details please see LTspice manual, chapter 10.
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::SemiconductorDevices::Jfet2Model new jfetmod njf -vto -2 -beta 10e-4 -rs 1e-4 -vbi 1.2
            # ```
            # Synopsis: name type ?-option value ...?
            set params [my argsPreprocess [list vto beta b alpha lambda rd rs cgs cgd pb kf af fc] {*}$args]
            next $name $type [linsert $params 0 [list level 1]]
        }
    } 
}
