
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



### ________________________ Basic devices _________________________ ###

namespace eval ::SpiceGenTcl::Xyce::BasicDevices {
    
#### ________________________ Resistor class _________________________ ####

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
            # R<name> <(+) node> <(-) node> R ={expression} [device parameters]
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
            if {[dict exists $arguments model]} {
                lappend params "model [dict get $arguments model] -posnocheck"
            }
            if {[dict exists $arguments r]} {
                set rVal [dict get $arguments r]
                if {[dict exists $arguments beh]} {
                    lappend params "r $rVal -eq"
                } elseif {([llength $rVal]>1) && ([lindex $rVal 1]=="-eq")} {
                    lappend params "r [lindex $rVal 0] -poseq"
                } else {
                    lappend params "r $rVal -pos"
                }
            } elseif {[dict exists $arguments model]==0} {
                error "Resistor value must be specified with '-r value'"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {r beh model}} {
                    lappend params "$paramName $value"
                }
            }
            next r$name [list "np $npNode" "nm $nmNode"] $params
        }
    }
    
#### ________________________ R class _________________________ ####
    
    # alias for Resistor class
    oo::class create R {
        superclass Resistor
    }

#### ________________________ Capacitor class _________________________ ####

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
            # Behavioral capacitor with C expression:
            # ```
            # C<device name> <(+) node> <(-) node> C={expression} [device parameters]
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Xyce::BasicDevices::Capacitor new 1 netp netm -c "V(a)+V(b)+pow(V(c),2)" -beh -tc1 1
            # ```
            # Behavioral capacitor with Q expression:
            # ```
            # C<device name> <(+) node> <(-) node> Q={expression} [device parameters]
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
            if {[dict exists $arguments model]} {
                lappend params "model [dict get $arguments model] -posnocheck"
            }
            if {[dict exists $arguments c]} {
                set cVal [dict get $arguments c]
                if {[dict exists $arguments beh]} {
                    lappend params "c $cVal -eq"
                } elseif {([llength $cVal]>1) && ([lindex $cVal 1]=="-eq")} {
                    lappend params "c [lindex $cVal 0] -poseq"
                } else {
                    lappend params "c $cVal -pos"
                }
            } elseif {([dict exists $arguments model]==0) && ([dict exists $arguments q]==0)} {
                error "Capacitor value must be specified with '-c value'"
            }
            if {[dict exists $arguments q]} {
                set qVal [dict get $arguments q]
                if {[dict exists $arguments beh]} {
                    lappend params "q $qVal -eq"
                } else {
                    error "Charge of capacitor can't be specified without '-beh' switch"
                }
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {c q beh model}} {
                    lappend params "$paramName $value"
                }
            }
            next c$name [list "np $npNode" "nm $nmNode"] $params
        }
    }
    
#### ________________________ C class _________________________ ####

    # alias for Capacitor class
    oo::class create C {
        superclass Capacitor
    }

#### ________________________ Inductor class _________________________ ####

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
            if {[dict exists $arguments model]} {
                lappend params "model [dict get $arguments model] -posnocheck"
            }
            set lVal [dict get $arguments l]
            if {([llength $lVal]>1) && ([lindex $lVal 1]=="-eq")} {
                lappend params "l [lindex $lVal 0] -poseq"
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
    
#### ________________________ L class _________________________ ####
    
    # alias for Inductor class
    oo::class create L {
        superclass Inductor
    }   
    
#### ________________________ VSwitch class _________________________ ####
  
    oo::class create VSwitch {
        superclass ::SpiceGenTcl::Common::BasicDevices::VSwitch
    }

#### ________________________ VSw class _________________________ ####
    
    # alias for VSwitch class
    oo::class create VSw {
        superclass VSwitch
    }
    
#### ________________________ CSwitch class _________________________ ##
  
    oo::class create CSwitch {
        superclass ::SpiceGenTcl::Common::BasicDevices::CSwitch
    }

#### ________________________ W class _________________________ ####
    
    # alias for CSwitch class
    oo::class create W {
        superclass CSwitch
    }
    
#### ________________________ GenSwitch class _________________________ ##
  
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
            # S<name> <(+) switch node> <(-) switch node> <model name> [ON] [OFF] <control = expression>  
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
            lappend params "model [dict get $arguments model] -posnocheck"
            if {[dict exists $arguments on]} {
                lappend params {on -sw}
            } elseif {[dict exists $arguments off]} {
                lappend params {off -sw}
            }
            lappend params "control [dict get $arguments control] -eq"
            next s$name [list "np $npNode" "nm $nmNode"] $params
        }
    }

