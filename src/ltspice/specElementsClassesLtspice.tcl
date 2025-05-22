#  .|'''.|            ||                   ..|'''.|                   |''||''|         '||'
#  ||..  '  ... ...  ...    ....    ....  .|'     '    ....  .. ...      ||      ....   ||
#   ''|||.   ||'  ||  ||  .|   '' .|...|| ||    .... .|...||  ||  ||     ||    .|   ''  ||
# .     '||  ||    |  ||  ||      ||      '|.    ||  ||       ||  ||     ||    ||       ||
# |'....|'   ||...'  .||.  '|...'  '|...'  ''|...'|   '|...' .||. ||.   .||.    '|...' .||.
#            ||
#           ''''
# specElementsClassesLtspice.tcl
# Describes LTspice elements classes
#
# Copyright (c) 2024 George Yashin, georgtree@gmail.com
#
# MIT License
# See the file "LICENSE.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

namespace eval ::SpiceGenTcl {
    namespace eval Ltspice::BasicDevices {
        namespace export Resistor R  Capacitor C Inductor L SubcircuitInstance X SubcircuitInstanceAuto XAuto VSwitch\
                VSw CSwitch W
    }
    namespace eval Ltspice::Sources {
        namespace export Vdc Idc Vac Iac Vpulse Ipulse Vsin Isin Vexp Iexp Vpwl Ipwl Vsffm Isffm Vam Iam Vccs G Vcvs E\
                Cccs F Ccvs H BehaviouralSource B Vport
    }
    namespace eval Ltspice::SemiconductorDevices {
        namespace export Diode D Bjt Q Jfet J Mesfet Z Mosfet M
    }
}



###  Basic devices

namespace eval ::SpiceGenTcl::Ltspice::BasicDevices {

####  Resistor class

    oo::class create Resistor {
        superclass ::SpiceGenTcl::Common::BasicDevices::Resistor
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
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -c - capacitance value or equation
            #  -q - charge equation
            #  -m - multiplier value, optional
            #  -temp - device temperature, optional
            #  -ic - initial voltage on capacitor, optional
            #  -rser - series resistance, optional
            #  -lser - series inductance, optional
            #  -rpar - parallel resistance, optional
            #  -cpar - parallel capacitor, optional
            #  -rlshunt - shunt resistance across series inductance, optional
            # Capacitor type could be specified with additional switch `-q` if we
            # want to model circuit's variable dependent capacitor.
            # Simple capacitor:
            # ```
            # Cnnn n1 n2 <capacitance> [ic=<value>]
            # + [Rser=<value>] [Lser=<value>] [Rpar=<value>]
            # + [Cpar=<value>] [m=<value>]
            # + [RLshunt=<value>] [temp=<value>]
            # ```
            # Example of class initialization as a simple capacitor:
            # ```
            # ::SpiceGenTcl::Ltspice::BasicDevices::Capacitor new 1 netp netm -r 1e-6 -temp {temp -eq}
            # ```
            # Behavioral capacitor with Q expression:
            # ```
            # Cnnn n1 n2 Q=<expression> [ic=<value>] [m=<value>]
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::BasicDevices::Capacitor new 1 netp netm -q "V(a)+V(b)+pow(V(c),2)"
            # ```
            # Synopsis: name npNode nmNode -c value ?-m value? ?-temp value? ?-ic value? ?-rser value? ?-lser value?
            #   ?-rpar value? ?-cpar value? ?-rlshunt value?
            # Synopsis: name npNode nmNode -q value ?-m value? ?-ic value? ?-rser value? ?-lser value? ?-rpar value?
            #   ?-cpar value? ?-rlshunt value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Capacitor' that describes capacitor} {
                {-c= -forbid q -help {Capacitance value or equation}}
                {-q= -forbid c -help {Charge equation}}
                {-m= -help {Multiplier value}}
                {-temp= -forbid q -help {Device temperature}}
                {-ic= -help {Initial voltage on capacitor}}
                {-rser= -help {Series resistance}}
                {-lser= -help {Series inductance}}
                {-rpar= -help {Parallel resistance}}
                {-cpar= -help {Parallel capacitor}}
                {-rlshunt= -help {Shunt resistance across series inductance}}
                {name -help {Name of the device without first-letter designator}}
                {npNode -help {Name of node connected to positive pin}}
                {nmNode -help {Name of node connected to negative pin}}
            }]
            set params {}
            if {[dexist $arguments c]} {
                set cVal [dget $arguments c]
                if {([llength $cVal]>1) && ([@ $cVal 1] eq {-eq})} {
                    lappend params [list c [@ $cVal 0] -poseq]
                } else {
                    lappend params [list c $cVal -pos]
                }
            } elseif {![dexist $arguments q]} {
                return -code error {Capacitor value must be specified with '-c value'}
            }
            if {[dexist $arguments q]} {
                set qVal [dget $arguments q]
                lappend params [list q $qVal -eq]
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {c q name npNode nmNode}} {
                    lappend params [list $paramName {*}$value]
                }
            }
            next c[dget $arguments name] [list [list np [dget $arguments npNode]] [list nm [dget $arguments nmNode]]]\
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
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -l - inductance value
            #  -flux - equation for the flux
            #  -hyst - nonlinear inductor model switch
            #  -m - number of parallel units
            #  -ic - initial current
            #  -temp - device temperature
            #  -tc1 - linear inductance temperature coefficient
            #  -tc2 - quadratic inductance temperature coefficient
            #  -rser - series resistance
            #  -rpar - parallel resistance
            #  -cpar - parallel capacitor
            #  -hc - coercive force
            #  -br - remnant flux density
            #  -bs - saturation flux density
            #  -lm - magnetic Length (excl. gap)
            #  -lg - length of gap
            #  -a - cross sectional area
            #  -n - number of turns
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
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Inductor' that describes inductor} {
                {-l= -forbid {flux hyst} -help {Inductance value}}
                {-flux= -forbid {l hyst} -help {Equation for the flux}}
                {-hyst -forbid {l flux} -reciprocal -require {hc br bs lm lg a n} -help {Nonlinear inductor model\
                                                                                                 switch}}
                {-m= -help {Number of parallel units}}
                {-ic= -help {Initial current}}
                {-temp= -help {Device temperature}}
                {-tc1= -help {Linear inductance temperature coefficient}}
                {-tc2= -help {Quadratic inductance temperature coefficient}}
                {-rser= -help {Series resistance}}
                {-rpar= -help {Parallel resistance}}
                {-cpar= -help {Parallel capacitor}}
                {-hc= -help {Coercive force}}
                {-br= -help {Remnant flux density}}
                {-bs= -help {Saturation flux density}}
                {-lm= -help {Magnetic Length (excl. gap)}}
                {-lg= -help {Length of gap}}
                {-a= -help {Cross sectional area}}
                {-n= -help {Number of turns}}
                {name -help {Name of the device without first-letter designator}}
                {npNode -help {Name of node connected to positive pin}}
                {nmNode -help {Name of node connected to negative pin}}
            }]
            set params {}
            if {[dexist $arguments l]} {
                set lVal [dget $arguments l]
                if {([llength $lVal]>1) && ([@ $lVal 1] eq {-eq})} {
                    lappend params [list l [@ $lVal 0] -poseq]
                } else {
                    lappend params [list l $lVal -pos]
                }
            } elseif {![dexist $arguments flux] && ![dexist $arguments hyst]} {
                return -code error {Inductor value must be specified with '-l value'}
            }
            if {[dexist $arguments flux]} {
                set fluxVal [dget $arguments flux]
                lappend params [list flux [dget $arguments flux] -eq]
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {l flux hyst name npNode nmNode}} {
                    lappend params [list $paramName {*}$value]
                }
            }
            next l[dget $arguments name] [list [list np [dget $arguments npNode]] [list nm [dget $arguments nmNode]]]\
                    $params
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
            # Xxxx n1 n2 n3... <subckt name> [<parameter>=<expression>]
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::BasicDevices::SubcircuitInstance new 1 {{plus net1} {minus net2}} rcnet {{r 1} {c cpar -eq}}
            # ```
            argparse -pfirst -help {Creates object of class 'SubcircuitInstance' that describes subcircuit instance} {
                {name -help {Name of the device without first-letter designator}}
                {pins -help {List of pins {{pinName nodeName} {pinName nodeName} ...}}}
                {subName -help {Name of subcircuit definition}}
                {params -help {List of parameters {{paramName paramValue ?-eq?} {paramName paramValue ?-eq?}}}}
            }
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
            # Xxxx n1 n2 n3... <subckt name> [<parameter>=<expression>]
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::BasicDevices::SubcircuitInstanceAuto new $subcktObj 1 {net1 net2} -r 1 -c {cpar -eq}
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
}

