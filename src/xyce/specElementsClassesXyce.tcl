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
        namespace export Resistor R Capacitor C Inductor L \
                SubcircuitInstance X SubcircuitInstanceAuto XAuto \
                VSwitch VSw CSwitch W GenSwitch GenS
    }
    namespace eval Xyce::Sources {
        namespace export Vdc Idc Vac Iac Vpulse Ipulse Vsin Isin Vexp Iexp Vpwl Ipwl Vsffm Isffm Vccs G \
                Vcvs E Cccs F Ccvs H BehaviouralSource B
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
        mixin ::SpiceGenTcl::KeyArgsBuilder
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
            # R<name> <(+) node> <(-) node> <value> [device parameters]
            # ```
            # Example of class initialization as a simple resistor:
            # ```
            # ::SpiceGenTcl::Xyce::BasicDevices::Resistor new 1 netp netm -r 1e3 -tc1 1 -temp {temp_amb -eq}
            # ```
            # Behavioral resistor:
            # ```
            # R<name> <(+) node> <(-) node> R ={=ession} [device parameters]
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::BasicDevices::Resistor new 1 netp netm -r "V(a)+V(b)+pow(V(c),2)" -beh -tc1 1
            # ```
            # Resistor with model card:
            # ```
            # R<name> <(+) node> <(-) node> <model name> [value] [device parameters]
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::BasicDevices::Resistor new 1 netp netm -model resm -l 1e-6 -w 10e-6
            # ```
            set arguments [argparse -inline {
                -r=
                {-beh -forbid {model} -require {r}}
                {-model= -forbid {beh}}
                -m=
                -temp=
                -tc1=
                -tc2=
                -tce=
                {-l= -require {model}}
                {-w= -require {model}}
            }]
            if {[dexist $arguments model]} {
                lappend params "model [dget $arguments model] -posnocheck"
            }
            if {[dexist $arguments r]} {
                set rVal [dget $arguments r]
                if {[dexist $arguments beh]} {
                    lappend params "r $rVal -eq"
                } elseif {([llength $rVal]>1) && ([@ $rVal 1]=="-eq")} {
                    lappend params "r [@ $rVal 0] -poseq"
                } else {
                    lappend params "r $rVal -pos"
                }
            } elseif {[dexist $arguments model]==0} {
                return -code error "Resistor value must be specified with '-r value'"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {r beh model}} {
                    lappend params "$paramName $value"
                }
            }
            next r$name [list "np $npNode" "nm $nmNode"] $params
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
        mixin ::SpiceGenTcl::KeyArgsBuilder
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
            # C<device name> <(+) node> <(-) node> <value> [device parameters]
            # ```
            # Example of class initialization as a simple capacitor:
            # ```
            # ::SpiceGenTcl::Xyce::BasicDevices::Capacitor new 1 netp netm 1e-6 -tc1 1 -temp {temp -eq}
            # ```
            # Behavioral capacitor with C =ession:
            # ```
            # C<device name> <(+) node> <(-) node> C={=ession} [device parameters]
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::BasicDevices::Capacitor new 1 netp netm -c "V(a)+V(b)+pow(V(c),2)" -beh -tc1 1
            # ```
            # Behavioral capacitor with Q =ession:
            # ```
            # C<device name> <(+) node> <(-) node> Q={=ession} [device parameters]
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::BasicDevices::Capacitor new 1 netp netm -q "V(a)+V(b)+pow(V(c),2)" -beh -tc1 1
            # ```
            # Capacitor with model card:
            # ```
            # C<device name> <(+) node> <(-) node> <model name> [value] [device parameters]
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::BasicDevices::Capacitor new 1 netp netm -model capm -l 1e-6 -w 10e-6
            # ```
            set arguments [argparse -inline {
                {-c= -forbid {q}}
                {-q= -require {beh} -forbid {c model}}
                {-beh -forbid {model}}
                {-model= -forbid {beh}}
                -m=
                -temp=
                -tc1=
                -tc2=
                -ic=
                -age=
                -d=
                {-l= -require {model}}
                {-w= -require {model}}
            }]
            if {[dexist $arguments model]} {
                lappend params "model [dget $arguments model] -posnocheck"
            }
            if {[dexist $arguments c]} {
                set cVal [dget $arguments c]
                if {[dexist $arguments beh]} {
                    lappend params "c $cVal -eq"
                } elseif {([llength $cVal]>1) && ([@ $cVal 1]=="-eq")} {
                    lappend params "c [@ $cVal 0] -poseq"
                } else {
                    lappend params "c $cVal -pos"
                }
            } elseif {([dexist $arguments model]==0) && ([dexist $arguments q]==0)} {
                return -code error "Capacitor value must be specified with '-c value'"
            }
            if {[dexist $arguments q]} {
                set qVal [dget $arguments q]
                lappend params "q $qVal -eq"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {c q beh model}} {
                    lappend params "$paramName $value"
                }
            }
            next c$name [list "np $npNode" "nm $nmNode"] $params
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
        mixin ::SpiceGenTcl::KeyArgsBuilder
        constructor {name npNode nmNode args} {
            # Creates object of class `Inductor` that describes inductor. 
            #  name - name of the device without first-letter designator L
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  args - keyword instance parameters
            # Inductor type could be specified with additional switch `-model modelName`
            # if we want to simulate inductor with model card.
            # Simple inductor:
            # ```
            # L<name> <(+) node> <(-) node> <value> [device parameters]
            # ```
            # Example of class initialization as a simple inductor:
            # ```
            # ::SpiceGenTcl::Xyce::BasicDevices::Inductor new 1 netp netm -l 1e-6 -tc1 1 -temp {temp -eq}
            # ```
            # Behavioral inductor:
            # ```
            # L<name> <(+) node> <(-) node> [model] <value> [device parameters]
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::BasicDevices::Inductor new 1 netp netm -l "V(a)+V(b)+pow(V(c),2)" -beh -tc1 1
            # ```
            # Inductor with model card:
            # ```
            # L<name> <(+) node> <(-) node> [model] <value> [device parameters]
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::BasicDevices::Inductor new 1 netp netm -l 1e-6 -model indm
            # ```
            set arguments [argparse -inline {
                {-l= -required}
                -model=
                -m=
                -temp=
                -tc1=
                -tc2=
                -ic=
            }]
            if {[dexist $arguments model]} {
                lappend params "model [dget $arguments model] -posnocheck"
            }
            set lVal [dget $arguments l]
            if {([llength $lVal]>1) && ([@ $lVal 1]=="-eq")} {
                lappend params "l [@ $lVal 0] -poseq"
            } else {
                lappend params "l $lVal -pos"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {l model}} {
                    lappend params "$paramName $value"
                }
            }
            next l$name [list "np $npNode" "nm $nmNode"] $params
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
        constructor {name npNode nmNode args} {
            # Creates object of class `GenSwitch` that describes generic switch device.
            #  name - name of the device without first-letter designator S
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -model - model name
            #  -control - control equation
            #  -on/-off - initial state of switch
            # ```
            # S<name> <(+) switch node> <(-) switch node> <model name> [ON] [OFF] <control = =ession>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::BasicDevices::GenSwitch new 1 net1 0 -model sw1 -control {I(VMON)}
            # ```
            set arguments [argparse -inline {
                {-model= -required}
                {-control= -required}
                {-on -forbid {off}}
                {-off -forbid {on}}
            }]
            lappend params "model [dget $arguments model] -posnocheck"
            if {[dexist $arguments on]} {
                lappend params {on -sw}
            } elseif {[dexist $arguments off]} {
                lappend params {off -sw}
            }
            lappend params "control [dget $arguments control] -eq"
            next s$name [list "np $npNode" "nm $nmNode"] $params
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
        constructor {name pins subName params} {
            # Creates object of class `SubcircuitInstance` that describes subcircuit instance.
            #  name - name of the device without first-letter designator X
            #  pins - list of pins {{pinName nodeName} {pinName nodeName} ...}
            #  subName - name of subcircuit definition
            #  params - {{paramName paramValue ?-eq?} {paramName paramValue ?-eq?}}
            # ```
            # X<name> [nodes] <subcircuit name> [PARAMS: [<name> = <value>] ...]
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::BasicDevices::SubcircuitInstance new 1 {{plus net1} {minus net2}} rcnet {{r 1} {c cpar -eq}}
            # ```
            set params [linsert $params 0 "model $subName -posnocheck"]
            set params [linsert $params 1 "params PARAMS: -posnocheck"]
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
            # X<name> [nodes] <subcircuit name> [PARAMS: [<name> = <value>] ...]
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::BasicDevices::SubcircuitInstanceAuto new $subcktObj 1 {net1 net2} -r 1 -c {cpar -eq}
            # ```
            
            # check that inputs object class is Subcircuit
            if {[info object class $subcktObj "::SpiceGenTcl::Subcircuit"]!=1} {
                set objClass [info object class $subcktObj]
                return -code error "Wrong object class '$objClass' is passed as subcktObj, should be\
                        '::SpiceGenTcl::Subcircuit'"
            }
            # get name of subcircuit
            set subName [$subcktObj configure -Name] 
            # get pins names of subcircuit
            set pinsNames [dict keys [$subcktObj getPins]]
            # check if number of pins in subcircuit definition matchs the number of supplied nodes
            if {[llength $pinsNames]!=[llength $nodes]} {
                return -code error "Wrong number of nodes '[llength $nodes]' in definition, should be\
                        '[llength $pinsNames]'"
            }
            # create list of pins and connected nodes
            foreach pinName $pinsNames node $nodes {
                lappend pinsList "$pinName $node"
            }
            # get parameters names of subcircuit
            set paramsNames [dict keys [$subcktObj getParams]]
            foreach paramName $paramsNames {
                lappend paramDefList "-${paramName}="
            }
            if {[info exists paramDefList]} {
                # create definition for argparse module for passing parameters as optional arguments
                set arguments [argparse -inline "
                    [join $paramDefList \n]
                "]
                # create list of parameters and values from which were supplied by args
                dict for {paramName value} $arguments {
                    lappend params "$paramName $value"
                }
            } else {
                set params ""
            }
            set params [linsert $params 0 "model $subName -posnocheck"]
            if {[info exists paramDefList]} {
                set params [linsert $params 1 "params PARAMS: -posnocheck"]
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
        mixin ::SpiceGenTcl::KeyArgsBuilder
        constructor {name npNode nmNode args} {
            # Creates object of class `BehaviouralSource` that describes behavioural source.
            #  name - name of the device without first-letter designator R
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -i - current =ession
            #  -v - voltage =ession
            #  -smoothbsrc - enables the smooth transitions, optional, require -v
            #  -rcconst -  rc constant of the RC network, optional, require -v
            # ```
            # B<name> <(+) node> <(-) node> V={=ession} [device parameters]
            # B<name> <(+) node> <(-) node> I={=ession}
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::Sources::BehaviouralSource new 1 netp netm -v "V(a)+V(b)+pow(V(c),2)"
            # ```
            set arguments [argparse -inline {
                {-i= -forbid {v}}
                {-v= -forbid {i}}
                {-smoothbsrc -require {v}}
                {-rcconst= -require {v}}
            }]
            if {[dexist $arguments i]} {
                lappend params "i [dget $arguments i] -eq"
            } elseif {[dexist $arguments v]} {
                lappend params "v [dget $arguments v] -eq"
            } else {
                return -code error "Equation must be specified as argument to -i or -v"
            }
            if {[dexist $arguments smoothbsrc]} {
                lappend params "smoothbsrc 1"
            }
            if {[dexist $arguments rcconst]} {
                lappend params "rcconst [dget $arguments rcconst]"
            }
            next b$name [list "np $npNode" "nm $nmNode"] $params
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
            #  -custparams - key that collects all arguments at the end of device definition, to provide an ability
            #  to add custom parameters in form `-custparams param1 param1Val param2 {param2eq -eq} param3 param3Val ...`
            #  Must be specified after all others options. Optional.
            # ```
            # D<name> <(+) node> <(-) node> <model name> [device parameters]
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::SemiconductorDevices::Diode new 1 netp netm -model diomod -area 1e-6
            # ```
            set arguments [argparse -inline {
                {-model= -required}
                -area=
                -pj=
                -ic=
                -m=
                -temp=
                {-custparams -catchall}
            }]
            lappend params "model [dget $arguments model] -posnocheck"
            if {[dexist $arguments area]} {
                set areaVal [dget $arguments area]
                if {([llength $areaVal]>1) && ([@ $areaVal 1]=="-eq")} {
                    lappend params "area [@ $areaVal 0] -poseq"
                } else {
                    lappend params "area $areaVal -pos"
                }
            }
            if {[dexist $arguments pj]} {
                set pjVal [dget $arguments pj]
                if {([llength $pjVal]>1) && ([@ $pjVal 1]=="-eq")} {
                    lappend params "pj [@ $pjVal 0] -poseq"
                } else {
                    lappend params "pj $pjVal -pos"
                }
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {model custparams area pj}} {
                    lappend params "$paramName $value"
                }
            }
            if {[dget $arguments custparams]!=""} {
                if {[llength [dget $arguments custparams]]%2!=0} {
                    return -code error "Custom parameters list must be even length"
                }
                set custParamDict [dcreate {*}[dget $arguments custparams]]
                dict for {paramName value} $custParamDict {
                    lappend params "$paramName $value"
                }
            }
            next d$name [list "np $npNode" "nm $nmNode"] $params
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
        constructor {name ncNode nbNode neNode args} {
            # Creates object of class `Bjt` that describes semiconductor bipolar junction transistor device.
            #  name - name of the device without first-letter designator Q
            #  ncNode - name of node connected to collector pin
            #  nbNode - name of node connected to base pin
            #  neNode - name of node connected to emitter pin
            #  -model - name of the model
            #  -area - scale factor, optional
            #  -m - multiplier of area and perimeter, optional
            #  -temp - device temperature, optional
            #  -ic1 - initial conditions for vbe, optional
            #  -ic2 - initial conditions for vce, optional
            #  -ns - name of node connected to substrate pin, optional
            #  -tj - name of node connected to thermal pin, optional, requires -ns 
            # ```
            # QXXXXXXX nc nb ne <ns> <tj> mname <area=val> <areac=val>
            # + <areab=val> <m=val> <off> <ic=vbe,vce> <temp=val>
            # + <dtemp=val>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::SemiconductorDevices::Bjt new 1 netc netb nete -model bjtmod -ns nets -area 1e-3
            # ```
            set arguments [argparse -inline {
                {-model= -required}
                -area=
                -m=
                -temp=
                {-off -boolean}
                -ic1=
                -ic2=
                -ns=
                {-tj= -require {ns}}
            }]            
            lappend params "model [dget $arguments model] -posnocheck"
            if {[dexist $arguments area]} {
                set areaVal [dget $arguments area]
                if {([llength $areaVal]>1) && ([@ $areaVal 1]=="-eq")} {
                    lappend params "area [@ $areaVal 0] -poseq"
                } else {
                    lappend params "area $areaVal -pos"
                }
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {model area off ns tj}} {
                    lappend params "$paramName $value"
                }
            }
            set pinList [list "nc $ncNode" "nb $nbNode" "ne $neNode"]
            if {[dexist $arguments ns]} {
                lappend pinList "ns [dget $arguments ns]"
                if {[dexist $arguments tj]} {
                    lappend pinList "tj [dget $arguments tj]"
                }
            }
            next q$name $pinList $params
        }
        method genSPICEString {} {
            # Modify substrate pin string in order to complain square brackets enclosure,
            # see BJT info in reference manual of Xyce
            set SPICEStr [next]
            if {[dexist [my getPins] ns]} {
                set SPICEList [split $SPICEStr]
                set SPICEStr [join [lreplace $SPICEList 4 4 "\[[@ $SPICEList 4]\]"]]
            }
            return $SPICEStr
        }
    }

####  Q class #
    
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
            #  -area - scale factor, optional
            #  -temp - device temperature, optional
            # ```
            # J<name> <drain node> <gate node> <source node> <model name> [area value] [device parameters]
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::SemiconductorDevices::Jfet new 1 netd netg nets -model jfetmod -area {area*2 -eq} -temp 25
            # ```
            set arguments [argparse -inline {
                {-model= -required}
                -area=
                -temp=
            }]
            lappend params "model [dget $arguments model] -posnocheck"
            if {[dexist $arguments area]} {
                set areaVal [dget $arguments area]
                if {([llength $areaVal]>1) && ([@ $areaVal 1]=="-eq")} {
                    lappend params "area [@ $areaVal 0] -poseq"
                } else {
                    lappend params "area $areaVal -pos"
                }
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {model area}} {
                    lappend params "$paramName $value"
                }
            }
            next j$name [list "nd $ndNode" "ng $ngNode" "ns $nsNode"] $params
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
        constructor {name ndNode ngNode nsNode args} {
            # Creates object of class `Mesfet` that describes semiconductor MESFET device.
            #  name - name of the device without first-letter designator Z
            #  ndNode - name of node connected to drain pin
            #  ngNode - name of node connected to gate pin
            #  nsNode - name of node connected to source pin
            #  -model - name of the model
            #  -area - emitter scale factor, optional
            #  -temp - device temperature, optional
            # ```
            # Z<name> < drain node> <gate node> <source node> <model name> [area value] [device parameters]
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::SemiconductorDevices::Mesfet new 1 netd netg nets -model mesfetmod -area {area*2 -eq}
            # ```
            set arguments [argparse -inline {
                {-model= -required}
                -area=
                -temp=
            }]
            lappend params "model [dget $arguments model] -posnocheck"
            if {[dexist $arguments area]} {
                set areaVal [dget $arguments area]
                if {([llength $areaVal]>1) && ([@ $areaVal 1]=="-eq")} {
                    lappend params "area [@ $areaVal 0] -poseq"
                } else {
                    lappend params "area $areaVal -pos"
                }
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {model area}} {
                    lappend params "$paramName $value"
                }
            }
            next z$name [list "nd $ndNode" "ng $ngNode" "ns $nsNode"] $params
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
            #  -ic - initial conditions for vds, vgs and vbs, in form of two element list, optional, require 4th node
            #  -off - initial state, optional
            #  -n4 - name of 4th node;
            #  -n5 - name of 5th node, require -n4, optional
            #  n6 - name of 6th node, require -n5, optional
            #  -n7 - name of 7th node, require -n6, optional
            #  -custparams - key that collects all arguments at the end of device definition, to provide an ability
            #  to add custom parameters in form `-custparams param1 param1Val param2 {param2eq -eq} param3 param3Val ...`
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
            # ::SpiceGenTcl::Xyce::Mosfet new 1 netd netg nets -model mosfetmod -l 1e-6 -w 10e-3 -n4 netsub -n5 net5
            # ```
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
                {-ic= -validate {[llength $arg]==3}}
                -n4=
                {-n5= -require {n4}}
                {-n6= -require {n5}}
                {-n7= -require {n7}}
                {-custparams -catchall}
            }]
            lappend params "model [dget $arguments model] -posnocheck"
            if {[dexist $arguments ic]} {
                lappend params "ic [join [dget $arguments ic] ,] -nocheck"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {model off ic n4 n5 n6 n7 custparams}} {
                    lappend params "$paramName $value"
                }
            }
            if {[dget $arguments custparams]!=""} {
                if {[llength [dget $arguments custparams]]%2!=0} {
                    return -code error "Custom parameters list must be even length"
                }
                set custParamDict [dcreate {*}[dget $arguments custparams]]
                dict for {paramName value} $custParamDict {
                    lappend params "$paramName $value"
                }
            }
            set pinList [list "nd $ndNode" "ng $ngNode" "ns $nsNode"]
            if {[dexist $arguments n4]} {
                lappend pinList "n4 [dget $arguments n4]"
                if {[dexist $arguments n5]} {
                    lappend pinList "n5 [dget $arguments n5]"
                    if {[dexist $arguments n6]} {
                        lappend pinList "n6 [dget $arguments n6]"
                        if {[dexist $arguments n7]} {
                            lappend pinList "n7 [dget $arguments n7]"
                        }
                    }
                }
            }
            next m$name $pinList $params
        }
    }

####  M class #
    
    # alias for Mosfet class
    oo::class create M {
        superclass Mosfet
    }    
}




