
namespace eval ::SpiceGenTcl::Ngspice::BasicDevices {
    
    namespace export RModel CModel LModel VSwitchModel CSwitchModel 

    
### ________________________ RModel class _________________________ ###
    
    oo::class create RModel {
        superclass ::SpiceGenTcl::Model
        mixin ::SpiceGenTcl::KeyArgsBuilder
        constructor {name args} {
            # Creates object of class `RModel` that describes semiconductor resistor model.
            #  name - name of the model 
            #  args - keyword instance parameters 
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::RModel new resmod -tc1 1 -tc2 2
            # ```
            set paramsNames [list tc1 tc2 rsh defw narrow short tnom kf af wf lf ef {r res}]
            next $name r [my argsPreprocess $paramsNames {*}$args]
        }
    }

### ________________________ CModel class _________________________ ###
    
    oo::class create CModel {
        superclass ::SpiceGenTcl::Model
        mixin ::SpiceGenTcl::KeyArgsBuilder
        constructor {name args} {
            # Creates object of class `CModel` that describes semiconductor capacitor model.
            #  name - name of the model 
            #  args - keyword instance parameters 
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::CModel new capmod -tc1 1 -tc2 2
            # ```
            set paramsNames [list cap cj cjsw defw narrow short tc1 tc2 tnom di thick]
            next $name c [my argsPreprocess $paramsNames {*}$args]
        }
    }

### ________________________ LModel class _________________________ ###
    
    oo::class create LModel {
        superclass ::SpiceGenTcl::Model
        mixin ::SpiceGenTcl::KeyArgsBuilder
        constructor {name args} {
            # Creates object of class `LModel` that describes inductor model.
            #  name - name of the model 
            #  args - keyword instance parameters 
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::LModel new indmod -tc1 1 -tc2 2
            # ```
            set paramsNames [list ind csect dia length tc1 tc2 tnom nt mu]
            next $name l [my argsPreprocess $paramsNames {*}$args]
        }
    }    
### ________________________ VSwitchModel class _________________________ ###
    
    oo::class create VSwitchModel {
        superclass ::SpiceGenTcl::Model
        mixin ::SpiceGenTcl::KeyArgsBuilder
        constructor {name args} {
            # Creates object of class `VSwitchModel` that describes voltage switch model.
            #  name - name of the model 
            #  args - keyword instance parameters 
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::VSwitchModel new swmod -vt 1 -vh 0.5 -ron 1 -roff 1e6
            # ```
            set paramsNames [list vt vh ron roff]
            next $name sw [my argsPreprocess $paramsNames {*}$args]
        }
    }

### ________________________ CSwitchModel class _________________________ ###
    
    oo::class create CSwitchModel {
        superclass ::SpiceGenTcl::Model
        mixin ::SpiceGenTcl::KeyArgsBuilder
        constructor {name args} {
            # Creates object of class `CSwitchModel` that describes current switch model.
            #  name - name of the model 
            #  args - keyword instance parameters 
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::CSwitchModel new cswmod -it 1 -ih 0.5 -ron 1 -roff 1e6
            # ```
            set paramsNames [list it ih ron roff]
            next $name csw [my argsPreprocess $paramsNames {*}$args]
        }
    }
}
    
namespace eval ::SpiceGenTcl::Ngspice::SemiconductorDevices {    
    
    namespace export DiodeModel BjtGPModel Jfet1Model Jfet2Model Mesfet1Model
    
### ________________________ DiodeModel class _________________________ ###
    
    oo::class create DiodeModel {
        superclass ::SpiceGenTcl::Model
        mixin ::SpiceGenTcl::KeyArgsBuilder
        constructor {name args} {
            # Creates object of class `DiodeModel` that describes semiconductor diode model.
            #  name - name of the model 
            #  args - keyword model parameters, for details please see Ngspice manual, chapter 7.
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::SemiconductorDevices::DiodeModel new diodemod -is 1e-14 -n 1.2 -rs 0.01 -cj0 1e-9
            # ```
            set paramsNames [list level jws n rs bv ibv nbv ikr jtun jtunsw ntun xtitun keg isr nr \
                    fc fcs mjsw php tt lm lp wm wp xom xoi xm xp eg trs2 tm1 tm2 ttt1 ttt2 \
                    xti tlev tlevc ctp tcv {is js} {ikf ik} {cjo cj0} {cjp cjsw} {m mj} {vj pb} \
                    {tnom tref} {trs1 trs} {cta ctc}]
            next $name d [my argsPreprocess $paramsNames {*}$args]
        }
    }    
    
### ________________________ BjtGPModel class _________________________ ###
    
