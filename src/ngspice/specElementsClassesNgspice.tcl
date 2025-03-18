#  .|'''.|            ||                   ..|'''.|                   |''||''|         '||'
#  ||..  '  ... ...  ...    ....    ....  .|'     '    ....  .. ...      ||      ....   ||
#   ''|||.   ||'  ||  ||  .|   '' .|...|| ||    .... .|...||  ||  ||     ||    .|   ''  ||
# .     '||  ||    |  ||  ||      ||      '|.    ||  ||       ||  ||     ||    ||       ||
# |'....|'   ||...'  .||.  '|...'  '|...'  ''|...'|   '|...' .||. ||.   .||.    '|...' .||.
#            ||
#           ''''
# specElementsClassesNgspice.tcl
# Describes Ngspice elements classes
#
# Copyright (c) 2024 George Yashin, georgtree@gmail.com
#
# MIT License
# See the file "LICENSE.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

namespace eval ::SpiceGenTcl {
    namespace eval Ngspice::BasicDevices {
        namespace export Resistor R  Capacitor C Inductor L Coupling K SubcircuitInstance X SubcircuitInstanceAuto XAuto\
                VSwitch S CSwitch W VerilogA N
    }
    namespace eval Ngspice::Sources {
        namespace export Vdc Idc Vac Iac Vpulse Ipulse Vsin Isin Vexp Iexp Vpwl Ipwl Vsffm Isffm Vam Iam Vccs G Vcvs E\
                Cccs F Ccvs H BehaviouralSource B Vport
    }
    namespace eval Ngspice::SemiconductorDevices {
        namespace export Diode D Bjt Q Jfet J Mesfet Z Mosfet M
    }
}



###  Basic devices

namespace eval ::SpiceGenTcl::Ngspice::BasicDevices {

####  Resistor class

    oo::class create Resistor {
        superclass ::SpiceGenTcl::Device
        constructor {name npNode nmNode args} {
            # Creates object of class `Resistor` that describes resistor.
            #  name - name of the device without first-letter designator R
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  args - keyword instance parameters
            # Resistor type could be specified with additional switches: `-beh` if we
            # want to model circuit's variable dependent resistor, or `-model modelName`
            # if we want to simulate resistor with model card.
            # Simple resistor:
            # ```
            # RXXXXXXX n+ n- <resistance|r=>value <ac=val> <m=val>
            # + <scale=val> <temp=val> <dtemp=val> <tc1=val> <tc2=val>
            # + <noisy=0|1>
            # ```
            # Example of class initialization as a simple resistor:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::Resistor new 1 netp netm -r 1e3 -tc1 1 -ac 1e6 -temp {temp_amb -eq}
            # ```
            # Behavioral resistor:
            # ```
            # RXXXXXXX n+ n- R={expression} <tc1=value> <tc2=value> <noisy=0>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::Resistor new 1 netp netm -r "V(a)+V(b)+pow(V(c),2)" -beh -tc1 1
            # ```
            # Resistor with model card:
            # ```
            # RXXXXXXX n+ n- <value> <mname> <l=length> <w=width>
            # + <temp=val> <dtemp=val> <m=val> <ac=val> <scale=val>
            # + <noisy=0|1>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::Resistor new 1 netp netm -model resm -l 1e-6 -w 10e-6
            # ```
            # Synopsis: name npNode nmNode -r value ?-tc1 value? ?-tc2 value? ?-ac value? ?-m value? ?-noisy 0|1?
            #   ?-temp value|-dtemp value? ?-scale value?
            # Synopsis: name npNode nmNode -beh -r value ?-tc1 value? ?-tc2 value?
            # Synopsis: name npNode nmNode -model value ?-r value? ?-l value? ?-w value? ?-temp value|-dtemp value?
            #   ?-m value? ?-noisy 0|1? ?-ac value? ?scale value?
            set arguments [argparse -inline {
                -r=
                {-beh -forbid {model} -require {r}}
                {-model= -forbid {beh}}
                {-ac= -forbid {model beh}}
                {-m= -forbid {beh}}
                {-scale= -forbid {beh}}
                {-temp= -forbid {beh dtemp}}
                {-dtemp= -forbid {beh temp}}
                {-tc1= -forbid {model}}
                {-tc2= -forbid {model}}
                {-noisy= -enum {0 1}}
                {-l= -require {model}}
                {-w= -require {model}}
            }]
            set params {}
            if {[dexist $arguments r]} {
                set rVal [dget $arguments r]
                if {[dexist $arguments beh]} {
                    lappend params [list r $rVal -eq]
                } elseif {([llength $rVal]>1) && ([@ $rVal 1] eq {-eq})} {
                    lappend params [list r [@ $rVal 0] -poseq]
                } else {
                    lappend params [list r $rVal -pos]
                }
            } elseif {![dexist $arguments model]} {
                return -code error "Resistor value must be specified with '-r value'"
            }
            if {[dexist $arguments model]} {
                lappend params [list model [dget $arguments model] -posnocheck]
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {r beh model}} {
                    lappend params [list $paramName {*}$value]
                }
            }
            next r$name [list [list np $npNode] [list nm $nmNode]] $params
        }
    }
####  R class
    # alias for Resistor class
    oo::class create R {
        superclass Resistor
    }