#### ________________________ GenS class _________________________ ####
    
    # alias for GenSwitch class
    oo::class create GenS {
        superclass GenSwitch
    }        
    
#### ________________________ SubcircuitInstance class _________________________ ####

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

#### ________________________ X class _________________________ ####
    
    # alias for SubcircuitInstance class
    oo::class create X {
        superclass SubcircuitInstance
    }
    
#### ________________________ SubcircuitInstanceAuto class _________________________ ##
    
    oo::class create SubcircuitInstanceAuto {
        superclass ::SpiceGenTcl::Device
        constructor {subcktObj name nodes args} {
            # Creates object of class `SubcircuitInstanceAuto` that describes subcircuit instance with already created subcircuit definition object.
            #  subcktObj - object of subcircuit that defines it's pins, subName and parameters
            #  nodes - list of nodes connected to pins in the same order as pins in subcircuit definition {nodeName1 nodeName2 ...}
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
                error "Wrong object class '$objClass' is passed as subcktObj, should be '::SpiceGenTcl::Subcircuit'"
            }
            # get name of subcircuit
            set subName [$subcktObj configure -Name] 
            # get pins names of subcircuit
            set pinsNames [dict keys [$subcktObj getPins]]
            # check if number of pins in subcircuit definition matchs the number of supplied nodes
            if {[llength $pinsNames]!=[llength $nodes]} {
                error "Wrong number of nodes '[llength $nodes]' in definition, should be '[llength $pinsNames]'"
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
            set params [linsert $params 1 "params PARAMS: -posnocheck"]
            next x$name $pinsList $params
        }
    }

#### ________________________ XAuto class _________________________ ####
    
    # alias for SubcircuitInstanceAuto class
    oo::class create XAuto {
        superclass SubcircuitInstanceAuto
    }
}

### ________________________ Sources devices _________________________ #

namespace eval ::SpiceGenTcl::Xyce::Sources {

    
#### ________________________ Vdc class _________________________ ##
        
    oo::class create Vdc {
        superclass ::SpiceGenTcl::Common::Sources::Vdc
    }

#### ________________________ Vac class _________________________ ##
    
    oo::class create Vac {
        superclass ::SpiceGenTcl::Common::Sources::Vac
    }
    
#### ________________________ Vpulse class _________________________ ##

    oo::class create Vpulse {
        superclass ::SpiceGenTcl::Common::Sources::Vpulse
    }  
    
#### ________________________ Vsin class _________________________ ##

    oo::class create Vsin {
        superclass ::SpiceGenTcl::Common::Sources::Vsin
    }
    
#### ________________________ Vexp class _________________________ ##

    oo::class create Vexp {
        superclass ::SpiceGenTcl::Common::Sources::Vexp
    }
    
#### ________________________ Vpwl class _________________________ ##

    oo::class create Vpwl {
        superclass ::SpiceGenTcl::Common::Sources::Vpwl
    }    
    
#### ________________________ Vsffm class _________________________ ##

    oo::class create Vsffm {
        superclass ::SpiceGenTcl::Common::Sources::Vsffm
    }     
    
#### ________________________ Idc class _________________________ ##

    oo::class create Idc {
        superclass ::SpiceGenTcl::Common::Sources::Idc
    }

#### ________________________ Iac class _________________________ ##

    oo::class create Iac {
        superclass ::SpiceGenTcl::Common::Sources::Iac
    }
    
#### ________________________ Ipulse class _________________________ ##

    oo::class create Ipulse {
        superclass ::SpiceGenTcl::Common::Sources::Ipulse
    }
    
#### ________________________ Isin class _________________________ ##

    oo::class create Isin {
        superclass ::SpiceGenTcl::Common::Sources::Isin
    }
    
#### ________________________ Iexp class _________________________ ##

