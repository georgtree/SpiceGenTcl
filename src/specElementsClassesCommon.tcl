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
        namespace export Resistor R Capacitor C Inductor L SubcircuitInstance X SubcircuitInstanceAuto XAuto \
                VSwitch VSw CSwitch W
    }
    namespace eval Common::Sources {
        namespace export Vdc Idc Vac Iac Vpulse Ipulse Vsin Isin Vexp Iexp Vpwl Ipwl Vsffm Isffm Vccs G \
                Vcvs E Cccs F Ccvs H
    }
}



###  Basic devices 

namespace eval ::SpiceGenTcl::Common::BasicDevices {

    
####  Resistor class 

    oo::class create Resistor {
        superclass ::SpiceGenTcl::Device
        constructor {name npNode nmNode args} {
            # Creates object of class `Resistor` that describes resistor.
            #  name - name of the device without first-letter designator R
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  -r - resistance value
            #  -m - multiplier value, optional
            #  -temp - device temperature, optional, optional
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
            set arguments [argparse -inline {
                {-r= -required}
                -m=
                -temp=
                -tc1=
                -tc2=
            }]
            set rVal [dget $arguments r]
            if {([llength $rVal]>1) && ([@ $rVal 1]=="-eq")} {
                lappend params "r [@ $rVal 0] -poseq"
            } else {
                lappend params "r $rVal -pos"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {r}} {
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
        constructor {name npNode nmNode args} {
            # Creates object of class `Capacitor` that describes capacitor.
            #  name - name of the device without first-letter designator C
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
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
            set arguments [argparse -inline {
                {-c= -required}
                -m=
                -temp=
                -tc1=
                -tc2=
                -ic=
            }]
            set cVal [dget $arguments c]
            if {([llength $cVal]>1) && ([@ $cVal 1]=="-eq")} {
                lappend params "c [@ $cVal 0] -poseq"
            } else {
                lappend params "c $cVal -pos"
            }
            
            dict for {paramName value} $arguments {
                if {$paramName ni {c}} {
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
            set arguments [argparse -inline {
                {-l= -required}
                -m= 
                -temp=
                -tc1=
                -tc2=
            }]
            set lVal [dget $arguments l]
            if {([llength $lVal]>1) && ([@ $lVal 1]=="-eq")} {
                lappend params "l [@ $lVal 0] -poseq"
            } else {
                lappend params "l $lVal -pos"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {l}} {
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
            # ::SpiceGenTcl::Common::BasicDevices::SubcircuitInstance new 1 {{plus net1} {minus net2}} rcnet {{r 1} {c cpar -eq}}
            # ```
            set params [linsert $params 0 "model $subName -posnocheck"]
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
            lappend params "model [dget $arguments model] -posnocheck"
            if {[dexist $arguments on]} {
                lappend params {on -sw}
            } elseif {[dexist $arguments off]} {
                lappend params {off -sw}
            }
            next s$name [list "np $npNode" "nm $nmNode" "ncp $ncpNode" "ncm $ncmNode"] $params
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
            lappend params "icntrl [dget $arguments icntrl] -posnocheck"
            lappend params "model [dget $arguments model] -posnocheck"
            if {[dexist $arguments on]} {
                lappend params {on -sw}
            } elseif {[dexist $arguments off]} {
                lappend params {off -sw}
            }
            next w$name [list "np $npNode" "nm $nmNode"] $params
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
            
            # check that inputs object class is Subcircuit
            if {[info object class $subcktObj "::SpiceGenTcl::Subcircuit"]!=1} {
                set objClass [info object class $subcktObj]
                error "Wrong object class '$objClass' is passed as subcktObj, should be '::SpiceGenTcl::Subcircuit'"
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
        constructor {name type npNode nmNode args} {
            set arguments [argparse -inline {
                {-dc= -required}
            }]
            set dcVal [dget $arguments dc]
            if {([llength $dcVal]>1) && ([@ $dcVal 1]=="-eq")} {
                lappend params "dc [@ $dcVal 0] -poseq"
            } else {
                lappend params "dc $dcVal -pos"
            }
            next $type$name [list "np $npNode" "nm $nmNode"] $params
        }
    }

####  ac sources template class 

    oo::abstract create ac {
        superclass ::SpiceGenTcl::Device
        constructor {name type npNode nmNode args} {
            set arguments [argparse -inline {
                {-ac= -required}
                -acphase=
            }]
            set acVal [dget $arguments ac]
            lappend params "ac -sw"
            if {([llength $acVal]>1) && ([@ $acVal 1]=="-eq")} {
                lappend params "acval [@ $acVal 0] -poseq"
            } else {
                lappend params "acval $acVal -pos"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {ac}} {
                    if {([llength $value]>1) && ([@ $value 1]=="-eq")} {
                        lappend params "$paramName [@ $value 0] -poseq"
                    } else {
                        lappend params "$paramName $value -pos"
                    }
                }
            }
            next $type$name [list "np $npNode" "nm $nmNode"] $params
        }
    }   
    
####  pulse sources template class 
    
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
            }]
            set paramsOrder [list low high td tr tf pw per]
            foreach param $paramsOrder {
                if {[dexist $arguments $param]} {
                    dict append argsOrdered $param [dget $arguments $param]
                }
            }
            lappend params "model pulse -posnocheck"
            dict for {paramName value} $argsOrdered {
                if {([llength $value]>1) && ([@ $value 1]=="-eq")} {
                    lappend params "$paramName [@ $value 0] -poseq"
                } else {
                    lappend params "$paramName $value -pos"
                }
            }
            next $type$name [list "np $npNode" "nm $nmNode"] $params
        }
    } 
    
####  sin sources template class 
    
    oo::abstract create sin {
        superclass ::SpiceGenTcl::Device
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
                if {[dexist $arguments $param]} {
                    dict append argsOrdered $param [dget $arguments $param]
                }
            }
            lappend params "model sin -posnocheck"
            dict for {paramName value} $argsOrdered {
                if {([llength $value]>1) && ([@ $value 1]=="-eq")} {
                    lappend params "$paramName [@ $value 0] -poseq"
                } else {
                    lappend params "$paramName $value -pos"
                }
            }
            next $type$name [list "np $npNode" "nm $nmNode"] $params
        }
    }  
    
####  exp sources template class 
    
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
                if {[dexist $arguments $param]} {
                    dict append argsOrdered $param [dget $arguments $param]
                }
            }
            lappend params "model exp -posnocheck"
            dict for {paramName value} $argsOrdered {
                if {([llength $value]>1) && ([@ $value 1]=="-eq")} {
                    lappend params "$paramName [@ $value 0] -poseq"
                } else {
                    lappend params "$paramName $value -pos"
                }
            }
            next $type$name [list "np $npNode" "nm $nmNode"] $params
        }
    }    
    