####  Capacitor class

    oo::class create Capacitor {
        superclass ::SpiceGenTcl::Device
        constructor {name npNode nmNode args} {
            # Creates object of class `Capacitor` that describes capacitor.
            #  name - name of the device without first-letter designator C
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  args - keyword instance parameters
            # Capacitor type could be specified with additional switches: `-beh` if we
            # want to model circuit's variable dependent capacitor, or `-model modelName`
            # if we want to simulate capacitor with model card.
            # Simple capacitor:
            # ```
            # CXXXXXXX n+ n- <value> <mname> <m=val> <scale=val> <temp=val>
            # + <dtemp=val> <tc1=val> <tc2=val> <ic=init_condition>
            # ```
            # Example of class initialization as a simple capacitor:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::Capacitor new 1 netp netm 1e-6 -tc1 1 -temp {temp -eq}
            # ```
            # Behavioral capacitor with C =ession:
            # ```
            # CXXXXXXX n+ n- C={expression} <tc1=value> <tc2=value>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::Capacitor new 1 netp netm -c "V(a)+V(b)+pow(V(c),2)" -beh -tc1 1
            # ```
            # Behavioral capacitor with Q expression:
            # ```
            # CXXXXXXX n+ n- Q={expression} <tc1=value> <tc2=value>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::Capacitor new 1 netp netm -q "V(a)+V(b)+pow(V(c),2)" -beh -tc1 1
            # ```
            # Capacitor with model card:
            # ```
            # CXXXXXXX n+ n- <value> <mname> <l=length> <w=width> <m=val>
            # + <scale=val> <temp=val> <dtemp=val> <ic=init_condition>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::Capacitor new 1 netp netm -model capm -l 1e-6 -w 10e-6
            # ```
            # Synopsis: name npNode nmNode -c value ?-tc1 value? ?-tc2 value? ?-m value? ?-temp value|-dtemp value?
            #   ?-scale value? ?-ic value?
            # Synopsis: name npNode nmNode -beh -c value ?-tc1 value? ?-tc2 value?
            # Synopsis: name npNode nmNode -beh -q value ?-tc1 value? ?-tc2 value?
            # Synopsis: name npNode nmNode -model value ?-c value? ?-l value? ?-w value? ?-temp value|-dtemp value?
            #   ?-m value? ?scale value? ?-ic value?
            set arguments [argparse -inline {
                {-c= -forbid {q}}
                {-q= -require {beh} -forbid {c model}}
                {-beh -forbid {model}}
                {-model= -forbid {beh}}
                {-m= -forbid {beh}}
                {-scale= -forbid {beh}}
                {-temp= -forbid {beh dtemp}}
                {-dtemp= -forbid {beh temp}}
                {-tc1= -forbid {model}}
                {-tc2= -forbid {model}}
                {-ic= -forbid {beh}}
                {-l= -require {model}}
                {-w= -require {model}}
            }]
            set params {}
            if {[dexist $arguments c]} {
                set cVal [dget $arguments c]
                if {[dexist $arguments beh]} {
                    lappend params [list c $cVal -eq]
                } elseif {([llength $cVal]>1) && ([@ $cVal 1] eq {-eq})} {
                    lappend params [list c [@ $cVal 0] -poseq]
                } else {
                    lappend params [list c $cVal -pos]
                }
            } elseif {![dexist $arguments model] && ![dexist $arguments q]} {
                return -code error "Capacitor value must be specified with '-c value'"
            }
            if {[dexist $arguments q]} {
                set qVal [dget $arguments q]
                lappend params [list q $qVal -eq]
            }
            if {[dexist $arguments model]} {
                lappend params [list model [dget $arguments model] -posnocheck]
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {c q beh model}} {
                    lappend params [list $paramName {*}$value]
                }
            }
            next c$name [list [list np $npNode] [list nm $nmNode]] $params
        }
    }
####  C class
    # alias for Capacitor class
    oo::class create C {
        superclass Capacitor
    }

####  Inductor class

    oo::class create Inductor {
        superclass ::SpiceGenTcl::Device
        constructor {name npNode nmNode args} {
            # Creates object of class `Inductor` that describes inductor.
            #  name - name of the device without first-letter designator L
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  args - keyword instance parameters
            # Inductor type could be specified with additional switches: `-beh` if we
            # want to model circuit's variable dependent inductor, or `-model modelName`
            # if we want to simulate inductor with model card.
            # Simple inductor:
            # ```
            # LYYYYYYY n+ n- <value> <m=val>
            # + <scale=val> <temp=val> <dtemp=val> <tc1=val>
            # + <tc2=val> <ic=init_condition>
            # ```
            # Example of class initialization as a simple inductor:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::Inductor new 1 netp netm -l 1e-6 -tc1 1 -temp {temp -eq}
            # ```
            # Behavioral inductor:
            # ```
            # LYYYYYYY n+ n- L={expression} <tc1=val> <tc2=val>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::Inductor new 1 netp netm -l "V(a)+V(b)+pow(V(c),2)" -beh -tc1 1
            # ```
            # Inductor with model card:
            # ```
            # LYYYYYYY n+ n- <value> <mname> <nt=val> <m=val>
            # + <scale=val> <temp=val> <dtemp=val> <tc1=val>
            # + <tc2=val> <ic=init_condition>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::Inductor new 1 netp netm -l 1e-6 -model indm
            # ```
            # Synopsis: name npNode nmNode -l value ?-tc1 value? ?-tc2 value? ?-m value? ?-temp value|-dtemp value?
            #   ?-scale value? ?-ic value?
            # Synopsis: name npNode nmNode -beh -l value ?-tc1 value? ?-tc2 value?
            # Synopsis: name npNode nmNode -model value ?-l value? ?-temp value|-dtemp value? ?-m value? ?scale value?
            #   ?-ic value? ?-nt value? ?-tc1 value? ?-tc2 value?
            set arguments [argparse -inline {
                -l=
                {-beh -forbid {model} -require {l}}
                {-model= -forbid {beh}}
                {-m= -forbid {beh}}
                {-scale= -forbid {beh}}
                {-temp= -forbid {beh dtemp}}
                {-dtemp= -forbid {beh temp}}
                -tc1=
                -tc2=
                {-nt= -require {model}}
                {-ic= -forbid {beh}}
            }]
            set params {}
            if {[dexist $arguments l]} {
                set lVal [dget $arguments l]
                if {[dexist $arguments beh]} {
                    lappend params [list l $lVal -eq]
                } elseif {([llength $lVal]>1) && ([@ $lVal 1] eq {-eq})} {
                    lappend params [list l [@ $lVal 0] -poseq]
                } else {
                    lappend params [list l $lVal -pos]
                }
            } elseif {![dexist $arguments model]} {
                return -code error "Inductor value must be specified with '-l value'"
            }
            if {[dexist $arguments model]} {
                lappend params [list model [dget $arguments model] -posnocheck]
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {l beh model}} {
                    lappend params [list $paramName {*}$value]
                }
            }
            next l$name [list [list np $npNode] [list nm $nmNode]] $params
        }
    }

