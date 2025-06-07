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
        constructor {args} {
            # Creates object of class `Resistor` that describes resistor.
            #  name - name of the device without first-letter designator R
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  -r - resistance value or equation
            #  -ac - AC resistance value, optional
            #  -m - multiplier value, optional
            #  -scale - scaling factor, optional
            #  -temp - device temperature, optional
            #  -dtemp - temperature offset, optional
            #  -tc1 - linear thermal coefficient, optional
            #  -tc2 - quadratic thermal coefficient, optional
            #  -model - model of the resistor, optional
            #  -beh - selects behavioural type of resistor, optional
            #  -noisy - selects noise behaviour
            #  -l - length of semiconductor resistor, optional
            #  -w - width of semiconductor resistor, optional
            # Resistor type could be specified with additional switches: `-beh` if we
            # want to model circuit's variable dependent resistor, or `-model modelName`
            # if we want to simulate resistor with model card (semiconductor resistor).
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
            # Synopsis: name np nm -r value ?-tc1 value? ?-tc2 value? ?-ac value? ?-m value? ?-noisy 0|1?
            #   ?-temp value|-dtemp value? ?-scale value?
            # Synopsis: name np nm -beh -r value ?-tc1 value? ?-tc2 value?
            # Synopsis: name np nm -model value ?-r value? ?-l value? ?-w value? ?-temp value|-dtemp value?
            #   ?-m value? ?-noisy 0|1? ?-ac value? ?scale value?
            set arguments [argparse -inline -pfirst -help {Creates object of class `Resistor` that describes resistor} {
                {-r= -help {Resistance value or equation}}
                {-beh -forbid {model} -require {r} -help {Selects behavioural type of resistor}}
                {-model= -forbid {beh} -help {Model of the resistor}}
                {-ac= -forbid {model beh} -help {AC resistance value}}
                {-m= -forbid {beh} -help {Multiplier value,}}
                {-scale= -forbid {beh} -help {Scaling factor}}
                {-temp= -forbid {beh dtemp} -help {Device temperature}}
                {-dtemp= -forbid {beh temp} -help {Temperature offset}}
                {-tc1= -forbid {model} -help {Linear thermal coefficient}}
                {-tc2= -forbid {model} -help {Quadratic thermal coefficient}}
                {-noisy= -enum {0 1} -help {Selects noise behaviour}}
                {-l= -require {model} -help {Length of semiconductor resistor}}
                {-w= -require {model} -help {Width of semiconductor resistor}}
                {name -help {Name of the device without first-letter designator}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
            }]
            set params {}
            if {[dexist $arguments r]} {
                set rVal [dget $arguments r]
                if {[dexist $arguments beh]} {
                    lappend params [list -eq r $rVal]
                } elseif {([llength $rVal]>1) && ([@ $rVal 0] eq {-eq})} {
                    lappend params [list -poseq r [@ $rVal 1]]
                } else {
                    lappend params [list -pos r $rVal]
                }
            } elseif {![dexist $arguments model]} {
                return -code error {Resistor value must be specified with '-r value'}
            }
            if {[dexist $arguments model]} {
                lappend params [list -posnocheck model [dget $arguments model]]
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {r beh model name np nm}} {
                    if {[@ $value 0] eq {-eq}} {
                        lappend params [list -eq $paramName [@ $value 1]]
                    } else {
                        lappend params [list $paramName $value]
                    }
                }
            }
            next r[dget $arguments name] [list [list np [dget $arguments np]] [list nm [dget $arguments nm]]] $params
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
        constructor {args} {
            # Creates object of class `Capacitor` that describes capacitor.
            #  name - name of the device without first-letter designator C
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  -c - capacitance value or equation
            #  -q - charge equation
            #  -m - multiplier value, optional
            #  -scale - scaling factor, optional
            #  -temp - device temperature, optional
            #  -dtemp - temperature offset, optional
            #  -tc1 - linear thermal coefficient, optional
            #  -tc2 - quadratic thermal coefficient, optional
            #  -model - model of the resistor, optional
            #  -beh - selects behavioural type of resistor, optional
            #  -l - length of semiconductor capacitor, optional
            #  -w - width of semiconductor capacitor, optional
            #  -ic - initial voltage on capacitor, optional
            # Capacitor type could be specified with additional switches: `-beh` if we
            # want to model circuit's variable dependent capacitor, or `-model modelName`
            # if we want to simulate capacitor with model card (semiconductor capacitor).
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
            # Synopsis: name np nm -c value ?-tc1 value? ?-tc2 value? ?-m value? ?-temp value|-dtemp value?
            #   ?-scale value? ?-ic value?
            # Synopsis: name np nm -beh -c value ?-tc1 value? ?-tc2 value?
            # Synopsis: name np nm -beh -q value ?-tc1 value? ?-tc2 value?
            # Synopsis: name np nm -model value ?-c value? ?-l value? ?-w value? ?-temp value|-dtemp value?
            #   ?-m value? ?scale value? ?-ic value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Capacitor' that describes capacitor} {
                {-c= -forbid {q} -help {Capacitance value or equation}}
                {-q= -require {beh} -forbid {c model} -help {Charge equation}}
                {-beh -forbid {model} -help {Selects behavioural type of capacitor}}
                {-model= -forbid {beh} -help {Model of the capacitor}}
                {-m= -forbid {beh} -help {Multiplier value}}
                {-scale= -forbid {beh} -help {Scaling factor}}
                {-temp= -forbid {beh dtemp} -help {Device temperature}}
                {-dtemp= -forbid {beh temp} -help {Temperature offset}}
                {-tc1= -forbid {model} -help {Linear thermal coefficient}}
                {-tc2= -forbid {model} -help {Quadratic thermal coefficient}}
                {-ic= -forbid {beh} -help {Initial voltage on capacitor}}
                {-l= -require {model} -help {Length of semiconductor capacitor}}
                {-w= -require {model} -help {Width of semiconductor capacitor}}
                {name -help {Name of the device without first-letter designator}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
            }]
            set params {}
            if {[dexist $arguments c]} {
                set cVal [dget $arguments c]
                if {[dexist $arguments beh]} {
                    lappend params [list -eq c $cVal]
                } elseif {([llength $cVal]>1) && ([@ $cVal 0] eq {-eq})} {
                    lappend params [list -poseq c [@ $cVal 1]]
                } else {
                    lappend params [list -pos c $cVal]
                }
            } elseif {![dexist $arguments model] && ![dexist $arguments q]} {
                return -code error {Capacitor value must be specified with '-c value'}
            }
            if {[dexist $arguments q]} {
                set qVal [dget $arguments q]
                lappend params [list -eq q $qVal]
            }
            if {[dexist $arguments model]} {
                lappend params [list -posnocheck model [dget $arguments model]]
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {c q beh model name np nm}} {
                    if {[@ $value 0] eq {-eq}} {
                        lappend params [list -eq $paramName [@ $value 1]]
                    } else {
                        lappend params [list $paramName $value]
                    }
                }
            }
            next c[dget $arguments name] [list [list np [dget $arguments np]] [list nm [dget $arguments nm]]]\
                    $params
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
        constructor {args} {
            # Creates object of class `Inductor` that describes inductor.
            #  name - name of the device without first-letter designator L
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  -l - inductance value or equation
            #  -m - multiplier value, optional
            #  -scale - scaling factor, optional
            #  -temp - device temperature, optional
            #  -dtemp - temperature offset, optional
            #  -tc1 - linear thermal coefficient, optional
            #  -tc2 - quadratic thermal coefficient, optional
            #  -model - model of the inductor, optional
            #  -beh - selects behavioural type of inductor, optional
            #  -ic - initial current through inductor, optional
            #  -nt - number of turns, optional
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
            # Synopsis: name np nm -l value ?-tc1 value? ?-tc2 value? ?-m value? ?-temp value|-dtemp value?
            #   ?-scale value? ?-ic value?
            # Synopsis: name np nm -beh -l value ?-tc1 value? ?-tc2 value?
            # Synopsis: name np nm -model value ?-l value? ?-temp value|-dtemp value? ?-m value? ?scale value?
            #   ?-ic value? ?-nt value? ?-tc1 value? ?-tc2 value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Inductor' that describes inductor} {
                {-l= -help {Inductance value or equation}}
                {-beh -forbid {model} -require {l} -help {Selects behavioural type of inductor}}
                {-model= -forbid {beh} -help {Model of the inductor}}
                {-m= -forbid {beh} -help {Multiplier value}}
                {-scale= -forbid {beh} -help {Scaling factor}}
                {-temp= -forbid {beh dtemp} -help {Device temperature}}
                {-dtemp= -forbid {beh temp} -help {Temperature offset}}
                {-tc1= -help {Linear thermal coefficient}}
                {-tc2= -help {Quadratic thermal coefficient}}
                {-nt= -require {model} -help {Number of turns}}
                {-ic= -forbid {beh} -help {Initial current through inductor}}
                {name -help {Name of the device without first-letter designator}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
            }]
            set params {}
            if {[dexist $arguments l]} {
                set lVal [dget $arguments l]
                if {[dexist $arguments beh]} {
                    lappend params [list -eq l $lVal]
                } elseif {([llength $lVal]>1) && ([@ $lVal 0] eq {-eq})} {
                    lappend params [list -poseq l [@ $lVal 1]]
                } else {
                    lappend params [list -pos l $lVal]
                }
            } elseif {![dexist $arguments model]} {
                return -code error {Inductor value must be specified with '-l value'}
            }
            if {[dexist $arguments model]} {
                lappend params [list -posnocheck model [dget $arguments model]]
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {l beh model name np nm}} {
                    if {[@ $value 0] eq {-eq}} {
                        lappend params [list -eq $paramName [@ $value 1]]
                    } else {
                        lappend params [list $paramName $value]
                    }
                }
            }
            next l[dget $arguments name] [list [list np [dget $arguments np]] [list nm [dget $arguments nm]]] $params
        }
    }

