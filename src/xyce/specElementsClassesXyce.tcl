#  .|'''.|            ||                   ..|'''.|                   |''||''|         '||'
#  ||..  '  ... ...  ...    ....    ....  .|'     '    ....  .. ...      ||      ....   ||
#   ''|||.   ||'  ||  ||  .|   '' .|...|| ||    .... .|...||  ||  ||     ||    .|   ''  ||
# .     '||  ||    |  ||  ||      ||      '|.    ||  ||       ||  ||     ||    ||       ||
# |'....|'   ||...'  .||.  '|...'  '|...'  ''|...'|   '|...' .||. ||.   .||.    '|...' .||.
#            ||
#           ''''
# specElementsClassesXyce.tcl
# Describes Xyce elements classes
#
# Copyright (c) 2024 George Yashin, georgtree@gmail.com
#
# MIT License
# See the file "LICENSE.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

namespace eval ::SpiceGenTcl {
    namespace eval Xyce::BasicDevices {
        namespace export Resistor R Capacitor C Inductor L SubcircuitInstance X SubcircuitInstanceAuto XAuto VSwitch\
                VSw CSwitch W GenSwitch GenS
    }
    namespace eval Xyce::Sources {
        namespace export Vdc Idc Vac Iac Vpulse Ipulse Vsin Isin Vexp Iexp Vpwl Ipwl Vsffm Isffm Vccs G Vcvs E Cccs F\
                Ccvs H BehaviouralSource B
    }
    namespace eval Xyce::SemiconductorDevices {
        namespace export Diode D Bjt Q BjtSub QSub BjtSubTj QSubTj Jfet J Mesfet Z Mosfet M
    }
}



###  Basic devices

