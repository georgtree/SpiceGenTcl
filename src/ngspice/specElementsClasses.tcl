
namespace eval SpiceGenTcl {
    namespace eval Ngspice::BasicDevices {
        namespace export Resistor R ResistorBehavioural RBeh ResistorSemiconductor RSem Capacitor \
                CapacitorBehaviouralQ CBehQ CapacitorBehaviouralC CBehC \
                C CapacitorSemiconductor CSem Inductor L InductorBehavioural LBeh \
                SubcircuitInstance X SubcircuitInstanceAuto XAuto \
                VSwitch VSw CSwitch CSw 
    }
    namespace eval Ngspice::Sources {
        namespace export Vdc Idc Vac Iac Vpulse Ipulse Vsin Isin Vexp Iexp Vpwl Ipwl Vsffm Isffm Vam Iam Vccs G \
                Vcvs E Cccs F Ccvs H BehaviouralSource B
    }
    namespace eval Ngspice::SemiconductorDevices {
        namespace export Diode D Bjt Q BjtSub QSub BjtSubTj QSubTj Jfet J Mesfet Z Mosfet M
    } 
}



    # ________________________ Basic devices _________________________ #

namespace eval SpiceGenTcl::Ngspice::BasicDevices {

    ## ________________________ resistor classes _________________________ ##
    
    ### ________________________ Resistor class _________________________ ###