###  Sources devices

namespace eval ::SpiceGenTcl::Ltspice::Sources {

####  dc sources template class

    oo::abstract create dc {
        superclass ::SpiceGenTcl::Device
        constructor {type args} {
            if {$type eq {v}} {
                set typeName voltage
            } else {
                set typeName current
            }
            set arguments [argparse -inline -pfirst -help "Creates object of class '[string totitle ${type}dc]' that\
                     describes simple constant $typeName source" {
                {-dc= -required -help {DC voltage value}}
                {-rser= -help {Series resistor value}}
                {-cpar= -help {Parallel capacitor value}}
                {name -help {Name of the device without first-letter designator}}
                {npNode -help {Name of node connected to positive pin}}
                {nmNode -help {Name of node connected to negative pin}}
            }]
            set dcVal [dget $arguments dc]
            if {([llength $dcVal]>1) && ([@ $dcVal 1] eq {-eq})} {
                lappend params [list dc [@ $dcVal 0] -poseq]
            } else {
                lappend params [list dc $dcVal -pos]
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {dc name npNode nmNode}} {
                    if {([llength $value]>1) && ([@ $value 1] eq {-eq})} {
                        lappend params [list $paramName [@ $value 0] -eq]
                    } else {
                        lappend params [list $paramName {*}$value]
                    }
                }
            }
            next $type[dget $arguments name] [list [list np [dget $arguments npNode]]\
                                                      [list nm [dget $arguments nmNode]]] $params
        }
    }

####  ac sources template class

    oo::abstract create ac {
        superclass ::SpiceGenTcl::Device
        constructor {type args} {
            if {$type eq {v}} {
                set typeName voltage
            } else {
                set typeName current
            }
            set arguments [argparse -inline -pfirst -help "Creates object of class '[string totitle ${type}ac]' that\
                    describes ac $typeName source" {
                {-dc= -default 0 -help {DC voltage value}}
                {-ac= -required -help {AC voltage value}}
                {-rser= -help {Series resistor value}}
                {-cpar= -help {Parallel capacitor value}}
                {name -help {Name of the device without first-letter designator}}
                {npNode -help {Name of node connected to positive pin}}
                {nmNode -help {Name of node connected to negative pin}}
            }]
            set dcVal [dget $arguments dc]
            if {([llength $dcVal]>1) && ([@ $dcVal 1] eq {-eq})} {
                lappend params [list dc [@ $dcVal 0] -poseq]
            } else {
                lappend params [list dc $dcVal -pos]
            }
            set acVal [dget $arguments ac]
            if {([llength $acVal]>1) && ([@ $acVal 1] eq {-eq})} {
                lappend params [list ac [@ $acVal 0] -eq]
            } else {
                lappend params [list ac $acVal]
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {dc ac name npNode nmNode}} {
                    if {([llength $value]>1) && ([@ $value 1] eq {-eq})} {
                        lappend params [list $paramName [@ $value 0] -eq]
                    } else {
                        lappend params [list $paramName {*}$value]
                    }
                }
            }
            next $type[dget $arguments name] [list [list np [dget $arguments npNode]]\
                                                      [list nm [dget $arguments nmNode]]] $params
        }
    }

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
                {-voff|ioff|low= -required -help {Low value}}
                {-von|ion|high= -required -help {High value}}
                {-td= -required -help {Delay time}}
                {-tr= -required -help {Rise time}}
                {-tf= -required -help {Fall time}}
                {-pw|ton= -required -help {Width of pulse}}
                {-per|tper= -required -help {Period time}}
                {-ncycles|np= -help {Number of pulses}}
                {-rser= -help {Series resistor value}}
                {-cpar= -help {Parallel capacitor value}}
                {name -help {Name of the device without first-letter designator}}
                {npNode -help {Name of node connected to positive pin}}
                {nmNode -help {Name of node connected to negative pin}}
            }]
            set paramsOrder {low high td tr tf ton tper np}
            lappend params {model pulse -posnocheck}
            my ParamsProcess $paramsOrder $arguments params
            dict for {paramName value} $arguments {
                if {($paramName ni $paramsOrder) && ($paramName ni {name npNode nmNode})} {
                    if {([llength $value]>1) && ([@ $value 1] eq {-eq})} {
                        lappend params [list $paramName [@ $value 0] -eq]
                    } else {
                        lappend params [list $paramName {*}$value]
                    }
                }
            }
            next $type[dget $arguments name] [list [list np [dget $arguments npNode]]\
                                                      [list nm [dget $arguments nmNode]]] $params
        }
    }

