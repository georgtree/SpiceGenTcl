
namespace eval ::SpiceGenTcl {
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

namespace eval ::SpiceGenTcl::Ngspice::BasicDevices {

    ## ________________________ resistor classes _________________________ ##
    
    ### ________________________ Resistor class _________________________ ###

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
            # RXXXXXXX n+ n- R ={expression} <tc1=value> <tc2=value> <noisy=0>
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
            set params ""
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
            if {[dict exists $arguments model]} {
                lappend params "model [dict get $arguments model] -posnocheck"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {r beh model}} {
                    lappend params "$paramName $value"
                }
            }
            next r$name [list "np $npNode" "nm $nmNode"] $params
        }
    }
    ### ________________________ R class _________________________ ###
    # alias for Resistor class
    oo::class create R {
        superclass Resistor
    }

    ## ________________________ capacitor classes _________________________ ##

    ### ________________________ Capacitor class _________________________ ###

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
            # CXXXXXXX n+ n- <value> <mname> <m=val> <scale=val> <temp=val>
            # + <dtemp=val> <tc1=val> <tc2=val> <ic=init_condition>
            # ```
            # Example of class initialization as a simple capacitor:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::Capacitor new 1 netp netm 1e-6 -tc1 1 -temp {temp -eq}
            # ```
            # Behavioral capacitor with C expression:
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
            set params ""
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
            if {[dict exists $arguments model]} {
                lappend params "model [dict get $arguments model] -posnocheck"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {c q beh model}} {
                    lappend params "$paramName $value"
                }
            }
            next c$name [list "np $npNode" "nm $nmNode"] $params
        }
    }
    ### ________________________ C class _________________________ ###
    # alias for Capacitor class
    oo::class create C {
        superclass Capacitor
    }

    ## ________________________ inductor classes _________________________ ##

    ### ________________________ Inductor class _________________________ ###

    oo::class create Inductor {
        superclass ::SpiceGenTcl::Device
        mixin ::SpiceGenTcl::KeyArgsBuilder
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
            }]
            set params ""
            if {[dict exists $arguments l]} {
                set lVal [dict get $arguments l]
                if {[dict exists $arguments beh]} {
                    lappend params "l $lVal -eq"
                } elseif {([llength $lVal]>1) && ([lindex $lVal 1]=="-eq")} {
                    lappend params "l [lindex $lVal 0] -poseq"
                } else {
                    lappend params "l $lVal -pos"
                }
            } elseif {[dict exists $arguments model]==0} {
                error "Inductor value must be specified with '-l value'"
            }
            if {[dict exists $arguments model]} {
                lappend params "model [dict get $arguments model] -posnocheck"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {l beh model}} {
                    lappend params "$paramName $value"
                }
            }
            next l$name [list "np $npNode" "nm $nmNode"] $params
            
        }
    }
    
    ### ________________________ L class _________________________ ###
    
    # alias for Inductor class
    oo::class create L {
        superclass Inductor
    }    
    
    ## ________________________ VSwitch class _________________________ ##
  
    oo::class create VSwitch {
        superclass ::SpiceGenTcl::Device
        constructor {name npNode nmNode ncpNode ncmNode args} {
            # Creates object of class `VSwitch` that describes voltage controlled switch device.
            #  name - name of the device without first-letter designator S
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  ncpNode - name of node connected to positive controlling pin
            #  ncmNode - name of node connected to negative controlling pin
            #  -model - model name
            #  -on/-off - initial state of switch
            # ```
            # SXXXXXXX N+ N- NC+ NC- MODEL <ON> <OFF>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::BasicDevices::VSwitch new 1 net1 0 netc 0 -model sw1 -on
            # ```
            set arguments [argparse -inline {
                {-model= -required}
                {-on -forbid {off}}
                {-off -forbid {on}}
            }]
            lappend params "model [dict get $arguments model] -posnocheck"
            if {[dict exists $arguments on]} {
                lappend params {on -sw}
            } elseif {[dict exists $arguments off]} {
                lappend params {off -sw}
            }
            next s$name [list "np $npNode" "nm $nmNode" "ncp $ncpNode" "ncm $ncmNode"] $params
        }
    }
    # alias for VSwitch class
    oo::class create VSw {
        superclass VSwitch
    }    
    
    ## ________________________ CSwitch class _________________________ ##
  
    oo::class create CSwitch {
        superclass ::SpiceGenTcl::Device
        # special positional parameter that is placed before model name
        variable CControlParam
        constructor {name npNode nmNode args} {
            # Creates object of class `CSwitch` that describes current controlled switch device.
            #  name - name of the device without first-letter designator W
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
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
            set arguments [argparse -inline {
                {-icntrl= -required}
                {-model= -required}
                {-on -forbid {off}}
                {-off -forbid {on}}
            }]
            lappend params "icntrl [dict get $arguments icntrl] -posnocheck"
            lappend params "model [dict get $arguments model] -posnocheck"
            if {[dict exists $arguments on]} {
                lappend params {on -sw}
            } elseif {[dict exists $arguments off]} {
                lappend params {off -sw}
            }
            next w$name [list "np $npNode" "nm $nmNode"] $params
        }
    }
    # alias for CSwitch class
    oo::class create CSw {
        superclass CSwitch
    }
    
    ## ________________________ SubcircuitInstance class _________________________ ##

    oo::class create SubcircuitInstance {
        superclass ::SpiceGenTcl::DeviceModel
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
            # ::SpiceGenTcl::Ngspice::BasicDevices::SubcircuitInstance new 1 {{plus net1} {minus net2}} rcnet {{r 1} {c cpar -eq}}
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
        superclass ::SpiceGenTcl::DeviceModel
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
            # ::SpiceGenTcl::Ngspice::BasicDevices::SubcircuitInstanceAuto new $subcktObj 1 {net1 net2} -r 1 -c {cpar -eq}
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

namespace eval ::SpiceGenTcl::Ngspice::Sources {

    ## ________________________ dc sources template class _________________________ ##
    
    oo::abstract create dc {
        superclass ::SpiceGenTcl::Device
        constructor {name type npNode nmNode args} {
            set arguments [argparse -inline {
                {-dc= -required}
            }]
            set dcVal [dict get $arguments dc]
            if {([llength $dcVal]>1) && ([lindex $dcVal 1]=="-eq")} {
                lappend params "dc [lindex $dcVal 0] -poseq"
            } else {
                lappend params "dc $dcVal -pos"
            }
            next $type$name [list "np $npNode" "nm $nmNode"] $params
        }
    }

    ## ________________________ ac sources template class _________________________ ##

    oo::abstract create ac {
        superclass ::SpiceGenTcl::Device
        constructor {name type npNode nmNode args} {
            set arguments [argparse -inline {
                {-ac= -required}
                -acphase=
            }]
            set acVal [dict get $arguments ac]
            lappend params "ac -sw"
            if {([llength $acVal]>1) && ([lindex $acVal 1]=="-eq")} {
                lappend params "acval [lindex $acVal 0] -poseq"
            } else {
                lappend params "acval $acVal -pos"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {ac}} {
                    if {([llength $value]>1) && ([lindex $value 1]=="-eq")} {
                        lappend params "$paramName [lindex $value 0] -poseq"
                    } else {
                        lappend params "$paramName $value -pos"
                    }
                }
            }
            next $type$name [list "np $npNode" "nm $nmNode"] $params
        }
    }   
    
    ## ________________________ pulse sources template class _________________________ ##
    
    oo::abstract create pulse {
        superclass ::SpiceGenTcl::Device
        constructor {name type npNode nmNode args} {
            set arguments [argparse -inline {
                {-low= -required}
                {-high= -required}
                {-td= -required}
                {-tr= -required}
                {-tf= -required}
                {-pw= -required}
                {-per= -required}
                -np=
            }]
            set paramsOrder [list low high td tr tf pw per np]
            foreach param $paramsOrder {
                if {[dict exists $arguments $param]} {
                    dict append argsOrdered $param [dict get $arguments $param]
                }
            }
            lappend params "model pulse -posnocheck"
            dict for {paramName value} $argsOrdered {
                if {([llength $value]>1) && ([lindex $value 1]=="-eq")} {
                    lappend params "$paramName [lindex $value 0] -poseq"
                } else {
                    lappend params "$paramName $value -pos"
                }
            }
            next $type$name [list "np $npNode" "nm $nmNode"] $params
        }
    } 
    
    ## ________________________ sin sources template class _________________________ ##
    
    oo::abstract create sin {
        superclass ::SpiceGenTcl::Device
        mixin ::SpiceGenTcl::KeyArgsBuilder
        constructor {name type npNode nmNode args} {
            set arguments [argparse -inline {
                {-v0= -required}
                {-va= -required}
                {-freq= -required}
                -td=
                {-theta= -require {td}}
                {-phase= -require {td theta}}
            }]
            set paramsOrder [list v0 va freq td theta phase]
            foreach param $paramsOrder {
                if {[dict exists $arguments $param]} {
                    dict append argsOrdered $param [dict get $arguments $param]
                }
            }
            lappend params "model sin -posnocheck"
            dict for {paramName value} $argsOrdered {
                if {([llength $value]>1) && ([lindex $value 1]=="-eq")} {
                    lappend params "$paramName [lindex $value 0] -poseq"
                } else {
                    lappend params "$paramName $value -pos"
                }
            }
            next $type$name [list "np $npNode" "nm $nmNode"] $params
        }
    }  
    
    ## ________________________ exp sources template class _________________________ ##
    
    oo::abstract create exp {
        superclass ::SpiceGenTcl::Device
        constructor {name type npNode nmNode args} {
            set arguments [argparse -inline {
                {-v1= -required}
                {-v2= -required}
                {-td1= -required}
                {-tau1= -required}
                {-td2= -required}
                {-tau2= -required}
            }]
            set paramsOrder [list v1 v2 td1 tau1 td2 tau2]
            foreach param $paramsOrder {
                if {[dict exists $arguments $param]} {
                    dict append argsOrdered $param [dict get $arguments $param]
                }
            }
            lappend params "model exp -posnocheck"
            dict for {paramName value} $argsOrdered {
                if {([llength $value]>1) && ([lindex $value 1]=="-eq")} {
                    lappend params "$paramName [lindex $value 0] -poseq"
                } else {
                    lappend params "$paramName $value -pos"
                }
            }
            next $type$name [list "np $npNode" "nm $nmNode"] $params
        }
    }    
    
    ## ________________________ pwl sources template class _________________________ ##
    
    oo::abstract create pwl {
        superclass ::SpiceGenTcl::Device
        constructor {name type npNode nmNode args} {
            set arguments [argparse -inline {
                {-seq= -required}
            }]
            set pwlSeqVal [dict get $arguments seq]
            set pwlSeqLen [llength $pwlSeqVal]
            if {$pwlSeqLen%2} {
                error "Number of elements '$pwlSeqLen' in pwl sequence is odd in element '$type$name', must be even"
            } elseif {$pwlSeqLen<4} {
                error "Number of elements '$pwlSeqLen' in pwl sequence in element '$type$name' must be >=4"
            }
            # parse pwlSeq argument
            for {set i 0} {$i<[llength $pwlSeqVal]/2} {incr i} {
                set 2i [* 2 $i]
                set 2ip1 [+ $2i 1]
                lappend params "t$i [list [lindex $pwlSeqVal $2i]]" "$type$i [list [lindex $pwlSeqVal $2ip1]]"
            }
            foreach param $params {
                if {([llength [lindex $param 1]]>1) && ([lindex [lindex $param 1] 1]=="-eq")} {
                    lappend paramList "[lindex $param 0] [lindex [lindex $param 1] 0] -poseq"
                } else {
                    lappend paramList "[lindex $param 0] [lindex $param 1] -pos"
                }
            }
            set paramList [linsert $paramList 0 "model pwl -posnocheck"]
            next $type$name [list "np $npNode" "nm $nmNode"] $paramList
        }
    }

    ## ________________________ sffm sources template class _________________________ ##
    
    oo::abstract create sffm {
        superclass ::SpiceGenTcl::Device
        mixin ::SpiceGenTcl::KeyArgsBuilder
        constructor {name type npNode nmNode args} {
            set arguments [argparse -inline {
                {-v0= -required}
                {-va= -required}
                {-fc= -required}
                {-mdi= -required}
                {-fs= -required}
                -phasec=
                {-phases= -require {phasec}}
            }]
            set paramsOrder [list v0 va fc mdi fs phasec phases]
            foreach param $paramsOrder {
                if {[dict exists $arguments $param]} {
                    dict append argsOrdered $param [dict get $arguments $param]
                }
            }
            lappend params "model sffm -posnocheck"
            dict for {paramName value} $argsOrdered {
                if {([llength $value]>1) && ([lindex $value 1]=="-eq")} {
                    lappend params "$paramName [lindex $value 0] -poseq"
                } else {
                    lappend params "$paramName $value -pos"
                }
            }
            next $type$name [list "np $npNode" "nm $nmNode"] $params
        }
    }      

    ## ________________________ am sources template class _________________________ ##
    
    oo::abstract create am {
        superclass ::SpiceGenTcl::Device
        constructor {name type npNode nmNode args} {
            set arguments [argparse -inline {
                {-v0= -required}
                {-va= -required}
                {-mf= -required}
                {-fc= -required}
                {-td= -required}
                -phases=
            }]
            set paramsOrder [list v0 va mf fc td phases]
            foreach param $paramsOrder {
                if {[dict exists $arguments $param]} {
                    dict append argsOrdered $param [dict get $arguments $param]
                }
            }
            lappend params "model am -posnocheck"
            dict for {paramName value} $argsOrdered {
                if {([llength $value]>1) && ([lindex $value 1]=="-eq")} {
                    lappend params "$paramName [lindex $value 0] -poseq"
                } else {
                    lappend params "$paramName $value -pos"
                }
            }
            next $type$name [list "np $npNode" "nm $nmNode"] $params
        }
    }   
    
    ## ________________________ Vdc class _________________________ ##
        
    oo::class create Vdc {
        superclass ::SpiceGenTcl::Ngspice::Sources::dc
        constructor {name npNode nmNode args} {
            # Creates object of class `Vdc` that describes simple constant voltage source.
            #  name - name of the device without first-letter designator V
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -dc - DC voltage value
            # ```
            # VYYYYYYY n+ n- <<DC> DC/TRAN VALUE>>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Vdc new 1 netp netm -dc 10
            # ```
            next $name v $npNode $nmNode {*}$args
        }
    }

    ## ________________________ Vac class _________________________ ##
    
    oo::class create Vac {
        superclass ::SpiceGenTcl::Ngspice::Sources::ac
        constructor {name npNode nmNode args} {
            # Creates object of class `Vac` that describes ac voltage source.
            #  name - name of the device without first-letter designator V
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -dc - AC voltage value
            #  -acphase - phase of AC voltage
            # ```
            # VYYYYYYY n+ n- <AC<ACMAG<ACPHASE>>>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Vac new 1 netp netm -ac 10 -acphase 45
            # ```
            next $name v $npNode $nmNode {*}$args

        }
    }
    
    ## ________________________ Vpulse class _________________________ ##

    oo::class create Vpulse {
        superclass ::SpiceGenTcl::Ngspice::Sources::pulse
        constructor {name npNode nmNode args} {
            # Creates object of class `Vpulse` that describes pulse voltage source.
            #  name - name of the device without first-letter designator V
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
            # ```
            # VYYYYYYY n+ n- PULSE(V1 V2 TD TR TF PW PER NP)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Vpulse new 1 net1 net2 -low 0 -high 1 -td {td -eq} -tr 1e-9 -tf 1e-9 -pw 10e-6 -per 20e-6 -np {np -eq}
            # ```
            next $name v $npNode $nmNode {*}$args
        }
    }  
    
    ## ________________________ Vsin class _________________________ ##

    oo::class create Vsin {
        superclass ::SpiceGenTcl::Ngspice::Sources::sin
        mixin ::SpiceGenTcl::KeyArgsBuilder
        constructor {name npNode nmNode args} {
            # Creates object of class `Vsin` that describes sinusoidal voltage source.
            #  name - name of the device without first-letter designator V
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -v0 - DC shift value
            #  -va - amplitude value
            #  -freq - frequency of sinusoidal signal
            #  -td - time delay, optional
            #  -theta - damping factor, optional, require -td
            #  -phase - phase of signal, optional, require -td and -phase
            # ```
            # VYYYYYYY n+ n- SIN(VO VA FREQ TD THETA PHASE)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Vsin new 1 net1 net2 -v0 0 -va 2 -freq {freq -eq} -td 1e-6 -theta {theta -eq}
            # ```
            next $name v $npNode $nmNode {*}$args
        }
    }
    
    ## ________________________ Vexp class _________________________ ##

    oo::class create Vexp {
        superclass ::SpiceGenTcl::Ngspice::Sources::exp
        constructor {name npNode nmNode args} {
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
            # ```
            # VYYYYYYY n+ n- EXP(V1 V2 TD1 TAU1 TD2 TAU2)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Vexp new 1 net1 net2 -v1 0 -v2 1 -td1 1e-9 -tau1 1e-9 -td2 {td2 -eq} -tau2 10e-6
            # ```
            next $name v $npNode $nmNode {*}$args
        }
    }
    
    ## ________________________ Vpwl class _________________________ ##

    oo::class create Vpwl {
        superclass ::SpiceGenTcl::Ngspice::Sources::pwl
        constructor {name npNode nmNode args} {
            # Creates object of class `Vpwl` that describes piece-wise voltage source.
            #  name - name of the device without first-letter designator V
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -seq - sequence of pwl points in form {t0 v0 t1 v1 t2 v2 t3 v3 ...}
            # ```
            # VYYYYYYY n+ n- PWL (T1 V1 <T2 V2 T3 V3 T4 V4 ...>)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Vpwl new 1 npNode nmNode -seq {0 0 {t1 -eq} 1 2 2 3 3 4 4}
            # ```
            next $name v $npNode $nmNode {*}$args
        }
    }    
    
    ## ________________________ Vsffm class _________________________ ##

    oo::class create Vsffm {
        superclass ::SpiceGenTcl::Ngspice::Sources::sffm
        mixin ::SpiceGenTcl::KeyArgsBuilder
        constructor {name npNode nmNode args} {
            # Creates object of class `Vsffm` that describes single-frequency FM voltage source.
            #  name - name of the device without first-letter designator V
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -v0 - initial value
            #  -va - pulsed value
            #  -fc - carrier frequency
            #  -mdi - modulation index
            #  -fs - signal frequency
            #  -phasec - carrier phase, optional
            #  -phases - signal phase, optional, require -phasec
            # ```
            # VYYYYYYY n+ n- SFFM(VO VA FC MDI FS PHASEC PHASES)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Vsin new 1 net1 net2 -v0 0 -va 1 -fc {freq -eq} -mdi 0 -fs 1e3 -phasec {phase -eq}
            # ```
            next $name v $npNode $nmNode {*}$args
        }
    }
    
    ## ________________________ Vam class _________________________ ##

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
            # ```
            # VYYYYYYY n+ n- AM(VA VO MF FC TD PHASES)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Vam new 1 net1 net2 -v0 0 -va 2 -mf 1e3 -fc {freq -eq} -td 1e-6 -phases {phase -eq}
            # ```
            next $name v $npNode $nmNode {*}$args
        }
    }    
    
    ## ________________________ Idc class _________________________ ##

    oo::class create Idc {
        superclass ::SpiceGenTcl::Ngspice::Sources::dc
        constructor {name npNode nmNode args} {
            # Creates object of class `Idc` that describes simple constant voltage source.
            #  name - name of the device without first-letter designator I
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -dc - DC voltage value
            # ```
            # IYYYYYYY n+ n- <<DC> DC/TRAN VALUE>>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Idc new 1 netp netm -dc 10
            # ```
            next $name i $npNode $nmNode {*}$args
        }
    }

    ## ________________________ Iac class _________________________ ##

    oo::class create Iac {
        superclass ::SpiceGenTcl::Ngspice::Sources::ac
        constructor {name npNode nmNode args} {
            # Creates object of class `Iac` that describes ac current source.
            #  name - name of the device without first-letter designator I
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -dc - AC current value
            #  -acphase - phase of AC current
            # ```
            # IYYYYYYY n+ n- <AC<ACMAG<ACPHASE>>>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Iac new 1 netp netm -ac 10 -acphase 45
            next $name i $npNode $nmNode {*}$args
        }
    }
    

    ## ________________________ Ipulse class _________________________ ##

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
            # ```
            # IYYYYYYY n+ n- PULSE(V1 V2 TD TR TF PW PER NP)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Ipulse new 1 net1 net2 -low 0 -high 1 -td {td -eq} -tr 1e-9 -tf 1e-9 -pw 10e-6 -per 20e-6 -np {np -eq}
            # ```
            next $name i $npNode $nmNode {*}$args
        }
    }
    
    ## ________________________ Isin class _________________________ ##

    oo::class create Isin {
        superclass ::SpiceGenTcl::Ngspice::Sources::sin
        mixin ::SpiceGenTcl::KeyArgsBuilder
        constructor {name npNode nmNode args} {
            # Creates object of class `Isin` that describes sinusoidal current source.
            #  name - name of the device without first-letter designator I
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -v0 - DC shift value
            #  -va - amplitude value
            #  -freq - frequency of sinusoidal signal
            #  -td - time delay, optional
            #  -theta - damping factor, optional, require -td
            #  -phase - phase of signal, optional, require -td and -phase
            # ```
            # IYYYYYYY n+ n- SIN(VO VA FREQ TD THETA PHASE)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Isin new 1 net1 net2 -v0 0 -va 2 -freq {freq -eq} -td 1e-6 -theta {theta -eq}
            # ```
            next $name i $npNode $nmNode {*}$args
        }
    }
    
    ## ________________________ Iexp class _________________________ ##

    oo::class create Iexp {
        superclass ::SpiceGenTcl::Ngspice::Sources::exp
        constructor {name npNode nmNode args} {
            # Creates object of class `Iexp` that describes exponential current source.
            #  name - name of the device without first-letter designator I
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -v1 - initial value
            #  -v2 - pulsed value
            #  -td1 - rise delay time
            #  -tau1 - rise time constant
            #  -td2 - fall delay time
            #  -tau2 - fall time constant
            # ```
            # IYYYYYYY n+ n- EXP(V1 V2 TD1 TAU1 TD2 TAU2)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Iexp new 1 net1 net2 -v1 0 -v2 1 -td1 1e-9 -tau1 1e-9 -td2 {td2 -eq} -tau2 10e-6
            # ```
            next $name i $npNode $nmNode {*}$args
        }
    }

    ## ________________________ Ipwl class _________________________ ##

    oo::class create Ipwl {
        superclass ::SpiceGenTcl::Ngspice::Sources::pwl
        constructor {name npNode nmNode args} {
            # Creates object of class `Ipwl` that describes piece-wise current source.
            #  name - name of the device without first-letter designator I
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -seq - sequence of pwl points in form {t0 v0 t1 v1 t2 v2 t3 v3 ...}
            # ```
            # IYYYYYYY n+ n- PWL (T1 V1 <T2 V2 T3 V3 T4 V4 ...>)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Ipwl new 1 npNode nmNode -seq {0 0 {t1 -eq} 1 2 2 3 3 4 4}
            # ```
            next $name i $npNode $nmNode {*}$args
        }
    }   
    
    ## ________________________ Isffm class _________________________ ##

    oo::class create Isffm {
        superclass ::SpiceGenTcl::Ngspice::Sources::sffm
        mixin ::SpiceGenTcl::KeyArgsBuilder
        constructor {name npNode nmNode args} {
            # Creates object of class `Isffm` that describes single-frequency FM current source.
            #  name - name of the device without first-letter designator I
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -v0 - initial value
            #  -va - pulsed value
            #  -fc - carrier frequency
            #  -mdi - modulation index
            #  -fs - signal frequency
            #  -phasec - carrier phase, optional
            #  -phases - signal phase, optional, require -phasec
            # ```
            # IYYYYYYY n+ n- SFFM(VO VA FC MDI FS PHASEC PHASES)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Isin new 1 net1 net2 -v0 0 -va 1 -fc {freq -eq} -mdi 0 -fs 1e3 -phasec {phase -eq}
            # ```
            next $name i $npNode $nmNode {*}$args
        }
    }
        
    ## ________________________ Iam class _________________________ ##

    oo::class create Iam {
        superclass ::SpiceGenTcl::Ngspice::Sources::am
        constructor {name npNode nmNode args} {
            # Creates object of class `Iam` that describes single-frequency FM current source.
            #  name - name of the device without first-letter designator I
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -v0 - initial value
            #  -va - pulsed value
            #  -mf - modulating frequency
            #  -fc - carrier frequency
            #  -td - signal delay, optional
            #  -phases - phase, optional, require -td
            # ```
            # IYYYYYYY n+ n- AM(VA VO MF FC TD PHASES)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Iam new 1 net1 net2 -v0 0 -va 2 -mf 1e3 -fc {freq -eq} -td 1e-6 -phases {phase -eq}
            # ```
            next $name i $npNode $nmNode {*}$args
        }
    }
    
    ## ________________________ Vccs class _________________________ ##
  
    oo::class create Vccs {
        superclass ::SpiceGenTcl::Device
        constructor {name npNode nmNode ncpNode ncmNode args} {
            # Creates object of class `Vccs` that describes linear voltage-controlled current source.
            #  name - name of the device without first-letter designator G
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  ncpNode - name of node connected to positive controlling pin
            #  ncmNode - name of node connected to negative controlling pin
            #  -trcond - transconductance
            #  -m - multiplier factor, optional
            # ```
            # GXXXXXXX N+ N- NC+ NC- VALUE <m=val>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Vccs new 1 net1 0 netc 0 -trcond 10 -m 1
            # ```
            set arguments [argparse -inline {
                {-trcond -required}
                -m=
            }]
            set trcondVal [dict get $arguments trcond]
            if {([llength $trcondVal]>1) && ([lindex $trcondVal 1]=="-eq")} {
                lappend params "trcond [lindex $trcondVal 0] -poseq"
            } else {
                lappend params "trcond $trcondVal -pos"
            }
            if {[dict exists $arguments m]} {
                set mVal [dict get $arguments m]
                if {([llength $mVal]>1) && ([lindex $mVal 1]=="-eq")} {
                    lappend params "m [lindex $mVal 0] -eq"
                } else {
                    lappend params "m $mVal"
                }
            }
            next g$name [list "np $npNode" "nm $nmNode" "ncp $ncpNode" "ncm $ncmNode"] $params
        }
    }
    # alias for Vccs class
    oo::class create G {
        superclass Vccs
    }    

    ## ________________________ Vcvs class _________________________ ##
  
    oo::class create Vcvs {
        superclass ::SpiceGenTcl::Device
        constructor {name npNode nmNode ncpNode ncmNode args} {
            # Creates object of class `Vcvs` that describes linear voltage-controlled current source.
            #  name - name of the device without first-letter designator G
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  ncpNode - name of node connected to positive controlling pin
            #  ncmNode - name of node connected to negative controlling pin
            #  -gain - voltage gain 
            # ```
            # EXXXXXXX N+ N- NC+ NC- VALUE
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Vcvs new 1 net1 0 netc 0 -gain 10
            # ```
            set arguments [argparse -inline {
                {-gain -required}
            }]
            set gainVal [dict get $arguments gain]
            if {([llength $gainVal]>1) && ([lindex $gainVal 1]=="-eq")} {
                lappend params "vgain [lindex $gainVal 0] -poseq"
            } else {
                lappend params "vgain $gainVal -pos"
            }
            next e$name [list "np $npNode" "nm $nmNode" "ncp $ncpNode" "ncm $ncmNode"] $params
        }
    }
    # alias for Vcvs class
    oo::class create E {
        superclass Vcvs
    } 
    
    ## ________________________ Cccs class _________________________ ##
  
    oo::class create Cccs {
        superclass ::SpiceGenTcl::Device
        constructor {name npNode nmNode args} {
            # Creates object of class `Cccs` that describes linear current-controlled current source. 
            #  name - name of the device without first-letter designator F
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -consrc - name of controlling source
            #  -gain - current gain 
            #  -m - parallel source multiplicator
            # ```
            # FXXXXXXX N+ N- VNAM VALUE <m=val>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Cccs new 1 net1 0 netc 0 -consrc vc -gain 10 -m 1
            # ```
            set arguments [argparse -inline {
                {-consrc -required}
                {-gain -required}
                -m=
            }]
            set consrcVal [dict get $arguments consrc]
            lappend params "consrc $consrcVal -posnocheck"
            set gainVal [dict get $arguments gain]
            if {([llength $gainVal]>1) && ([lindex $gainVal 1]=="-eq")} {
                lappend params "igain [lindex $gainVal 0] -poseq"
            } else {
                lappend params "igain $gainVal -pos"
            }
            if {[dict exists $arguments m]} {
                set mVal [dict get $arguments m]
                if {([llength $mVal]>1) && ([lindex $mVal 1]=="-eq")} {
                    lappend params "m [lindex $mVal 0] -eq"
                } else {
                    lappend params "m $mVal"
                }
            }
            next f$name [list "np $npNode" "nm $nmNode"] $params
        } 
    }
    # alias for Cccs class
    oo::class create F {
        superclass Cccs
    } 
        
    ## ________________________ Ccvs class _________________________ ##
  
    oo::class create Ccvs {
        superclass ::SpiceGenTcl::Device
        constructor {name npNode nmNode args} {
            # Creates object of class `Ccvs` that describes linear current-controlled current source.
            #  name - name of the device without first-letter designator H
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -consrc - name of controlling source
            #  -transr - transresistance 
            # ```
            # HXXXXXXX N+ N- VNAM VALUE
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::Ccvs new 1 net1 0 -consrc vc -transr {tres -eq}
            # ```
            set arguments [argparse -inline {
                {-consrc -required}
                {-transr -required}
            }]
            set consrcVal [dict get $arguments consrc]
            lappend params "consrc $consrcVal -posnocheck"
            set transrVal [dict get $arguments transr]
            if {([llength $transrVal]>1) && ([lindex $transrVal 1]=="-eq")} {
                lappend params "transr [lindex $transrVal 0] -poseq"
            } else {
                lappend params "transr $transrVal -pos"
            }
            next h$name [list "np $npNode" "nm $nmNode"] $params
        }
    }
    # alias for Ccvs class
    oo::class create H {
        superclass Ccvs
    } 
    
    ## ________________________ BehaviouralSource class _________________________ ##
    
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
            # ```
            # BXXXXXXX n+ n- <i=expr> <v=expr> <tc1=value> <tc2=value> <dtemp=value> <temp=value>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Sources::BehaviouralSource new 1 netp netm -v "V(a)+V(b)+pow(V(c),2)" -tc1 1
            # ```
            set arguments [argparse -inline {
                {-i= -forbid {v}}
                {-v= -forbid {i}}
                -tc1=
                -tc2=
                -noisy=
                {-temp= -forbid {dtemp}}
                {-dtemp= -forbid {temp}}
            }]
            if {[dict exists $arguments i]} {
                lappend params "i [dict get $arguments i] -eq"
            } elseif {[dict exists $arguments v]} {
                lappend params "v [dict get $arguments v] -eq"
            } else {
                error "Equation must be specified as argument to -i or -v"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {i v}} {
                    lappend params "$paramName $value"
                }
            }
            next b$name [list "np $npNode" "nm $nmNode"] $params
        }
    }

    # alias for BehaviouralSource class
    oo::class create B {
        superclass BehaviouralSource
    }
}
    # ________________________ SemiconductorDevices _________________________ #