    oo::class create Resistor {
        superclass SpiceGenTcl::Device
        mixin SpiceGenTcl::KeyArgsBuilder
        constructor {name npNode nmNode rVal args} {
            # Creates object of class `Resistor` that describes simple resistor. 
            #  name - name of the device without first-letter designator R
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  rVal - value of resistance
            #  args - keyword instance parameters
            # ```
            # RXXXXXXX n+ n- <resistance|r=>value <ac=val> <m=val>
            # + <scale=val> <temp=val> <dtemp=val> <tc1=val> <tc2=val>
            # + <noisy=0|1>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::BasicDevices::Resistor new 1 netp netm 1e3 -tc1 1 -ac 1e6 -temp {temp_amb -eq}
            # ```
            set paramsNames [list ac m scale temp dtemp tc1 tc2 noisy]
            set paramDefList [my buildArgStr $paramsNames]
            set arguments [argparse -inline "
                $paramDefList
            "]
            if {([llength $rVal]>1) && ([lindex $rVal 1]=="-eq")} {
                lappend paramList "r [lindex $rVal 0] -poseq"
            } else {
                lappend paramList "r $rVal -pos"
            }
            dict for {paramName value} $arguments {
                lappend paramList "$paramName $value"
            }
            next r$name [list "np $npNode" "nm $nmNode"] $paramList
        }
    }
    # alias for Resistor class
    oo::class create R {
        superclass Resistor
    }
    
    ### ________________________ ResistorBehavioural class _________________________ ###
    
    oo::class create ResistorBehavioural {
        superclass SpiceGenTcl::Device
        mixin SpiceGenTcl::KeyArgsBuilder
        constructor {name npNode nmNode rExpr args} {
            # Creates object of class `ResistorBehavioural` that describes device dependent on expressions.
            #  name - name of the device without first-letter designator R
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  rExpr - equation of resistance
            #  args - keyword instance parameters
            # ```
            # RXXXXXXX n+ n- R ={expression} <tc1=value> <tc2=value> <noisy=0>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::BasicDevices::ResistorBehavioural new 1 netp netm "V(a)+V(b)+pow(V(c),2)" -tc1 1
            # ```
            set paramDefList [my buildArgStr [list tc1 tc2 noisy]]
            set arguments [argparse -inline "
                $paramDefList
            "]
            lappend paramList "r $rExpr -eq"
            dict for {paramName value} $arguments {
                lappend paramList "$paramName $value"
            }
            next r$name [list "np $npNode" "nm $nmNode"] $paramList
        }
    }

    # alias for ResistorBehavioural class
    oo::class create RBeh {
        superclass ResistorBehavioural
    }    
    
    ### ________________________ ResistorSemiconductor class _________________________ ###
    
    oo::class create ResistorSemiconductor {
        superclass SpiceGenTcl::DeviceModel
        mixin SpiceGenTcl::KeyArgsBuilder
        constructor {name npNode nmNode modelName args} {
            # Creates object of class `ResistorSemiconductor` that describes semiconductor resistor device.
            #  name - name of the device without first-letter designator R
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  modelName - name of the model
            #  args - keyword instance parameters
            # ```
            # RXXXXXXX n+ n- <value> <mname> <l=length> <w=width>
            # + <temp=val> <dtemp=val> <m=val> <ac=val> <scale=val>
            # + <noisy=0|1>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::ResistorSemiconductor new 1 netp netm resm -l 1e-6 -w 10e-6
            # ```
            set paramsNames [list l w temp dtemp m ac scale noisy]
            set paramDefList [my buildArgStr $paramsNames]
            set arguments [argparse -inline "
                $paramDefList
            "]
            dict for {paramName value} $arguments {
                lappend paramList "$paramName $value"
            }
            next r$name [list "np $npNode" "nm $nmNode"] $modelName $paramList
        }
    }
    # alias for ResistorSemiconductor class
    oo::class create RSem {
        superclass ResistorSemiconductor
    }

    ## ________________________ capacitor classes _________________________ ##

    ### ________________________ Capacitor class _________________________ ###

    oo::class create Capacitor {
        superclass SpiceGenTcl::Device
        mixin SpiceGenTcl::KeyArgsBuilder
        constructor {name npNode nmNode cVal args} {
            # Creates object of class `Capacitor` that describes simple capacitor device.
            #  name - name of the device without first-letter designator C
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  cVal - value of capacitance
            #  args - keyword instance parameters
            # ```
            # CXXXXXXX n+ n- <value> <mname> <m=val> <scale=val> <temp=val>
            # + <dtemp=val> <tc1=val> <tc2=val> <ic=init_condition>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::BasicDevices::Capacitor new 1 netp netm 1e-6 -tc1 1 -temp 25
            # ```
            set paramsNames [list m scale temp dtemp tc1 tc2 ic]
            set paramDefList [my buildArgStr $paramsNames]
            set arguments [argparse -inline "
                $paramDefList
            "]
            if {([llength $cVal]>1) && ([lindex $cVal 1]=="-eq")} {
                lappend paramList "c [lindex $cVal 0] -poseq"
            } else {
                lappend paramList "c $cVal -pos"
            }
            dict for {paramName value} $arguments {
                lappend paramList "$paramName $value"
            }
            next c$name [list "np $npNode" "nm $nmNode"] $paramList
        }
    }
    # alias for Capacitor class
    oo::class create C {
        superclass Capacitor
    }

    ### ________________________ CapacitorBehaviouralC class _________________________ ###

    oo::class create CapacitorBehaviouralC {
        superclass SpiceGenTcl::Device
        mixin SpiceGenTcl::KeyArgsBuilder
        constructor {name npNode nmNode cExpr args} {
            # Creates object of class `CapacitorBehaviouralC` that describes capacitor device dependents on expressions in C form.
            #  name - name of the device without first-letter designator R
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  cExpr - equation of capacitance
            #  args - keyword instance parameters
            # ```
            # CXXXXXXX n+ n- C={expression} <tc1=value> <tc2=value>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::BasicDevices::CapacitorBehaviouralC new 1 netp netm "V(a)+V(b)+pow(V(c),2)" -tc1 1
            # ```
            set paramDefList [my buildArgStr [list tc1 tc2]]
            set arguments [argparse -inline "
                $paramDefList
            "]
            lappend paramList "c $cExpr -eq"
            dict for {paramName value} $arguments {
                lappend paramList "$paramName $value"
            }
            next c$name [list "np $npNode" "nm $nmNode"] $paramList
        }
    }
    
    # alias for CapacitorBehaviouralC class
    oo::class create CBehC {
        superclass CapacitorBehaviouralC
    }  

    ### ________________________ CapacitorBehaviouralQ class _________________________ ###

    oo::class create CapacitorBehaviouralQ {
        superclass SpiceGenTcl::Device
        mixin SpiceGenTcl::KeyArgsBuilder
        constructor {name npNode nmNode qExpr args} {
            # Creates object of class `CapacitorBehaviouralQ` that describes capacitor device dependents on expressions in Q form.
            #  name - name of the device without first-letter designator R
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  qExpr - equation of charge
            #  args - keyword instance parameters
            # ```
            # CXXXXXXX n+ n- Q={expression} <tc1=value> <tc2=value>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::BasicDevices::CapacitorBehaviouralQ new 1 netp netm "V(a)+V(b)+pow(V(c),2)" -tc1 1
            # ```
            set paramDefList [my buildArgStr [list tc1 tc2]]
            set arguments [argparse -inline "
                $paramDefList
            "]
            lappend paramList "q $qExpr -eq"
            dict for {paramName value} $arguments {
                lappend paramList "$paramName $value"
            }
            next c$name [list "np $npNode" "nm $nmNode"] $paramList
        }
    }
    
    # alias for CapacitorBehaviouralQ class
    oo::class create CBehQ {
        superclass CapacitorBehaviouralQ
    }      
    
    ### ________________________ CapacitorSemiconductor class _________________________ ###
    
    oo::class create CapacitorSemiconductor {
        superclass SpiceGenTcl::DeviceModel
        mixin SpiceGenTcl::KeyArgsBuilder
        constructor {name npNode nmNode modelName args} {
            # Creates object of class `CapacitorBehaviouralQ` that describes semiconductor capacitor device.
            #  name - name of the device without first-letter designator C
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  modelName - name of the model
            #  args - keyword instance parameters
            # ```
            # CXXXXXXX n+ n- <value> <mname> <l=length> <w=width> <m=val>
            # + <scale=val> <temp=val> <dtemp=val> <ic=init_condition>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::CapacitorSemiconductor new 1 netp netm capm -l 1e-6 -w 10e-6
            # ```
            set paramsNames [list l w temp dtemp m ac scale]
            set paramDefList [my buildArgStr $paramsNames]
            set arguments [argparse -inline "
                $paramDefList
            "]
            dict for {paramName value} $arguments {
                lappend paramList "$paramName $value"
            }
            next c$name [list "np $npNode" "nm $nmNode"] $modelName $paramList
        }
    }
    # alias for CapacitorSemiconductor class
    oo::class create CSem {
        superclass CapacitorSemiconductor
    }

    ## ________________________ inductor classes _________________________ ##

    ### ________________________ Inductor class _________________________ ###

    oo::class create Inductor {
        superclass SpiceGenTcl::Device
        mixin SpiceGenTcl::KeyArgsBuilder
        constructor {name npNode nmNode lVal args} {
            # Creates object of class `Inductor` that describes simple inductor device.
            #  name - name of the device without first-letter designator L
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  lVal - value of inductance
            #  args - keyword instance parameters
            # ```
            # LYYYYYYY n+ n- <value> <mname> <nt=val> <m=val>
            # + <scale=val> <temp=val> <dtemp=val> <tc1=val>
            # + <tc2=val> <ic=init_condition>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::BasicDevices::Inductor new 1 netp netm 1e-6 -tc1 1 -temp 25
            # ```
            set paramsNames [list nt m scale temp dtemp tc1 tc2 ic]
            set paramDefList [my buildArgStr $paramsNames]
            set arguments [argparse -inline "
                $paramDefList
            "]
            if {([llength $lVal]>1) && ([lindex $lVal 1]=="-eq")} {
                lappend paramList "l [lindex $lVal 0] -poseq"
            } else {
                lappend paramList "l $lVal -pos"
            }
            dict for {paramName value} $arguments {
                lappend paramList "$paramName $value"
            }
            next l$name [list "np $npNode" "nm $nmNode"] $paramList
        }
    }
    # alias for Inductor class
    oo::class create L {
        superclass Inductor
    }
    
    ### ________________________ InductorBehavioural class _________________________ ###
    
    oo::class create InductorBehavioural {
        superclass SpiceGenTcl::Device
        mixin SpiceGenTcl::KeyArgsBuilder
        constructor {name npNode nmNode lExpr args} {
            # Creates object of class `InductorBehavioural` that describes inductor device dependent on expressions.
            #  name - name of the device without first-letter designator R
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  lExpr - equation of inductance
            #  args - keyword instance parameters
            # ```
            # LXXXXXXX n+ n- L={expression} <tc1=value> <tc2=value>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::BasicDevices::InductorBehavioural new 1 netp netm "V(a)+V(b)+pow(V(c),2)" -tc1 1
            # ```
            set paramDefList [my buildArgStr [list tc1 tc2]]
            set arguments [argparse -inline "
                $paramDefList
            "]
            lappend paramList "l $lExpr -eq"
            dict for {paramName value} $arguments {
                lappend paramList "$paramName $value"
            }
            next l$name [list "np $npNode" "nm $nmNode"] $paramList
        }
    }
    
    # alias for InductorBehavioural class
    oo::class create LBeh {
        superclass InductorBehavioural
    }  
    
    ## ________________________ VSwitch class _________________________ ##
  
    oo::class create VSwitch {
        superclass SpiceGenTcl::DeviceModel
        constructor {name npNode nmNode ncpNode ncmNode modelName args} {
            # Creates object of class `VSwitch` that describes voltage controlled switch device.
            #  name - name of the device without first-letter designator S
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  ncpNode - name of node connected to positive controlling pin
            #  ncmNode - name of node connected to negative controlling pin
            #  modelName - name of the model
            #  args - on or off state parameter, optional
            # ```
            # SXXXXXXX N+ N- NC+ NC- MODEL <ON> <OFF>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::BasicDevices::VSwitch new 1 net1 0 netc 0 sw1 -on
            # ```
            set arguments [argparse {
                {-on -forbid {off}}
                {-off -forbid {on}}
            }]
            if {[info exists on]} {
                lappend param {on -sw}
            } elseif {[info exists off]} {
                lappend param {off -sw}
            } else {
                set param ""
            }
            next s$name [list "np $npNode" "nm $nmNode" "ncp $ncpNode" "ncm $ncmNode"] $modelName $param
        }
    }
    # alias for VSwitch class
    oo::class create VSw {
        superclass VSwitch
    }    
    
    ## ________________________ CSwitch class _________________________ ##
  
    oo::class create CSwitch {
        superclass SpiceGenTcl::DeviceModel
        # special positional parameter that is placed before model name
        variable CControlParam
        constructor {name npNode nmNode cControl modelName args} {
            # Creates object of class `CSwitch` that describes current controlled switch device.
            #  name - name of the device without first-letter designator W
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  cControl - name of source current through which controls switch
            #  modelName - name of the model
            #  args - on or off state parameter, optional
            # ```
            # WYYYYYYY N+ N- VNAM MODEL <ON> <OFF>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::BasicDevices::ISwitch new 1 net1 0 v1 sw1 -on
            # ```
            set arguments [argparse {
                {-on -forbid {off}}
                {-off -forbid {on}}
            }]
            if {[info exists on]} {
                lappend param {on -sw}
            } elseif {[info exists off]} {
                lappend param {off -sw}
            } else {
                set param ""
            }
            set CControlParam [SpiceGenTcl::ParameterPositionalNoCheck new ccontrol $cControl]
            next w$name [list "np $npNode" "nm $nmNode"] $modelName $param
        }
        method genSPICEString {} {
            set string [next]
            return [linsert $string 3 [$CControlParam getValue]]
        }
    }
    # alias for CSwitch class
    oo::class create CSw {
        superclass CSwitch
    }
    
    ## ________________________ SubcircuitInstance class _________________________ ##

    oo::class create SubcircuitInstance {
        superclass SpiceGenTcl::DeviceModel
        constructor {name pins subName params} {
            # Creates object of class `CSwitch` that describes subcircuit instance.
            #  name - name of the device without first-letter designator X
            #  pins - list of pins {{pinName nodeName} {pinName nodeName} ...}
            #  subName - name of subcircuit definition
            #  params - {{paramName paramValue ?-eq?} {paramName paramValue ?-eq?}}
            # ```
            # .SUBCKT subnam N1 <N2 N3 ...>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::BasicDevices::SubcircuitInstance new 1 {{plus net1} {minus net2}} rcnet {{r 1} {c cpar -eq}}
            # ```
            next x$name $pins $subName $params
        }
    }
    # alias for SubcircuitInstance class
    oo::class create X {
        superclass SubcircuitInstance
    }
    
    ## ________________________ SubcircuitInstanceAuto class _________________________ ##
    
    oo::class create SubcircuitInstanceAuto {
        superclass SpiceGenTcl::DeviceModel
        constructor {subcktObj name nodes args} {
            # Creates object of class `SubcircuitInstanceAuto` that describes subcircuit instance with already created subcircuit definition object.
            #  subcktObj - object of subcircuit that defines it's pins, subName and parameters
            #  nodes - list of nodes connected to pins in the same order as pins in subcircuit definition {nodeName1 nodeName2 ...}
            #  args - parameters as argument in form : -paramName {paramValue ?-eq?} -paramName {paramValue ?-eq?}
            # ```
            # .SUBCKT subnam N1 <N2 N3 ...>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::BasicDevices::SubcircuitInstanceAuto new $subcktObj 1 {net1 net2} -r 1 -c {cpar -eq}
            # ```
            
            # check that inputs object class is Subcircuit
            if {[info object class $subcktObj "SpiceGenTcl::Subcircuit"]!=1} {
                set objClass [info object class $subcktObj]
                error "Wrong object class '$objClass' is passed as subcktObj, should be 'SpiceGenTcl::Subcircuit'"
            }
            # get name of subcircuit
            set subName [$subcktObj getName] 
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
                    lappend paramList "$paramName $value"
                }
            } else {
                set paramList ""
            }
            next x$name $pinsList $subName $paramList
        }
    }
    
    # alias for SubcircuitInstanceAuto class
    oo::class create XAuto {
        superclass SubcircuitInstanceAuto
    }
}

    # ________________________ Sources devices _________________________ #

namespace eval SpiceGenTcl::Ngspice::Sources {

    ## ________________________ dc sources template class _________________________ ##
    
    oo::class create dc {
        superclass SpiceGenTcl::Device
        constructor {name type npNode nmNode dcVal} {
            if {([llength $dcVal]>1) && ([lindex $dcVal 1]=="-eq")} {
                lappend paramList "dc [lindex $dcVal 0] -poseq"
            } else {
                lappend paramList "dc $dcVal -pos"
            }
            next $type$name [list "np $npNode" "nm $nmNode"] $paramList
        }
        self unexport create new
    }

    ## ________________________ ac sources template class _________________________ ##

    oo::class create ac {
        superclass SpiceGenTcl::Device
        constructor {name type npNode nmNode acMag args} {
            set arguments [argparse {
                -acphase=
            }]
            lappend paramList "ac -sw"
            if {([llength $acMag]>1) && ([lindex $acMag 1]=="-eq")} {
                lappend paramList "acmag [lindex $acMag 0] -poseq"
            } else {
                lappend paramList "acmag $acMag -pos"
            }
            if {[info exists acphase]} {
                if {([llength $acphase]>1) && ([lindex $acphase 1]=="-eq")} {
                    lappend paramList "acphase [lindex $acphase 0] -poseq"
                } else {
                    lappend paramList "acphase $acphase -pos"
                }
            }
            next $type$name [list "np $npNode" "nm $nmNode"] $paramList
        }
        self unexport create new
    }   
    
    ## ________________________ pulse sources template class _________________________ ##
    
    oo::class create pulse {
        superclass SpiceGenTcl::DeviceModel
        constructor {name type npNode nmNode low high td tr tf pw per args} {
            set arguments [argparse {
                -np=
            }]
            set paramNames [lrange [lindex [info class constructor [info object class [self]]] 0] 3 end-1]
            foreach paramName $paramNames {
                set paramNameVal [subst $$paramName]
                if {([llength $paramNameVal]>1) && ([lindex $paramNameVal 1]=="-eq")} {
                    lappend paramList "$paramName [lindex $paramNameVal 0] -poseq"
                } else {
                    lappend paramList "$paramName $paramNameVal -pos"
                }
            }
            if {[info exists np]} {
                if {([llength $np]>1) && ([lindex $np 1]=="-eq")} {
                    lappend paramList "np [lindex $np 0] -poseq"
                } else {
                    lappend paramList "np $np -pos"
                }
            }
            next $type$name [list "np $npNode" "nm $nmNode"] pulse $paramList
        }
        method genSPICEString {} {
            # method creates device string for SPICE netlist in form
            #  "referenceName nodes modelName(parameters)"
            # this is special extension for independent sources
            my variable Params
            my variable Pins
            dict for {pinName pin} $Pins {
                set error [catch {$pin genSPICEString} errStr] 
                if {$error!=1} {
                    lappend nodes [$pin genSPICEString]
                } else {
                    error "Device '[my getName]' can't be netlisted because '$pinName' pin is floating"
                }
            }
            if {$Params==""} {
                lappend params ""
                return "[my getName] [join $nodes] [my getModelName]"
            } else {
                dict for {paramName param} $Params {
                    lappend params [$param genSPICEString]
                }
                return "[my getName] [join $nodes] [my getModelName]([join $params])"
            } 
        }
        self unexport create new
    }  
    
    ## ________________________ sin sources template class _________________________ ##
    
    oo::class create sin {
        superclass SpiceGenTcl::DeviceModel
        mixin SpiceGenTcl::KeyArgsBuilder
        constructor {name type npNode nmNode v0 va freq args} {
            set paramDefList [my buildArgStr [list td theta phase]]
            set arguments [argparse -inline "
                $paramDefList
            "]
            set paramNames [lrange [lindex [info class constructor [info object class [self]]] 0] 3 end-1]
            foreach paramName $paramNames {
                set paramNameVal [subst $$paramName]
                if {([llength $paramNameVal]>1) && ([lindex $paramNameVal 1]=="-eq")} {
                    lappend paramList "$paramName [lindex $paramNameVal 0] -poseq"
                } else {
                    lappend paramList "$paramName $paramNameVal -pos"
                }
            }
            dict for {paramName value} $arguments {
                if {([llength $value]>1) && ([lindex $value 1]=="-eq")} {
                    lappend paramList "$paramName [lindex $value 0] -poseq"
                } else {
                    lappend paramList "$paramName $value -pos"
                }
            }
            next $type$name [list "np $npNode" "nm $nmNode"] sin $paramList
        }
        set def [info class definition SpiceGenTcl::Ngspice::Sources::pulse genSPICEString]
        method genSPICEString [lindex $def 0] [lindex $def 1]
        self unexport create new
    }  
    
    ## ________________________ exp sources template class _________________________ ##
    
    oo::class create exp {
        superclass SpiceGenTcl::DeviceModel
        constructor {name type npNode nmNode v1 v2 td1 tau1 td2 tau2} {
            set paramNames [lrange [lindex [info class constructor [info object class [self]]] 0] 3 end]
            foreach paramName $paramNames {
                set paramNameVal [subst $$paramName]
                if {([llength $paramNameVal]>1) && ([lindex $paramNameVal 1]=="-eq")} {
                    lappend paramList "$paramName [lindex $paramNameVal 0] -poseq"
                } else {
                    lappend paramList "$paramName $paramNameVal -pos"
                }
            }
            next $type$name [list "np $npNode" "nm $nmNode"] exp $paramList
        }
        set def [info class definition SpiceGenTcl::Ngspice::Sources::pulse genSPICEString]
        method genSPICEString [lindex $def 0] [lindex $def 1]
        self unexport create new
    }    
    
    ## ________________________ pwl sources template class _________________________ ##
    
    oo::class create pwl {
        superclass SpiceGenTcl::DeviceModel
        constructor {name type npNode nmNode pwlSeq} {
            set pwlSeqLen [llength $pwlSeq]
            if {$pwlSeqLen%2} {
                error "Number of elements '$pwlSeqLen' in pwl sequence is odd in element '$type$name', must be even"
            } elseif {$pwlSeqLen<4} {
                error "Number of elements '$pwlSeqLen' in pwl sequence in element '$type$name' must be >=4"
            }
            # parse pwlSeq argument
            for {set i 0} {$i<[llength $pwlSeq]/2} {incr i} {
                set 2i [* 2 $i]
                set 2ip1 [+ $2i 1]
                lappend params "t$i [list [lindex $pwlSeq $2i]]" "$type$i [list [lindex $pwlSeq $2ip1]]"
            }
            foreach param $params {
                if {([llength [lindex $param 1]]>1) && ([lindex [lindex $param 1] 1]=="-eq")} {
                    lappend paramList "[lindex $param 0] [lindex [lindex $param 1] 0] -poseq"
                } else {
                    lappend paramList "[lindex $param 0] [lindex $param 1] -pos"
                }
            }
            next $type$name [list "np $npNode" "nm $nmNode"] pwl $paramList
        }
        set def [info class definition SpiceGenTcl::Ngspice::Sources::pulse genSPICEString]
        method genSPICEString [lindex $def 0] [lindex $def 1]
        self unexport create new
    }

    ## ________________________ sffm sources template class _________________________ ##
    
    oo::class create sffm {
        superclass SpiceGenTcl::DeviceModel
        mixin SpiceGenTcl::KeyArgsBuilder
        constructor {name type npNode nmNode v0 va fc mdi fs args} {
            set paramDefList [my buildArgStr [list phasec phases]]
            set arguments [argparse -inline "
                $paramDefList
            "]
            set paramNames [lrange [lindex [info class constructor [info object class [self]]] 0] 3 end-1]
            foreach paramName $paramNames {
                set paramNameVal [subst $$paramName]
                if {([llength $paramNameVal]>1) && ([lindex $paramNameVal 1]=="-eq")} {
                    lappend paramList "$paramName [lindex $paramNameVal 0] -poseq"
                } else {
                    lappend paramList "$paramName $paramNameVal -pos"
                }
            }
            dict for {paramName value} $arguments {
                if {([llength $value]>1) && ([lindex $value 1]=="-eq")} {
                    lappend paramList "$paramName [lindex $value 0] -poseq"
                } else {
                    lappend paramList "$paramName $value -pos"
                }
            }
            next $type$name [list "np $npNode" "nm $nmNode"] sffm $paramList
        }
        set def [info class definition SpiceGenTcl::Ngspice::Sources::pulse genSPICEString]
        method genSPICEString [lindex $def 0] [lindex $def 1]
        self unexport create new
    }      

    ## ________________________ am sources template class _________________________ ##
    
    oo::class create am {
        superclass SpiceGenTcl::DeviceModel
        constructor {name type npNode nmNode v0 va mf fc td args} {
            set arguments [argparse -inline {
                -phases=
            }]
            set paramNames [lrange [lindex [info class constructor [info object class [self]]] 0] 3 end-1]
            foreach paramName $paramNames {
                set paramNameVal [subst $$paramName]
                if {([llength $paramNameVal]>1) && ([lindex $paramNameVal 1]=="-eq")} {
                    lappend paramList "$paramName [lindex $paramNameVal 0] -poseq"
                } else {
                    lappend paramList "$paramName $paramNameVal -pos"
                }
            }
            dict for {paramName value} $arguments {
                if {([llength $value]>1) && ([lindex $value 1]=="-eq")} {
                    lappend paramList "$paramName [lindex $value 0] -poseq"
                } else {
                    lappend paramList "$paramName $value -pos"
                }
            }
            next $type$name [list "np $npNode" "nm $nmNode"] am $paramList
        }
        set def [info class definition SpiceGenTcl::Ngspice::Sources::pulse genSPICEString]
        method genSPICEString [lindex $def 0] [lindex $def 1]
        self unexport create new
    }   
    
    ## ________________________ Vdc class _________________________ ##
        
    oo::class create Vdc {
        superclass SpiceGenTcl::Ngspice::Sources::dc
        constructor {name npNode nmNode dcVal} {
            # Creates object of class `Vdc` that describes simple constant voltage source.
            #  name - name of the device without first-letter designator V
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  dcVal - value of constant voltage
            # ```
            # VYYYYYYY n+ n- <<DC> DC/TRAN VALUE>>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::Sources::Vdc new 1 netp netm 10
            # ```
            next $name v $npNode $nmNode $dcVal
        }
    }

    ## ________________________ Vac class _________________________ ##
    
    oo::class create Vac {
        superclass SpiceGenTcl::Ngspice::Sources::ac
        constructor {name npNode nmNode acMag args} {
            # Creates object of class `Vac` that describes ac voltage source.
            #  name - name of the device without first-letter designator V
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  acMag - value of ac voltage
            #  args - optional phase of ac voltage
            # ```
            # VYYYYYYY n+ n-  <AC <ACMAG <ACPHASE>>>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::Sources::Vac new 1 netp netm 10
            # ```
            set arguments [argparse {
                -acphase=
            }]
            if {[info exists acphase]} {
                next $name v $npNode $nmNode $acMag -acphase $acphase
            } else {
                next $name v $npNode $nmNode $acMag
            }
        }
    }
    
    ## ________________________ Vpulse class _________________________ ##

    oo::class create Vpulse {
        superclass SpiceGenTcl::Ngspice::Sources::pulse
        constructor {name npNode nmNode low high td tr tf pw per args} {
            # Creates object of class `Vpulse` that describes pulse voltage source.
            #  name - name of the device without first-letter designator V
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  low - initial value
            #  high - pulsed value
            #  td - delay time
            #  tr - rise time
            #  pw - pulse width
            #  per - period
            #  args - option argument -np: number of pulses
            # ```
            # VYYYYYYY n+ n- PULSE(V1 V2 TD TR TF PW PER NP)
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::Sources::Vpulse new 1 net1 net2 0 1 {td -eq} 1e-9 1e-9 10e-6 20e-6 -np {np -eq}
            # ```
            set arguments [argparse {
                -np=
            }]
            if {[info exists np]} {
                next $name v $npNode $nmNode $low $high $td $tr $tf $pw $per -np $np
            } else {
                next $name v $npNode $nmNode $low $high $td $tr $tf $pw $per
            }
        }
    }  
    
    ## ________________________ Vsin class _________________________ ##

    oo::class create Vsin {
        superclass SpiceGenTcl::Ngspice::Sources::sin
        mixin SpiceGenTcl::KeyArgsBuilder
        constructor {name npNode nmNode v0 va freq args} {
            # Creates object of class `Vsin` that describes sinusoidal voltage source.
            #  name - name of the device without first-letter designator V
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  v0 - initial value
            #  va - pulsed value
            #  freq - delay time
            #  args - optional arguments -td: delay, -theta: damping factor, -phase: phase
            # ```
            # VYYYYYYY n+ n- SIN(VO VA FREQ TD THETA PHASE)
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::Sources::Vsin new 1 net1 net2 0 2 50 -td 1e-6 -phase {phase -eq}
            # ```
            set paramDefList [my buildArgStr [list td theta phase]]
            set arguments [argparse -inline "
                $paramDefList
            "]            
            dict for {paramName value} $arguments {
                if {([llength $value]>1) && ([lindex $value 1]=="-eq")} {
                    lappend paramList "-$paramName" "[lindex $value 0] -poseq"
                } else {
                    lappend paramList "-$paramName" "$value"
                }
            }
            if {[info exists paramList]} {
                next $name v $npNode $nmNode $v0 $va $freq {*}$paramList
            } else {
                next $name v $npNode $nmNode $v0 $va $freq
            }
        }
    }
    
    ## ________________________ Vexp class _________________________ ##

    oo::class create Vexp {
        superclass SpiceGenTcl::Ngspice::Sources::exp
        constructor {name npNode nmNode v1 v2 td1 tau1 td2 tau2} {
            # Creates object of class `Vexp` that describes exponential voltage source.
            #  name - name of the device without first-letter designator V
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  v1 - initial value
            #  v2 - pulsed value
            #  td1 - rise delay time
            #  tau1 - rise time constant
            #  td2 - fall delay time
            #  tau2 - fall time constant
            # ```
            # VYYYYYYY n+ n- EXP(V1 V2 TD1 TAU1 TD2 TAU2)
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::Sources::Vexp new 1 net1 net2 0 1 1e-9 1e-9 {td2 -eq} 10e-6
            # ```
            next $name v $npNode $nmNode $v1 $v2 $td1 $tau1 $td2 $tau2
        }
    }
    
    ## ________________________ Vpwl class _________________________ ##

    oo::class create Vpwl {
        superclass SpiceGenTcl::Ngspice::Sources::pwl
        constructor {name npNode nmNode pwlSeq} {
            # Creates object of class `Vpwl` that describes piece-wise voltage source.
            #  name - name of the device without first-letter designator V
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  pwlSeq - sequence of pwl points in form (t0 v0 t1 v1 t2 v2 t3 v3 ...)
            # ```
            # VYYYYYYY n+ n- PWL (T1 V1 <T2 V2 T3 V3 T4 V4 ...>)
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::Sources::Vpwl new 1 npNode nmNode {0 0 {t1 -eq} 1 2 2 3 3 4 4}
            # ```
            next $name v $npNode $nmNode $pwlSeq
        }
    }    
    
    ## ________________________ Vsffm class _________________________ ##

    oo::class create Vsffm {
        superclass SpiceGenTcl::Ngspice::Sources::sffm
        mixin SpiceGenTcl::KeyArgsBuilder
        constructor {name npNode nmNode v0 va fc mdi fs args} {
            # Creates object of class `Vsffm` that describes single-frequency FM voltage source.
            #  name - name of the device without first-letter designator V
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  v0 - initial value
            #  va - pulsed value
            #  fc - carrier frequency
            #  mdi - modulation index
            #  fs - signal frequency
            #  args - optional arguments -phasec: carrier phase, -phases: signal phase
            # ```
            # VYYYYYYY n+ n- SFFM(VO VA FC MDI FS PHASEC PHASES)
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::Sources::Vsin new 1 net1 net2 0 2 50 -td 1e-6 -phase {phase -eq}
            # ```
            set paramDefList [my buildArgStr [list phasec phases]]
            set arguments [argparse -inline "
                $paramDefList
            "]    
            dict for {paramName value} $arguments {
                if {([llength $value]>1) && ([lindex $value 1]=="-eq")} {
                    lappend paramList "-$paramName" "[lindex $value 0] -poseq"
                } else {
                    lappend paramList "-$paramName" "$value"
                }
            }
            if {[info exists paramList]} {
                next $name v $npNode $nmNode $v0 $va $fc $mdi $fs {*}$paramList
            } else {
                next $name v $npNode $nmNode $v0 $va $fc $mdi $fs
            }
        }
    }
    
    ## ________________________ Vam class _________________________ ##

    oo::class create Vam {
        superclass SpiceGenTcl::Ngspice::Sources::am
        constructor {name npNode nmNode v0 va mf fc td args} {
            # Creates object of class `Vam` that describes single-frequency FM voltage source.
            #  name - name of the device without first-letter designator V
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  v0 - initial value
            #  va - pulsed value
            #  mf - modulating frequency
            #  fc - carrier frequency
            #  args - optional arguments -td: signal delay, -phases: phase
            # ```
            # VYYYYYYY n+ n- AM(VA VO MF FC TD PHASES)
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::Sources::Vam new 1 net1 net2 0 2 1e3 5e3 -phase {phase -eq}
            # ```
            set arguments [argparse -inline {
                -phases=
            }]
            dict for {paramName value} $arguments {
                if {([llength $value]>1) && ([lindex $value 1]=="-eq")} {
                    lappend paramList "-$paramName" "[lindex $value 0] -poseq"
                } else {
                    lappend paramList "-$paramName" "$value"
                }
            }
            if {[info exists paramList]} {
                next $name v $npNode $nmNode $v0 $va $mf $fc $td {*}$paramList
            } else {
                next $name v $npNode $nmNode $v0 $va $mf $fc $td
            }
        }
    }    
    
    ## ________________________ Idc class _________________________ ##

    oo::class create Idc {
        superclass SpiceGenTcl::Ngspice::Sources::dc
        constructor {name npNode nmNode dcVal} {
            # Creates object of class `Idc` that describes simple constant current source.
            #  name - name of the device without first-letter designator V
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  dcVal - value of constant current
            # ```
            # IYYYYYYY n+ n- <<DC> DC/TRAN VALUE>>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::Sources::Idc new 1 netp netm 10 -acphase 45
            # ```
            next $name i $npNode $nmNode $dcVal
        }
    }

    ## ________________________ Iac class _________________________ ##

    oo::class create Iac {
        superclass SpiceGenTcl::Ngspice::Sources::ac
        constructor {name npNode nmNode acMag args} {
            # Creates object of class `Iac` that describes simple ac current source.
            #  name - name of the device without first-letter designator I
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  acMag - value of ac current
            #  args - optional phase of ac current
            # ```
            # IYYYYYYY n+ n-  <AC <ACMAG <ACPHASE>>>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::Sources::Iac new 1 netp netm 10 -acphase 45
            # ```
            set arguments [argparse {
                -acphase=
            }]
            if {[info exists acphase]} {
                next $name i $npNode $nmNode $acMag -acphase $acphase
            } else {
                next $name i $npNode $nmNode $acMag
            }
        }
    }
    

    ## ________________________ Ipulse class _________________________ ##

    oo::class create Ipulse {
        superclass SpiceGenTcl::Ngspice::Sources::pulse
        constructor {name npNode nmNode low high td tr tf pw per args} {
            # Creates object of class `Ipulse` that describes pulse current source.
            #  name - name of the device without first-letter designator I
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  low - initial value
            #  high - pulsed value
            #  td - delay time
            #  tr - rise time
            #  pw - pulse width
            #  per - period
            #  args - option argument -np: number of pulses
            # ```
            # IYYYYYYY n+ n- PULSE(V1 V2 TD TR TF PW PER NP)
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::Sources::Ipulse new 1 net1 net2 0 1 {td -eq} 1e-9 1e-9 10e-6 20e-6 -np {np -eq}
            # ```
            set arguments [argparse {
                -np=
            }]
            if {[info exists np]} {
                next $name i $npNode $nmNode $low $high $td $tr $tf $pw $per -np $np
            } else {
                next $name i $npNode $nmNode $low $high $td $tr $tf $pw $per
            }
        }
    }
    
    ## ________________________ Isin class _________________________ ##

    oo::class create Isin {
        superclass SpiceGenTcl::Ngspice::Sources::sin
        mixin SpiceGenTcl::KeyArgsBuilder
        constructor {name npNode nmNode v0 va freq args} {
            # Creates object of class `Isin` that describes sinusoidal current source.
            #  name - name of the device without first-letter designator I
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  v0 - initial value
            #  va - pulsed value
            #  freq - delay time
            #  args - optional arguments -td: delay, -theta: damping factor, -phase: phase
            # ```
            # IYYYYYYY n+ n- SIN(VO VA FREQ TD THETA PHASE)
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::Sources::Isin new 1 net1 net2 0 2 50 -td 1e-6 -phase {phase -eq}
            # ```
            set paramDefList [my buildArgStr [list td theta phase]]
            set arguments [argparse -inline "
                $paramDefList
            "]    
            dict for {paramName value} $arguments {
                if {([llength $value]>1) && ([lindex $value 1]=="-eq")} {
                    lappend paramList "-$paramName" "[lindex $value 0] -poseq"
                } else {
                    lappend paramList "-$paramName" "$value"
                }
            }
            if {[info exists paramList]} {
                next $name i $npNode $nmNode $v0 $va $freq {*}$paramList
            } else {
                next $name i $npNode $nmNode $v0 $va $freq
            }
        }
    }
    
    ## ________________________ Iexp class _________________________ ##

    oo::class create Iexp {
        superclass SpiceGenTcl::Ngspice::Sources::exp
        constructor {name npNode nmNode v1 v2 td1 tau1 td2 tau2} {
            # Creates object of class `Iexp` that describes exponential current source.
            #  name - name of the device without first-letter designator I
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  v1 - initial value
            #  v2 - pulsed value
            #  td1 - rise delay time
            #  tau1 - rise time constant
            #  td2 - fall delay time
            #  tau2 - fall time constant
            # ```
            # IYYYYYYY n+ n- EXP(V1 V2 TD1 TAU1 TD2 TAU2)
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::Sources::Iexp new 1 net1 net2 0 1 1e-9 1e-9 {td2 -eq} 10e-6
            # ```
            next $name i $npNode $nmNode $v1 $v2 $td1 $tau1 $td2 $tau2
        }
    }

    ## ________________________ Ipwl class _________________________ ##

    oo::class create Ipwl {
        superclass SpiceGenTcl::Ngspice::Sources::pwl
        constructor {name npNode nmNode pwlSeq} {
            # Creates object of class `Ipwl` that describes piece-wise linear current source.
            #  name - name of the device without first-letter designator I
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  pwlSeq - sequence of pwl points in form (t0 i0 t1 i1 t2 i2 t3 i3 ...)
            # ```
            # IYYYYYYY n+ n- PWL (T1 I1 <T2 I2 T3 I3 T4 I4 ...>)
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::Sources::Ipwl new 1 npNode nmNode {0 0 {t1 -eq} 1 2 2 3 3 4 4}
            # ```
            next $name i $npNode $nmNode $pwlSeq
        }
    }   
    
    ## ________________________ Isffm class _________________________ ##

    oo::class create Isffm {
        superclass SpiceGenTcl::Ngspice::Sources::sffm
        mixin SpiceGenTcl::KeyArgsBuilder
        constructor {name npNode nmNode v0 va fc mdi fs args} {
            # Creates object of class `Isffm` that describes single-frequency FM current source.
            #  name - name of the device without first-letter designator I
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  v0 - initial value
            #  va - pulsed value
            #  fc - carrier frequency
            #  mdi - modulation index
            #  fs - signal frequency
            #  args - optional arguments -phasec: carrier phase, -phases: signal phase
            # ```
            # IYYYYYYY n+ n- SFFM(VO VA FC MDI FS PHASEC PHASES)
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::Sources::Isin new 1 net1 net2 0 2 50 -td 1e-6 -phase {phase -eq}
            # ```
            set paramDefList [my buildArgStr [list phasec phases]]
            set arguments [argparse -inline "
                $paramDefList
            "]    
            dict for {paramName value} $arguments {
                if {([llength $value]>1) && ([lindex $value 1]=="-eq")} {
                    lappend paramList "-$paramName" "[lindex $value 0] -poseq"
                } else {
                    lappend paramList "-$paramName" "$value"
                }
            }
            if {[info exists paramList]} {
                next $name i $npNode $nmNode $v0 $va $fc $mdi $fs {*}$paramList
            } else {
                next $name i $npNode $nmNode $v0 $va $fc $mdi $fs
            }
        }
    }
        
    ## ________________________ Iam class _________________________ ##

    oo::class create Iam {
        superclass SpiceGenTcl::Ngspice::Sources::am
        constructor {name npNode nmNode v0 va mf fc td args} {
            # Creates object of class `Iam` that describes single-frequency AM current source.
            #  name - name of the device without first-letter designator I
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  v0 - initial value
            #  va - pulsed value
            #  mf - modulating frequency
            #  fc - carrier frequency
            #  td - signal delay
            #  args - optional argument -phases: phase
            # ```
            # IYYYYYYY n+ n- AM(VA VO MF FC TD PHASES)
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::Sources::Iam new 1 net1 net2 0 2 1e3 5e3 -phase {phase -eq}
            # ```
            set arguments [argparse -inline {
                -phases=
            }]
            dict for {paramName value} $arguments {
                if {([llength $value]>1) && ([lindex $value 1]=="-eq")} {
                    lappend paramList "-$paramName" "[lindex $value 0] -poseq"
                } else {
                    lappend paramList "-$paramName" "$value"
                }
            }
            if {[info exists paramList]} {
                next $name i $npNode $nmNode $v0 $va $mf $fc $td {*}$paramList
            } else {
                next $name i $npNode $nmNode $v0 $va $mf $fc $td
            }
        }
    }
    
    ## ________________________ Vccs class _________________________ ##
  
    oo::class create Vccs {
        superclass SpiceGenTcl::Device
        constructor {name npNode nmNode ncpNode ncmNode value args} {
            # Creates object of class `Vccs` that describes linear voltage-controlled current source.
            #  name - name of the device without first-letter designator G
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  ncpNode - name of node connected to positive controlling pin
            #  ncmNode - name of node connected to negative controlling pin
            #  value - transconductance 
            #  args - on or off state parameter, optional
            # ```
            # GXXXXXXX N+ N- NC+ NC- VALUE <m=val>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::Sources::Vccs new 1 net1 0 netc 0 10 -m 1
            # ```
            set arguments [argparse {
                -m=
            }]
            if {([llength $value]>1) && ([lindex $value 1]=="-eq")} {
                lappend paramList "trcond [lindex $value 0] -poseq"
            } else {
                lappend paramList "trcond $value -pos"
            }
            if {[info exists m]} {
                if {([llength $m]>1) && ([lindex $m 1]=="-eq")} {
                    lappend paramList "m [lindex $m 0] -eq"
                } else {
                    lappend paramList "m $m"
                }
            }
            next g$name [list "np $npNode" "nm $nmNode" "ncp $ncpNode" "ncm $ncmNode"] $paramList
        }
    }
    # alias for Vccs class
    oo::class create G {
        superclass Vccs
    }    

    ## ________________________ Vcvs class _________________________ ##
  
    oo::class create Vcvs {
        superclass SpiceGenTcl::Device
        constructor {name npNode nmNode ncpNode ncmNode value} {
            # Creates object of class `Vcvs` that describes linear voltage-controlled current source.
            #  name - name of the device without first-letter designator G
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  ncpNode - name of node connected to positive controlling pin
            #  ncmNode - name of node connected to negative controlling pin
            #  value - voltage gain 
            # ```
            # EXXXXXXX N+ N- NC+ NC- VALUE
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::Sources::Vcvs new 1 net1 0 netc 0 10
            # ```
            if {([llength $value]>1) && ([lindex $value 1]=="-eq")} {
                lappend paramList "vgain [lindex $value 0] -poseq"
            } else {
                lappend paramList "vgain $value -pos"
            }
            next e$name [list "np $npNode" "nm $nmNode" "ncp $ncpNode" "ncm $ncmNode"] $paramList
        }
    }
    # alias for Vcvs class
    oo::class create E {
        superclass Vcvs
    } 
    
    ## ________________________ Cccs class _________________________ ##
  
    oo::class create Cccs {
        superclass SpiceGenTcl::Device
        variable Vname
        constructor {name npNode nmNode vname value args} {
            # Creates object of class `Cccs` that describes linear current-controlled current source. 
            #  name - name of the device without first-letter designator F
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  vname - name of controlling source
            #  value - current gain 
            #  args - optional argument -m: parallel source multiplicator
            # ```
            # FXXXXXXX N+ N- VNAM VALUE <m=val>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::Sources::Cccs new 1 net1 0 netc 0 10
            # ```
            set arguments [argparse {
                -m=
            }]
            if {([llength $value]>1) && ([lindex $value 1]=="-eq")} {
                lappend paramList "igain [lindex $value 0] -poseq"
            } else {
                lappend paramList "igain $value -pos"
            }
            if {[info exists m]} {
                if {([llength $m]>1) && ([lindex $m 1]=="-eq")} {
                    lappend paramList "m [lindex $m 0] -eq"
                } else {
                    lappend paramList "m $m"
                }
            }
            set Vname [SpiceGenTcl::ParameterPositionalNoCheck new vname $vname]
            next f$name [list "np $npNode" "nm $nmNode"] $paramList
        }
        method genSPICEString {} {
            my variable Pins
            my variable Params
            dict for {pinName pin} $Pins {
                set error [catch {$pin genSPICEString} errStr] 
                if {$error!=1} {
                    lappend nodes [$pin genSPICEString]
                } else {
                    error "Device '[my getName]' can't be netlisted because '$pinName' pin is floating"
                }
            }
            dict for {paramName param} $Params {
                lappend params [$param genSPICEString]
            }
            return "[my getName] [join $nodes] [$Vname getValue] [join $params]"
        } 
    }
    # alias for Cccs class
    oo::class create F {
        superclass Cccs
    } 
        
    ## ________________________ Ccvs class _________________________ ##
  
    oo::class create Ccvs {
        superclass SpiceGenTcl::Device
        variable Vname
        constructor {name npNode nmNode vname value args} {
            # Creates object of class `Ccvs` that describes linear current-controlled current source.
            #  name - name of the device without first-letter designator H
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  vname - name of controlling source
            #  value - transresistance 
            # ```
            # HXXXXXXX N+ N- VNAM VALUE
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::Sources::Ccvs new 1 net1 0 vc 10
            # ```
            if {([llength $value]>1) && ([lindex $value 1]=="-eq")} {
                lappend paramList "tres [lindex $value 0] -poseq"
            } else {
                lappend paramList "tres $value -pos"
            }
            set Vname [SpiceGenTcl::ParameterPositionalNoCheck new vname $vname]
            next h$name [list "np $npNode" "nm $nmNode"] $paramList
        }
        method genSPICEString {} {
            my variable Pins
            my variable Params
            dict for {pinName pin} $Pins {
                set error [catch {$pin genSPICEString} errStr] 
                if {$error!=1} {
                    lappend nodes [$pin genSPICEString]
                } else {
                    error "Device '[my getName]' can't be netlisted because '$pinName' pin is floating"
                }
            }
            dict for {paramName param} $Params {
                lappend params [$param genSPICEString]
            }
            return "[my getName] [join $nodes] [$Vname getValue] [join $params]"
        } 
    }
    # alias for Ccvs class
    oo::class create H {
        superclass Ccvs
    } 
    
    ## ________________________ BehaviouralSource class _________________________ ##
    
    oo::class create BehaviouralSource {
        superclass SpiceGenTcl::Device
        mixin SpiceGenTcl::KeyArgsBuilder
        constructor {name npNode nmNode type expr args} {
            # Creates object of class `BehaviouralSource` that describes behavioural source.
            #  name - name of the device without first-letter designator R
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  rExpr - equation of resistance
            #  args - keyword instance parameters
            # ```
            # BXXXXXXX n+ n- <i=expr> <v=expr> <tc1=value> <tc2=value> <dtemp=value> <temp=value>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::Sources::BehaviouralSource new 1 netp netm i "V(a)+V(b)+pow(V(c),2)" -tc1 1
            # ```
            set paramsNames [list tc1 tc2 noisy temp dtemp]
            set paramDefList [my buildArgStr $paramsNames]
            set arguments [argparse -inline "
                $paramDefList
            "]    
            if {$type ni {i v I V}} {
                error "Type '$type' in 'b${name}' source not 'i' or 'v'"
            }
            lappend paramList "$type $expr -eq"
            dict for {paramName value} $arguments {
                lappend paramList "$paramName $value"
            }
            next b$name [list "np $npNode" "nm $nmNode"] $paramList
        }
    }

    # alias for BehaviouralSource class
    oo::class create B {
        superclass BehaviouralSource
    }
}
    # ________________________ SemiconductorDevices _________________________ #

namespace eval SpiceGenTcl::Ngspice::SemiconductorDevices {
    
    ## ________________________ Diode class _________________________ ##
    
    oo::class create Diode {
        superclass SpiceGenTcl::DeviceModel
        mixin SpiceGenTcl::KeyArgsBuilder
        constructor {name npNode nmNode modelName args} {
            # Creates object of class `Diode` that describes semiconductor diode device.
            #  name - name of the device without first-letter designator D
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  modelName - name of the model
            #  args - keyword instance parameters, for details please see Ngspice manual, 7 chapter.
            # ```
            # DXXXXXXX n+ n- mname <area=val> <m=val>
            # + <ic=vd> <temp=val> <dtemp=val>
            # + <lm=val> <wm=val> <lp=val> <wp=val> <pj=val>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::SemiconductorDevices::Diode new 1 netp netm diomod -l 1e-6 -w 10e-6
            # ```
            set paramsNames [list area pj ic temp dtemp lm wm lp wp]
            set paramDefList [my buildArgStr $paramsNames]
            set arguments [argparse -inline "
                $paramDefList
            "]    
            dict for {paramName value} $arguments {
                lappend paramList "$paramName $value"
            }
            if {[info exists paramList]} {
                next d$name [list "np $npNode" "nm $nmNode"] $modelName $paramList
            } else {
                next d$name [list "np $npNode" "nm $nmNode"] $modelName ""
            }
            
        }
    }
    # alias for Diode class
    oo::class create D {
        superclass Diode
    }
    
    ## ________________________ Bjt class _________________________ ##
    
    oo::class create Bjt {
        superclass SpiceGenTcl::DeviceModel
        mixin SpiceGenTcl::KeyArgsBuilder
        constructor {name ncNode nbNode neNode modelName args} {
            # Creates object of class `Bjt` that describes semiconductor bipolar junction transistor device.
            #  name - name of the device without first-letter designator Q
            #  ncNode - name of node connected to collector pin
            #  nbNode - name of node connected to base pin
            #  neNode - name of node connected to emitter pin
            #  modelName - name of the model
            #  args - keyword instance parameters, for details please see Ngspice manual, 8 chapter.
            # ```
            # QXXXXXXX nc nb ne mname <area=val> <areac=val>
            # + <areab=val> <m=val> <off> <ic=vbe , vce> <temp=val>
            # + <dtemp=val>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::SemiconductorDevices::Bjt new 1 netc netb nete bjtmod -area 1e-3
            # ```
            set paramsNames [list area areac areab m temp dtemp]
            set paramDefList [my buildArgStr $paramsNames]
            set arguments [argparse -inline "
                $paramDefList
            "]
            dict for {paramName value} $arguments {
                lappend paramList "$paramName $value"
            }
            if {[info exists paramList]} {
                next q$name [list "nc $ncNode" "nb $nbNode" "ne $neNode"] $modelName $paramList
            } else {
                next q$name [list "nc $ncNode" "nb $nbNode" "ne $neNode"] $modelName ""
            }
            
        }
    }
    # alias for Bjt class
    oo::class create Q {
        superclass Bjt
    }
    
    ## ________________________ BjtSub class _________________________ ##
    
    oo::class create BjtSub {
        superclass SpiceGenTcl::DeviceModel
        mixin SpiceGenTcl::KeyArgsBuilder
        constructor {name ncNode nbNode neNode nsNode modelName args} {
            # Creates object of class `BjtSub` that describes semiconductor bipolar junction transistor device with substrate pin.
            #  name - name of the device without first-letter designator Q
            #  ncNode - name of node connected to collector pin
            #  nbNode - name of node connected to base pin
            #  neNode - name of node connected to emitter pin
            #  nsNode - name of node connected to substrate pin
            #  modelName - name of the model
            #  args - keyword instance parameters, for details please see Ngspice manual, 8 chapter.
            # ```
            # QXXXXXXX nc nb ne ns mname <area=val> <areac=val>
            # + <areab=val> <m=val> <off> <ic=vbe , vce> <temp=val>
            # + <dtemp=val>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::SemiconductorDevices::Bjt new 1 netc netb nete bjtmod -area 1e-3
            # ```
            set paramsNames [list area areac areab m temp dtemp]
            set paramDefList [my buildArgStr $paramsNames]
            set arguments [argparse -inline "
                $paramDefList
            "]
            dict for {paramName value} $arguments {
                lappend paramList "$paramName $value"
            }
            if {[info exists paramList]} {
                next q$name [list "nc $ncNode" "nb $nbNode" "ne $neNode" "ns $nsNode"] $modelName $paramList
            } else {
                next q$name [list "nc $ncNode" "nb $nbNode" "ne $neNode" "ns $nsNode"] $modelName ""
            }
            
        }
    }
    # alias for BjtSub class
    oo::class create QSub {
        superclass BjtSub
    }
    
    ## ________________________ BjtSubTj class _________________________ ##
    
    oo::class create BjtSubTj {
        superclass SpiceGenTcl::DeviceModel
        mixin SpiceGenTcl::KeyArgsBuilder
        constructor {name ncNode nbNode neNode nsNode tjNode modelName args} {
            # Creates object of class `BjtSubTj` that describes semiconductor bipolar junction transistor device with substrate pin and thermal pin.
            #  name - name of the device without first-letter designator Q
            #  ncNode - name of node connected to collector pin
            #  nbNode - name of node connected to base pin
            #  neNode - name of node connected to emitter pin
            #  nsNode - name of node connected to substrate pin
            #  tjNode - name of node connected to thermal pin
            #  modelName - name of the model
            #  args - keyword instance parameters, for details please see Ngspice manual, 8 chapter.
            # ```
            # QXXXXXXX nc nb ne ns tj mname <area=val> <areac=val>
            # + <areab=val> <m=val> <off> <ic=vbe , vce> <temp=val>
            # + <dtemp=val>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::SemiconductorDevices::Bjt new 1 netc netb nete nettj bjtmod -area 1e-3
            # ```
            set paramsNames [list area areac areab m temp dtemp]
            set paramDefList [my buildArgStr $paramsNames]
            set arguments [argparse -inline "
                $paramDefList
            "]
            dict for {paramName value} $arguments {
                lappend paramList "$paramName $value"
            }
            if {[info exists paramList]} {
                next q$name [list "nc $ncNode" "nb $nbNode" "ne $neNode" "ns $nsNode" "tj $tjNode"] $modelName $paramList
            } else {
                next q$name [list "nc $ncNode" "nb $nbNode" "ne $neNode" "ns $nsNode" "tj $tjNode"] $modelName ""
            }
        }
    }
    # alias for BjtSubTj class
    oo::class create QSubTj {
        superclass BjtSubTj
    }
    
    ## ________________________ Jfet class _________________________ ##
    
    oo::class create Jfet {
        superclass SpiceGenTcl::DeviceModel
        mixin SpiceGenTcl::KeyArgsBuilder
        constructor {name ndNode ngNode nsNode modelName args} {
            # Creates object of class `Jfet` that describes semiconductor junction FET device.
            #  name - name of the device without first-letter designator J
            #  ndNode - name of node connected to drain pin
            #  ngNode - name of node connected to gate pin
            #  nsNode - name of node connected to source pin
            #  modelName - name of the model
            #  args - keyword instance parameters, for details please see Ngspice manual, 9 chapter.
            # ```
            # JXXXXXXX nd ng ns mname <area> <temp=t>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::SemiconductorDevices::J new 1 netd netg nets jfetmod -area {area*2 -eq} -temp 25
            # ```
            set paramsNames [list area temp]
            set paramDefList [my buildArgStr $paramsNames]
            set arguments [argparse -inline "
                $paramDefList
            "]
            dict for {paramName value} $arguments {
                if {$paramName=="area"} {
                    if {[lindex $value 1]=="-eq"} {
                        lappend paramList "area [lindex $value 0] -poseq"
                    } else {
                        lappend paramList "area [lindex $value 0] -pos"
                    }
                    
                } else {
                    lappend paramList "$paramName $value"
                }
            }
            if {[info exists paramList]} {
                next j$name [list "nd $ndNode" "ng $ngNode" "ns $nsNode"] $modelName $paramList
            } else {
                next j$name [list "nd $ndNode" "ng $ngNode" "ns $nsNode"] $modelName ""
            }
            
        }
    }
    # alias for Jfet class
    oo::class create J {
        superclass Jfet
    }
    
    ## ________________________ Mesfet class _________________________ ##
    
    oo::class create Mesfet {
        superclass SpiceGenTcl::DeviceModel
        mixin SpiceGenTcl::KeyArgsBuilder
        constructor {name ndNode ngNode nsNode modelName args} {
            # Creates object of class `Mesfet` that describes semiconductor MESFET device.
            #  name - name of the device without first-letter designator Z
            #  ndNode - name of node connected to drain pin
            #  ngNode - name of node connected to gate pin
            #  nsNode - name of node connected to source pin
            #  modelName - name of the model
            #  args - keyword instance parameters, for details please see Ngspice manual, 10 chapter.
            # ```
            # ZXXXXXXX ND NG NS MNAME <AREA>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::SemiconductorDevices::J new 1 netd netg nets jfetmod -area {area*2 -eq} -temp 25
            # ```
            set paramsNames [list area]
            set paramDefList [my buildArgStr $paramsNames]
            set arguments [argparse -inline "
                $paramDefList
            "]
            dict for {paramName value} $arguments {
                if {$paramName=="area"} {
                    if {[lindex $value 1]=="-eq"} {
                        lappend paramList "area [lindex $value 0] -poseq"
                    } else {
                        lappend paramList "area [lindex $value 0] -pos"
                    }
                    
                } else {
                    lappend paramList "$paramName $value"
                }
            }
            if {[info exists paramList]} {
                next z$name [list "nd $ndNode" "ng $ngNode" "ns $nsNode"] $modelName $paramList
            } else {
                next z$name [list "nd $ndNode" "ng $ngNode" "ns $nsNode"] $modelName ""
            }
            
        }
    }
    # alias for Mesfet class
    oo::class create Z {
        superclass Mesfet
    }   
 
    ## ________________________ Mosfet class _________________________ ##
    
    oo::class create Mosfet {
        superclass SpiceGenTcl::DeviceModel
        mixin SpiceGenTcl::KeyArgsBuilder
        constructor {name ndNode ngNode nsNode nbNode modelName args} {
            # Creates object of class `Mosfet` that describes semiconductor MOSFET device.
            #  name - name of the device without first-letter designator M
            #  ndNode - name of node connected to drain pin
            #  ngNode - name of node connected to gate pin
            #  nsNode - name of node connected to source pin
            #  nbNode - name of node connected to source pin
            #  modelName - name of the model
            #  args - keyword instance parameters, for details please see Ngspice manual, 10 chapter.
            # ```
            # MXXXXXXX nd ng ns nb mname <m=val> <l=val> <w=val>
            # + <ad=val> <as=val> <pd=val> <ps=val> <nrd=val>
            # + <nrs=val> <temp=t>
            # ```
            # Example of class initialization:
            # ```
            # SpiceGenTcl::Ngspice::SemiconductorDevices::J new 1 netd netg nets jfetmod -area {area*2 -eq} -temp 25
            # ```
            set paramsNames [list m l w ad as pd ps nrd nrs]
            set paramDefList [my buildArgStr $paramsNames]
            set arguments [argparse -inline "
                $paramDefList
            "]
            dict for {paramName value} $arguments { 
                lappend paramList "$paramName $value"
            }
            if {[info exists paramList]} {
                next m$name [list "nd $ndNode" "ng $ngNode" "ns $nsNode" "nb $nbNode"] $modelName $paramList
            } else {
                next m$name [list "nd $ndNode" "ng $ngNode" "ns $nsNode" "nb $nbNode"] $modelName ""
            }
            
        }
    }
    # alias for Mosfet class
    oo::class create M {
        superclass Mosfet
    }    
}