####  sin sources template class

    oo::abstract create sin {
        superclass ::SpiceGenTcl::Device
        mixin ::SpiceGenTcl::Utility
        constructor {type args} {
            if {$type eq {v}} {
                set typeName voltage
            } else {
                set typeName current
            }
            set arguments [argparse -inline -pfirst -help "Creates object of class '[string totitle ${type}sin]' that\
                    describes sinusoidal $typeName source" {
                {-i0|voffset|ioffset|v0= -required -help {DC value}}
                {-ia|vamp|iamp|va= -required -help {AC value}}
                {-freq= -required -help {Frequency of sinusoidal signal}}
                {-td= -help {Time delay}}
                {-theta= -require td -help {Damping factor}}
                {-phi|phase= -require {td theta} -help {Phase of signal}}
                {-ncycles= -require {td theta phase} -help {Number of periods}}
                {-rser= -help {Series resistor value}}
                {-cpar= -help {Parallel capacitor value}}
                {name -help {Name of the device without first-letter designator}}
                {npNode -help {Name of node connected to positive pin}}
                {nmNode -help {Name of node connected to negative pin}}
            }]
            set paramsOrder {v0 va freq td theta phase ncycles}
            lappend params {model sin -posnocheck}
            my ParamsProcess $paramsOrder $arguments params
            dict for {paramName value} $arguments {
                if {($paramName ni $paramsOrder) && ($paramName ni {name npNode nmNode})} {
                    if {([llength $value]>1) && ([@ $value 1] eq {-eq})} {
                        lappend params [list $paramName [@ $value 0] -eq]
                    } else {
                        lappend params [list $paramName {*}$value]
                    }
                }
            }
            next $type[dget $arguments name] [list [list np [dget $arguments npNode]]\
                                                      [list nm [dget $arguments nmNode]]] $params
        }
    }

####  exp sources template class

    oo::abstract create exp {
        superclass ::SpiceGenTcl::Device
        mixin ::SpiceGenTcl::Utility
        constructor {type args} {
            if {$type eq {v}} {
                set typeName voltage
            } else {
                set typeName current
            }
            set arguments [argparse -inline -pfirst -help "Creates object of class '[string totitle ${type}exp]' that\
                    describes exponential $typeName source" {
                {-i1|v1= -required -help {Initial value}}
                {-i2|v2= -required -help {Pulsed value}}
                {-td1= -required -help {Rise delay time}}
                {-tau1= -required -help {Rise time constant}}
                {-td2= -required -help {Fall delay time}}
                {-tau2= -required -help {Fall time constant}}
                {-rser= -help {Series resistor value}}
                {-cpar= -help {Parallel capacitor value}}
                {name -help {Name of the device without first-letter designator}}
                {npNode -help {Name of node connected to positive pin}}
                {nmNode -help {Name of node connected to negative pin}}
            }]
            set paramsOrder {v1 v2 td1 tau1 td2 tau2}
            lappend params {model exp -posnocheck}
            my ParamsProcess $paramsOrder $arguments params
            dict for {paramName value} $arguments {
                if {($paramName ni $paramsOrder) && ($paramName ni {name npNode nmNode})} {
                    if {([llength $value]>1) && ([@ $value 1] eq {-eq})} {
                        lappend params [list $paramName [@ $value 0] -eq]
                    } else {
                        lappend params [list $paramName {*}$value]
                    }
                }
            }
            next $type[dget $arguments name] [list [list np [dget $arguments npNode]]\
                                                      [list nm [dget $arguments nmNode]]] $params
        }
    }