####  Coupling class

    oo::class create Coupling {
        superclass ::SpiceGenTcl::Device
        constructor {name args} {
            # Creates object of class `Coupling` that describes inductance coupling between inductors.
            #  name - name of the device without first-letter designator L
            #  -l1 - first inductor name
            #  -l2 - second inductor name
            #  -k - coupling coefficient
            # ```
            # KXXXXXXX LYYYYYYY LZZZZZZZ value
            # ```
            # Example of class initialization as a simple inductor:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::Coupling new 1 -l1 la -l2 lb -k 0.5
            # ```
            # Synopsis: name -l1 value -l2 value -k value
            argparse {
                {-l1= -required}
                {-l2= -required}
                {-k= -required}
            }
            ##nagelfar variable k
            if {([llength $k]>1) && ([@ $k 1] eq {-eq})} {
                ##nagelfar ignore
                set k [list k [@ $k 0] -poseq]
            } else {
                ##nagelfar ignore
                set k [list k $k -pos]
            }
            ##nagelfar variable l1
            ##nagelfar variable l2
            ##nagelfar ignore
            next k$name {} [list [list l1 $l1 -posnocheck] [list l2 $l2 -posnocheck] $k]
        }
    }

####  K class

    # alias for Coupling class
    oo::class create K {
        superclass Coupling
    }

####  L class

    # alias for Inductor class
    oo::class create L {
        superclass Inductor
    }

####  VSwitch class

    oo::class create VSwitch {
        superclass ::SpiceGenTcl::Common::BasicDevices::VSwitch
    }

####  S class

    # alias for VSwitch class
    oo::class create S {
        superclass VSwitch
    }

####  CSwitch class

    oo::class create CSwitch {
        superclass ::SpiceGenTcl::Common::BasicDevices::CSwitch
    }

####  W class

    # alias for CSwitch class
    oo::class create W {
        superclass CSwitch
    }

####  SubcircuitInstance class

    oo::class create SubcircuitInstance {
        superclass ::SpiceGenTcl::Device
        constructor {name pins subName params} {
            # Creates object of class `SubcircuitInstance` that describes subcircuit instance.
            #  name - name of the device without first-letter designator X
            #  pins - list of pins {{pinName nodeName} {pinName nodeName} ...}
            #  subName - name of subcircuit definition
            #  params - {{paramName paramValue ?-eq?} {paramName paramValue ?-eq?}}
            # ```
            # XYYYYYYY N1 <N2 N3 ...> SUBNAM
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::SubcircuitInstance new 1 {{plus net1} {minus net2}} rcnet {{r 1} {c cpar -eq}}
            # ```
            set params [linsert $params 0 [list model $subName -posnocheck]]
            next x$name $pins $params
        }
    }

####  X class

    # alias for SubcircuitInstance class
    oo::class create X {
        superclass SubcircuitInstance
    }

####  SubcircuitInstanceAuto class

    oo::class create SubcircuitInstanceAuto {
        superclass ::SpiceGenTcl::Device
        constructor {subcktObj name nodes args} {
            # Creates object of class `SubcircuitInstanceAuto` that describes subcircuit instance with already created
            # subcircuit definition object.
            #  subcktObj - object of subcircuit that defines it's pins, subName and parameters
            #  nodes - list of nodes connected to pins in the same order as pins in subcircuit definition
            #   {nodeName1 nodeName2 ...}
            #  args - parameters as argument in form : -paramName {paramValue ?-eq?} -paramName {paramValue ?-eq?}
            # ```
            # XYYYYYYY N1 <N2 N3 ...> SUBNAM
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::SubcircuitInstanceAuto new $subcktObj 1 {net1 net2} -r 1 -c {cpar -eq}
            # ```
            # Synopsis: subcktObj name nodes ?-paramName {paramValue ?-eq?} ...?

            # check that inputs object class is Subcircuit
            if {![info object class $subcktObj "::SpiceGenTcl::Subcircuit"]} {
                set objClass [info object class $subcktObj]
                return -code error "Wrong object class '$objClass' is passed as subcktObj, should be\
                        '::SpiceGenTcl::Subcircuit'"
            }
            # get name of subcircuit
            set subName [$subcktObj configure -name]
            # get pins names of subcircuit
            set pinsNames [dict keys [$subcktObj getPins]]
            # check if number of pins in subcircuit definition matchs the number of supplied nodes
            if {[llength $pinsNames]!=[llength $nodes]} {
                return -code error "Wrong number of nodes '[llength $nodes]' in definition, should be\
                        '[llength $pinsNames]'"
            }
            # create list of pins and connected nodes
            foreach pinName $pinsNames node $nodes {
                lappend pinsList [list $pinName $node]
            }
            # get parameters names of subcircuit
            if {![catch {$subcktObj getParams}]} {
                set paramsNames [dict keys [$subcktObj getParams]]
                foreach paramName $paramsNames {
                    lappend paramDefList -${paramName}=
                }
            }
            if {[info exists paramDefList]} {
                # create definition for argparse module for passing parameters as optional arguments
                set arguments [argparse -inline "
                    [join $paramDefList \n]
                "]
                # create list of parameters and values from which were supplied by args
                dict for {paramName value} $arguments {
                    lappend params [list $paramName {*}$value]
                }
            } else {
                set params {}
            }
            set params [linsert $params 0 [list model $subName -posnocheck]]
            next x$name $pinsList $params
        }
    }

####  XAuto class

    # alias for SubcircuitInstanceAuto class
    oo::class create XAuto {
        superclass SubcircuitInstanceAuto
    }

####  VerilogA class

    oo::class create VerilogA {
        superclass ::SpiceGenTcl::Device
        constructor {name pins modName params} {
            # Creates object of class `VerilogA` that describes Verilog-A instance.
            #  name - name of the device without first-letter designator N
            #  pins - list of pins {{pinName nodeName} {pinName nodeName} ...}
            #  modName - name of Verilog-A model
            #  params - {{paramName paramValue ?-eq?} {paramName paramValue ?-eq?}}
            # ```
            # NYYYYYYY N1 <N2 N3 ...> MODNAME
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::VerilogA new 1 {{plus net1} {minus net2}} vmod {{r 1} {c cpar -eq}}
            # ```
            set params [linsert $params 0 [list model $modName -posnocheck]]
            next n$name $pins $params
        }
    }

####  N class

    # alias for VerilogA class
    oo::class create N {
        superclass VerilogA
    }

}



###  Sources devices

namespace eval ::SpiceGenTcl::Ngspice::Sources {


####  pulse sources template class