namespace eval ::SpiceGenTcl::Xyce::BasicDevices {

####  Resistor class
    oo::class create Resistor {
        superclass ::SpiceGenTcl::Device
        constructor {args} {
            # Creates object of class `Resistor` that describes resistor.
            #  name - name of the device without first-letter designator R
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  -r value - resistance value or equation
            #  -beh - selects behavioural type of resistor, optional
            #  -model value - model of the resistor, optional
            #  -m value - multiplier value, optional
            #  -temp value - device temperature, optional
            #  -tc1 value - linear thermal coefficient, optional
            #  -tc2 value - quadratic thermal coefficient, optional
            #  -tce value - exponential thermal coefficient, optional
            #  -l value - length of semiconductor resistor, optional
            #  -w value - width of semiconductor resistor, optional
            # Resistor type could be specified with additional switches: `-beh` if we want to model circuit's variable
            # dependent resistor, or `-model modelName` if we want to simulate resistor with model card.
            # Simple resistor:
            # ```
            # R<name> <(+) node> <(-) node> <value> [device parameters]
            # ```
            # Example of class initialization as a simple resistor:
            # ```
            # Resistor new 1 netp netm -r 1e3 -tc1 1 -temp {-eq temp_amb}
            # ```
            # Behavioral resistor:
            # ```
            # R<name> <(+) node> <(-) node> R ={expression} [device parameters]
            # ```
            # Example of class initialization:
            # ```
            # Resistor new 1 netp netm -r "V(a)+V(b)+pow(V(c),2)" -beh -tc1 1
            # ```
            # Resistor with model card:
            # ```
            # R<name> <(+) node> <(-) node> <model name> [value] [device parameters]
            # ```
            # Example of class initialization:
            # ```
            # Resistor new 1 netp netm -model resm -l 1e-6 -w 10e-6
            # ```
            # Synopsis: name np nm -r value ?-tc1 value? ?-tc2 value? ?-tce value? ?-m value? ?-temp value?
            # Synopsis: name np nm -r value -beh ?-tc1 value? ?-tc2 value? ?-tce value? ?-m value? ?-temp value?
            # Synopsis: name np nm -r value -model ?-tc1 value? ?-tc2 value? ?-tce value? ?-m value? ?-temp value?
            #   ?-l value? ?-w value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Resistor' that describes resistor} {
                {-r= -help {Resistance value or equation}}
                {-beh -forbid model -require r -help {Selects behavioural type of resistor}}
                {-model= -forbid beh -help {Model of the resistor}}
                {-m= -help {Multiplier value}}
                {-temp= -help {Device temperature}}
                {-tc1= -help {Linear thermal coefficient}}
                {-tc2= -help {Quadratic thermal coefficient}}
                {-tce= -help {Exponential thermal coefficient}}
                {-l= -require model -help {Length of semiconductor resistor}}
                {-w= -require model -help {Width of semiconductor resistor}}
                {name -help {Name of the device without first-letter designator}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
            }]
            if {[dexist $arguments model]} {
                lappend params [list -posnocheck model [dget $arguments model]]
            }
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
            #  -c value - capacitance value or equation
            #  -q value - charge equation
            #  -beh - selects behavioural type of capacitor, optional
            #  -model value - model of the capacitor, optional
            #  -m value - multiplier value, optional
            #  -temp value - device temperature, optional
            #  -tc1 value - linear thermal coefficient, optional
            #  -tc2 value - quadratic thermal coefficient, optional
            #  -ic value - initial voltage on capacitor, optional
            #  -age value - aging coefficient, optional
            #  -d value - aging coefficient, optional
            #  -l value - length of semiconductor capacitor, optional
            #  -w value - width of semiconductor capacitor, optional
            # Capacitor type could be specified with additional switches: `-beh` if we want to model circuit's variable
            # dependent capacitor, or `-model modelName` if we want to simulate capacitor with model card.
            # Simple capacitor:
            # ```
            # C<device name> <(+) node> <(-) node> <value> [device parameters]
            # ```
            # Example of class initialization as a simple capacitor:
            # ```
            # Capacitor new 1 netp netm 1e-6 -tc1 1 -temp {-eq temp}
            # ```
            # Behavioral capacitor with C expression:
            # ```
            # C<device name> <(+) node> <(-) node> C={expression} [device parameters]
            # ```
            # Example of class initialization:
            # ```
            # Capacitor new 1 netp netm -c "V(a)+V(b)+pow(V(c),2)" -beh -tc1 1
            # ```
            # Behavioral capacitor with Q expression:
            # ```
            # C<device name> <(+) node> <(-) node> Q={expression} [device parameters]
            # ```
            # Example of class initialization:
            # ```
            # Capacitor new 1 netp netm -q "V(a)+V(b)+pow(V(c),2)" -beh -tc1 1
            # ```
            # Capacitor with model card:
            # ```
            # C<device name> <(+) node> <(-) node> <model name> [value] [device parameters]
            # ```
            # Example of class initialization:
            # ```
            # Capacitor new 1 netp netm -model capm -l 1e-6 -w 10e-6
            # ```
            # Synopsis: name np nm -c value ?-tc1 value? ?-tc2 value? ?-m value? ?-temp value? ?-ic value?
            #   ?-age value? ?-d value?
            # Synopsis: name np nm -beh -c value ?-tc1 value? ?-tc2 value? ?-m value? ?-temp value? ?-ic value?
            #   ?-age value? ?-d value?
            # Synopsis: name np nm -beh -q value ?-tc1 value? ?-tc2 value? ?-m value? ?-temp value? ?-ic value?
            #   ?-age value? ?-d value?
            # Synopsis: name np nm -model value ?-tc1 value? ?-tc2 value? ?-m value? ?-temp value? ?-ic value?
            #   ?-age value? ?-d value? ?-l value? ?-w value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Capacitor' that describes\
                                                                   capacitor} {
                {-c= -forbid q -help {Capacitance value or equation}}
                {-q= -require beh -forbid {c model} -help {Charge equation}}
                {-beh -forbid model -help {Selects behavioural type of capacitor}}
                {-model= -forbid beh -help {Model of the capacitor}}
                {-m= -help {Multiplier value}}
                {-temp= -help {Device temperature}}
                {-tc1= -help {Linear thermal coefficient}}
                {-tc2= -help {Quadratic thermal coefficient}}
                {-ic= -help {Initial voltage on capacitor}}
                {-age= -help {Aging coefficient}}
                {-d= -help {Aging coefficient}}
                {-l= -require model -help {Length of semiconductor capacitor}}
                {-w= -require model -help {Width of semiconductor capacitor}}
                {name -help {Name of the device without first-letter designator}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
            }]
            if {[dexist $arguments model]} {
                lappend params [list -posnocheck model [dget $arguments model]]
            }
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
            dict for {paramName value} $arguments {
                if {$paramName ni {c q beh model name np nm}} {
                    if {[@ $value 0] eq {-eq}} {
                        lappend params [list -eq $paramName [@ $value 1]]
                    } else {
                        lappend params [list $paramName $value]
                    }
                }
            }
            next c[dget $arguments name] [list [list np [dget $arguments np]] [list nm [dget $arguments nm]]] $params
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
            #  -l value - inductance value
            #  -model value - model of the inductor, optional
            #  -m value - multiplier value, optional
            #  -temp value - device temperature, optional
            #  -tc1 value - linear thermal coefficient, optional
            #  -tc2 value - quadratic thermal coefficient, optional
            #  -ic value - initial current through inductor, optional
            # Inductor type could be specified with additional switch `-model modelName` if we want to simulate inductor
            # with model card.
            # Simple inductor:
            # ```
            # L<name> <(+) node> <(-) node> <value> [device parameters]
            # ```
            # Example of class initialization as a simple inductor:
            # ```
            # Inductor new 1 netp netm -l 1e-6 -tc1 1 -temp {-eq temp}
            # ```
            # Inductor with model card:
            # ```
            # L<name> <(+) node> <(-) node> [model] <value> [device parameters]
            # ```
            # Example of class initialization:
            # ```
            # Inductor new 1 netp netm -l 1e-6 -model indm
            # ```
            # Synopsis: name np nm -l value ?-tc1 value? ?-tc2 value? ?-m value? ?-temp value? ?-ic value?
            # Synopsis: name np nm -model value -l value ?-tc1 value? ?-tc2 value? ?-m value? ?-temp value?
            #   ?-ic value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Capacitor' that describes\
                                                                   capacitor} {
                {-l= -required -help {Inductance value}}
                {-model= -help {Model of the inductor}}
                {-m= -help {Multiplier value}}
                {-temp= -help {Device temperature}}
                {-tc1= -help {Linear thermal coefficient}}
                {-tc2= -help {Quadratic thermal coefficient}}
                {-ic= -help {Initial current through inductor}}
                {name -help {Name of the device without first-letter designator}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
            }]
            if {[dexist $arguments model]} {
                lappend params [list -posnocheck model [dget $arguments model]]
            }
            set lVal [dget $arguments l]
            if {([llength $lVal]>1) && ([@ $lVal 0] eq {-eq})} {
                lappend params [list -poseq l [@ $lVal 1]]
            } else {
                lappend params [list -pos l $lVal]
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {l model name np nm}} {
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

####  L class
    # alias for Inductor class
    oo::class create L {
        superclass Inductor
    }

####  VSwitch class
    oo::class create VSwitch {
        superclass ::SpiceGenTcl::Common::BasicDevices::VSwitch
    }

####  VSw class
    # alias for VSwitch class
    oo::class create VSw {
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

####  GenSwitch class
    oo::class create GenSwitch {
        superclass ::SpiceGenTcl::Device
        constructor {args} {
            # Creates object of class `GenSwitch` that describes generic switch device.
            #  name - name of the device without first-letter designator S
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  -model value - model name
            #  -control value - control equation
            #  -on/-off - initial state of switch
            # ```
            # S<name> <(+) switch node> <(-) switch node> <model name> [ON] [OFF] <control = =ession>
            # ```
            # Example of class initialization:
            # ```
            # GenSwitch new 1 net1 0 -model sw1 -control {I(VMON)}
            # ```
            # Synopsis: name np nm -model value -control value ?-on|off?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'GenSwitch' that describes generic\
                                                                  switch device} {
                {-model= -required -help {Model name}}
                {-control= -required -help {Control equation}}
                {-on -forbid {off} -help {Initial on state of switch}}
                {-off -forbid {on} -help {Initial off state of switch}}
                {name -help {Name of the device without first-letter designator}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
            }]
            lappend params [list -posnocheck model [dget $arguments model]]
            if {[dexist $arguments on]} {
                lappend params {-sw on}
            } elseif {[dexist $arguments off]} {
                lappend params {-sw off}
            }
            lappend params [list -eq control [dget $arguments control]]
            next s[dget $arguments name] [list [list np [dget $arguments np]] [list nm [dget $arguments nm]]]\
                    $params
        }
    }

####  GenS class
    # alias for GenSwitch class
    oo::class create GenS {
        superclass GenSwitch
    }

####  SubcircuitInstance class
    oo::class create SubcircuitInstance {
        superclass ::SpiceGenTcl::Device
        constructor {args} {
            # Creates object of class `SubcircuitInstance` that describes subcircuit instance.
            #  name - name of the device without first-letter designator X
            #  pins - list of pins `{{pinName nodeName} {pinName nodeName} ...}`
            #  subName - name of subcircuit definition
            #  params - list of parameters `{{?-eq? paramName paramValue} {?-eq? paramName paramValue}}`
            # ```
            # X<name> [nodes] <subcircuit name> [PARAMS: [<name> = <value>] ...]
            # ```
            # Example of class initialization:
            # ```
            # SubcircuitInstance new 1 {{plus net1} {minus net2}} rcnet {{r 1} {-eq c cpar}}
            # ```
            ##nagelfar implicitvarcmd {argparse *Creates object of class 'SubcircuitInstance'*} name pins subName params
            argparse -pfirst -help {Creates object of class 'SubcircuitInstance' that describes subcircuit instance} {
                {name -help {Name of the device without first-letter designator}}
                {pins -help {List of pins {{pinName nodeName} {pinName nodeName} ...}}}
                {subName -help {Name of subcircuit definition}}
                {params -help {List of parameters {{?-eq? paramName paramValue} {?-eq? paramName paramValue}}}}
            }
            set params [linsert [linsert $params 0 [list -posnocheck model $subName]] 1 {-posnocheck params PARAMS:}]
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
            #  nodes - list of nodes connected to pins in the same order as pins in subcircuit definition `{nodeName1
            #   nodeName2 ...}`
            #  args - parameters as argument in form: `-paramName {?-eq? paramValue} -paramName {?-eq? paramValue}`
            # ```
            # X<name> [nodes] <subcircuit name> [PARAMS: [<name> = <value>] ...]
            # ```
            # Example of class initialization:
            # ```
            # SubcircuitInstanceAuto new $subcktObj 1 {net1 net2} -r 1 -c {-eq cpar}
            # ```
            # Synopsis: subcktObj name nodes ?-paramName {?-eq? paramValue} ...?

            # check that inputs object class is Subcircuit
            if {[info object class $subcktObj "::SpiceGenTcl::Subcircuit"]!=1} {
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
            if {[info exists paramDefList]} {
                set params [linsert $params 1 { -posnocheck params PARAMS:}]
            }
            next x$name $pinsList $params
        }
    }

####  XAuto class
    # alias for SubcircuitInstanceAuto class
    oo::class create XAuto {
        superclass SubcircuitInstanceAuto
    }
}

###  Sources devices

namespace eval ::SpiceGenTcl::Xyce::Sources {


####  Vdc class
    oo::class create Vdc {
        superclass ::SpiceGenTcl::Common::Sources::Vdc
    }

####  Vac class
    oo::class create Vac {
        superclass ::SpiceGenTcl::Common::Sources::Vac
    }

####  Vpulse class
    oo::class create Vpulse {
        superclass ::SpiceGenTcl::Common::Sources::Vpulse
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
        superclass ::SpiceGenTcl::Common::Sources::Vsffm
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
        superclass ::SpiceGenTcl::Common::Sources::Ipulse
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
        superclass ::SpiceGenTcl::Common::Sources::Isffm
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
            #  -i value - current expression
            #  -v value - voltage expression
            #  -smoothbsrc - enables the smooth transitions, optional, require `-v`
            #  -rcconst value - rc constant of the RC network, optional, require `-v`
            # ```
            # B<name> <(+) node> <(-) node> V={expression} [device parameters]
            # B<name> <(+) node> <(-) node> I={expression}
            # ```
            # Example of class initialization:
            # ```
            # BehaviouralSource new 1 netp netm -v "V(a)+V(b)+pow(V(c),2)"
            # ```
            # Synopsis: name np nm -i value
            # Synopsis: name np nm -v value ?-smoothbsrc? ?-rcconst value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'BehaviouralSource' that describes\
                                                                  behavioural source} {
                {-i= -forbid {v} -help {Current expression}}
                {-v= -forbid {i} -help {Voltage expression}}
                {-smoothbsrc -require {v} -help {Enables the smooth transitions}}
                {-rcconst= -require {v} -help {RC constant of the RC network}}
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
            if {[dexist $arguments smoothbsrc]} {
                lappend params {smoothbsrc 1}
            }
            if {[dexist $arguments rcconst]} {
                lappend params [list rcconst [dget $arguments rcconst]]
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

namespace eval ::SpiceGenTcl::Xyce::SemiconductorDevices {

####  Diode class
    oo::class create Diode {
        superclass ::SpiceGenTcl::Device
        constructor {args} {
            # Creates object of class `Diode` that describes semiconductor diode device.
            #  name - name of the device without first-letter designator D
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  -model value - name of the model
            #  -area value - area scale factor, optional
            #  -m value - multiplier of area and perimeter, optional
            #  -pj value - perimeter scale factor, optional
            #  -ic value - initial condition, optional
            #  -temp value - device temperature, optional
            #  -custparams list - key that collects all arguments at the end of device definition, to provide an ability
            #  to add custom parameters in form `-custparams param1 param1Val param2 {-eq param2eq} param3 param3Val
            #  ...` Must be specified after all others options. Optional.
            # ```
            # D<name> <(+) node> <(-) node> <model name> [device parameters]
            # ```
            # Example of class initialization:
            # ```
            # Diode new 1 netp netm -model diomod -area 1e-6
            # ```
            # Synopsis: name np nm -model value ?-area value? ?-pj value? ?-ic value? ?-m value? ?-temp value?
            #   ?-custparams param1 \{?-eq|-poseq|-posnocheck|-pos|-nocheck? param1Val\} ...?
            set arguments [argparse -inline -pfirst -help {Creates object of class `Diode` that describes semiconductor\
                                                                  diode device} {
                {-model= -required -help {Name of the model}}
                {-area= -help {Area scale factor}}
                {-pj= -help {Perimeter scale factor}}
                {-ic= -help {Initial condition}}
                {-m= -help {Multiplier of area and perimeter}}
                {-temp= -help {Device temperature}}
                {-custparams -catchall -help {Key that collects all arguments at the end of device definition, to\
                                                      provide an ability to add custom parameters in form\
                                                      '-custparams param1 param1Val param2 {-eq param2eq} param3\
                                                      param3Val ...'}}
                {name -help {Name of the device without first-letter designator}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
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
            if {[dexist $arguments pj]} {
                set pjVal [dget $arguments pj]
                if {([llength $pjVal]>1) && ([@ $pjVal 0] eq {-eq})} {
                    lappend params [list -poseq pj [@ $pjVal 1]]
                } else {
                    lappend params [list -pos pj $pjVal]
                }
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {model custparams area pj name np nm}} {
                    if {[@ $value 0] eq {-eq}} {
                        lappend params [list -eq $paramName [@ $value 1]]
                    } else {
                        lappend params [list $paramName $value]
                    }
                }
            }
            if {[dget $arguments custparams] ne {}} {
                if {[llength [dget $arguments custparams]]%2!=0} {
                    return -code error "Custom parameters list must be even length"
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
            next d[dget $arguments name] [my FormPinNodeList $arguments {np nm}] $params
        }
    }

####  D class #
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
            #  -model value - name of the model
            #  -area value - scale factor, optional
            #  -m value - multiplier of area and perimeter, optional
            #  -temp value - device temperature, optional
            #  -ic1 value - initial conditions for vbe, optional
            #  -ic2 value - initial conditions for vce, optional
            #  -ns value - name of node connected to substrate pin, optional
            #  -tj value - name of node connected to thermal pin, optional, requires `-ns`
            # ```
            # QXXXXXXX nc nb ne <ns> <tj> mname <area=val> <areac=val>
            # + <areab=val> <m=val> <off> <ic=vbe,vce> <temp=val>
            # + <dtemp=val>
            # ```
            # Example of class initialization:
            # ```
            # Bjt new 1 netc netb nete -model bjtmod -ns nets -area 1e-3
            # ```
            # Synopsis: name nc nb ne -model value ?-ns value ?-tj value?? ?-area value? ?-m value?
            #   ?-temp value? ?-off? ?-ic1 value? ?-ic2 value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Bjt' that describes semiconductor\
                                                                  bipolar junction transistor device} {
                {-model= -required -help {Name of the model}}
                {-area= -help {Scale factor}}
                {-m= -help {Multiplier of area and perimeter}}
                {-temp= -help {Device temperature}}
                {-off -boolean -help {Initial state}}
                {-ic1= -help {Initial conditions for vbe}}
                {-ic2= -help {Initial conditions for vce}}
                {-ns= -help {Name of node connected to substrate pin}}
                {-tj= -require {ns} -help {Name of node connected to thermal pin}}
                {name -help {Name of the device without first-letter designator}}
                {nc -help {Name of node connected to collector pin}}
                {nb -help {Name of node connected to base pin}}
                {ne -help {Name of node connected to emitter pin}}
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
            dict for {paramName value} $arguments {
                if {$paramName ni {model area off ns tj name nc nb ne}} {
                    if {[@ $value 0] eq {-eq}} {
                        lappend params [list -eq $paramName [@ $value 1]]
                    } else {
                        lappend params [list $paramName $value]
                    }
                }
            }
            set pinList [my FormPinNodeList $arguments {nc nb ne}]
            if {[dexist $arguments ns]} {
                lappend pinList [list ns [dget $arguments ns]]
                if {[dexist $arguments tj]} {
                    lappend pinList [list tj [dget $arguments tj]]
                }
            }
            next q[dget $arguments name] $pinList $params
        }
        method genSPICEString {} {
            # Modify substrate pin string in order to complain square brackets enclosure,
            # see BJT info in reference manual of Xyce
            # Returns: SPICE netlist's string
            set SPICEStr [next]
            if {[dexist [my actOnPin -get -all] ns]} {
                set SPICEList [split $SPICEStr]
                set SPICEStr [join [lreplace $SPICEList 4 4 "\[[@ $SPICEList 4]\]"]]
            }
            return $SPICEStr
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
            #  -model value - name of the model
            #  -area value - scale factor, optional
            #  -temp value - device temperature, optional
            # ```
            # J<name> <drain node> <gate node> <source node> <model name> [area value] [device parameters]
            # ```
            # Example of class initialization:
            # ```
            # Jfet new 1 netd netg nets -model jfetmod -area {-eq area*2} -temp 25
            # ```
            # Synopsis: name nd ng ns -model value ?-area value? ?-temp value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Jfet' that describes semiconductor\
                                                                  junction FET device} {
                {-model= -required -help {Name of the model}}
                {-area= -help {Emitter scale factor}}
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
            dict for {paramName value} $arguments {
                if {$paramName ni {model area name nd ng ns}} {
                    if {[@ $value 0] eq {-eq}} {
                        lappend params [list -eq $paramName [@ $value 1]]
                    } else {
                        lappend params [list $paramName $value]
                    }
                }
            }
            next j[dget $arguments name] [my FormPinNodeList $arguments {nd ng ns}] $params
        }
    }

####  J class #
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
            #  -model value - name of the model
            #  -area value - scale factor, optional
            #  -temp value - device temperature, optional
            # ```
            # Z<name> < drain node> <gate node> <source node> <model name> [area value] [device parameters]
            # ```
            # Example of class initialization:
            # ```
            # Mesfet new 1 netd netg nets -model mesfetmod -area {-eq area*2}
            # ```
            # Synopsis: name nd ng ns -model value ?-area value? ?-temp value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Mesfet' that describes\
                                                                  semiconductor MESFET device} {
                {-model= -required -help {Name of the model}}
                {-area= -help {Scale factor}}
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
            dict for {paramName value} $arguments {
                if {$paramName ni {model area name nd ng ns}} {
                    if {[@ $value 0] eq {-eq}} {
                        lappend params [list -eq $paramName [@ $value 1]]
                    } else {
                        lappend params [list $paramName $value]
                    }
                }
            }
            next z[dget $arguments name] [my FormPinNodeList $arguments {nd ng ns}] $params
        }
    }

####  Z class #
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
            #  -model value - name of the model
            #  -m value - multiplier, optional
            #  -l value - length of channel, optional
            #  -w value - width of channel, optional
            #  -ad value - diffusion area of drain, optional, forbids `-nrd`
            #  -as value - diffusion area of source, optional, forbids `-nrs`
            #  -pd value - perimeter area of drain, optional
            #  -ps value - perimeter area of source, optional
            #  -nrd value - equivalent number of squares of the drain diffusions
            #  -nrs value - equivalent number of squares of the source diffusions
            #  -temp value - device temperature
            #  -ic value - initial conditions for vds, vgs and vbs, in form of three element list, optional, require 4th
            #    node
            #  -off - initial state, optional
            #  -n4 value - name of 4th node;
            #  -n5 value - name of 5th node, require `-n4`, optional
            #  -n6 value - name of 6th node, require `-n5`, optional
            #  -n7 value - name of 7th node, require `-n6`, optional
            #  -custparams - key that collects all arguments at the end of device definition, to provide an ability to
            #  add custom parameters in form `-custparams param1 param1Val param2 {-eq param2eq} param3 param3Val ...`
            #  Must be specified after all others options. Optional.
            # ```
            # M<name> <drain node> <gate node> <source node>
            # + <bulk/substrate node> <model name>
            # + [L=<value>] [W=<value>]
            # + [AD=<value>] [AS=<value>]
            # + [PD=<value>] [PS=<value>]
            # + [NRD=<value>] [NRS=<value>]
            # + [M=<value] [IC=<value, ...>]
            # ```
            # Example of class initialization:
            # ```
            # Mosfet new 1 netd netg nets -model mosfetmod -l 1e-6 -w 10e-3 -n4 netsub -n5 net5
            # ```
            # Synopsis: name nd ng ns -model value ?-n4 value ?-n5 value ?-n6 value ?-n7 value???? ?-m value?
            #   ?-l value? ?-w value? ?-ad value|-nrd value? ?-as value|-nrs value? ?-temp value? ?-off? ?-pd value?
            #   ?-ps value? ?-ic \{value value value\}?
            #   ?-custparams param1 \{?-eq|-poseq|-posnocheck|-pos|-nocheck? param1Val\} ...?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Mosfet' that describes\
                                                                  semiconductor MOSFET device} {
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
                {-ic= -validate {[llength $arg]==3} -help {Initial conditions for vds, vgs and vbs, in form\
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
                    return -code error "Custom parameters list must be even length"
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
            set pinList [my FormPinNodeList $arguments {nd ng ns}]
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

####  M class #
    # alias for Mosfet class
    oo::class create M {
        superclass Mosfet
    }
}