    oo::class create BjtGPModel {
        superclass ::SpiceGenTcl::Model
        mixin ::SpiceGenTcl::KeyArgsBuilder
        constructor {name type args} {
            # Creates object of class `BjtGPModel` that describes Gummel-Poon model of semiconductor bipolar transistor.
            #  name - name of the model 
            #  type - npn or pnp
            #  args - keyword model parameters, for details please see Ngspice manual, chapter 8.
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::SemiconductorDevices::DiodeModel new bjtmod npn -is 1e-15 -bf 200 -vaf 100 -cje 1e-10
            # ```
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
        
### ________________________ Jfet1Model class _________________________ ###
    
    oo::class create Jfet1Model {
        superclass ::SpiceGenTcl::Model
        mixin ::SpiceGenTcl::KeyArgsBuilder
        constructor {name type args} {
            # Creates object of class `Jfet1Model` that describes JFET level 1 model with Parker Skellern modification.
            #  name - name of the model 
            #  type - njf or pjf
            #  args - keyword model parameters, for details please see Ngspice manual, chapter 9.
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::SemiconductorDevices::Jfet1Model new jfetmod njf -vto 2 -beta 1e-3 -lambda 1e-4 -cgd 1e-12
            # ```
            set paramsNames [list vto beta lambda rd rs cgs cgd pb is b kf af nlev gdsnoi fc tnom \
                    tcv vtotc bex betatce xti eg]
            set params [my argsPreprocess $paramsNames {*}$args]
            next $name $type [linsert $params 0 [list level 1]]
        }
    }
    
### ________________________ Jfet2Model class _________________________ ###
    
    oo::class create Jfet2Model {
        superclass ::SpiceGenTcl::Model
        mixin ::SpiceGenTcl::KeyArgsBuilder
        constructor {name type args} {
            # Creates object of class `Jfet2Model` that describes JFET level 2 model with Parker Skellern modification.
            #  name - name of the model 
            #  type - njf or pjf
            #  args - keyword model parameters, for details please see Ngspice manual, chapter 9.
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::SemiconductorDevices::Jfet2Model new jfetmod njf -vto -2 -beta 10e-4 -rs 1e-4 -vbi 1.2
            # ```
            set paramsNames [list acgam beta cgd cgs delta fc hfeta hfe1 hfe2 hfgam \
                    hfg1 hfg2 ibd is lfgam lfg1 lfg2 mvst n p q rs rd  taud taug vbd \
                    vbi vst vto xc xi z rg lg ls ld cdss afac nfing tnom temp]
            set params [my argsPreprocess $paramsNames {*}$args]
            next $name $type [linsert $params 0 [list level 2]]
        }
    } 
    
### ________________________ Mesfet1Model class _________________________ ###
    
    oo::class create Mesfet1Model {
        superclass ::SpiceGenTcl::Model
        mixin ::SpiceGenTcl::KeyArgsBuilder
        constructor {name type args} {
            # Creates object of class `Mesfet1Model` that describes MESFET model by Statz e.a..
            #  name - name of the model 
            #  type - nmf or pmf
            #  args - keyword model parameters, for details please see Ngspice manual, chapter 10.
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::SemiconductorDevices::Jfet2Model new jfetmod njf -vto -2 -beta 10e-4 -rs 1e-4 -vbi 1.2
            # ```
            set paramsNames [list vto beta b alpha lambda rd rs cgs cgd pb kf af fc]
            set params [my argsPreprocess $paramsNames {*}$args]
            next $name $type [linsert $params 0 [list level 1]]
        }
    } 
}