    oo::abstract create pulse {
        superclass ::SpiceGenTcl::Device
        mixin ::SpiceGenTcl::Utility
        constructor {name type npNode nmNode args} {
            set arguments [argparse -inline {
                -dc=
                -ac=
                {-acphase= -require ac}
                {-low= -forbid {voff ioff}}
                {-voff= -forbid {low ioff}}
                {-ioff= -forbid {low voff}}
                {-high= -forbid {von ion}}
                {-von= -forbid {high ion}}
                {-ion= -forbid {high von}}
                {-td= -required}
                {-tr= -required}
                {-tf= -required}
                {-pw= -forbid ton}
                {-ton= -forbid pw}
                {-per= -forbid tper}
                {-tper= -forbid per}
                {-np= -forbid ncycles}
                {-ncycles= -forbid np}
            }]
            if {[dexist $arguments dc]} {
                lappend params {dc -sw}
                set dcVal [dget $arguments dc]
                if {([llength $dcVal]>1) && ([@ $dcVal 1] eq {-eq})} {
                    lappend params [list dcval [@ $dcVal 0] -poseq]
                } else {
                    lappend params [list dcval $dcVal -pos]
                }
            }
            if {[dexist $arguments ac]} {
                lappend params {ac -sw}
                set acVal [dget $arguments ac]
                if {([llength $acVal]>1) && ([@ $acVal 1] eq {-eq})} {
                    lappend params [list acval [@ $acVal 0] -poseq]
                } else {
                    lappend params [list acval $acVal -pos]
                }
                if {[dexist $arguments acphase]} {
                    set acphaseVal [dget $arguments acphase]
                    if {([llength $acphaseVal]>1) && ([@ $acphaseVal 1] eq {-eq})} {
                        lappend params [list acphase [@ $acphaseVal 0] -poseq]
                    } else {
                        lappend params [list acphase $acphaseVal -pos]
                    }
                }
            }
            my AliasesKeysCheck $arguments {low voff ioff}
            my AliasesKeysCheck $arguments {high von ion}
            my AliasesKeysCheck $arguments {pw ton}
            my AliasesKeysCheck $arguments {per tper}
            set paramsOrder {low voff ioff high von ion td tr tf pw ton per tper np ncycles}
            lappend params {model pulse -posnocheck}
            my ParamsProcess $paramsOrder $arguments params
            next $type$name [list [list np $npNode] [list nm $nmNode]] $params
        }
    }


####  sffm sources template class

    oo::abstract create sffm {
        superclass ::SpiceGenTcl::Device
        mixin ::SpiceGenTcl::Utility
        constructor {name type npNode nmNode args} {
            set arguments [argparse -inline {
                -dc=
                -ac=
                {-acphase= -require ac}
                {-v0= -forbid {i0 voff ioff}}
                {-i0= -forbid {v0 voff ioff}}
                {-voff= -forbid {v0 i0 ioff}}
                {-ioff= -forbid {v0 i0 voff}}
                {-va= -forbid {ia vamp iamp}}
                {-ia= -forbid {va vamp iamp}}
                {-vamp= -forbid {va ia iamp}}
                {-iamp= -forbid {va ia vamp}}
                {-fc= -forbid fcar}
                {-fcar= -forbid fc}
                {-mdi= -required}
                {-fs= -forbid fsig}
                {-fsig= -forbid fs}
                -phasec=
                {-phases= -require {phasec}}
            }]
            if {[dexist $arguments dc]} {
                lappend params {dc -sw}
                set dcVal [dget $arguments dc]
                if {([llength $dcVal]>1) && ([@ $dcVal 1] eq {-eq})} {
                    lappend params [list dcval [@ $dcVal 0] -poseq]
                } else {
                    lappend params [list dcval $dcVal -pos]
                }
            }
            if {[dexist $arguments ac]} {
                lappend params {ac -sw}
                set acVal [dget $arguments ac]
                if {([llength $acVal]>1) && ([@ $acVal 1] eq {-eq})} {
                    lappend params [list acval [@ $acVal 0] -poseq]
                } else {
                    lappend params [list acval $acVal -pos]
                }
                if {[dexist $arguments acphase]} {
                    set acphaseVal [dget $arguments acphase]
                    if {([llength $acphaseVal]>1) && ([@ $acphaseVal 1] eq {-eq})} {
                        lappend params [list acphase [@ $acphaseVal 0] -poseq]
                    } else {
                        lappend params [list acphase $acphaseVal -pos]
                    }
                }
            }
            my AliasesKeysCheck $arguments {v0 i0 voff ioff}
            my AliasesKeysCheck $arguments {va ia vamp iamp}
            my AliasesKeysCheck $arguments {fc fcar}
            my AliasesKeysCheck $arguments {fs fsig}
            set paramsOrder {v0 i0 voff ioff va ia vamp iamp fc fcar mdi fs fsig phasec phases}
            lappend params {model sffm -posnocheck}
            my ParamsProcess $paramsOrder $arguments params
            next $type$name [list [list np $npNode] [list nm $nmNode]] $params
        }
    }

####  am sources template class

    oo::abstract create am {
        superclass ::SpiceGenTcl::Device
        mixin ::SpiceGenTcl::Utility
        constructor {name type npNode nmNode args} {
            set arguments [argparse -inline {
                -dc=
                -ac=
                {-acphase= -require ac}
                {-v0= -forbid i0}
                {-i0= -forbid v0}
                {-va= -forbid ia}
                {-ia= -forbid va}
                {-mf= -required}
                {-fc= -required}
                {-td= -required}
                -phases=
            }]
            if {[dexist $arguments dc]} {
                lappend params {dc -sw}
                set dcVal [dget $arguments dc]
                if {([llength $dcVal]>1) && ([@ $dcVal 1] eq {-eq})} {
                    lappend params [list dcval [@ $dcVal 0] -poseq]
                } else {
                    lappend params [list dcval $dcVal -pos]
                }
            }
            if {[dexist $arguments ac]} {
                lappend params {ac -sw}
                set acVal [dget $arguments ac]
                if {([llength $acVal]>1) && ([@ $acVal 1] eq {-eq})} {
                    lappend params [list acval [@ $acVal 0] -poseq]
                } else {
                    lappend params [list acval $acVal -pos]
                }
                if {[dexist $arguments acphase]} {
                    set acphaseVal [dget $arguments acphase]
                    if {([llength $acphaseVal]>1) && ([@ $acphaseVal 1] eq {-eq})} {
                        lappend params [list acphase [@ $acphaseVal 0] -poseq]
                    } else {
                        lappend params [list acphase $acphaseVal -pos]
                    }
                }
            }
            my AliasesKeysCheck $arguments {v0 i0}
            my AliasesKeysCheck $arguments {va ia}
            set paramsOrder {v0 i0 va ia mf fc td phases}
            lappend params {model am -posnocheck}
            my ParamsProcess $paramsOrder $arguments params
            next $type$name [list [list np $npNode] [list nm $nmNode]] $params
        }
    }

####  Vdc class