####  pwl sources template class 
    
    oo::abstract create pwl {
        superclass ::SpiceGenTcl::Device
        constructor {name type npNode nmNode args} {
            set arguments [argparse -inline {
                {-seq= -required}
            }]
            set pwlSeqVal [dget $arguments seq]
            set pwlSeqLen [llength $pwlSeqVal]
            if {$pwlSeqLen%2} {
                return -code error "Number of elements '$pwlSeqLen' in pwl sequence is odd in element '$type$name', must\
                        be even"
            } elseif {$pwlSeqLen<4} {
                return -code error "Number of elements '$pwlSeqLen' in pwl sequence in element '$type$name' must be >=4"
            }
            # parse pwlSeq argument
            for {set i 0} {$i<[llength $pwlSeqVal]/2} {incr i} {
                set 2i [* 2 $i]
                set 2ip1 [+ $2i 1]
                lappend params "t$i [list [@ $pwlSeqVal $2i]]" "$type$i [list [@ $pwlSeqVal $2ip1]]"
            }
            foreach param $params {
                if {([llength [@ $param 1]]>1) && ([@ [@ $param 1] 1]=="-eq")} {
                    lappend paramList "[@ $param 0] [@ [@ $param 1] 0] -poseq"
                } else {
                    lappend paramList "[@ $param 0] [@ $param 1] -pos"
                }
            }
            set paramList [linsert $paramList 0 "model pwl -posnocheck"]
            next $type$name [list "np $npNode" "nm $nmNode"] $paramList
        }
    }

####  sffm sources template class 
    
    oo::abstract create sffm {
        superclass ::SpiceGenTcl::Device
        constructor {name type npNode nmNode args} {
            set arguments [argparse -inline {
                {-v0= -required}
                {-va= -required}
                {-fc= -required}
                {-mdi= -required}
                {-fs= -required}
            }]
            set paramsOrder [list v0 va fc mdi fs]
            foreach param $paramsOrder {
                if {[dexist $arguments $param]} {
                    dict append argsOrdered $param [dget $arguments $param]
                }
            }
            lappend params "model sffm -posnocheck"
            dict for {paramName value} $argsOrdered {
                if {([llength $value]>1) && ([@ $value 1]=="-eq")} {
                    lappend params "$paramName [@ $value 0] -poseq"
                } else {
                    lappend params "$paramName $value -pos"
                }
            }
            next $type$name [list "np $npNode" "nm $nmNode"] $params
        }
    }      
    