####  pwl sources template class

    oo::abstract create pwl {
        superclass ::SpiceGenTcl::Device
        constructor {type args} {
            if {$type eq {v}} {
                set typeName voltage
            } else {
                set typeName current
            }
            set arguments [argparse -inline -pfirst -help "Creates object of class '[string totitle ${type}pwl]' that\
                    describes piece-wise $typeName source" {
                {-seq= -required -help {Sequence of pwl points in form {t0 i0 t1 i1 t2 i2 t3 i3 ...}}}
                {-rser= -help {Series resistor value}}
                {-cpar= -help {Parallel capacitor value}}
                {name -help {Name of the device without first-letter designator}}
                {npNode -help {Name of node connected to positive pin}}
                {nmNode -help {Name of node connected to negative pin}}
            }]
            set pwlSeqVal [dget $arguments seq]
            set pwlSeqLen [llength $pwlSeqVal]
            if {$pwlSeqLen%2} {
                return -code error "Number of elements '$pwlSeqLen' in pwl sequence is odd in element\
                        '$type[dget $arguments name]', must be even"
            } elseif {$pwlSeqLen<4} {
                return -code error "Number of elements '$pwlSeqLen' in pwl sequence in element\
                        '$type[dget $arguments name]' must be >=4"
            }
            # parse pwlSeq argument
            for {set i 0} {$i<[llength $pwlSeqVal]/2} {incr i} {
                set 2i [* 2 $i]
                set 2ip1 [+ $2i 1]
                lappend params [list t$i [@ $pwlSeqVal $2i]] [list $type$i [@ $pwlSeqVal $2ip1]]
            }
            foreach param $params {
                if {([llength [@ $param 1]]>1) && ([@ [@ $param 1] 1] eq {-eq})} {
                    lappend paramList [list [@ $param 0] [@ [@ $param 1] 0] -poseq]
                } else {
                    lappend paramList [list [@ $param 0] [@ $param 1] -pos]
                }
            }
            foreach paramName {rser cpar} {
                if {[dexist $arguments $paramName]} {
                    set paramVal [dget $arguments $paramName]
                    if {([llength $paramVal]>1) && ([@ $paramVal 1] eq {-eq})} {
                        lappend paramList [list $paramName [@ $paramVal 0] -eq]
                    } else {
                        lappend paramList [list $paramName {*}$paramVal]
                    }
                }
            }
            set paramList [linsert $paramList 0 {model pwl -posnocheck}]
            next $type[dget $arguments name] [list [list np [dget $arguments npNode]]\
                                                      [list nm [dget $arguments nmNode]]] $paramList
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
                {-i0|voff|ioff|v0= -required -help {Initial value}}
                {-ia|vamp|iamp|va= -required -help {Pulsed value}}
                {-fcar|fc= -required -help {Carrier frequency}}
                {-mdi= -required -help {Modulation index}}
                {-fsig|fs= -required -help {Signal frequency}}
                {-rser= -help {Series resistor value}}
                {-cpar= -help {Parallel capacitor value}}
                {name -help {Name of the device without first-letter designator}}
                {npNode -help {Name of node connected to positive pin}}
                {nmNode -help {Name of node connected to negative pin}}
            }]
            set paramsOrder {v0 va fc mdi fs}
            lappend params {model sffm -posnocheck}
            my ParamsProcess $paramsOrder $arguments params
            dict for {paramName value} $arguments {
                if {($paramName ni $paramsOrder) && ($paramName ni {name npNode nmNode})} {
                    if {([llength $value]>1) && ([@ $value 1] eq {-eq})} {
                        lappend params [list $paramName [@ $value 0] -eq]
                    } else {
                        lappend params [list $paramName {*}$value]
                    }
                }
            }
            next $type[dget $arguments name] [list [list np [dget $arguments npNode]]\
                                                      [list nm [dget $arguments nmNode]]] $params
        }
    }

####  Vdc class

    oo::class create Vdc {
        superclass ::SpiceGenTcl::Ltspice::Sources::dc
        constructor {args} {
            # Creates object of class `Vdc` that describes simple constant voltage source.
            #  name - name of the device without first-letter designator V
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -dc - DC voltage value
            #  -rser - series resistor value, optional
            #  -cpar - parallel capacitor value, optional
            # ```
            # Vxxx n+ n- <voltage> [Rser=<value>] [Cpar=<value>]
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::Sources::Vdc new 1 netp netm -dc 10 -rser 0.001
            # ```
            # Synopsis: name npNode nmNode -dc value ?-rser value? ?-cpar value?
            next v {*}$args
        }
    }

####  Vac class

    oo::class create Vac {
        superclass ::SpiceGenTcl::Ltspice::Sources::ac
        constructor {args} {
            # Creates object of class `Vac` that describes ac voltage source.
            #  name - name of the device without first-letter designator V
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -dc - DC voltage value, default 0
            #  -ac - AC voltage value
            #  -rser - series resistor value, optional
            #  -cpar - parallel capacitor value, optional
            # ```
            # Vxxx n+ n- <voltage> AC=<amplitude> [Rser=<value>] [Cpar=<value>]
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Sources::Vac new 1 netp netm -ac 10 -cpar 1e-9
            # ```
            # Synopsis: name npNode nmNode -ac value ?-dc value? ?-rser value? ?-cpar value?
            next v {*}$args
        }
    }


####  Vpulse class

    oo::class create Vpulse {
        superclass ::SpiceGenTcl::Ltspice::Sources::pulse
        constructor {args} {
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
            #  -np - number of pulses, optional, alias -ncycles
            #  -rser - series resistor value, optional
            #  -cpar - parallel capacitor value, optional
            # ```
            # Vxxx n+ n- PULSE(V1 V2 Tdelay Trise Tfall Ton Tperiod Ncycles)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::Sources::Vpulse new 1 net1 net2 -low 0 -high 1 -td {td -eq} -tr 1e-9 -tf 1e-9 -pw 10e-6 -per 20e-6 -np {np -eq}
            # ```
            # Synopsis: name npNode nmNode -low|voff value -high|von value -td value -tr value -tf value -pw|ton value
            #   -per|tper value ?-np|ncycles value? ?-rser value? ?-cpar value?
            next v {*}$args
        }
    }

####  Vsin class

    oo::class create Vsin {
        superclass ::SpiceGenTcl::Ltspice::Sources::sin
        constructor {args} {
            # Creates object of class `Vsin` that describes sinusoidal voltage source.
            #  name - name of the device without first-letter designator V
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -v0 - DC shift value, aliases: -voffset, -i0, -ioffset
            #  -va - amplitude value, aliases: -vamp, -ia, -iamp
            #  -freq - frequency of sinusoidal signal
            #  -td - time delay, optional
            #  -theta - damping factor, optional, require -td
            #  -phase - phase of signal, optional, require -td and -theta, alias -phi
            #  -ncycles - number of cycles, optional, require -td, -theta and -phase
            #  -rser - series resistor value, optional
            #  -cpar - parallel capacitor value, optional
            # ```
            # Vxxx n+ n- SINE(Voffset Vamp Freq Td Theta Phi Ncycles)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Sources::Vsin new 1 net1 net2 -v0 0 -va 2 -freq {freq -eq} -td 1e-6 -theta {theta -eq}
            # ```
            # Synopsis: name npNode nmNode -v0|voffset value -va|vamp value -freq value ?-td value ?-theta value
            #   ?-phase|phi value ?-ncycles value???? ?-rser value? ?-cpar value?
            next v {*}$args
        }
    }