    oo::class create Vdc {
        superclass ::SpiceGenTcl::Common::Sources::Vdc
    }

####  Vac class

    oo::class create Vac {
        superclass ::SpiceGenTcl::Common::Sources::Vac
    }

####  Vport class

    oo::class create Vport {
        superclass ::SpiceGenTcl::Device
        constructor {name npNode nmNode args} {
            # Creates object of class `Vport` that describes simple constant voltage source.
            #  name - name of the device without first-letter designator V
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -dc - DC voltage value
            #  -ac - AC voltage value
            #  -portnum - number of port
            #  -z0 - internal source impedance
            # ```
            # VYYYYYYY n+ n- DC 0 AC 1 portnum n1 <z0 n2>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Vport new 1 netp netm -dc 1 -ac 1 -portnum 1 -z0 100
            # ```
            # Synopsis: name npNode nmNode -dc value -ac value -portnum value ?-z0 value?
            set arguments [argparse -inline {
                {-dc= -required}
                {-ac= -required}
                {-portnum= -required}
                {-z0=}
            }]
            set paramsOrder [list dc ac portnum z0]
            foreach param $paramsOrder {
                if {[dexist $arguments $param]} {
                    dict append argsOrdered $param [dget $arguments $param]
                }
            }
            dict for {paramName value} $argsOrdered {
                lappend params [list $paramName -sw]
                if {([llength $value]>1) && ([@ $value 1] eq {-eq})} {
                    lappend params [list ${paramName}val [@ $value 0] -poseq]
                } else {
                    lappend params [list ${paramName}val $value -pos]
                }
            }
            next v$name [list [list np $npNode] [list nm $nmNode]] $params
        }
    }

####  Vpulse class

    oo::class create Vpulse {
        superclass ::SpiceGenTcl::Ngspice::Sources::pulse
        constructor {name npNode nmNode args} {
            # Creates object of class `Vpulse` that describes pulse voltage source.
            #  name - name of the device without first-letter designator V
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -low - low value, aliases: -voff, -ioff
            #  -high - high value, aliases: -von, ion
            #  -td - time delay
            #  -tr - rise time
            #  -tf - fall time
            #  -pw - width of pulse, alias -ton
            #  -per - period time, alias -tper
            #  -np - number of pulses, optional
            #  -dc - DC value, optional
            #  -ac - AC value, optional
            #  -acphase - phase of AC signal, optional, requires -ac
            # ```
            # VYYYYYYY n+ n- PULSE(V1 V2 TD TR TF PW PER NP)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Vpulse new 1 net1 net2 -low 0 -high 1 -td {td -eq} -tr 1e-9 -tf 1e-9 -pw 10e-6 -per 20e-6 -np {np -eq}
            # ```
            # Synopsis: name npNode nmNode -low|voff value -high|von value -td value -tr value -tf value -pw|ton value
            #   -per|tper value ?-np value?
            next $name v $npNode $nmNode {*}$args
        }
    }

####  Vsin class

    oo::class create Vsin {
        superclass ::SpiceGenTcl::Common::Sources::Vsin
    }

####  Vexp class

    oo::class create Vexp {
        superclass ::SpiceGenTcl::Common::Sources::Vexp
    }

####  Vpwl class

    oo::class create Vpwl {
        superclass ::SpiceGenTcl::Common::Sources::Vpwl
    }

####  Vsffm class

    oo::class create Vsffm {
        superclass ::SpiceGenTcl::Ngspice::Sources::sffm
        constructor {name npNode nmNode args} {
            # Creates object of class `Vsffm` that describes single-frequency FM voltage source.
            #  name - name of the device without first-letter designator V
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -v0 - initial value, aliases: -voff, -i0, -ioff
            #  -va - pulsed value, aliases: -vamp, -ia, -iamp
            #  -fc - carrier frequency, alias -fcar
            #  -mdi - modulation index
            #  -fs - signal frequency, alias -fsig
            #  -phasec - carrier phase, optional
            #  -phases - signal phase, optional, require -phasec
            #  -dc - DC value, optional
            #  -ac - AC value, optional
            #  -acphase - phase of AC signal, optional, requires -ac
            # ```
            # VYYYYYYY n+ n- SFFM(VO VA FC MDI FS PHASEC PHASES)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Vsin new 1 net1 net2 -v0 0 -va 1 -fc {freq -eq} -mdi 0 -fs 1e3 -phasec {phase -eq}
            # ```
            # Synopsis: name npNode nmNode -v0|voff value -va|vamp value -fc|fcar value -mdi value -fs|fsig value
            #   ?-phasec value  ?-phases value??
            next $name v $npNode $nmNode {*}$args
        }
    }

####  Vam class

    oo::class create Vam {
        superclass ::SpiceGenTcl::Ngspice::Sources::am
        constructor {name npNode nmNode args} {
            # Creates object of class `Vam` that describes single-frequency FM voltage source.
            #  name - name of the device without first-letter designator V
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -v0 - initial value
            #  -va - pulsed value
            #  -mf - modulating frequency
            #  -fc - carrier frequency
            #  -td - signal delay, optional
            #  -phases - phase, optional, require -td
            #  -dc - DC value, optional
            #  -ac - AC value, optional
            #  -acphase - phase of AC signal, optional, requires -ac
            # ```
            # VYYYYYYY n+ n- AM(VA VO MF FC TD PHASES)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Vam new 1 net1 net2 -v0 0 -va 2 -mf 1e3 -fc {freq -eq} -td 1e-6 -phases {phase -eq}
            # ```
            # Synopsis: name npNode nmNode -v0 value -va value -mf value -fc value ?-td value ?-phases value??
            next $name v $npNode $nmNode {*}$args
        }
    }

####  Idc class

    oo::class create Idc {
        superclass ::SpiceGenTcl::Common::Sources::Idc
    }

####  Iac class

    oo::class create Iac {
        superclass ::SpiceGenTcl::Common::Sources::Iac
    }


####  Ipulse class