    oo::class create Iexp {
        superclass ::SpiceGenTcl::Common::Sources::Iexp
    }

#### ________________________ Ipwl class _________________________ ##

    oo::class create Ipwl {
        superclass ::SpiceGenTcl::Common::Sources::Ipwl
    }   
    
#### ________________________ Isffm class _________________________ ##

    oo::class create Isffm {
        superclass ::SpiceGenTcl::Common::Sources::Isffm
    }        
    
#### ________________________ Vccs class _________________________ ##
  
    oo::class create Vccs {
        superclass ::SpiceGenTcl::Common::Sources::Vccs
    }

#### ________________________ G class _________________________ ####
    
    # alias for Vccs class
    oo::class create G {
        superclass Vccs
    }    

#### ________________________ Vcvs class _________________________ ##
  
    oo::class create Vcvs {
        superclass ::SpiceGenTcl::Common::Sources::Vcvs
    }

#### ________________________ E class _________________________ ####
    
    # alias for Vcvs class
    oo::class create E {
        superclass Vcvs
    } 
    
#### ________________________ Cccs class _________________________ ##
  
    oo::class create Cccs {
        superclass ::SpiceGenTcl::Common::Sources::Cccs
    }

#### ________________________ F class _________________________ ####
    
    # alias for Cccs class
    oo::class create F {
        superclass Cccs
    } 
        
#### ________________________ Ccvs class _________________________ ##
  
    oo::class create Ccvs {
        superclass ::SpiceGenTcl::Common::Sources::Ccvs
    }

#### ________________________ H class _________________________ ####
    
    # alias for Ccvs class
    oo::class create H {
        superclass Ccvs
    } 
    
#### ________________________ BehaviouralSource class _________________________ ##
    
    oo::class create BehaviouralSource {
        superclass ::SpiceGenTcl::Device
        mixin ::SpiceGenTcl::KeyArgsBuilder
        constructor {name npNode nmNode args} {
            # Creates object of class `BehaviouralSource` that describes behavioural source.
            #  name - name of the device without first-letter designator R
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -i - current expression
            #  -v - voltage expression
            #  -smoothbsrc - enables the smooth transitions, optional, require -v
            #  -rcconst -  rc constant of the RC network, optional, require -v
            # ```
            # B<name> <(+) node> <(-) node> V={expression} [device parameters]
            # B<name> <(+) node> <(-) node> I={expression}
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
            if {[dict exists $arguments i]} {
                lappend params "i [dict get $arguments i] -eq"
            } elseif {[dict exists $arguments v]} {
                lappend params "v [dict get $arguments v] -eq"
            } else {
                error "Equation must be specified as argument to -i or -v"
            }
            if {[dict exists $arguments smoothbsrc]} {
                lappend params "smoothbsrc 1"
            }
            if {[dict exists $arguments rcconst]} {
                lappend params "rcconst [dict get $arguments rcconst]"
            }
            next b$name [list "np $npNode" "nm $nmNode"] $params
        }
    }

#### ________________________ B class _________________________ ####
    
    # alias for BehaviouralSource class
    oo::class create B {
        superclass BehaviouralSource
    }
}
### ________________________ SemiconductorDevices _________________________ #

namespace eval ::SpiceGenTcl::Xyce::SemiconductorDevices {
    
#### ________________________ Diode class _________________________ ##
    
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
            lappend params "model [dict get $arguments model] -posnocheck"
            if {[dict exists $arguments area]} {
                set areaVal [dict get $arguments area]
                if {([llength $areaVal]>1) && ([lindex $areaVal 1]=="-eq")} {
                    lappend params "area [lindex $areaVal 0] -poseq"
                } else {
                    lappend params "area $areaVal -pos"
                }
            }
            if {[dict exists $arguments pj]} {
                set pjVal [dict get $arguments pj]
                if {([llength $pjVal]>1) && ([lindex $pjVal 1]=="-eq")} {
                    lappend params "pj [lindex $pjVal 0] -poseq"
                } else {
                    lappend params "pj $pjVal -pos"
                }
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {model custparams area pj}} {
                    lappend params "$paramName $value"
                }
            }
            if {[dict get $arguments custparams]!=""} {
                if {[llength [dict get $arguments custparams]]%2!=0} {
                    error "Custom parameters list must be even length"
                }
                set custParamDict [dict create {*}[dict get $arguments custparams]]
                dict for {paramName value} $custParamDict {
                    lappend params "$paramName $value"
                }
            }
            next d$name [list "np $npNode" "nm $nmNode"] $params
        }
    }