####  Vexp class

    oo::class create Vexp {
        superclass ::SpiceGenTcl::Ltspice::Sources::exp
        constructor {args} {
            # Creates object of class `Vexp` that describes exponential voltage source.
            #  name - name of the device without first-letter designator V
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -v1 - initial value
            #  -v2 - pulsed value
            #  -td1 - rise delay time
            #  -tau1 - rise time constant
            #  -td2 - fall delay time
            #  -tau2 - fall time constant
            #  -rser - series resistor value, optional
            #  -cpar - parallel capacitor value, optional
            # ```
            # Vxxx n+ n- EXP(V1 V2 Td1 Tau1 Td2 Tau2)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::Sources::Vexp new 1 net1 net2 -v1 0 -v2 1 -td1 1e-9 -tau1 1e-9 -td2 {td2 -eq} -tau2 10e-6
            # ```
            # Synopsis: name npNode nmNode -v1 value -v2 value -td1 value -tau1 value -td2 value -tau2 value
            #   ?-rser value? ?-cpar value?
            next v {*}$args
        }
    }

####  Vpwl class

    oo::class create Vpwl {
        superclass ::SpiceGenTcl::Ltspice::Sources::pwl
        constructor {args} {
            # Creates object of class `Vpwl` that describes piece-wise voltage source.
            #  name - name of the device without first-letter designator V
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -seq - sequence of pwl points in form {t0 v0 t1 v1 t2 v2 t3 v3 ...}
            #  -rser - series resistor value, optional
            #  -cpar - parallel capacitor value, optional
            # ```
            # Vxxx n+ n- PWL(t1 v1 t2 v2 t3 v3...)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::Sources::Vpwl new 1 npNode nmNode -seq {0 0 {t1 -eq} 1 2 2 3 3 4 4}
            # ```
            # Synopsis: name npNode nmNode -seq list ?-rser value? ?-cpar value?
            next v {*}$args
        }
    }

####  Vsffm class

    oo::class create Vsffm {
        superclass ::SpiceGenTcl::Ltspice::Sources::sffm
        constructor {args} {
            # Creates object of class `Vsffm` that describes single-frequency FM voltage source.
            #  name - name of the device without first-letter designator V
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -v0 - initial value, aliases: -voff, -i0, -ioff
            #  -va - pulsed value, aliases: -vamp, -ia, -iamp
            #  -fc - carrier frequency, alias -fcar
            #  -mdi - modulation index
            #  -fs - signal frequency, alias -fsig
            #  -rser - series resistor value, optional
            #  -cpar - parallel capacitor value, optional
            # ```
            # Vxxx n+ n- SFFM(Voff Vamp Fcar MDI Fsig)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::Sources::Vsin new 1 net1 net2 -v0 0 -va 1 -fc {freq -eq} -mdi 0 -fs 1e3
            # ```
            # Synopsis: name npNode nmNode -v0|voff value -va|vamp value -fc|fcar value -mdi value -fs|fsig value
            #   ?-rser value? ?-cpar value?
            next v {*}$args
        }
    }