    oo::class create Ipulse {
        superclass ::SpiceGenTcl::Ngspice::Sources::pulse
        constructor {name npNode nmNode args} {
            # Creates object of class `Ipulse` that describes pulse current source.
            #  name - name of the device without first-letter designator I
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -low - low value
            #  -high - high value
            #  -td - time delay
            #  -tr - rise time
            #  -tf - fall time
            #  -pw - width of pulse
            #  -per - period time
            #  -np - number of pulses, optional
            #  -dc - DC value, optional
            #  -ac - AC value, optional
            #  -acphase - phase of AC signal, optional, requires -ac
            # ```
            # IYYYYYYY n+ n- PULSE(V1 V2 TD TR TF PW PER NP)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Ipulse new 1 net1 net2 -low 0 -high 1 -td {td -eq} -tr 1e-9 -tf 1e-9 -pw 10e-6 -per 20e-6 -np {np -eq}
            # ```
            # Synopsis: name npNode nmNode -low value -high value -td value -tr value -tf value -pw value -per value
            #   ?-np value?
            next $name i $npNode $nmNode {*}$args
        }
    }

####  Isin class

    oo::class create Isin {
        superclass ::SpiceGenTcl::Common::Sources::Isin
    }

####  Iexp class

    oo::class create Iexp {
        superclass ::SpiceGenTcl::Common::Sources::Iexp
    }

####  Ipwl class

    oo::class create Ipwl {
        superclass ::SpiceGenTcl::Common::Sources::Ipwl
    }

####  Isffm class

    oo::class create Isffm {
        superclass ::SpiceGenTcl::Ngspice::Sources::sffm
        constructor {name npNode nmNode args} {
            # Creates object of class `Isffm` that describes single-frequency FM current source.
            #  name - name of the device without first-letter designator I
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -i0 - initial value, aliases: -voff, -v0, -ioff
            #  -ia - pulsed value, aliases: -vamp, -va, -iamp
            #  -fc - carrier frequency, alias -fcar
            #  -mdi - modulation index
            #  -fs - signal frequency, alias -fsig
            #  -phasec - carrier phase, optional
            #  -phases - signal phase, optional, require -phasec
            #  -dc - DC value, optional
            #  -ac - AC value, optional
            #  -acphase - phase of AC signal, optional, requires -ac
            # ```
            # IYYYYYYY n+ n- SFFM(VO VA FC MDI FS PHASEC PHASES)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Isin new 1 net1 net2 -i0 0 -ia 1 -fc {freq -eq} -mdi 0 -fs 1e3 -phasec {phase -eq}
            # ```
            # Synopsis: name npNode nmNode -i0|ioff value -ia|iamp value -fc|fcar value -mdi value -fs|fsig value
            #   ?-phasec value ?-phases value??
            next $name i $npNode $nmNode {*}$args
        }
    }

####  Iam class

    oo::class create Iam {
        superclass ::SpiceGenTcl::Ngspice::Sources::am
        constructor {name npNode nmNode args} {
            # Creates object of class `Iam` that describes single-frequency FM current source.
            #  name - name of the device without first-letter designator I
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -i0 - initial value
            #  -ia - pulsed value
            #  -mf - modulating frequency
            #  -fc - carrier frequency
            #  -td - signal delay, optional
            #  -phases - phase, optional, require -td
            # ```
            # IYYYYYYY n+ n- AM(VA VO MF FC TD PHASES)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Iam new 1 net1 net2 -i0 0 -ia 2 -mf 1e3 -fc {freq -eq} -td 1e-6 -phases {phase -eq}
            # ```
            # Synopsis: name npNode nmNode -i0 value -ia value -mf value -fc value ?-td value ?-phases value??
            next $name i $npNode $nmNode {*}$args
        }
    }

####  Vccs class

    oo::class create Vccs {
        superclass ::SpiceGenTcl::Common::Sources::Vccs
    }

####  G class

    # alias for Vccs class
    oo::class create G {
        superclass Vccs
    }

####  Vcvs class

    oo::class create Vcvs {
        superclass ::SpiceGenTcl::Common::Sources::Vcvs
    }

####  E class

    # alias for Vcvs class
    oo::class create E {
        superclass Vcvs
    }

####  Cccs class

    oo::class create Cccs {
        superclass ::SpiceGenTcl::Common::Sources::Cccs
    }

####  F class

    # alias for Cccs class
    oo::class create F {
        superclass Cccs
    }

####  Ccvs class

    oo::class create Ccvs {
        superclass ::SpiceGenTcl::Common::Sources::Ccvs
    }

####  H class

    # alias for Ccvs class
    oo::class create H {
        superclass Ccvs
    }

####  BehaviouralSource class

    oo::class create BehaviouralSource {
        superclass ::SpiceGenTcl::Device
        constructor {name npNode nmNode args} {
            # Creates object of class `BehaviouralSource` that describes behavioural source.
            #  name - name of the device without first-letter designator B
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -i - current expression
            #  -v - voltage expression
            # ```
            # BXXXXXXX n+ n- <i=expr> <v=expr> <tc1=value> <tc2=value> <dtemp=value> <temp=value>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::BehaviouralSource new 1 netp netm -v "V(a)+V(b)+pow(V(c),2)" -tc1 1
            # ```
            # Synopsis: name npNode nmNode -i value ?-tc1 value? ?-tc2 value? ?-noisy 0|1? ?-temp value|-dtemp value?
            # Synopsis: name npNode nmNode -v value ?-tc1 value? ?-tc2 value? ?-noisy 0|1? ?-temp value|-dtemp value?
            set arguments [argparse -inline {
                {-i= -forbid {v}}
                {-v= -forbid {i}}
                -tc1=
                -tc2=
                {-noisy= -enum {0 1}}
                {-temp= -forbid {dtemp}}
                {-dtemp= -forbid {temp}}
            }]
            if {[dexist $arguments i]} {
                lappend params [list i [dget $arguments i] -eq]
            } elseif {[dexist $arguments v]} {
                lappend params [list v [dget $arguments v] -eq]
            } else {
                return -code error "Equation must be specified as argument to -i or -v"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {i v}} {
                    lappend params [list $paramName {*}$value]
                }
            }
            next b$name [list [list np $npNode] [list nm $nmNode]] $params
        }
    }

####  B class

    # alias for BehaviouralSource class
    oo::class create B {
        superclass BehaviouralSource
    }
}
###  SemiconductorDevices

namespace eval ::SpiceGenTcl::Ngspice::SemiconductorDevices {

####  Diode class

