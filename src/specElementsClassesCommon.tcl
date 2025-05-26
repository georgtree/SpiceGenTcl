#  .|'''.|            ||                   ..|'''.|                   |''||''|         '||'
#  ||..  '  ... ...  ...    ....    ....  .|'     '    ....  .. ...      ||      ....   ||  
#   ''|||.   ||'  ||  ||  .|   '' .|...|| ||    .... .|...||  ||  ||     ||    .|   ''  ||  
# .     '||  ||    |  ||  ||      ||      '|.    ||  ||       ||  ||     ||    ||       ||  
# |'....|'   ||...'  .||.  '|...'  '|...'  ''|...'|   '|...' .||. ||.   .||.    '|...' .||. 
#            ||                                                                             
#           ''''                                                                            
# specElementsClassesCommon.tcl
# Describes common elements classes
#
# Copyright (c) 2024 George Yashin, georgtree@gmail.com
#
# MIT License
# See the file "LICENSE.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

namespace eval ::SpiceGenTcl {
    namespace eval Common::BasicDevices {
        namespace export Resistor R Capacitor C Inductor L SubcircuitInstance X SubcircuitInstanceAuto XAuto VSwitch\
                VSw CSwitch W
    }
    namespace eval Common::Sources {
        namespace export Vdc Idc Vac Iac Vpulse Ipulse Vsin Isin Vexp Iexp Vpwl Ipwl Vsffm Isffm Vccs G Vcvs E Cccs F\
                Ccvs H
    }
}

###  Basic devices 