####  Idc class

    oo::class create Idc {
        superclass ::SpiceGenTcl::Ltspice::Sources::dc
        constructor {args} {
            # Creates object of class `Idc` that describes simple constant current source.
            #  name - name of the device without first-letter designator I
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -dc - DC current value
            # ```
            # Ixxx n+ n- <current>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::Sources::Idc new 1 netp netm -dc 10
            # ```
            # Synopsis: name npNode nmNode -dc value
            if {({-rser} in $args) || ({-cpar} in $args)} {
                return -code error {Current source doesn't support rser and cpar parameters}
            }
            next i {*}$args
        }
    }

####  Iac class

    oo::class create Iac {
        superclass ::SpiceGenTcl::Ltspice::Sources::ac
        constructor {args} {
            # Creates object of class `Iac` that describes ac current source.
            #  name - name of the device without first-letter designator I
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -dc - DC current value, default 0
            #  -ac - AC current value
            # ```
            # Ixxx n+ n- <current> AC=<amplitude>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::Sources::Iac new 1 netp netm -ac 10
            # ```
            # Synopsis: name npNode nmNode -ac value ?-dc value?
            if {({-rser} in $args) || ({-cpar} in $args)} {
                return -code error {Current source doesn't support rser and cpar parameters}
            }
            next i {*}$args

        }
    }


####  Ipulse class

    oo::class create Ipulse {
        superclass ::SpiceGenTcl::Ltspice::Sources::pulse
        constructor {args} {
            # Creates object of class `Ipulse` that describes pulse current source.
            #  name - name of the device without first-letter designator I
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -low - low value, aliases: -voff, -ioff
            #  -high - high value, aliases: -von, ion
            #  -td - time delay
            #  -tr - rise time
            #  -tf - fall time
            #  -pw - width of pulse, alias -ton
            #  -per - period time, alias -tper
            #  -np - number of pulses, optional, alias -ncycles
            # ```
            # Ixxx n+ n- PULSE(Ioff Ion Tdelay Trise Tfall Ton Tperiod Ncycles)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::Sources::Ipulse new 1 net1 net2 -low 0 -high 1 -td {td -eq} -tr 1e-9 -tf 1e-9 -pw 10e-6 -per 20e-6 -np {np -eq}
            # ```
            # Synopsis: name npNode nmNode -low|ioff value -high|ion value -td value -tr value -tf value -pw|ton value
            #   -per|tper value ?-np|ncycles value?
            if {({-rser} in $args) || ({-cpar} in $args)} {
                return -code error {Current source doesn't support rser and cpar parameters}
            }
            next i {*}$args
        }
    }

####  Isin class

    oo::class create Isin {
        superclass ::SpiceGenTcl::Ltspice::Sources::sin
        constructor {args} {
            # Creates object of class `Isin` that describes sinusoidal current source.
            #  name - name of the device without first-letter designator I
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -v0 - DC shift value, aliases: -voffset, -v0, -ioffset
            #  -va - amplitude value, aliases: -vamp, -va, -iamp
            #  -freq - frequency of sinusoidal signal
            #  -td - time delay, optional
            #  -theta - damping factor, optional, require -td
            #  -phase - phase of signal, optional, require -td and -theta, alias -phi
            #  -ncycles - number of cycles, optional, require -td, -theta and -phase
            # ```
            # Ixxx n+ n- SINE(Ioffset Iamp Freq Td Theta Phi Ncycles)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::Sources::Isin new 1 net1 net2 -v0 0 -va 2 -freq {freq -eq} -td 1e-6 -theta {theta -eq}
            # ```
            # Synopsis: name npNode nmNode -i0|ioffset value -ia|iamp value -freq value ?-td value ?-theta value
            #   ?-phase|phi value ?-ncycles value????
            if {({-rser} in $args) || ({-cpar} in $args)} {
                return -code error {Current source doesn't support rser and cpar parameters}
            }
            next i {*}$args
        }
    }

####  Iexp class

    oo::class create Iexp {
        superclass ::SpiceGenTcl::Ltspice::Sources::exp
        constructor {args} {
            # Creates object of class `Iexp` that describes exponential current source.
            #  name - name of the device without first-letter designator I
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -i1 - initial value
            #  -i2 - pulsed value
            #  -td1 - rise delay time
            #  -tau1 - rise time constant
            #  -td2 - fall delay time
            #  -tau2 - fall time constant
            # ```
            # Ixxx n+ n- EXP(I1 I2 Td1 Tau1 Td2 Tau2)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::Sources::Iexp new 1 net1 net2 -i1 0 -i2 1 -td1 1e-9 -tau1 1e-9 -td2 {td2 -eq} -tau2 10e-6
            # ```
            # Synopsis: name npNode nmNode -i1 value -i2 value -td1 value -tau1 value -td2 value -tau2 value
            if {({-rser} in $args) || ({-cpar} in $args)} {
                return -code error {Current source doesn't support rser and cpar parameters}
            }
            next i {*}$args
        }
    }

####  Ipwl class

    oo::class create Ipwl {
        superclass ::SpiceGenTcl::Ltspice::Sources::pwl
        constructor {args} {
            # Creates object of class `Ipwl` that describes piece-wise current source.
            #  name - name of the device without first-letter designator I
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -seq - sequence of pwl points in form {t0 v0 t1 v1 t2 v2 t3 v3 ...}
            #  -rser - series resistor value, optional
            #  -cpar - parallel capacitor value, optional
            # ```
            # Ixxx n+ n- PWL(t1 i1 t2 i2 t3 i3...)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::Sources::Ipwl new 1 npNode nmNode -seq {0 0 {t1 -eq} 1 2 2 3 3 4 4}
            # ```
            # Synopsis: name npNode nmNode -seq list
            if {({-rser} in $args) || ({-cpar} in $args)} {
                return -code error {Current source doesn't support rser and cpar parameters}
            }
            next i {*}$args
        }
    }

####  Isffm class

    oo::class create Isffm {
        superclass ::SpiceGenTcl::Ltspice::Sources::sffm
        constructor {args} {
            # Creates object of class `Isffm` that describes single-frequency FM current source.
            #  name - name of the device without first-letter designator I
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -i0 - initial value, aliases: -voff, -v0, -ioff
            #  -ia - pulsed value, aliases: -vamp, -va, -iamp
            #  -fc - carrier frequency, alias -fcar
            #  -mdi - modulation index
            #  -fs - signal frequency, alias -fsig
            # ```
            # Ixxx n+ n- SFFM(Ioff Iamp Fcar MDI Fsig)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::Sources::Isin new 1 net1 net2 -i0 0 -ia 1 -fc {freq -eq} -mdi 0 -fs 1e3
            # ```
            # Synopsis: name npNode nmNode -i0|ioff value -ia|iamp value -fc|fcar value -mdi value -fs|fsig value
            if {({-rser} in $args) || ({-cpar} in $args)} {
                return -code error {Current source doesn't support rser and cpar parameters}
            }
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
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -i - current expression
            #  -v - voltage expression
            #  -ic - initial condition
            #  -tripdv - voltage control step rejection
            #  -tripdt - voltage control time step rejection
            # ```
            # Bnnn n001 n002 V=<expression> [ic=<value>]
            # + [tripdv=<value>] [tripdt=<value>]
            # + [laplace=<expression> [window=<time>]
            # + [nfft=<number>] [mtol=<number>]]
            # ```
            # ```
            #  Bnnn n001 n002 I=<expression> [ic=<value>]
            # + [tripdv=<value>] [tripdt=<value>] [Rpar=<value>]
            # + [laplace=<expression> [window=<time>]
            # + [nfft=<number>] [mtol=<number>]]
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::Sources::BehaviouralSource new 1 netp netm -v "V(a)+V(b)+pow(V(c),2)"
            # ```
            # Synopsis: name npNode nmNode -v value ?-ic value? ?-tripdv value -tripdt value? ?-laplace value
            #   ?-window value? ?-nfft value? ?-mtol value??
            # Synopsis: name npNode nmNode -i value ?-ic value? ?-tripdv value -tripdt value? ?-laplace value
            #   ?-window value? ?-nfft value? ?-mtol value??
            set arguments [argparse -inline -pfirst -help {Creates object of class 'BehaviouralSource' that describes\
                                                                  behavioural source} {
                {-i= -forbid {v} -help {Current expression}}
                {-v= -forbid {i} -help {Voltage expression}}
                {-ic= -help {Initial condition}}
                {-tripdv= -require tripdt -help {Voltage control step rejection}}
                {-tripdt= -require tripdv -help {Voltage control time step rejection}}
                {-laplace= -help {Laplace equation}}
                {-window= -require laplace}
                {-nfft= -require laplace}
                {-mtol= -require laplace}
                {name -help {Name of the device without first-letter designator}}
                {npNode -help {Name of node connected to positive pin}}
                {nmNode -help {Name of node connected to negative pin}}
            }]
            if {[dexist $arguments i]} {
                lappend params [list i [dget $arguments i] -eq]
            } elseif {[dexist $arguments v]} {
                lappend params [list v [dget $arguments v] -eq]
            } else {
                return -code error {Equation must be specified as argument to -i or -v}
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {i v name npNode nmNode}} {
                    lappend params [list $paramName {*}$value]
                }
            }
            next b[dget $arguments name] [list [list np [dget $arguments npNode]] [list nm [dget $arguments nmNode]]]\
                    $params
        }
    }

####  B class

    # alias for BehaviouralSource class
    oo::class create B {
        superclass BehaviouralSource
    }
}
###  SemiconductorDevices

namespace eval ::SpiceGenTcl::Ltspice::SemiconductorDevices {

####  Diode class

    oo::class create Diode {
        superclass ::SpiceGenTcl::Device
        constructor {args} {
            # Creates object of class `Diode` that describes semiconductor diode device.
            #  name - name of the device without first-letter designator D
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -model - name of the model
            #  -area - area scale factor, optional
            #  -m - number of parallel devices, optional
            #  -n - number of series devices, optional
            #  -temp - device temperature, optional
            #  -off - initial state, optional
            # ```
            # Dnnn anode cathode <model> [area] [off] [m=<val>] [n=<val>] [temp=<value>]
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::SemiconductorDevices::Diode new 1 netp netm -model diomod -area 1e-6
            # ```
            # Synopsis: name npNode nmNode -model value ?-area value? ?-off? ?-m value? ?-n value? ?-temp value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Diode' that describes diode} {
                {-model= -required -help {Name of the model}}
                {-area= -help {Area scale factor}}
                {-off -boolean -help {Initial state}}
                {-m= -help {Multiplier of area and perimeter}}
                {-n= -help {Number of series devices}}
                {-temp= -help {Device temperature}}
                {name -help {Name of the device without first-letter designator}}
                {npNode -help {Name of node connected to positive pin}}
                {nmNode -help {Name of node connected to negative pin}}
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
            dict for {paramName value} $arguments {
                if {$paramName ni {model area off name npNode nmNode}} {
                    lappend params [list $paramName {*}$value]
                }
            }
            next d[dget $arguments name] [list [list np [dget $arguments npNode]] [list nm [dget $arguments nmNode]]]\
                    $params
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
            #  ncNode - name of node connected to collector pin
            #  nbNode - name of node connected to base pin
            #  neNode - name of node connected to emitter pin
            #  -model - name of the model
            #  -area - scale factor, optional
            #  -m - multiplier of area and perimeter, optional
            #  -temp - device temperature, optional
            #  -ns - name of node connected to substrate pin, optional
            # ```
            # Qxxx Collector Base Emitter [Substrate Node] model [area] [off] [temp=<T>]
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::SemiconductorDevices::Bjt new 1 netc netb nete -model bjtmod -ns nets -area 1e-3
            # ```
            # Synopsis: name ncNode nbNode neNode -model value ?-ns value? ?-area value? ?-m value?  ?-temp value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Bjt' that describes semiconductor\
                                                                  bipolar junction transistor device} {
                {-model= -required -help {Name of the model}}
                {-area= -help {Emitter scale factor}}
                {-off -boolean}
                {-m= -help {Multiplier of area and perimeter}}
                {-temp= -help {Device temperature}}
                {-ns= -help {Name of node connected to substrate pin}}
                {name -help {Name of the device without first-letter designator}}
                {ncNode -help {Name of node connected to collector pin}}
                {nbNode -help {Name of node connected to base pin}}
                {neNode -help {Name of node connected to emitter pin}}
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
            dict for {paramName value} $arguments {
                if {$paramName ni {model area off ns name ncNode nbNode neNode}} {
                    lappend params [list $paramName {*}$value]
                }
            }
            set pinList [list [list nc [dget $arguments ncNode]] [list nb [dget $arguments nbNode]]\
                                 [list ne [dget $arguments neNode]]]
            if {[dexist $arguments ns]} {
                lappend pinList [list ns [dget $arguments ns]]
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
            #  ndNode - name of node connected to drain pin
            #  ngNode - name of node connected to gate pin
            #  nsNode - name of node connected to source pin
            #  -model - name of the model
            #  -area - emitter scale factor, optional
            #  -temp - device temperature, optional
            #  -m - parallel device multiplier, optional
            #  -off - initial state, optional
            # ```
            # JXXXXXXX nd ng ns mname  <area> <off> <temp =t>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::SemiconductorDevices::Jfet new 1 netd netg nets -model jfetmod -area {area*2 -eq} -temp 25
            # ```
            # Synopsis: name ndNode ngNode nsNode -model value ?-area value? ?-off? ?-temp value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Jfet' that describes semiconductor\
                                                                  junction FET device} {
                {-model= -required}
                {-area= -help {Scale factor}}
                {-m= -help {Parallel device multiplier}}
                {-off -boolean -help {Initial state}}
                {-temp= -help {Device temperature}}
                {name -help {Name of the device without first-letter designator}}
                {ndNode -help {Name of node connected to drain pin}}
                {ngNode -help {Name of node connected to gate pin}}
                {nsNode -help {Name of node connected to source pin}}
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
            dict for {paramName value} $arguments {
                if {$paramName ni {model area off name ndNode ngNode nsNode}} {
                    lappend params [list $paramName {*}$value]
                }
            }
            next j[dget $arguments name] [list [list nd [dget $arguments ndNode]] [list ng [dget $arguments ngNode]]\
                                                  [list ns [dget $arguments nsNode]]] $params
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
            #  ndNode - name of node connected to drain pin
            #  ngNode - name of node connected to gate pin
            #  nsNode - name of node connected to source pin
            #  -model - name of the model
            #  -area - emitter scale factor, optional
            #  -m - parallel device multiplier, optional
            #  -temp - device temperature, optional
            #  -off - initial state, optional
            # ```
            # ZXXXXXXX ND NG NS MNAME <AREA> <OFF> <IC=VDS,VGS>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::SemiconductorDevices::Mesfet new 1 netd netg nets -model mesfetmod -area {area*2 -eq}
            # ```
            # Synopsis: name ndNode ngNode nsNode -model value ?-area value? ?-off? ?-ic \{value value\} ?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Mesfet' that describes semiconductor\
                                                                  junction FET device} {
                {-model= -required -help {Name of the model}}
                {-area= -help {Scale factor}}
                {-m= -help {Parallel device multiplier}}
                {-off -boolean -help {Initial state}}
                {-temp= -help {Device temperature}}
                {name -help {Name of the device without first-letter designator}}
                {ndNode -help {Name of node connected to drain pin}}
                {ngNode -help {Name of node connected to gate pin}}
                {nsNode -help {Name of node connected to source pin}}
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
            dict for {paramName value} $arguments {
                if {$paramName ni {model area off name ndNode ngNode nsNode}} {
                    lappend params [list $paramName {*}$value]
                }
            }
            next z[dget $arguments name] [list [list nd [dget $arguments ndNode]] [list ng [dget $arguments ngNode]]\
                                                  [list ns [dget $arguments nsNode]]] $params

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
            #  ndNode - name of node connected to drain pin
            #  ngNode - name of node connected to gate pin
            #  nsNode - name of node connected to source pin
            #  -model - name of the model
            #  -m - multiplier, optional
            #  -l - length of channel, optional
            #  -w - width of channel, optional
            #  -area - area of VDMOS device, optional
            #  -ad - diffusion area of drain, optional, forbid -nrd, require -n4
            #  -as - diffusion area of source, optional, forbid -nrs, require -n4
            #  -pd - perimeter area of drain, optional, require -n4
            #  -ps - perimeter area of source, optional, require -n4
            #  -nrd - equivalent number of squares of the drain diffusions, forbid -ad, require -n4
            #  -nrs - equivalent number of squares of the source diffusions, forbid -as, require -n4
            #  -temp - device temperature
            #  -ic - initial conditions for vds, vgs and vbs, in form of three element list, optional, require -n4
            #  -off - initial state, optional
            #  -n4 - name of substrate node
            #  -n5 - name of 5th node, require -n4, optional
            #  -n6 - name of 6th node, require -n5, optional
            #  -n7 - name of 7th node, require -n6, optional
            #  -custparams - key that collects all arguments at the end of device definition, to provide an ability
            #  to add custom parameters in form `-custparams param1 param1Val param2 {param2eq -eq} param3 param3Val ...`
            #  Must be specified after all others options. Optional.
            # ```
            # Mxxx Nd Ng Ns Nb <model> [m=<value>] [L=<len>]
            # + [W=<width>] [AD=<area>] [AS=<area>]
            # + [PD=<perim>] [PS=<perim>] [NRD=<value>]
            # + [NRS=<value>] [off] [IC=<Vds, Vgs, Vbs>]
            # + [temp=<T>]
            # ```
            # ```
            # Mxxx Nd Ng Ns <model> [L=<len>] [W=<width>]
            # + [area=<value>] [m=<value>] [off]
            # + [temp=<T>]
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::Mosfet new 1 netd netg nets -model mosfetmod -l 1e-6 -w 10e-3 -n4 netsub -n5 net5
            # ```
            # Synopsis: name ndNode ngNode nsNode -model value -n4|nb value ?-n5 value ?-n6 value ?-n7 value???
            #   ?-m value? ?-l value? ?-w value? ?-ad value|-nrd value? ?-as value|-nrs value? ?-temp value? ?-off?
            #   ?-pd value? ?-ps value? ?-ic \{value value value\}?
            #   ?-custparams param1 \{param1Val ?-eq|-poseq|-posnocheck|-pos|-nocheck?\} ...?
            # Synopsis: name ndNode ngNode nsNode -model value ?-m value? ?-l value? ?-w value?
            #    ?-temp value? ?-off? ?-custparams param1 \{param1Val ?-eq|-poseq|-posnocheck|-pos|-nocheck?\} ...?
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
                {ndNode -help {Name of node connected to drain pin}}
                {ngNode -help {Name of node connected to gate pin}}
                {nsNode -help {Name of node connected to source pin}}
            }]
            lappend params [list model [dget $arguments model] -posnocheck]
            if {[dget $arguments off]==1} {
                lappend params {off -sw}
            }
            if {[dexist $arguments ic]} {
                lappend params [list ic [join [dget $arguments ic] ,] -nocheck]
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {model off ic n4 n5 n6 n7 custparams name ndNode ngNode nsNode}} {
                    lappend params [list $paramName {*}$value]
                }
            }
            if {[dget $arguments custparams] ne {}} {
                if {[llength [dget $arguments custparams]]%2!=0} {
                    return -code error {Custom parameters list must be even length}
                }
                set custParamDict [dcreate {*}[dget $arguments custparams]]
                dict for {paramName value} $custParamDict {
                    lappend params [list $paramName {*}$value]
                }
            }
            set pinList [list [list nd [dget $arguments ndNode]] [list ng [dget $arguments ngNode]]\
                                 [list ns [dget $arguments nsNode]]]
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