    oo::class create Diode {
        superclass ::SpiceGenTcl::Device
        constructor {name npNode nmNode args} {
            # Creates object of class `Diode` that describes semiconductor diode device.
            #  name - name of the device without first-letter designator D
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -model - name of the model
            #  -area - area scale factor, optional
            #  -m - multiplier of area and perimeter, optional
            #  -pj - perimeter scale factor, optional
            #  -ic - initial condition, optional
            #  -temp - device temperature, optional
            #  -dtemp - temperature offset, optional
            #  -lm - length of metal capacitor, optional
            #  -wm - width of metal capacitor, optional
            #  -lp - length of polysilicon capacitor, optional
            #  -wp - width of polysilicon capacitor, optional
            #  -off - initial state, optional
            # ```
            # DXXXXXXX n+ n- mname <area=val> <m=val>
            # + <ic=vd> <temp=val> <dtemp=val>
            # + <lm=val> <wm=val> <lp=val> <wp=val> <pj=val>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::SemiconductorDevices::Diode new 1 netp netm -model diomod -l 1e-6 -w 10e-6
            # ```
            # Synopsis: name npNode nmNode -model value ?-area value? ?-pj value? ?-ic value? ?-m value?
            #   ?-temp value|-dtemp value? ?-lm value? ?-wm value? ?-lp value? ?-wp value? ?-off?
            set arguments [argparse -inline {
                {-model= -required}
                -area=
                -pj=
                -ic=
                -m=
                {-temp= -forbid {dtemp}}
                {-dtemp= -forbid {temp}}
                -lm=
                -wm=
                -lp=
                -wp=
                {-off -boolean}
            }]
            lappend params [list model [dget $arguments model] -posnocheck]
            if {[dget $arguments off]==1} {
                lappend params {off -sw}
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {model off}} {
                    lappend params [list $paramName {*}$value]
                }
            }
            next d$name [list [list np $npNode] [list nm $nmNode]] $params
        }
    }

####  D class

    # alias for Diode class
    oo::class create D {
        superclass Diode
    }

####  Bjt class

    oo::class create Bjt {
        superclass ::SpiceGenTcl::Device
        constructor {name ncNode nbNode neNode args} {
            # Creates object of class `Bjt` that describes semiconductor bipolar junction transistor device.
            #  name - name of the device without first-letter designator Q
            #  ncNode - name of node connected to collector pin
            #  nbNode - name of node connected to base pin
            #  neNode - name of node connected to emitter pin
            #  -model - name of the model
            #  -area - emitter scale factor, optional
            #  -areac - collector scale factor, optional
            #  -areab - base scale factor, optional
            #  -m - multiplier of area and perimeter, optional
            #  -temp - device temperature, optional
            #  -dtemp - temperature offset, optional
            #  -ic - initial conditions for vds and vgs, in form of two element list, optional
            #  -ns - name of node connected to substrate pin, optional
            #  -tj - name of node connected to thermal pin, optional, requires -ns
            #  -off - initial state, optional
            # ```
            # QXXXXXXX nc nb ne <ns> <tj> mname <area=val> <areac=val>
            # + <areab=val> <m=val> <off> <ic=vbe,vce> <temp=val>
            # + <dtemp=val>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::SemiconductorDevices::Bjt new 1 netc netb nete -model bjtmod -ns nets -area 1e-3
            # ```
            # Synopsis: name ncNode nbNode neNode -model value ?-ns value ?-tj value?? ?-area value? ?-areac value?
            #   ?-areab value? ?-m value? ?-ic \{value value\}? ?-temp value|-dtemp value? ?-off?
            set arguments [argparse -inline {
                {-model= -required}
                -area=
                -areac=
                -areab=
                -m=
                {-ic= -validate {[llength $arg]==2}}
                {-temp= -forbid {dtemp}}
                {-dtemp= -forbid {temp}}
                -ns=
                {-tj= -require {ns}}
                {-off -boolean}
            }]
            lappend params [list model [dget $arguments model] -posnocheck]
            if {[dget $arguments off]==1} {
                lappend params {off -sw}
            }
            if {[dexist $arguments ic]} {
                lappend params [list ic [join [dget $arguments ic] ,] -nocheck]
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {model ns tj ic off}} {
                    lappend params [list $paramName {*}$value]
                }
            }
            set pinList [list [list nc $ncNode] [list nb $nbNode] [list ne $neNode]]
            if {[dexist $arguments ns]} {
                lappend pinList [list ns [dget $arguments ns]]
                if {[dexist $arguments tj]} {
                    lappend pinList [list tj [dget $arguments tj]]
                }
            }
            next q$name $pinList $params
        }
    }

####  Q class

    # alias for Bjt class
    oo::class create Q {
        superclass Bjt
    }

####  Jfet class

    oo::class create Jfet {
        superclass ::SpiceGenTcl::Device
        constructor {name ndNode ngNode nsNode args} {
            # Creates object of class `Jfet` that describes semiconductor junction FET device.
            #  name - name of the device without first-letter designator J
            #  ndNode - name of node connected to drain pin
            #  ngNode - name of node connected to gate pin
            #  nsNode - name of node connected to source pin
            #  -model - name of the model
            #  -area - emitter scale factor, optional
            #  -temp - device temperature, optional
            #  -ic - initial conditions for vds and vgs, in form of two element list, optional
            #  -off - initial state, optional
            # ```
            # JXXXXXXX nd ng ns mname  <area> <off> <ic=vds,vgs> <temp =t>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::SemiconductorDevices::Jfet new 1 netd netg nets -model jfetmod -area {area*2 -eq} -temp 25
            # ```
            # Synopsis: name ndNode ngNode nsNode -model value ?-area value? ?-off? ?-ic \{value value\}? ?-temp value?
            set arguments [argparse -inline {
                {-model= -required}
                -area=
                {-off -boolean}
                {-ic= -validate {[llength $arg]==2}}
                -temp=
            }]
            lappend params [list model [dget $arguments model] -posnocheck]
            if {[dexist $arguments area]} {
                set areaVal [dget $arguments area]
                if {([llength $areaVal]>1) && ([@ $areaVal 1] eq {-eq})} {
                    lappend params [list area [@ $areaVal 0] -poseq]
                } else {
                    lappend params [list area $areaVal -pos]
                }
            }
            if {[dget $arguments off]==1} {
                lappend params {off -sw}
            }
            if {[dexist $arguments ic]} {
                lappend params [list ic [join [dget $arguments ic] ,] -nocheck]
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {model area off ic}} {
                    lappend params [list $paramName $value]
                }
            }
            next j$name [list [list nd $ndNode] [list ng $ngNode] [list ns $nsNode]] $params
        }
    }