namespace eval ::SpiceGenTcl::Common::BasicDevices {
    
####  Resistor class 
    oo::class create Resistor {
        superclass ::SpiceGenTcl::Device
        constructor {args} {
            # Creates object of class `Resistor` that describes resistor.
            #  name - name of the device without first-letter designator R
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  -r - resistance value
            #  -m - multiplier value, optional
            #  -temp - device temperature, optional
            #  -tc1 - linear thermal coefficient, optional
            #  -tc2 - quadratic thermal coefficient, optional
            # Simple resistor:
            # ```
            # RXXXXXXX n+ n- <value> <m=val> <temp=val> <tc1=val> <tc2=val>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::BasicDevices::Resistor new 1 netp netm -r 1e3 -tc1 1 -temp {temp_amb -eq}
            # ```
            # Synopsis: name np nm -r value ?-m value? ?-temp value? ?-tc1 value? ?-tc2 value?
            set arguments [argparse -inline -pfirst -helplevel 1 -help {Creates object of class `Resistor` that describes\
                                                                               resistor} {
                {-r= -required -help {Resistance value}}
                {-m= -help {Multiplier value}}
                {-temp= -help {Device temperature}}
                {-tc1= -help {Linear thermal coefficient}}
                {-tc2= -help {Quadratic thermal coefficient}}
                {name -help {Name of the device without first-letter designator R}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
            }]
            set rVal [dget $arguments r]
            if {([llength $rVal]>1) && ([@ $rVal 1] eq {-eq})} {
                lappend params [list r [@ $rVal 0] -poseq]
            } else {
                lappend params [list r $rVal -pos]
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {r name np nm}} {
                    lappend params [list $paramName {*}$value]
                }
            }
            next r[dget $arguments name] [list [list np [dget $arguments np]] [list nm [dget $arguments nm]]]\
                    $params
        }
        destructor {
            puts 1
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
            #  -c - capacitance value
            #  -m - multiplier value, optional
            #  -temp - device temperature, optional, optional
            #  -tc1 - linear thermal coefficient, optional
            #  -tc2 - quadratic thermal coefficient, optional
            #  -ic - initial condition, optional
            # Simple capacitor:
            # ```
            # CXXXXXXX n+ n- <value> <m=val> <temp=val> <tc1=val> <tc2=val>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::BasicDevices::Capacitor new 1 netp netm -c 1e3 -tc1 1 -temp {temp_amb -eq}
            # ```
            # Synopsis: name np nm -c value ?-m value? ?-temp value? ?-tc1 value? ?-tc2 value? ?-ic value?
            set arguments [argparse -inline -pfirst -help {Creates object of class `Capacitor` that describes capacitor.} {
                {-c= -required -help {Capacitance value}}
                {-m= -help {Multiplier value}}
                {-temp= -help {Device temperature}}
                {-tc1= -help {Linear thermal coefficient}}
                {-tc2= -help {Quadratic thermal coefficient}}
                {-ic= -help {Initial condition} }
                {name -help {Name of the device without first-letter designator C}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
            }]
            set cVal [dget $arguments c]
            if {([llength $cVal]>1) && ([@ $cVal 1] eq {-eq})} {
                lappend params [list c [@ $cVal 0] -poseq]
            } else {
                lappend params [list c $cVal -pos]
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {c name np nm}} {
                    lappend params [list $paramName {*}$value]
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
            #  -l - inductance value
            #  -m - multiplier value, optional
            #  -temp - device temperature, optional, optional
            #  -tc1 - linear thermal coefficient, optional
            #  -tc2 - quadratic thermal coefficient, optional
            # Simple inductor:
            # ```
            # LXXXXXXX n+ n- <value> <m=val> <temp=val> <tc1=val> <tc2=val>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::BasicDevices::Inductor new 1 netp netm -l 1e3 -tc1 1 -temp {temp_amb -eq}
            # ```
            # Synopsis: name np nm -l value ?-m value? ?-temp value? ?-tc1 value? ?-tc2 value?
            set arguments [argparse -inline -pfirst -help {Creates object of class `Inductor` that describes inductor} {
                {-l= -required -help {Inductance value}}
                {-m= -help {Multiplier value}}
                {-temp= -help {Device temperature}}
                {-tc1= -help {Linear thermal coefficient}}
                {-tc2= -help {Quadratic thermal coefficient}}
                {name -help {Name of the device without first-letter designator L}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
            }]
            set lVal [dget $arguments l]
            if {([llength $lVal]>1) && ([@ $lVal 1] eq {-eq})} {
                lappend params [list l [@ $lVal 0] -poseq]
            } else {
                lappend params [list l $lVal -pos]
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {l name np nm}} {
                    lappend params [list $paramName {*}$value]
                }
            }
            next l[dget $arguments name] [list [list np [dget $arguments np]] [list nm [dget $arguments nm]]]\
                    $params
        }
    }
    
####  L class 
    # alias for Inductor class
    oo::class create L {
        superclass Inductor
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
            # ::SpiceGenTcl::Common::BasicDevices::SubcircuitInstance new 1 {{plus net1} {minus net2}} rcnet {{r 1} {c cpar -eq}}
            # ```
            ##nagelfar implicitvarcmd {argparse *Creates object of class 'SubcircuitInstance'*} name pins subName params
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
    
####  VSwitch class 
    oo::class create VSwitch {
        superclass ::SpiceGenTcl::Device
        constructor {args} {
            # Creates object of class `VSwitch` that describes voltage controlled switch device.
            #  name - name of the device without first-letter designator S
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  ncp - name of node connected to positive controlling pin
            #  ncm - name of node connected to negative controlling pin
            #  -model - model name
            #  -on/-off - initial state of switch
            # ```
            # SXXXXXXX N+ N- NC+ NC- MODEL <ON> <OFF>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::VSwitch new 1 net1 0 netc 0 -model sw1 -on
            # ```
            # Synopsis: name np nm ncp ncm -model value ?-on|-off?
            set arguments [argparse -inline -pfirst -help {Creates object of class `VSwitch` that describes voltage\
                                                                  controlled switch device} {
                {-model= -required -help {Model name}}
                {-on -forbid {off} -help {Initial on state of switch}}
                {-off -forbid {on} -help {Initial off state of switch}}
                {name -help {Name of the device without first-letter designator}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
                {ncp -help {Name of node connected to positive controlling pin}}
                {ncm -help {Name of node connected to negative controlling pin}}
            }]
            lappend params [list model [dget $arguments model] -posnocheck]
            if {[dexist $arguments on]} {
                lappend params {on -sw}
            } elseif {[dexist $arguments off]} {
                lappend params {off -sw}
            }
            next s[dget $arguments name] [list [list np [dget $arguments np]] [list nm [dget $arguments nm]]\
                                 [list ncp [dget $arguments ncp]] [list ncm [dget $arguments ncm]]] $params
        }
    }

####  VSw class 
    # alias for VSwitch class
    oo::class create VSw {
        superclass VSwitch
    }    
    
####  CSwitch class 
    oo::class create CSwitch {
        superclass ::SpiceGenTcl::Device
        # special positional parameter that is placed before model name
        constructor {args} {
            # Creates object of class `CSwitch` that describes current controlled switch device.
            #  name - name of the device without first-letter designator W
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  -icntrl - source of control current
            #  -model - model name
            #  -on/-off - initial state of switch
            # ```
            # WYYYYYYY N+ N- VNAM MODEL <ON> <OFF>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::CSwitch new 1 net1 0 -icntrl v1 -model sw1 -on
            # ```
            # Synopsis: name np nm -icntrl value -model value ?-on|-off?
            set arguments [argparse -inline -pfirst -help {Creates object of class `CSwitch` that describes current\
                                                                  controlled switch device} {
                {-icntrl= -required -help {Source of control current}}
                {-model= -required -help {Model name}}
                {-on -forbid {off} -help {Initial on state of switch}}
                {-off -forbid {on} -help {Initial off state of switch}}
                {name -help {Name of the device without first-letter designator W}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
            }]
            lappend params [list icntrl [dget $arguments icntrl] -posnocheck]
            lappend params [list model [dget $arguments model] -posnocheck]
            if {[dexist $arguments on]} {
                lappend params {on -sw}
            } elseif {[dexist $arguments off]} {
                lappend params {off -sw}
            }
            next w[dget $arguments name] [list [list np [dget $arguments np]] [list nm [dget $arguments nm]]]\
                    $params
        }
    }

####  W class 
    # alias for CSwitch class
    oo::class create W {
        superclass CSwitch
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
            # ::SpiceGenTcl::Common::BasicDevices::SubcircuitInstanceAuto new $subcktObj 1 {net1 net2} -r 1 -c {cpar -eq}
            # ```
            # Synopsis: subcktObj name nodes ?-paramName {paramValue ?-eq?} ...?
            
            # check that inputs object class is Subcircuit
            if {![info object class $subcktObj "::SpiceGenTcl::Subcircuit"]} {
                set objClass [info object class $subcktObj]
                error "Wrong object class '$objClass' is passed as subcktObj, should be '::SpiceGenTcl::Subcircuit'"
            }
            set subName [$subcktObj configure -name] 
            set pinsNames [dict keys [$subcktObj getPins]]
            # check if number of pins in subcircuit definition matchs the number of supplied nodes
            if {[llength $pinsNames]!=[llength $nodes]} {
                return -code error "Wrong number of nodes '[llength $nodes]' in definition, should be\
                        '[llength $pinsNames]'"
            }
            set pinsList [lmap pinName $pinsNames node $nodes {join [list $pinName $node]}]
            if {![catch {$subcktObj getParams}]} {
                set paramDefList [lmap paramName [dict keys [$subcktObj getParams]] {subst -${paramName}=}]
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

namespace eval ::SpiceGenTcl::Common::Sources {

####  dc sources template class 
    oo::abstract create dc {
        superclass ::SpiceGenTcl::Device
        constructor {type args} {
            if {$type eq {v}} {
                set typeName voltage
            } else {
                set typeName current
            }
            set arguments [argparse -inline -pfirst -help "Creates object of class '[string totitle ${type}dc]' that describes simple\
                    constant $typeName source" {
                {-dc= -required -help {DC value}}
                {name -help {Name of the device without first-letter designator}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
            }]
            set dcVal [dget $arguments dc]
            if {([llength $dcVal]>1) && ([@ $dcVal 1] eq {-eq})} {
                lappend params [list dc [@ $dcVal 0] -poseq]
            } else {
                lappend params [list dc $dcVal -pos]
            }
            next $type[dget $arguments name] [list [list np [dget $arguments np]]\
                                                      [list nm [dget $arguments nm]]] $params
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
            set arguments [argparse -inline -pfirst -help "Creates object of class '[string totitle ${type}ac]' that describes ac\
                    $typeName source" {
                {-dc= -default 0 -help {DC voltage value}}
                {-ac= -required -help {AC voltage value}}
                {-acphase= -help {Phase of AC voltage}}
                {name -help {Name of the device without first-letter designator}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
            }]
            set dcVal [dget $arguments dc]
            if {([llength $dcVal]>1) && ([@ $dcVal 1] eq {-eq})} {
                lappend params [list dc [@ $dcVal 0] -poseq]
            } else {
                lappend params [list dc $dcVal -pos]
            }
            set acVal [dget $arguments ac]
            lappend params {acsw ac -posnocheck}
            if {([llength $acVal]>1) && ([@ $acVal 1] eq {-eq})} {
                lappend params [list ac [@ $acVal 0] -poseq]
            } else {
                lappend params [list ac $acVal -pos]
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {ac dc name np nm}} {
                    if {([llength $value]>1) && ([@ $value 1] eq {-eq})} {
                        lappend params [list $paramName [@ $value 0] -poseq]
                    } else {
                        lappend params [list $paramName $value -pos]
                    }
                }
            }
            next $type[dget $arguments name] [list [list np [dget $arguments np]]\
                                                      [list nm [dget $arguments nm]]] $params
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
                {-dc= -help {DC value}}
                {-ac= -help {AC value}}
                {-acphase= -require ac -help {AC phase}}
                {-voff|ioff|low= -required -help {Low value}}
                {-von|ion|high= -required -help {High value}}
                {-td= -required -help {Delay time}}
                {-tr= -required -help {Rise time}}
                {-tf= -required -help {Fall time}}
                {-pw|ton= -required -help {Width of pulse}}
                {-per|tper= -required -help {Period time}}
                {name -help {Name of the device without first-letter designator}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
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
                lappend params {acsw ac -posnocheck}
                set acVal [dget $arguments ac]
                if {([llength $acVal]>1) && ([@ $acVal 1] eq {-eq})} {
                    lappend params [list ac [@ $acVal 0] -poseq]
                } else {
                    lappend params [list ac $acVal -pos]
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
            set paramsOrder {low high td tr tf ton tper}
            lappend params {model pulse -posnocheck}
            my ParamsProcess $paramsOrder $arguments params
            next $type[dget $arguments name] [list [list np [dget $arguments np]]\
                                                      [list nm [dget $arguments nm]]] $params
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
                {-dc= -help {DC value}}
                {-ac= -help {AC value}}
                {-acphase= -require ac -help {phase of AC signal}}
                {-i0|voffset|ioffset|v0= -required -help {DC shift value}}
                {-ia|vamp|iamp|va= -required -help {Amplitude value}}
                {-freq= -required -help {Frequency of sinusoidal signal}}
                {-td= -help {Time delay}}
                {-theta= -require {td} -help {Damping factor}}
                {-phi|phase= -require {td theta} -help {Phase of signal}}
                {name -help {Name of the device without first-letter designator}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
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
                lappend params {acsw ac -posnocheck}
                set acVal [dget $arguments ac]
                if {([llength $acVal]>1) && ([@ $acVal 1] eq {-eq})} {
                    lappend params [list ac [@ $acVal 0] -poseq]
                } else {
                    lappend params [list ac $acVal -pos]
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
            set paramsOrder {v0 va freq td theta phase}
            lappend params {model sin -posnocheck}
            my ParamsProcess $paramsOrder $arguments params
            next $type[dget $arguments name] [list [list np [dget $arguments np]]\
                                                      [list nm [dget $arguments nm]]] $params
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
                {-dc= -help {DC value}}
                {-ac= -help {AC value}}
                {-acphase= -require ac -help {}}
                {-i1|v1= -required -help {Initial value}}
                {-i2|v2= -required -help {Pulsed value}}
                {-td1= -required -help {Rise delay time}}
                {-tau1= -required -help {Rise time constant}}
                {-td2= -required -help {Fall delay time}}
                {-tau2= -required -help {Fall time constant}}
                {name -help {Name of the device without first-letter designator}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
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
                lappend params {acsw ac -posnocheck}
                set acVal [dget $arguments ac]
                if {([llength $acVal]>1) && ([@ $acVal 1] eq {-eq})} {
                    lappend params [list ac [@ $acVal 0] -poseq]
                } else {
                    lappend params [list ac $acVal -pos]
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
            set paramsOrder {v1 v2 td1 tau1 td2 tau2}
            lappend params {model exp -posnocheck}
            my ParamsProcess $paramsOrder $arguments params
            next $type[dget $arguments name] [list [list np [dget $arguments np]]\
                                                      [list nm [dget $arguments nm]]] $params
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
                {-dc= -help {DC value}}
                {-ac= -help {AC value}}
                {-acphase= -require ac -help {Phase of AC signal}}
                {-seq= -required -help {Sequence of pwl points in form {t0 i0 t1 i1 t2 i2 t3 i3 ...}}}
                {name -help {Name of the device without first-letter designator}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
            }]
            set start 0
            if {[dexist $arguments dc]} {
                lappend paramList {dc -sw}
                set dcVal [dget $arguments dc]
                if {([llength $dcVal]>1) && ([@ $dcVal 1] eq {-eq})} {
                    lappend paramList [list dcval [@ $dcVal 0] -poseq]
                } else {
                    lappend paramList [list dcval $dcVal -pos]
                }
                incr start 2
            }
            if {[dexist $arguments ac]} {
                lappend paramList {acsw ac -posnocheck}
                set acVal [dget $arguments ac]
                if {([llength $acVal]>1) && ([@ $acVal 1] eq {-eq})} {
                    lappend paramList [list ac [@ $acVal 0] -poseq]
                } else {
                    lappend paramList [list ac $acVal -pos]
                }
                if {[dexist $arguments acphase]} {
                    set acphaseVal [dget $arguments acphase]
                    if {([llength $acphaseVal]>1) && ([@ $acphaseVal 1] eq {-eq})} {
                        lappend paramList [list acphase [@ $acphaseVal 0] -poseq]
                    } else {
                        lappend paramList [list acphase $acphaseVal -pos]
                    }
                    incr start 1
                }
                incr start 2
            }
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
            set paramList [linsert $paramList $start {model pwl -posnocheck}]
            next $type[dget $arguments name] [list [list np [dget $arguments np]]\
                                                      [list nm [dget $arguments nm]]] $paramList
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
                {name -help {Name of the device without first-letter designator}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
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
                lappend params {acsw ac -posnocheck}
                set acVal [dget $arguments ac]
                if {([llength $acVal]>1) && ([@ $acVal 1] eq {-eq})} {
                    lappend params [list ac [@ $acVal 0] -poseq]
                } else {
                    lappend params [list ac $acVal -pos]
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
            set paramsOrder {v0 va fc mdi fs}
            lappend params {model sffm -posnocheck}
            my ParamsProcess $paramsOrder $arguments params
            next $type[dget $arguments name] [list [list np [dget $arguments np]]\
                                                      [list nm [dget $arguments nm]]] $params
        }
    }      
    
####  Vdc class 
    oo::class create Vdc {
        superclass ::SpiceGenTcl::Common::Sources::dc
        constructor {args} {
            # Creates object of class `Vdc` that describes simple constant voltage source.
            #  name - name of the device without first-letter designator V
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  -dc - DC voltage value
            # ```
            # VYYYYYYY n+ n- <<DC> DC/TRAN VALUE>>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Sources::Vdc new 1 netp netm -dc 10
            # ```
            # Synopsis: name np nm -dc value
            next v {*}$args
        }
    }

####  Vac class 
    oo::class create Vac {
        superclass ::SpiceGenTcl::Common::Sources::ac
        constructor {args} {
            # Creates object of class `Vac` that describes ac voltage source.
            #  name - name of the device without first-letter designator V
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  -ac - AC voltage value
            #  -acphase - phase of AC voltage
            # ```
            # VYYYYYYY n+ n- <AC<ACMAG<ACPHASE>>>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Sources::Vac new 1 netp netm -ac 10 -acphase 45
            # ```
            # Synopsis: name np nm -ac value ?-acphase value?
            next v {*}$args

        }
    }
    
####  Vpulse class 
    oo::class create Vpulse {
        superclass ::SpiceGenTcl::Common::Sources::pulse
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
            #  -ton - width of pulse, alias -pw
            #  -tper - period time, alias -per
            #  -dc - DC value, optional
            #  -ac - AC value, optional
            #  -acphase - phase of AC signal, optional, requires -ac
            # ```
            # VYYYYYYY n+ n- PULSE(V1 V2 TD TR TF PW PER)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Sources::Vpulse new 1 net1 net2 -low 0 -high 1 -td {td -eq} -tr 1e-9 -tf 1e-9 -pw 10e-6 -per 20e-6
            # ```
            # Synopsis: name np nm -voff|ioff|low value -von|ion|high value -td value -tr value -tf value 
            #   -pw|ton value ?-dc value? ?-ac value ?-acphase value??
            next v {*}$args
        }
    }  
    
####  Vsin class 
    oo::class create Vsin {
        superclass ::SpiceGenTcl::Common::Sources::sin
        constructor {args} {
            # Creates object of class `Vsin` that describes sinusoidal voltage source.
            #  name - name of the device without first-letter designator V
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  -v0 - DC shift value, aliases: -voffset, -i0, -ioffset
            #  -va - amplitude value, aliases: -vamp, -ia, -iamp
            #  -freq - frequency of sinusoidal signal
            #  -td - time delay, optional
            #  -theta - damping factor, optional, require -td
            #  -phase - phase of signal, optional, require -td and -phase, alias -phi
            #  -dc - DC value, optional
            #  -ac - AC value, optional
            #  -acphase - phase of AC signal, optional, requires -ac
            # ```
            # VYYYYYYY n+ n- SIN(VO VA FREQ TD THETA PHASE)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Sources::Vsin new 1 net1 net2 -v0 0 -va 2 -freq {freq -eq} -td 1e-6 -theta {theta -eq}
            # ```
            # Synopsis: name np nm -i0|voffset|ioffset|v0 value -ia|vamp|iamp|va value -freq value
            #   ?-td value ?-theta value ?-phi|phase value???
            next v {*}$args
        }
    }
    
####  Vexp class 
    oo::class create Vexp {
        superclass ::SpiceGenTcl::Common::Sources::exp
        constructor {args} {
            # Creates object of class `Vexp` that describes exponential voltage source.
            #  name - name of the device without first-letter designator V
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  -v1 - initial value
            #  -v2 - pulsed value
            #  -td1 - rise delay time
            #  -tau1 - rise time constant
            #  -td2 - fall delay time
            #  -tau2 - fall time constant
            #  -dc - DC value, optional
            #  -ac - AC value, optional
            #  -acphase - phase of AC signal, optional, requires -ac
            # ```
            # VYYYYYYY n+ n- EXP(V1 V2 TD1 TAU1 TD2 TAU2)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Sources::Vexp new 1 net1 net2 -v1 0 -v2 1 -td1 1e-9 -tau1 1e-9 -td2 {td2 -eq} -tau2 10e-6
            # ```
            # Synopsis: name np nm -i1|v1 value -i2|v2 value -td1 value -tau1 value -td2 value -tau2 value
            #   ?-phi|phase value???
            next v {*}$args
        }
    }
    
####  Vpwl class 
    oo::class create Vpwl {
        superclass ::SpiceGenTcl::Common::Sources::pwl
        constructor {args} {
            # Creates object of class `Vpwl` that describes piece-wise voltage source.
            #  name - name of the device without first-letter designator V
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  -seq - sequence of pwl points in form {t0 v0 t1 v1 t2 v2 t3 v3 ...}
            #  -dc - DC value, optional
            #  -ac - AC value, optional
            #  -acphase - phase of AC signal, optional, requires -ac
            # ```
            # VYYYYYYY n+ n- PWL (T1 V1 <T2 V2 T3 V3 T4 V4 ...>)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Sources::Vpwl new 1 np nm -seq {0 0 {t1 -eq} 1 2 2 3 3 4 4}
            # ```
            # Synopsis: name np nm -seq list ?-phase|phi value???
            next v {*}$args
        }
    }    
    
####  Vsffm class 
    oo::class create Vsffm {
        superclass ::SpiceGenTcl::Common::Sources::sffm
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
            #  -dc - DC value, optional
            #  -ac - AC value, optional
            #  -acphase - phase of AC signal, optional, requires -ac
            # ```
            # VYYYYYYY n+ n- SFFM(VO VA FC MDI FS)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Sources::Vsin new 1 net1 net2 -v0 0 -va 1 -fc {freq -eq} -mdi 0 -fs 1e3
            # ```
            # Synopsis: name np nm -i0|voff|ioff|v0 value -ia|vamp|iamp|va value -fc|fcar value -mdi value 
            #   -fs|fsig ?-phi|phase value???
            next v {*}$args
        }
    }
       
    
####  Idc class 
    oo::class create Idc {
        superclass ::SpiceGenTcl::Common::Sources::dc
        constructor {args} {
            # Creates object of class `Idc` that describes simple constant current source.
            #  name - name of the device without first-letter designator I
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  -dc - DC voltage value
            # ```
            # IYYYYYYY n+ n- <<DC> DC/TRAN VALUE>>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Sources::Idc new 1 netp netm -dc 10
            # ```
            # Synopsis: name np nm -dc value
            next i {*}$args
        }
    }

####  Iac class 
    oo::class create Iac {
        superclass ::SpiceGenTcl::Common::Sources::ac
        constructor {args} {
            # Creates object of class `Iac` that describes ac current source.
            #  name - name of the device without first-letter designator I
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  -dc - AC current value
            #  -acphase - phase of AC current
            # ```
            # IYYYYYYY n+ n- <AC<ACMAG<ACPHASE>>>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Sources::Iac new 1 netp netm -ac 10 -acphase 45
            # Synopsis: name np nm -ac value ?-acphase value?
            next i {*}$args
        }
    }
    

####  Ipulse class 
    oo::class create Ipulse {
        superclass ::SpiceGenTcl::Common::Sources::pulse
        constructor {args} {
            # Creates object of class `Ipulse` that describes pulse current source.
            #  name - name of the device without first-letter designator I
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  -low - low value, aliases: -voff, -ioff
            #  -high - high value, aliases: -von, ion
            #  -td - time delay
            #  -tr - rise time
            #  -tf - fall time
            #  -pw - width of pulse, alias -ton
            #  -per - period time, alias -tper
            #  -dc - DC value, optional
            #  -ac - AC value, optional
            #  -acphase - phase of AC signal, optional, requires -ac
            # ```
            # IYYYYYYY n+ n- PULSE(V1 V2 TD TR TF PW PER)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Sources::Ipulse new 1 net1 net2 -low 0 -high 1 -td {td -eq} -tr 1e-9 -tf 1e-9 -pw 10e-6 -per 20e-6
            # ```
            # Synopsis: name np nm -voff|ioff|low value -von|ion|high value -td value -tr value -tf value
            #   -pw|ton value ?-phase|phi value???
            next i {*}$args
        }
    }
    
####  Isin class 
    oo::class create Isin {
        superclass ::SpiceGenTcl::Common::Sources::sin
        constructor {args} {
            # Creates object of class `Isin` that describes sinusoidal current source.
            #  name - name of the device without first-letter designator I
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  -i0 - DC shift value, aliases: -voffset, -v0, -ioffset
            #  -ia - amplitude value, aliases: -vamp, -va, -iamp
            #  -freq - frequency of sinusoidal signal
            #  -td - time delay, optional
            #  -theta - damping factor, optional, require -td
            #  -phase - phase of signal, optional, require -td and -phase, alias -phi
            #  -dc - DC value, optional
            #  -ac - AC value, optional
            #  -acphase - phase of AC signal, optional, requires -ac
            # ```
            # IYYYYYYY n+ n- SIN(VO VA FREQ TD THETA PHASE)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Sources::Isin new 1 net1 net2 -i0 0 -ia 2 -freq {freq -eq} -td 1e-6 -theta {theta -eq}
            # ```
            # Synopsis: name np nm -i0|ioffset value -ia|iamp value -freq value ?-td value ?-theta value
            #   ?-phase|phi value???
            next i {*}$args
        }
    }
    
####  Iexp class 
    oo::class create Iexp {
        superclass ::SpiceGenTcl::Common::Sources::exp
        constructor {args} {
            # Creates object of class `Iexp` that describes exponential current source.
            #  name - name of the device without first-letter designator I
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  -i1 - initial value
            #  -i2 - pulsed value
            #  -td1 - rise delay time
            #  -tau1 - rise time constant
            #  -td2 - fall delay time
            #  -tau2 - fall time constant
            #  -dc - DC value, optional
            #  -ac - AC value, optional
            #  -acphase - phase of AC signal, optional, requires -ac
            # ```
            # IYYYYYYY n+ n- EXP(V1 V2 TD1 TAU1 TD2 TAU2)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Sources::Iexp new 1 net1 net2 -i1 0 -i2 1 -td1 1e-9 -tau1 1e-9 -td2 {td2 -eq} -tau2 10e-6
            # ```
            # Synopsis: name np nm -i1 value -i2 value -td1 value -tau1 value -td2 value -tau2 value
            #   ?-phase|phi value???
            next i {*}$args
        }
    }

####  Ipwl class 
    oo::class create Ipwl {
        superclass ::SpiceGenTcl::Common::Sources::pwl
        constructor {args} {
            # Creates object of class `Ipwl` that describes piece-wise current source.
            #  name - name of the device without first-letter designator I
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  -seq - sequence of pwl points in form {t0 i0 t1 i1 t2 i2 t3 i3 ...}
            #  -dc - DC value, optional
            #  -ac - AC value, optional
            #  -acphase - phase of AC signal, optional, requires -ac
            # ```
            # IYYYYYYY n+ n- PWL (T1 I1 <T2 I2 T3 I3 T4 I4 ...>)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Sources::Ipwl new 1 np nm -seq {0 0 {t1 -eq} 1 2 2 3 3 4 4}
            # ```
            # Synopsis: name np nm -seq list ?-phase|phi value???
            next i {*}$args
        }
    }   
    
####  Isffm class 
    oo::class create Isffm {
        superclass ::SpiceGenTcl::Common::Sources::sffm
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
            #  -dc - DC value, optional
            #  -ac - AC value, optional
            #  -acphase - phase of AC signal, optional, requires -ac
            # ```
            # IYYYYYYY n+ n- SFFM(VO VA FC MDI FS)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Sources::Isin new 1 net1 net2 -i0 0 -ia 1 -fc {freq -eq} -mdi 0 -fs 1e3
            # ```
            # Synopsis: name np nm -i0|voff|ioff|v0 value -ia|vamp|iamp|va value -fc|fcar value -mdi value 
            #   -fs|fsig value ?-phi|phase value???
            next i {*}$args
        }
    }

####  Vccs class 
    oo::class create Vccs {
        superclass ::SpiceGenTcl::Device
        constructor {args} {
            # Creates object of class `Vccs` that describes linear voltage-controlled current source.
            #  name - name of the device without first-letter designator G
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  ncp - name of node connected to positive controlling pin
            #  ncm - name of node connected to negative controlling pin
            #  -trcond - transconductance
            #  -m - multiplier factor, optional
            # ```
            # GXXXXXXX N+ N- NC+ NC- VALUE <m=val>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Sources::Vccs new 1 net1 0 netc 0 -trcond 10 -m 1
            # ```
            # Synopsis: name np nm ncp ncm -trcond value ?-m value?
            set arguments [argparse -inline -pfirst -help {Creates object of class `Vccs` that describes linear\
                                                                  voltage-controlled current source} {
                {-trcond -required -help Transconductance}
                {-m= -help {Multiplier factor}}
                {name -help {Name of the device without first-letter designator G}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
                {ncp -help {Name of node connected to positive controlling pin}}
                {ncm -help {Name of node connected to negative controlling pin}}
            }]
            set trcondVal [dget $arguments trcond]
            if {([llength $trcondVal]>1) && ([@ $trcondVal 1] eq {-eq})} {
                lappend params [list trcond [@ $trcondVal 0] -poseq]
            } else {
                lappend params [list trcond $trcondVal -pos]
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {trcond name np nm ncp ncm}} {
                    lappend params [list $paramName {*}$value]
                }
            }
            next g[dget $arguments name] [list [list np [dget $arguments np]] [list nm [dget $arguments nm]]\
                                                  [list ncp [dget $arguments ncp]]\
                                                  [list ncm [dget $arguments ncm]]] $params
        }
    }

####  G class 
    # alias for Vccs class
    oo::class create G {
        superclass Vccs
    }    

####  Vcvs class 
    oo::class create Vcvs {
        superclass ::SpiceGenTcl::Device
        constructor {args} {
            # Creates object of class `Vcvs` that describes linear voltage-controlled current source.
            #  name - name of the device without first-letter designator E
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  ncp - name of node connected to positive controlling pin
            #  ncm - name of node connected to negative controlling pin
            #  -gain - voltage gain
            # ```
            # EXXXXXXX N+ N- NC+ NC- VALUE
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Sources::Vcvs new 1 net1 0 netc 0 -gain 10
            # ```
            # Synopsis: name np nm ncp ncm -gain value
            set arguments [argparse -inline -pfirst -help {Creates object of class `Vcvs` that describes linear\
                                                                  voltage-controlled current source} {
                {-gain -required -help {Voltage gain}}
                {name -help {Name of the device without first-letter designator E}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
                {ncp -help {Name of node connected to positive controlling pin}}
                {ncm -help {Name of node connected to negative controlling pin}}
            }]
            set gainVal [dget $arguments gain]
            if {([llength $gainVal]>1) && ([@ $gainVal 1] eq {-eq})} {
                lappend params [list vgain [@ $gainVal 0] -poseq]
            } else {
                lappend params [list vgain $gainVal -pos]
            }
            next e[dget $arguments name] [list [list np [dget $arguments np]] [list nm [dget $arguments nm]]\
                                                  [list ncp [dget $arguments ncp]]\
                                                  [list ncm [dget $arguments ncm]]] $params
        }
    }

####  E class 
    # alias for Vcvs class
    oo::class create E {
        superclass Vcvs
    } 
    
####  Cccs class 
    oo::class create Cccs {
        superclass ::SpiceGenTcl::Device
        constructor {args} {
            # Creates object of class `Cccs` that describes linear current-controlled current source. 
            #  name - name of the device without first-letter designator F
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  -consrc - name of controlling source
            #  -gain - current gain 
            #  -m - parallel source multiplicator
            # ```
            # FXXXXXXX N+ N- VNAM VALUE <m=val>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Sources::Cccs new 1 net1 0 netc 0 -consrc vc -gain 10 -m 1
            # ```
            # Synopsis: name np nm -consrc value -gain value ?-m value?
            set arguments [argparse -inline -pfirst -help {Creates object of class `Cccs` that describes linear\
                                                                  current-controlled current source} {
                {-consrc -required -help {Name of controlling source}}
                {-gain -required -help {Current gain}}
                {-m= -help {Parallel source multiplicator}}
                {name -help {Name of the device without first-letter designator F}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
            }]
            set consrcVal [dget $arguments consrc]
            lappend params [list consrc $consrcVal -posnocheck]
            set gainVal [dget $arguments gain]
            if {([llength $gainVal]>1) && ([@ $gainVal 1] eq {-eq})} {
                lappend params [list igain [@ $gainVal 0] -poseq]
            } else {
                lappend params [list igain $gainVal -pos]
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {consrc gain name np nm}} {
                    lappend params [list $paramName {*}$value]
                }
            }
            next f[dget $arguments name] [list [list np [dget $arguments np]] [list nm [dget $arguments nm]]]\
                $params
        } 
    }

####  F class 
    # alias for Cccs class
    oo::class create F {
        superclass Cccs
    } 
        
####  Ccvs class 
    oo::class create Ccvs {
        superclass ::SpiceGenTcl::Device
        constructor {args} {
            # Creates object of class `Ccvs` that describes linear current-controlled current source.
            #  name - name of the device without first-letter designator H
            #  np - name of node connected to positive pin
            #  nm - name of node connected to negative pin
            #  -consrc - name of controlling source
            #  -transr - transresistance 
            # ```
            # HXXXXXXX N+ N- VNAM VALUE
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Sources::Ccvs new 1 net1 0 -consrc vc -transr {tres -eq}
            # ```
            # Synopsis: name np nm -consrc value -transr value
            set arguments [argparse -inline -pfirst -help {Creates object of class `Ccvs` that describes linear\
                                                                  current-controlled current source} {
                {-consrc -required -help {Name of controlling source}}
                {-transr -required -help Transresistance}
                {name -help {Name of the device without first-letter designator H}}
                {np -help {Name of node connected to positive pin}}
                {nm -help {Name of node connected to negative pin}}
            }]
            set consrcVal [dget $arguments consrc]
            lappend params [list consrc $consrcVal -posnocheck]
            set transrVal [dget $arguments transr]
            if {([llength $transrVal]>1) && ([@ $transrVal 1] eq {-eq})} {
                lappend params [list transr [@ $transrVal 0] -poseq]
            } else {
                lappend params [list transr $transrVal -pos]
            }
            next h[dget $arguments name] [list [list np [dget $arguments np]] [list nm [dget $arguments nm]]]\
                    $params
        }
    }

####  H class 
    # alias for Ccvs class
    oo::class create H {
        superclass Ccvs
    } 
    
}