####  Vdc class 
        
    oo::class create Vdc {
        superclass ::SpiceGenTcl::Common::Sources::dc
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
            # ::SpiceGenTcl::Common::Sources::Vdc new 1 netp netm -dc 10
            # ```
            next $name v $npNode $nmNode {*}$args
        }
    }

####  Vac class 
    
    oo::class create Vac {
        superclass ::SpiceGenTcl::Common::Sources::ac
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
            # ::SpiceGenTcl::Common::Sources::Vac new 1 netp netm -ac 10 -acphase 45
            # ```
            next $name v $npNode $nmNode {*}$args

        }
    }
    
####  Vpulse class 

    oo::class create Vpulse {
        superclass ::SpiceGenTcl::Common::Sources::pulse
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
            # ```
            # VYYYYYYY n+ n- PULSE(V1 V2 TD TR TF PW PER)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Sources::Vpulse new 1 net1 net2 -low 0 -high 1 -td {td -eq} -tr 1e-9 -tf 1e-9 -pw 10e-6 -per 20e-6
            # ```
            next $name v $npNode $nmNode {*}$args
        }
    }  
    
####  Vsin class 

    oo::class create Vsin {
        superclass ::SpiceGenTcl::Common::Sources::sin
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
            # ::SpiceGenTcl::Common::Sources::Vsin new 1 net1 net2 -v0 0 -va 2 -freq {freq -eq} -td 1e-6 -theta {theta -eq}
            # ```
            next $name v $npNode $nmNode {*}$args
        }
    }
    
####  Vexp class 

    oo::class create Vexp {
        superclass ::SpiceGenTcl::Common::Sources::exp
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
            # ::SpiceGenTcl::Common::Sources::Vexp new 1 net1 net2 -v1 0 -v2 1 -td1 1e-9 -tau1 1e-9 -td2 {td2 -eq} -tau2 10e-6
            # ```
            next $name v $npNode $nmNode {*}$args
        }
    }
    
####  Vpwl class 

    oo::class create Vpwl {
        superclass ::SpiceGenTcl::Common::Sources::pwl
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
            # ::SpiceGenTcl::Common::Sources::Vpwl new 1 npNode nmNode -seq {0 0 {t1 -eq} 1 2 2 3 3 4 4}
            # ```
            next $name v $npNode $nmNode {*}$args
        }
    }    
    
####  Vsffm class 

    oo::class create Vsffm {
        superclass ::SpiceGenTcl::Common::Sources::sffm
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
            # ```
            # VYYYYYYY n+ n- SFFM(VO VA FC MDI FS)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Sources::Vsin new 1 net1 net2 -v0 0 -va 1 -fc {freq -eq} -mdi 0 -fs 1e3
            # ```
            next $name v $npNode $nmNode {*}$args
        }
    }
       
    
####  Idc class 

    oo::class create Idc {
        superclass ::SpiceGenTcl::Common::Sources::dc
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
            # ::SpiceGenTcl::Common::Sources::Idc new 1 netp netm -dc 10
            # ```
            next $name i $npNode $nmNode {*}$args
        }
    }

####  Iac class 

    oo::class create Iac {
        superclass ::SpiceGenTcl::Common::Sources::ac
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
            # ::SpiceGenTcl::Common::Sources::Iac new 1 netp netm -ac 10 -acphase 45
            next $name i $npNode $nmNode {*}$args
        }
    }
    

####  Ipulse class 

    oo::class create Ipulse {
        superclass ::SpiceGenTcl::Common::Sources::pulse
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
            # ```
            # IYYYYYYY n+ n- PULSE(V1 V2 TD TR TF PW PER)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Sources::Ipulse new 1 net1 net2 -low 0 -high 1 -td {td -eq} -tr 1e-9 -tf 1e-9 -pw 10e-6 -per 20e-6
            # ```
            next $name i $npNode $nmNode {*}$args
        }
    }
    
####  Isin class 

    oo::class create Isin {
        superclass ::SpiceGenTcl::Common::Sources::sin
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
            # ::SpiceGenTcl::Common::Sources::Isin new 1 net1 net2 -v0 0 -va 2 -freq {freq -eq} -td 1e-6 -theta {theta -eq}
            # ```
            next $name i $npNode $nmNode {*}$args
        }
    }
    