####  Coupling class
    oo::class create Coupling {
        superclass ::SpiceGenTcl::Device
        constructor {args} {
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
            ##nagelfar implicitvarcmd {argparse *Creates object of class `Coupling`*} name l1 l2 k
            argparse -pfirst -help {Creates object of class `Coupling` that describes inductance coupling between\
                                           inductors} {
                {name -help {Name of the device without first-letter designator}}
                {-l1= -required -help {First inductor name}}
                {-l2= -required -help {Second inductor name}}
                {-k= -required -help {Coupling coefficient}}
            }
            if {([llength $k]>1) && ([@ $k 0] eq {-eq})} {
                ##nagelfar ignore {Found constant "k"}
                set k [list -poseq k [@ $k 1]]
            } else {
                ##nagelfar ignore {Found constant "k"}
                set k [list -pos k $k]
            }
            ##nagelfar ignore {Found constant "l*"}
            next k$name {} [list [list -posnocheck l1 $l1] [list -posnocheck l2 $l2] $k]
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
        constructor {args} {
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
            ##nagelfar implicitvarcmd {argparse *Creates object of class 'SubcircuitInstance'*} name pins subName params
            argparse -pfirst -help {Creates object of class 'SubcircuitInstance' that describes subcircuit instance} {
                {name -help {Name of the device without first-letter designator}}
                {pins -help {List of pins {{pinName nodeName} {pinName nodeName} ...}}}
                {subName -help {Name of subcircuit definition}}
                {params -help {List of parameters {{paramName paramValue ?-eq?} {paramName paramValue ?-eq?}}}}
            }
            set params [linsert $params 0 [list -posnocheck model $subName]]
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
            set pinsNames [dict keys [$subcktObj actOnPin -get -all]]
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
            if {[$subcktObj actOnParam -get -all] ne {}} {
                set paramsNames [dict keys [$subcktObj actOnParam -get -all]]
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
                    if {[@ $value 0] eq {-eq}} {
                        lappend params [list -eq $paramName [@ $value 1]]
                    } else {
                        lappend params [list $paramName $value]
                    }
                }
            } else {
                set params {}
            }
            set params [linsert $params 0 [list -posnocheck model $subName]]
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
        constructor {args} {
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
            ##nagelfar implicitvarcmd {argparse *Creates object of class 'VerilogA'*} name pins modName params
            argparse -pfirst -help {Creates object of class 'VerilogA' that describes Verilog-A instance} {
                {name -help {Name of the device without first-letter designator}}
                {pins -help {List of pins {{pinName nodeName} {pinName nodeName} ...}}}
                {modName -help {name of Verilog-A model}}
                {params -help {List of parameters {{paramName paramValue ?-eq?} {paramName paramValue ?-eq?}}}}
            }
            set params [linsert $params 0 [list -posnocheck model $modName]]
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
        constructor {type args} {
            if {$type eq {v}} {
                set typeName voltage
            } else {
                set typeName current
            }
            set arguments [argparse -inline -pfirst -help "Creates object of class '[string totitle ${type}pulse]' that\
                    describes pulse $typeName source" {
                {-dc= -help {DC value}}
                {-ac= -help {AC value}}
                {-acphase= -require ac -help {}}
                {-voff|ioff|low= -required -help {Low value}}
                {-von|ion|high= -required -help {High value}}
                {-td= -required -help {Delay time}}
                {-tr= -required -help {Rise time}}
                {-tf= -required -help {Fall time}}
                {-pw|ton= -required -help {Width of pulse}}
                {-per|tper= -required -help {Period time}}
                {-ncycles|npulses= -help {Number of pulses}}
                {name -help {Name of the device without first-letter designator}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
            }]
            if {[dexist $arguments dc]} {
                lappend params {-sw dc}
                set dcVal [dget $arguments dc]
                if {([llength $dcVal]>1) && ([@ $dcVal 0] eq {-eq})} {
                    lappend params [list -poseq dcval [@ $dcVal 1]]
                } else {
                    lappend params [list -pos dcval $dcVal]
                }
            }
            if {[dexist $arguments ac]} {
                lappend params {-posnocheck acsw ac}
                set acVal [dget $arguments ac]
                if {([llength $acVal]>1) && ([@ $acVal 0] eq {-eq})} {
                    lappend params [list -poseq ac [@ $acVal 1]]
                } else {
                    lappend params [list -pos ac $acVal]
                }
                if {[dexist $arguments acphase]} {
                    set acphaseVal [dget $arguments acphase]
                    if {([llength $acphaseVal]>1) && ([@ $acphaseVal 0] eq {-eq})} {
                        lappend params [list -poseq acphase [@ $acphaseVal 1]]
                    } else {
                        lappend params [list -pos acphase $acphaseVal]
                    }
                }
            }
            set paramsOrder {low high td tr tf ton tper npulses}
            lappend params {-posnocheck model pulse}
            my ParamsProcess $paramsOrder $arguments params
            next $type[dget $arguments name] [list [list np [dget $arguments np]] [list nm [dget $arguments nm]]] $params
        }
    }


####  sffm sources template class
    oo::abstract create sffm {
        superclass ::SpiceGenTcl::Device
        mixin ::SpiceGenTcl::Utility
        constructor {type args} {
            if {$type eq {v}} {
                set typeName voltage
            } else {
                set typeName current
            }
            set arguments [argparse -inline -pfirst -help "Creates object of class '[string totitle ${type}sffm]' that\
                    describes single-frequency FM $typeName source" {
                {-dc= -help {DC value}}
                {-ac= -help {AC value}}
                {-acphase= -require ac -help {Phase of AC signal}}
                {-i0|voff|ioff|v0= -required -help {Initial value}}
                {-ia|vamp|iamp|va= -required -help {Pulsed value}}
                {-fcar|fc= -required -help {Carrier frequency}}
                {-mdi= -required -help {Modulation index}}
                {-fsig|fs= -required -help {Signal frequency}}
                {-phasec= -help {Modulation signal phase}}
                {-phases= -require {phasec} -help {Carrier signal phase}}
                {name -help {Name of the device without first-letter designator}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
            }]
            if {[dexist $arguments dc]} {
                lappend params {-sw dc}
                set dcVal [dget $arguments dc]
                if {([llength $dcVal]>1) && ([@ $dcVal 0] eq {-eq})} {
                    lappend params [list -poseq dcval [@ $dcVal 1]]
                } else {
                    lappend params [list -pos dcval $dcVal]
                }
            }
            if {[dexist $arguments ac]} {
                lappend params {-posnocheck acsw ac}
                set acVal [dget $arguments ac]
                if {([llength $acVal]>1) && ([@ $acVal 0] eq {-eq})} {
                    lappend params [list -poseq ac [@ $acVal 1]]
                } else {
                    lappend params [list -pos ac $acVal]
                }
                if {[dexist $arguments acphase]} {
                    set acphaseVal [dget $arguments acphase]
                    if {([llength $acphaseVal]>1) && ([@ $acphaseVal 0] eq {-eq})} {
                        lappend params [list -poseq acphase [@ $acphaseVal 1]]
                    } else {
                        lappend params [list -pos acphase $acphaseVal]
                    }
                }
            }
            set paramsOrder {v0 va fc mdi fs phasec phases}
            lappend params {-posnocheck model sffm}
            my ParamsProcess $paramsOrder $arguments params
            next $type[dget $arguments name] [list [list np [dget $arguments np]] [list nm [dget $arguments nm]]] $params
        }
    }

####  am sources template class
    oo::abstract create am {
        superclass ::SpiceGenTcl::Device
        mixin ::SpiceGenTcl::Utility
        constructor {type args} {
            if {$type eq {v}} {
                set typeName voltage
            } else {
                set typeName current
            }
            set arguments [argparse -inline -pfirst -help "Creates object of class '[string totitle ${type}am]' that\
                    describes single-frequency FM $typeName source" {
                {-dc= -help {DC value}}
                {-ac= -help {AC value}}
                {-acphase= -require ac -help {Phase of AC signal}}
                {-i0|v0= -required -help {Initial value}}
                {-ia|va= -required -help {Pulsed value}}
                {-mf= -required -help {Modulating frequency}}
                {-fc= -required -help {Carrier frequency}}
                {-td= -required -help {Signal delay}}
                {-phases= -help {Phase value}}
                {name -help {Name of the device without first-letter designator}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
            }]
            if {[dexist $arguments dc]} {
                lappend params {-sw dc}
                set dcVal [dget $arguments dc]
                if {([llength $dcVal]>1) && ([@ $dcVal 0] eq {-eq})} {
                    lappend params [list -poseq dcval [@ $dcVal 1]]
                } else {
                    lappend params [list -pos dcval $dcVal]
                }
            }
            if {[dexist $arguments ac]} {
                lappend params {-posnocheck acsw ac}
                set acVal [dget $arguments ac]
                if {([llength $acVal]>1) && ([@ $acVal 0] eq {-eq})} {
                    lappend params [list -poseq ac [@ $acVal 1]]
                } else {
                    lappend params [list -pos ac $acVal]
                }
                if {[dexist $arguments acphase]} {
                    set acphaseVal [dget $arguments acphase]
                    if {([llength $acphaseVal]>1) && ([@ $acphaseVal 0] eq {-eq})} {
                        lappend params [list -poseq acphase [@ $acphaseVal 1]]
                    } else {
                        lappend params [list -pos acphase $acphaseVal]
                    }
                }
            }
            set paramsOrder {v0 va mf fc td phases}
            lappend params {-posnocheck model am}
            my ParamsProcess $paramsOrder $arguments params
            next $type[dget $arguments name] [list [list np [dget $arguments np]] [list nm [dget $arguments nm]]] $params
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
        constructor {args} {
            # Creates object of class `Vport` that describes simple constant voltage source.
            #  name - name of the device without first-letter designator V
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
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
            # Synopsis: name np nm -dc value -ac value -portnum value ?-z0 value?
            set arguments [argparse -inline -pfirst -help {Creates object of class `Vport` that describes simple constant\
                                                                  voltage source} {
                {-dc= -required -help {DC voltage value}}
                {-ac= -required -help {AC voltage value}}
                {-portnum= -required -help {Number of port}}
                {-z0= -help {Internal source impedance}}
                {name -help {Name of the device without first-letter designator}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
            }]
            set paramsOrder {dc ac portnum z0}
            foreach param $paramsOrder {
                if {[dexist $arguments $param]} {
                    dict append argsOrdered $param [dget $arguments $param]
                }
            }
            dict for {paramName value} $argsOrdered {
                lappend params [list -sw $paramName]
                if {([llength $value]>1) && ([@ $value 0] eq {-eq})} {
                    lappend params [list -poseq ${paramName}val [@ $value 1]]
                } else {
                    lappend params [list -pos ${paramName}val $value]
                }
            }
            next v[dget $arguments name] [list [list np [dget $arguments np]] [list nm [dget $arguments nm]]] $params
        }
    }

####  Vpulse class
    oo::class create Vpulse {
        superclass ::SpiceGenTcl::Ngspice::Sources::pulse
        constructor {args} {
            # Creates object of class `Vpulse` that describes pulse voltage source.
            #  name - name of the device without first-letter designator V
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  -low - low value, aliases: -voff, -ioff
            #  -high - high value, aliases: -von, ion
            #  -td - time delay
            #  -tr - rise time
            #  -tf - fall time
            #  -pw - width of pulse, alias -ton
            #  -per - period time, alias -tper
            #  -npulses - number of pulses, optional
            #  -dc - DC value, optional
            #  -ac - AC value, optional
            #  -acphase - phase of AC signal, optional, requires -ac
            # ```
            # VYYYYYYY n+ n- PULSE(V1 V2 TD TR TF PW PER NP)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Vpulse new 1 net1 net2 -low 0 -high 1 -td {td -eq} -tr 1e-9 -tf 1e-9 -pw 10e-6 -per 20e-6 -npulses {np -eq}
            # ```
            # Synopsis: name np nm -low|voff value -high|von value -td value -tr value -tf value -pw|ton value
            #   -per|tper value ?-np value?
            next v {*}$args
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
        constructor {args} {
            # Creates object of class `Vsffm` that describes single-frequency FM voltage source.
            #  name - name of the device without first-letter designator V
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
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
            # Synopsis: name np nm -v0|voff value -va|vamp value -fc|fcar value -mdi value -fs|fsig value
            #   ?-phasec value  ?-phases value??
            next v {*}$args
        }
    }

####  Vam class
    oo::class create Vam {
        superclass ::SpiceGenTcl::Ngspice::Sources::am
        constructor {args} {
            # Creates object of class `Vam` that describes single-frequency AM voltage source.
            #  name - name of the device without first-letter designator V
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
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
            # Synopsis: name np nm -v0 value -va value -mf value -fc value ?-td value ?-phases value??
            next v {*}$args
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
        constructor {args} {
            # Creates object of class `Ipulse` that describes pulse current source.
            #  name - name of the device without first-letter designator I
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  -low - low value
            #  -high - high value
            #  -td - time delay
            #  -tr - rise time
            #  -tf - fall time
            #  -pw - width of pulse
            #  -per - period time
            #  -npulses - number of pulses, optional
            #  -dc - DC value, optional
            #  -ac - AC value, optional
            #  -acphase - phase of AC signal, optional, requires -ac
            # ```
            # IYYYYYYY n+ n- PULSE(V1 V2 TD TR TF PW PER NP)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Ipulse new 1 net1 net2 -low 0 -high 1 -td {td -eq} -tr 1e-9 -tf 1e-9 -pw 10e-6 -per 20e-6 -npulses {np -eq}
            # ```
            # Synopsis: name np nm -low value -high value -td value -tr value -tf value -pw value -per value
            #   ?-np value?
            next i {*}$args
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
        constructor {args} {
            # Creates object of class `Isffm` that describes single-frequency FM current source.
            #  name - name of the device without first-letter designator I
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
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
            # Synopsis: name np nm -i0|ioff value -ia|iamp value -fc|fcar value -mdi value -fs|fsig value
            #   ?-phasec value ?-phases value??
            next i {*}$args
        }
    }

####  Iam class
    oo::class create Iam {
        superclass ::SpiceGenTcl::Ngspice::Sources::am
        constructor {args} {
            # Creates object of class `Iam` that describes single-frequency FM current source.
            #  name - name of the device without first-letter designator I
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
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
            # Synopsis: name np nm -i0 value -ia value -mf value -fc value ?-td value ?-phases value??
            next i {*}$args
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
        constructor {args} {
            # Creates object of class `BehaviouralSource` that describes behavioural source.
            #  name - name of the device without first-letter designator B
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  -i - current expression
            #  -v - voltage expression
            #  -temp - device temperature, optional
            #  -dtemp - temperature offset, optional
            #  -tc1 - linear thermal coefficient, optional
            #  -tc2 - quadratic thermal coefficient, optional
            #  -noisy - selects noise behaviour
            # ```
            # BXXXXXXX n+ n- <i=expr> <v=expr> <tc1=value> <tc2=value> <dtemp=value> <temp=value>
            # ```
            # Example of class initialization:
             # ```
            # ::SpiceGenTcl::Ngspice::Sources::BehaviouralSource new 1 netp netm -v "V(a)+V(b)+pow(V(c),2)" -tc1 1
            # ```
            # Synopsis: name np nm -i value ?-tc1 value? ?-tc2 value? ?-noisy 0|1? ?-temp value|-dtemp value?
            # Synopsis: name np nm -v value ?-tc1 value? ?-tc2 value? ?-noisy 0|1? ?-temp value|-dtemp value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'BehaviouralSource' that describes\
                                                                  behavioural source} {
                {-i= -forbid {v} -help {Current expression}}
                {-v= -forbid {i} -help {Voltage expression}}
                {-tc1=  -help {Linear thermal coefficient}}
                {-tc2=  -help {Quadratic thermal coefficient}}
                {-noisy= -enum {0 1} -help {Selects noise behaviour}}
                {-temp= -forbid {dtemp} -help {Device temperature}}
                {-dtemp= -forbid {temp} -help {Temperature offset}}
                {name -help {Name of the device without first-letter designator}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
            }]
            if {[dexist $arguments i]} {
                lappend params [list -eq i [dget $arguments i]]
            } elseif {[dexist $arguments v]} {
                lappend params [list -eq v [dget $arguments v]]
            } else {
                return -code error "Equation must be specified as argument to -i or -v"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {i v name np nm}} {
                    if {[@ $value 0] eq {-eq}} {
                        lappend params [list -eq $paramName [@ $value 1]]
                    } else {
                        lappend params [list $paramName $value]
                    }
                }
            }
            next b[dget $arguments name] [list [list np [dget $arguments np]] [list nm [dget $arguments nm]]] $params
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
        constructor {args} {
            # Creates object of class `Diode` that describes semiconductor diode device.
            #  name - name of the device without first-letter designator D
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
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
            # Synopsis: name np nm -model value ?-area value? ?-pj value? ?-ic value? ?-m value?
            #   ?-temp value|-dtemp value? ?-lm value? ?-wm value? ?-lp value? ?-wp value? ?-off?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Diode' that describes diode} {
                {-model= -required -help {Name of the model}}
                {-area= -help {Area scale factor}}
                {-pj= -help {Perimeter scale factor}}
                {-ic= -help {Initial condition}}
                {-m= -help {Multiplier of area and perimeter}}
                {-temp= -forbid {dtemp} -help {Device temperature}}
                {-dtemp= -forbid {temp} -help {Temperature offset}}
                {-lm= -help {Length of metal capacitor}}
                {-wm= -help {Width of metal capacitor}}
                {-lp= -help {Length of polysilicon capacitor}}
                {-wp= -help {Width of polysilicon capacitor}}
                {-off -boolean -help {Initial state}}
                {name -help {Name of the device without first-letter designator}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
            }]
            lappend params [list -posnocheck model [dget $arguments model]]
            if {[dget $arguments off]==1} {
                lappend params {-sw off}
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {model off name np nm}} {
                    if {[@ $value 0] eq {-eq}} {
                        lappend params [list -eq $paramName [@ $value 1]]
                    } else {
                        lappend params [list $paramName $value]
                    }
                }
            }
            next d[dget $arguments name] [list [list np [dget $arguments np]] [list nm [dget $arguments nm]]] $params
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
        constructor {args} {
            # Creates object of class `Bjt` that describes semiconductor bipolar junction transistor device.
            #  name - name of the device without first-letter designator Q
            #  nc - name of node connected to collector pin
            #  nb - name of node connected to base pin
            #  ne - name of node connected to emitter pin
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
            # Synopsis: name nc nb ne -model value ?-ns value ?-tj value?? ?-area value? ?-areac value?
            #   ?-areab value? ?-m value? ?-ic \{value value\}? ?-temp value|-dtemp value? ?-off?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Bjt' that describes semiconductor\
                                                                  bipolar junction transistor device} {
                {-model= -required -help {Name of the model}}
                {-area= -help {Emitter scale factor}}
                {-areac= -help {Collector scale factor}}
                {-areab= -help {Base scale factor}}
                {-m= -help {Multiplier of area and perimeter}}
                {-ic= -validate {[llength $arg]==2} -help {Initial conditions for vds and vgs, in form of two element\
                                                                   list}}
                {-temp= -forbid {dtemp} -help {Device temperature}}
                {-dtemp= -forbid {temp} -help {Temperature offset}}
                {-ns= -help {Name of node connected to substrate pin}}
                {-tj= -require {ns} -help {Name of node connected to thermal pin}}
                {-off -boolean -help {Initial state}}
                {name -help {Name of the device without first-letter designator}}
                {nc -help {Name of node connected to collector pin}}
                {nb -help {Name of node connected to base pin}}
                {ne -help {Name of node connected to emitter pin}}
            }]
            lappend params [list -posnocheck model [dget $arguments model]]
            if {[dget $arguments off]==1} {
                lappend params {-sw off}
            }
            if {[dexist $arguments ic]} {
                lappend params [list -nocheck ic [join [dget $arguments ic] ,]]
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {model ns tj ic off name nc nb ne}} {
                    if {[@ $value 0] eq {-eq}} {
                        lappend params [list -eq $paramName [@ $value 1]]
                    } else {
                        lappend params [list $paramName $value]
                    }
                }
            }
            set pinList [list [list nc [dget $arguments nc]] [list nb [dget $arguments nb]]\
                                 [list ne [dget $arguments ne]]]
            if {[dexist $arguments ns]} {
                lappend pinList [list ns [dget $arguments ns]]
                if {[dexist $arguments tj]} {
                    lappend pinList [list tj [dget $arguments tj]]
                }
            }
            next q[dget $arguments name] $pinList $params
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
        constructor {args} {
            # Creates object of class `Jfet` that describes semiconductor junction FET device.
            #  name - name of the device without first-letter designator J
            #  nd - name of node connected to drain pin
            #  ng - name of node connected to gate pin
            #  ns - name of node connected to source pin
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
            # Synopsis: name nd ng ns -model value ?-area value? ?-off? ?-ic \{value value\}? ?-temp value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Jfet' that describes semiconductor\
                                                                  junction FET device} {
                {-model= -required -help {Name of the model}}
                {-area= -help {Scale factor}}
                {-off -boolean -help {Initial state}}
                {-ic= -validate {[llength $arg]==2} -help {Initial conditions for vds and vgs, in form of two element\
                                                                   list}}
                {-temp= -help {Device temperature}}
                {name -help {Name of the device without first-letter designator}}
                {nd -help {Name of node connected to drain pin}}
                {ng -help {Name of node connected to gate pin}}
                {ns -help {Name of node connected to source pin}}
            }]
            lappend params [list -posnocheck model [dget $arguments model]]
            if {[dexist $arguments area]} {
                set areaVal [dget $arguments area]
                if {([llength $areaVal]>1) && ([@ $areaVal 0] eq {-eq})} {
                    lappend params [list -poseq area [@ $areaVal 1]]
                } else {
                    lappend params [list -pos area $areaVal]
                }
            }
            if {[dget $arguments off]==1} {
                lappend params {-sw off}
            }
            if {[dexist $arguments ic]} {
                lappend params [list -nocheck ic [join [dget $arguments ic] ,]]
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {model area off ic name nd ng ns}} {
                    lappend params [list $paramName $value]
                }
            }
            next j[dget $arguments name] [list [list nd [dget $arguments nd]] [list ng [dget $arguments ng]]\
                                                  [list ns [dget $arguments ns]]] $params
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
        constructor {args} {
            # Creates object of class `Mesfet` that describes semiconductor MESFET device.
            #  name - name of the device without first-letter designator Z
            #  nd - name of node connected to drain pin
            #  ng - name of node connected to gate pin
            #  ns - name of node connected to source pin
            #  -model - name of the model
            #  -area - scale factor, optional
            #  -ic - initial conditions for vds and vgs, in form of two element list, optional
            #  -off - initial state, optional
            # ```
            # ZXXXXXXX ND NG NS MNAME <AREA> <OFF> <IC=VDS,VGS>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::SemiconductorDevices::Mesfet new 1 netd netg nets -model mesfetmod -area {area*2 -eq}
            # ```
            # Synopsis: name nd ng ns -model value ?-area value? ?-off? ?-ic \{value value\} ?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Mesfet' that describes semiconductor\
                                                                  junction FET device} {
                {-model= -required -help {Name of the model}}
                {-area= -help {Scale factor}}
                {-off -boolean -help {Initial state}}
                {-ic= -validate {[llength $arg]==2} -help {Initial conditions for vds and vgs, in form of two element\
                                                                   list}}
                {name -help {Name of the device without first-letter designator}}
                {nd -help {Name of node connected to drain pin}}
                {ng -help {Name of node connected to gate pin}}
                {ns -help {Name of node connected to source pin}}
            }]
            lappend params [list -posnocheck model [dget $arguments model]]
            if {[dexist $arguments area]} {
                set areaVal [dget $arguments area]
                if {([llength $areaVal]>1) && ([@ $areaVal 0] eq {-eq})} {
                    lappend params [list -poseq area [@ $areaVal 1]]
                } else {
                    lappend params [list -pos area $areaVal]
                }
            }
            if {[dget $arguments off]==1} {
                lappend params {-sw off}
            }
            if {[dexist $arguments ic]} {
                lappend params [list -nocheck ic [join [dget $arguments ic] ,]]
            }
            next z[dget $arguments name] [list [list nd [dget $arguments nd]] [list ng [dget $arguments ng]]\
                                                  [list ns [dget $arguments ns]]] $params

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
        constructor {args} {
            # Creates object of class `Mosfet` that describes semiconductor MOSFET device.
            #  name - name of the device without first-letter designator M
            #  nd - name of node connected to drain pin
            #  ng - name of node connected to gate pin
            #  ns - name of node connected to source pin
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
            # Synopsis: name nd ng ns -model value ?-n4 value ?-n5 value ?-n6 value ?-n7 value???? ?-m value?
            #   ?-l value? ?-w value? ?-ad value|-nrd value? ?-as value|-nrs value? ?-temp value? ?-off? ?-pd value?
            #   ?-ps value? ?-ic \{value value value\}?
            #   ?-custparams param1 \{param1Val ?-eq|-poseq|-posnocheck|-pos|-nocheck?\} ...?
            set arguments [argparse -inline -pfirst -help {Creates object of class `Mosfet` that describes semiconductor\
                                                                  MOSFET device} {
                {-model= -required -help {Name of the model}}
                {-m= -help Multiplier}
                {-l= -help {Length of channel}}
                {-w= -help {Width of channel}}
                {-ad= -forbid {nrd} -help {Diffusion area of drain}}
                {-as= -forbid {nrs} -help {Diffusion area of source}}
                {-pd= -help {Perimeter area of drain}}
                {-ps= -help {Perimeter area of source}}
                {-nrd= -forbid {ad} -help {Equivalent number of squares of the drain diffusions}}
                {-nrs= -forbid {as} -help {Equivalent number of squares of the source diffusions}}
                {-temp= -help {Device temperature}}
                {-off -boolean -help {Initial state}}
                {-ic= -validate {[llength $arg]==3} -require n4 -help {Initial conditions for vds, vgs and vbs, in form\
                                                                               of three element list}}
                {-n4= -help {Name of 4th node}}
                {-n5= -require {n4} -help {Name of 5th node}}
                {-n6= -require {n5} -help {Name of 6th node}}
                {-n7= -require {n7} -help {Name of 7th node}}
                {-custparams -catchall -help {Key that collects all arguments at the end of device definition, to\
                                                      provide an ability to add custom parameters in form\
                                                      '-custparams param1 param1Val param2 {param2eq -eq} param3\
                                                      param3Val ...'}}
                {name -help {Name of the device without first-letter designator}}
                {nd -help {Name of node connected to drain pin}}
                {ng -help {Name of node connected to gate pin}}
                {ns -help {Name of node connected to source pin}}
            }]
            lappend params [list -posnocheck model [dget $arguments model]]
            if {[dget $arguments off]==1} {
                lappend params {-sw off}
            }
            if {[dexist $arguments ic]} {
                lappend params [list -nocheck ic [join [dget $arguments ic] ,]]
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {model off ic n4 n5 n6 n7 custparams name nd ng ns}} {
                    if {[@ $value 0] eq {-eq}} {
                        lappend params [list -eq $paramName [@ $value 1]]
                    } else {
                        lappend params [list $paramName $value]
                    }
                }
            }
            if {[dget $arguments custparams] ne {}} {
                if {[llength [dget $arguments custparams]]%2!=0} {
                    return -code error {Custom parameters list must be even length}
                }
                set custParamDict [dcreate {*}[dget $arguments custparams]]
                dict for {paramName value} $custParamDict {
                    if {[@ $value 0] eq {-eq}} {
                        lappend params [list -eq $paramName [@ $value 1]]
                    } else {
                        lappend params [list $paramName $value]
                    }
                }
            }
            set pinList [list [list nd [dget $arguments nd]] [list ng [dget $arguments ng]]\
                                 [list ns [dget $arguments ns]]]
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
            next m[dget $arguments name] $pinList $params
        }
    }

####  M class
    # alias for Mosfet class
    oo::class create M {
        superclass Mosfet
    }
}