#### ________________________ D class _________________________ ####
    
    # alias for Diode class
    oo::class create D {
        superclass Diode
    }
    
#### ________________________ Bjt class _________________________ ##
    
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
            lappend params "model [dict get $arguments model] -posnocheck"
            if {[dict exists $arguments area]} {
                set areaVal [dict get $arguments area]
                if {([llength $areaVal]>1) && ([lindex $areaVal 1]=="-eq")} {
                    lappend params "area [lindex $areaVal 0] -poseq"
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
            if {[dict exists $arguments ns]} {
                lappend pinList "ns [dict get $arguments ns]"
                if {[dict exists $arguments tj]} {
                    lappend pinList "tj [dict get $arguments tj]"
                }
            }
            next q$name $pinList $params
        }
        method genSPICEString {} {
            # Modify substrate pin string in order to complain square brackets enclosure,
            # see BJT info in reference manual of Xyce
            set SPICEStr [next]
            if {[dict exists [my getPins] ns]} {
                set SPICEList [split $SPICEStr]
                set SPICEStr [join [lreplace $SPICEList 4 4 "\[[lindex $SPICEList 4]\]"]]
            }
            return $SPICEStr
        }
    }

#### ________________________ Q class _________________________ ####
    
    # alias for Bjt class
    oo::class create Q {
        superclass Bjt
    }
    
#### ________________________ Jfet class _________________________ ##
    
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
            lappend params "model [dict get $arguments model] -posnocheck"
            if {[dict exists $arguments area]} {
                set areaVal [dict get $arguments area]
                if {([llength $areaVal]>1) && ([lindex $areaVal 1]=="-eq")} {
                    lappend params "area [lindex $areaVal 0] -poseq"
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

#### ________________________ J class _________________________ ####
    
    # alias for Jfet class
    oo::class create J {
        superclass Jfet
    }
    
#### ________________________ Mesfet class _________________________ ##
    
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
            lappend params "model [dict get $arguments model] -posnocheck"
            if {[dict exists $arguments area]} {
                set areaVal [dict get $arguments area]
                if {([llength $areaVal]>1) && ([lindex $areaVal 1]=="-eq")} {
                    lappend params "area [lindex $areaVal 0] -poseq"
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

#### ________________________ Z class _________________________ ####
    
    # alias for Mesfet class
    oo::class create Z {
        superclass Mesfet
    }   
 
#### ________________________ Mosfet class _________________________ ##
    
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
            lappend params "model [dict get $arguments model] -posnocheck"
            if {[dict exists $arguments ic]} {
                lappend params "ic [join [dict get $arguments ic] ,] -nocheck"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {model off ic n4 n5 n6 n7 custparams}} {
                    lappend params "$paramName $value"
                }
            }
            if {[dict get $arguments custparams]!=""} {
                if {[llength [dict get $arguments custparams]]%2!=0} {
                    error "Custom parameters list must be even length"
                }
                set custParamDict [dict create {*}[dict get $arguments custparams]]
                dict for {paramName value} $custParamDict {
                    lappend params "$paramName $value"
                }
            }
            set pinList [list "nd $ndNode" "ng $ngNode" "ns $nsNode"]
            if {[dict exists $arguments n4]} {
                lappend pinList "n4 [dict get $arguments n4]"
                if {[dict exists $arguments n5]} {
                    lappend pinList "n5 [dict get $arguments n5]"
                    if {[dict exists $arguments n6]} {
                        lappend pinList "n6 [dict get $arguments n6]"
                        if {[dict exists $arguments n7]} {
                            lappend pinList "n7 [dict get $arguments n7]"
                        }
                    }
                }
            }
            next m$name $pinList $params
        }
    }

#### ________________________ M class _________________________ ####
    
    # alias for Mosfet class
    oo::class create M {
        superclass Mosfet
    }    
}