####  J class

    # alias for Jfet class
    oo::class create J {
        superclass Jfet
    }

####  Mesfet class

    oo::class create Mesfet {
        superclass ::SpiceGenTcl::Device
        constructor {name ndNode ngNode nsNode args} {
            # Creates object of class `Mesfet` that describes semiconductor MESFET device.
            #  name - name of the device without first-letter designator Z
            #  ndNode - name of node connected to drain pin
            #  ngNode - name of node connected to gate pin
            #  nsNode - name of node connected to source pin
            #  -model - name of the model
            #  -area - emitter scale factor, optional
            #  -ic - initial conditions for vds and vgs, in form of two element list, optional
            #  -off - initial state, optional
            # ```
            # ZXXXXXXX ND NG NS MNAME <AREA> <OFF> <IC=VDS,VGS>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::SemiconductorDevices::Mesfet new 1 netd netg nets -model mesfetmod -area {area*2 -eq}
            # ```
            # Synopsis: name ndNode ngNode nsNode -model value ?-area value? ?-off? ?-ic \{value value\} ?
            set arguments [argparse -inline {
                {-model= -required}
                -area=
                {-off -boolean}
                {-ic= -validate {[llength $arg]==2}}
            }]
            lappend params [list model [dget $arguments model] -posnocheck]
            if {[dexist $arguments area]} {
                set areaVal [dget $arguments area]
                if {([llength $areaVal]>1) && ([@ $areaVal 1] eq {-eq})} {
                    lappend params [list area [@ $areaVal 0] -poseq]
                } else {
                    lappend params [list area $areaVal -pos]
                }
            }
            if {[dget $arguments off]==1} {
                lappend params {off -sw}
            }
            if {[dexist $arguments ic]} {
                lappend params [list ic [join [dget $arguments ic] ,] -nocheck]
            }
            next z$name [list [list nd $ndNode] [list ng $ngNode] [list ns $nsNode]] $params

        }
    }

####  Z class

    # alias for Mesfet class
    oo::class create Z {
        superclass Mesfet
    }

####  Mosfet class

    oo::class create Mosfet {
        superclass ::SpiceGenTcl::Device
        constructor {name ndNode ngNode nsNode args} {
            # Creates object of class `Mosfet` that describes semiconductor MOSFET device.
            #  name - name of the device without first-letter designator M
            #  ndNode - name of node connected to drain pin
            #  ngNode - name of node connected to gate pin
            #  nsNode - name of node connected to source pin
            #  -model - name of the model
            #  -m - multiplier, optional
            #  -l - length of channel, optional
            #  -w - width of channel, optional
            #  -ad - diffusion area of drain, optional, forbid -nrd
            #  -as - diffusion area of source, optional,forbid -nrs
            #  -pd - perimeter area of drain, optional
            #  -ps - perimeter area of source, optional
            #  -nrd - equivalent number of squares of the drain diffusions
            #  -nrs - equivalent number of squares of the source diffusions
            #  -temp - device temperature
            #  -ic - initial conditions for vds, vgs and vbs, in form of three element list, optional, require 4th node
            #  -off - initial state, optional
            #  -n4 - name of 4th node;
            #  -n5 - name of 5th node, require -n4, optional
            #  -n6 - name of 6th node, require -n5, optional
            #  -n7 - name of 7th node, require -n6, optional
            #  -custparams - key that collects all arguments at the end of device definition, to provide an ability
            #  to add custom parameters in form `-custparams param1 param1Val param2 {param2eq -eq} param3 param3Val ...`
            #  Must be specified after all others options. Optional.
            # ```
            # MXXXXXXX nd ng ns nb mname <m=val> <l=val> <w=val>
            # + <ad=val> <as=val> <pd=val> <ps=val> <nrd=val>
            # + <nrs=val> <off> <ic=vds,vgs,vbs> <temp=t>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Mosfet new 1 netd netg nets -model mosfetmod -l 1e-6 -w 10e-3 -n4 netsub -n5 net5
            # ```
            # Synopsis: name ndNode ngNode nsNode -model value ?-n4 value ?-n5 value ?-n6 value ?-n7 value???? ?-m value?
            #   ?-l value? ?-w value? ?-ad value|-nrd value? ?-as value|-nrs value? ?-temp value? ?-off? ?-pd value?
            #   ?-ps value? ?-ic \{value value value\}?
            #   ?-custparams param1 \{param1Val ?-eq|-poseq|-posnocheck|-pos|-nocheck?\} ...?
            set arguments [argparse -inline {
                {-model= -required}
                -m=
                -l=
                -w=
                {-ad= -forbid {nrd}}
                {-as= -forbid {nrs}}
                -pd=
                -ps=
                {-nrd= -forbid {ad}}
                {-nrs= -forbid {as}}
                -temp=
                {-off -boolean}
                {-ic= -validate {[llength $arg]==3}}
                -n4=
                {-n5= -require {n4}}
                {-n6= -require {n5}}
                {-n7= -require {n7}}
                {-custparams -catchall}
            }]
            lappend params [list model [dget $arguments model] -posnocheck]
            if {[dget $arguments off]==1} {
                lappend params {off -sw}
            }
            if {[dexist $arguments ic]} {
                lappend params [list ic [join [dget $arguments ic] ,] -nocheck]
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {model off ic n4 n5 n6 n7 custparams}} {
                    lappend params [list $paramName {*}$value]
                }
            }
            if {[dget $arguments custparams] ne {}} {
                if {[llength [dget $arguments custparams]]%2!=0} {
                    return -code error "Custom parameters list must be even length"
                }
                set custParamDict [dcreate {*}[dget $arguments custparams]]
                dict for {paramName value} $custParamDict {
                    lappend params [list $paramName {*}$value]
                }
            }
            set pinList [list [list nd $ndNode] [list ng $ngNode] [list ns $nsNode]]
            if {[dexist $arguments n4]} {
                lappend pinList [list n4 [dget $arguments n4]]
                if {[dexist $arguments n5]} {
                    lappend pinList [list n5 [dget $arguments n5]]
                    if {[dexist $arguments n6]} {
                        lappend pinList [list n6 [dget $arguments n6]]
                        if {[dexist $arguments n7]} {
                            lappend pinList [list n7 [dget $arguments n7]]
                        }
                    }
                }
            }
            next m$name $pinList $params
        }
    }

####  M class

    # alias for Mosfet class
    oo::class create M {
        superclass Mosfet
    }
}