####  Iexp class 

    oo::class create Iexp {
        superclass ::SpiceGenTcl::Common::Sources::exp
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
            # ::SpiceGenTcl::Common::Sources::Iexp new 1 net1 net2 -v1 0 -v2 1 -td1 1e-9 -tau1 1e-9 -td2 {td2 -eq} -tau2 10e-6
            # ```
            next $name i $npNode $nmNode {*}$args
        }
    }

####  Ipwl class 

    oo::class create Ipwl {
        superclass ::SpiceGenTcl::Common::Sources::pwl
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
            # ::SpiceGenTcl::Common::Sources::Ipwl new 1 npNode nmNode -seq {0 0 {t1 -eq} 1 2 2 3 3 4 4}
            # ```
            next $name i $npNode $nmNode {*}$args
        }
    }   
    
####  Isffm class 

    oo::class create Isffm {
        superclass ::SpiceGenTcl::Common::Sources::sffm
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
            # ```
            # IYYYYYYY n+ n- SFFM(VO VA FC MDI FS)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Common::Sources::Isin new 1 net1 net2 -v0 0 -va 1 -fc {freq -eq} -mdi 0 -fs 1e3
            # ```
            next $name i $npNode $nmNode {*}$args
        }
    }

####  Vccs class 
  
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
            # ::SpiceGenTcl::Common::Sources::Vccs new 1 net1 0 netc 0 -trcond 10 -m 1
            # ```
            set arguments [argparse -inline {
                {-trcond -required}
                -m=
            }]
            set trcondVal [dget $arguments trcond]
            if {([llength $trcondVal]>1) && ([@ $trcondVal 1]=="-eq")} {
                lappend params "trcond [@ $trcondVal 0] -poseq"
            } else {
                lappend params "trcond $trcondVal -pos"
            }
            if {[dexist $arguments m]} {
                set mVal [dget $arguments m]
                if {([llength $mVal]>1) && ([@ $mVal 1]=="-eq")} {
                    lappend params "m [@ $mVal 0] -eq"
                } else {
                    lappend params "m $mVal"
                }
            }
            next g$name [list "np $npNode" "nm $nmNode" "ncp $ncpNode" "ncm $ncmNode"] $params
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
            # ::SpiceGenTcl::Common::Sources::Vcvs new 1 net1 0 netc 0 -gain 10
            # ```
            set arguments [argparse -inline {
                {-gain -required}
            }]
            set gainVal [dget $arguments gain]
            if {([llength $gainVal]>1) && ([@ $gainVal 1]=="-eq")} {
                lappend params "vgain [@ $gainVal 0] -poseq"
            } else {
                lappend params "vgain $gainVal -pos"
            }
            next e$name [list "np $npNode" "nm $nmNode" "ncp $ncpNode" "ncm $ncmNode"] $params
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
            # ::SpiceGenTcl::Common::Sources::Cccs new 1 net1 0 netc 0 -consrc vc -gain 10 -m 1
            # ```
            set arguments [argparse -inline {
                {-consrc -required}
                {-gain -required}
                -m=
            }]
            set consrcVal [dget $arguments consrc]
            lappend params "consrc $consrcVal -posnocheck"
            set gainVal [dget $arguments gain]
            if {([llength $gainVal]>1) && ([@ $gainVal 1]=="-eq")} {
                lappend params "igain [@ $gainVal 0] -poseq"
            } else {
                lappend params "igain $gainVal -pos"
            }
            if {[dexist $arguments m]} {
                set mVal [dget $arguments m]
                if {([llength $mVal]>1) && ([@ $mVal 1]=="-eq")} {
                    lappend params "m [@ $mVal 0] -eq"
                } else {
                    lappend params "m $mVal"
                }
            }
            next f$name [list "np $npNode" "nm $nmNode"] $params
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
            # ::SpiceGenTcl::Common::Sources::Ccvs new 1 net1 0 -consrc vc -transr {tres -eq}
            # ```
            set arguments [argparse -inline {
                {-consrc -required}
                {-transr -required}
            }]
            set consrcVal [dget $arguments consrc]
            lappend params "consrc $consrcVal -posnocheck"
            set transrVal [dget $arguments transr]
            if {([llength $transrVal]>1) && ([@ $transrVal 1]=="-eq")} {
                lappend params "transr [@ $transrVal 0] -poseq"
            } else {
                lappend params "transr $transrVal -pos"
            }
            next h$name [list "np $npNode" "nm $nmNode"] $params
        }
    }

####  H class 
    
    # alias for Ccvs class
    oo::class create H {
        superclass Ccvs
    } 
    
}