namespace eval ::SpiceGenTcl::Ngspice::SemiconductorDevices {
    
    ## ________________________ Diode class _________________________ ##
    
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
            # ```
            # DXXXXXXX n+ n- mname <area=val> <m=val>
            # + <ic=vd> <temp=val> <dtemp=val>
            # + <lm=val> <wm=val> <lp=val> <wp=val> <pj=val>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::SemiconductorDevices::Diode new 1 netp netm -model diomod -l 1e-6 -w 10e-6
            # ```
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
            }]
            lappend params "model [dict get $arguments model] -posnocheck"
            dict for {paramName value} $arguments {
                if {$paramName ni {model}} {
                    lappend params "$paramName $value"
                }
            }
            next d$name [list "np $npNode" "nm $nmNode"] $params
        }
    }
    # alias for Diode class
    oo::class create D {
        superclass Diode
    }
    
    ## ________________________ Bjt class _________________________ ##
    
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
            # ```
            # QXXXXXXX nc nb ne <ns> <tj> mname <area=val> <areac=val>
            # + <areab=val> <m=val> <off> <ic=vbe,vce> <temp=val>
            # + <dtemp=val>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::SemiconductorDevices::Bjt new 1 netc netb nete -model bjtmod -ns nets -area 1e-3
            # ```
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
            }]            
            lappend params "model [dict get $arguments model] -posnocheck"
            if {[dict exists $arguments ic]} {
                lappend params "ic [join [dict get $arguments ic] ,] -nocheck"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {model ns tj ic}} {
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
    }
    # alias for Bjt class
    oo::class create Q {
        superclass Bjt
    }
    
    ## ________________________ Jfet class _________________________ ##
    
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
            set arguments [argparse -inline {
                {-model= -required}
                -area=
                {-off -boolean}
                {-ic= -validate {[llength $arg]==2}}
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
            if {[dict get $arguments off]==1} {
                lappend params "off -sw"
            }
            if {[dict exists $arguments ic]} {
                lappend params "ic [join [dict get $arguments ic] ,] -nocheck"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {model area off ic}} {
                    lappend params "$paramName $value"
                }
            }
            next j$name [list "nd $ndNode" "ng $ngNode" "ns $nsNode"] $params
        }
    }
    # alias for Jfet class
    oo::class create J {
        superclass Jfet
    }
    
    ## ________________________ Mesfet class _________________________ ##
    
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
            # ZXXXXXXX ND NG NS MNAME <AREA> <OFF> <IC=VDS,VGS >
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::SemiconductorDevices::Mesfet new 1 netd netg nets -model mesfetmod -area {area*2 -eq}
            # ```
            set arguments [argparse -inline {
                {-model= -required}
                -area=
                {-off -boolean}
                {-ic= -validate {[llength $arg]==2}}
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
            if {[dict get $arguments off]==1} {
                lappend params "off -sw"
            }
            if {[dict exists $arguments ic]} {
                lappend params "ic [join [dict get $arguments ic] ,] -nocheck"
            }
            next z$name [list "nd $ndNode" "ng $ngNode" "ns $nsNode"] $params
            
        }
    }
    # alias for Mesfet class
    oo::class create Z {
        superclass Mesfet
    }   
 
    ## ________________________ Mosfet class _________________________ ##
    
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
            # MXXXXXXX nd ng ns nb mname <m=val> <l=val> <w=val>
            # + <ad=val> <as=val> <pd=val> <ps=val> <nrd=val>
            # + <nrs=val> <off> <ic=vds,vgs,vbs> <temp=t>
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ngspice::Mosfet new 1 netd netg nets -model mosfetmod -l 1e-6 -w 10e-3 -n4 netsub -n5 net5
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
                {-off -boolean}
                {-ic= -validate {[llength $arg]==3}}
                -n4=
                {-n5= -require {n4}}
                {-n6= -require {n5}}
                {-n7= -require {n7}}
                {-custparams -catchall}
            }]
            lappend params "model [dict get $arguments model] -posnocheck"
            if {[dict get $arguments off]==1} {
                lappend params "off -sw"
            }
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
    # alias for Mosfet class
    oo::class create M {
        superclass Mosfet
    }    
}



