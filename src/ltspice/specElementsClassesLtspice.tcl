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
        namespace export Resistor R  Capacitor \
                C Inductor L \
                SubcircuitInstance X SubcircuitInstanceAuto XAuto \
                VSwitch VSw CSwitch W 
    }
    namespace eval Ltspice::Sources {
        namespace export Vdc Idc Vac Iac Vpulse Ipulse Vsin Isin Vexp Iexp Vpwl Ipwl Vsffm Isffm Vam Iam Vccs G \
                Vcvs E Cccs F Ccvs H BehaviouralSource B Vport
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
        constructor {name npNode nmNode args} {
            # Creates object of class `Capacitor` that describes capacitor. 
            #  name - name of the device without first-letter designator C
            #  npNode - name of node connected to positive pin
            #  nmNode - name of node connected to negative pin
            #  args - keyword instance parameters
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
            set arguments [argparse -inline {
                {-c= -forbid q}
                {-q= -forbid c}
                -m=
                {-temp= -forbid q}
                -ic=
                -rser=
                -lser=
                -rpar=
                -cpar=
                -rlshunt=
            }]
            set params ""
            if {[dexist $arguments c]} {
                set cVal [dget $arguments c]
                if {([llength $cVal]>1) && ([@ $cVal 1] eq "-eq")} {
                    lappend params "c [@ $cVal 0] -poseq"
                } else {
                    lappend params "c $cVal -pos"
                }
            } elseif {![dexist $arguments q]} {
                return -code error "Capacitor value must be specified with '-c value'"
            }
            if {[dexist $arguments q]} {
                set qVal [dget $arguments q]
                lappend params "q $qVal -eq"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {c q}} {
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
                {-l= -forbid {flux hyst}}
                {-flux= -forbid {l hyst}}
                {-hyst -forbid {l flux} -reciprocal -require {hc br bs lm lg a n}}
                -m=
                -ic=
                -temp=
                -tc1=
                -tc2=
                -rser=
                -rpar=
                -cpar=
                -hc=
                -br=
                -bs=
                -lm=
                -lg=
                -a=
                -n=
            }]
            set params ""
            if {[dexist $arguments l]} {
                set lVal [dget $arguments l]
                if {([llength $lVal]>1) && ([@ $lVal 1] eq "-eq")} {
                    lappend params "l [@ $lVal 0] -poseq"
                } else {
                    lappend params "l $lVal -pos"
                }
            } elseif {![dexist $arguments flux] && ![dexist $arguments hyst]} {
                return -code error "Inductor value must be specified with '-l value'"
            }
            if {[dexist $arguments flux]} {
                set fluxVal [dget $arguments flux]
                lappend params "flux [dget $arguments flux] -eq"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {l flux hyst}} {
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
            # Xxxx n1 n2 n3... <subckt name> [<parameter>=<expression>]
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::BasicDevices::SubcircuitInstance new 1 {{plus net1} {minus net2}} rcnet {{r 1} {c cpar -eq}}
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

namespace eval ::SpiceGenTcl::Ltspice::Sources {

####  dc sources template class 
    
    oo::abstract create dc {
        superclass ::SpiceGenTcl::Device
        constructor {name type npNode nmNode args} {
            set arguments [argparse -inline {
                {-dc= -required}
                -rser=
                -cpar=
            }]
            set dcVal [dget $arguments dc]
            if {([llength $dcVal]>1) && ([@ $dcVal 1] eq "-eq")} {
                lappend params "dc [@ $dcVal 0] -poseq"
            } else {
                lappend params "dc $dcVal -pos"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {dc}} {
                    if {([llength $value]>1) && ([@ $value 1] eq "-eq")} {
                        lappend params "$paramName [@ $value 0] -eq"
                    } else {
                        lappend params "$paramName $value"
                    }
                }
            }
            next $type$name [list "np $npNode" "nm $nmNode"] $params
        }
    }

####  ac sources template class 

    oo::abstract create ac {
        superclass ::SpiceGenTcl::Device
        constructor {name type npNode nmNode args} {
            set arguments [argparse -inline {
                {-dc= -default 0}
                {-ac= -required}
                -rser=
                -cpar=
            }]
            set dcVal [dget $arguments dc]
            if {([llength $dcVal]>1) && ([@ $dcVal 1] eq "-eq")} {
                lappend params "dc [@ $dcVal 0] -poseq"
            } else {
                lappend params "dc $dcVal -pos"
            }
            set acVal [dget $arguments ac]
            if {([llength $acVal]>1) && ([@ $acVal 1] eq "-eq")} {
                lappend params "ac [@ $acVal 0] -eq"
            } else {
                lappend params "ac $acVal"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {dc ac}} {
                    if {([llength $value]>1) && ([@ $value 1] eq "-eq")} {
                        lappend params "$paramName [@ $value 0] -eq"
                    } else {
                        lappend params "$paramName $value"
                    }
                }
            }
            next $type$name [list "np $npNode" "nm $nmNode"] $params
        }
    } 

####  pulse sources template class 
    
    oo::abstract create pulse {
        superclass ::SpiceGenTcl::Device
        mixin ::SpiceGenTcl::Utility
        constructor {name type npNode nmNode args} {
            set arguments [argparse -inline {
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
                -rser=
                -cpar=
            }]
            my AliasesKeysCheck $arguments [list low voff ioff]
            my AliasesKeysCheck $arguments [list high von ion]
            my AliasesKeysCheck $arguments [list pw ton]
            my AliasesKeysCheck $arguments [list per tper]
            set paramsOrder [list low voff ioff high von ion td tr tf pw ton per tper np ncycles]
            lappend params "model pulse -posnocheck"
            my ParamsProcess $paramsOrder $arguments params
            dict for {paramName value} $arguments {
                if {$paramName ni $paramsOrder} {
                    if {([llength $value]>1) && ([@ $value 1] eq "-eq")} {
                        lappend params "$paramName [@ $value 0] -eq"
                    } else {
                        lappend params "$paramName $value"
                    }
                }
            }
            next $type$name [list "np $npNode" "nm $nmNode"] $params
        }
    }   

####  sin sources template class 
    
    oo::abstract create sin {
        superclass ::SpiceGenTcl::Device
        mixin ::SpiceGenTcl::Utility
        constructor {name type npNode nmNode args} {
            set arguments [argparse -inline {
                {-v0= -forbid {i0 voffset ioffset}}
                {-i0= -forbid {v0 voffset ioffset}}
                {-voffset= -forbid {v0 i0 ioffset}}
                {-ioffset= -forbid {v0 i0 voffset}}
                {-va= -forbid {ia vamp iamp}}
                {-ia= -forbid {va vamp iamp}}
                {-vamp= -forbid {va ia iamp}}
                {-iamp= -forbid {va ia vamp}}
                {-freq= -required}
                -td=
                {-theta= -require {td}}
                {-phase= -require {td theta} -forbid phi}
                {-phi= -require {td theta} -forbid phase}
                {-ncycles= -require {td theta}}
                -rser=
                -cpar=
            }]
            if {(![dexist $arguments phase] && ![dexist $arguments phi]) && [dexist $arguments ncycles]} {
                return -code error "-ncycles switch requires -phase or -phi switch"
            }
            my AliasesKeysCheck $arguments [list v0 i0 voffset ioffset]
            my AliasesKeysCheck $arguments [list va ia vamp iamp]
            set paramsOrder [list v0 i0 voffset ioffset va ia vamp iamp freq td theta phase phi ncycles]
            lappend params "model sin -posnocheck"
            my ParamsProcess $paramsOrder $arguments params
            dict for {paramName value} $arguments {
                if {$paramName ni $paramsOrder} {
                    if {([llength $value]>1) && ([@ $value 1] eq "-eq")} {
                        lappend params "$paramName [@ $value 0] -eq"
                    } else {
                        lappend params "$paramName $value"
                    }
                }
            }
            next $type$name [list "np $npNode" "nm $nmNode"] $params
        }
    } 

####  exp sources template class 
    
    oo::abstract create exp {
        superclass ::SpiceGenTcl::Device
        mixin ::SpiceGenTcl::Utility
        constructor {name type npNode nmNode args} {
            set arguments [argparse -inline {
                {-v1= -forbid i1}
                {-i1= -forbid v1}
                {-v2= -forbid i2}
                {-i2= -forbid v2}
                {-td1= -required}
                {-tau1= -required}
                {-td2= -required}
                {-tau2= -required}
                -rser=
                -cpar=
            }]
            my AliasesKeysCheck $arguments [list v1 i1]
            my AliasesKeysCheck $arguments [list v2 i2]
            set paramsOrder [list v1 i1 v2 i2 td1 tau1 td2 tau2]
            lappend params "model exp -posnocheck"
            my ParamsProcess $paramsOrder $arguments params
            dict for {paramName value} $arguments {
                if {$paramName ni $paramsOrder} {
                    if {([llength $value]>1) && ([@ $value 1] eq "-eq")} {
                        lappend params "$paramName [@ $value 0] -eq"
                    } else {
                        lappend params "$paramName $value"
                    }
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
                -rser=
                -cpar=
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
                if {([llength [@ $param 1]]>1) && ([@ [@ $param 1] 1] eq "-eq")} {
                    lappend paramList "[@ $param 0] [@ [@ $param 1] 0] -poseq"
                } else {
                    lappend paramList "[@ $param 0] [@ $param 1] -pos"
                }
            }
            foreach paramName {rser cpar} {
                if {[dexist $arguments $paramName]} {
                    set paramVal [dget $arguments $paramName]
                    if {([llength $paramVal]>1) && ([@ $paramVal 1] eq "-eq")} {
                        lappend paramList "$paramName [@ $paramVal 0] -eq"
                    } else {
                        lappend paramList "$paramName $paramVal"
                    }
                }
            }
            set paramList [linsert $paramList 0 "model pwl -posnocheck"]
            next $type$name [list "np $npNode" "nm $nmNode"] $paramList
        }
    }

####  sffm sources template class 
    
    oo::abstract create sffm {
        superclass ::SpiceGenTcl::Device
        mixin ::SpiceGenTcl::Utility
        constructor {name type npNode nmNode args} {
            set arguments [argparse -inline {
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
                -rser=
                -cpar=
            }]
            my AliasesKeysCheck $arguments [list v0 i0 voff ioff]
            my AliasesKeysCheck $arguments [list va ia vamp iamp]
            my AliasesKeysCheck $arguments [list fc fcar]
            my AliasesKeysCheck $arguments [list fs fsig]
            set paramsOrder [list v0 i0 voff ioff va ia vamp iamp fc fcar mdi fs fsig]
            lappend params "model sffm -posnocheck"
            my ParamsProcess $paramsOrder $arguments params
            dict for {paramName value} $arguments {
                if {$paramName ni $paramsOrder} {
                    if {([llength $value]>1) && ([@ $value 1] eq "-eq")} {
                        lappend params "$paramName [@ $value 0] -eq"
                    } else {
                        lappend params "$paramName $value"
                    }
                }
            }
            next $type$name [list "np $npNode" "nm $nmNode"] $params
        }
    }  

####  Vdc class 
        
    oo::class create Vdc {
        superclass ::SpiceGenTcl::Ltspice::Sources::dc
        constructor {name npNode nmNode args} {
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
            next $name v $npNode $nmNode {*}$args
        }
    }

####  Vac class 
    
    oo::class create Vac {
        superclass ::SpiceGenTcl::Ltspice::Sources::ac
        constructor {name npNode nmNode args} {
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
            next $name v $npNode $nmNode {*}$args

        }
    }

    
####  Vpulse class 

    oo::class create Vpulse {
        superclass ::SpiceGenTcl::Ltspice::Sources::pulse
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
            next $name v $npNode $nmNode {*}$args
        }
    }  
    
####  Vsin class 

    oo::class create Vsin {
        superclass ::SpiceGenTcl::Ltspice::Sources::sin
        constructor {name npNode nmNode args} {
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
            next $name v $npNode $nmNode {*}$args
        }
    }
    
####  Vexp class 

    oo::class create Vexp {
        superclass ::SpiceGenTcl::Ltspice::Sources::exp
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
            next $name v $npNode $nmNode {*}$args
        }
    }
    
####  Vpwl class 

    oo::class create Vpwl {
        superclass ::SpiceGenTcl::Ltspice::Sources::pwl
        constructor {name npNode nmNode args} {
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
            next $name v $npNode $nmNode {*}$args
        }
    }    
    
####  Vsffm class 

    oo::class create Vsffm {
        superclass ::SpiceGenTcl::Ltspice::Sources::sffm
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
            next $name v $npNode $nmNode {*}$args
        }
    }

####  Idc class 
        
    oo::class create Idc {
        superclass ::SpiceGenTcl::Ltspice::Sources::dc
        constructor {name npNode nmNode args} {
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
            if {"-rser" in $args || "-cpar" in $args} {
                return -code error "Current source doesn't support rser and cpar parameters"
            }
            next $name i $npNode $nmNode {*}$args
        }
    }

####  Iac class 
    
    oo::class create Iac {
        superclass ::SpiceGenTcl::Ltspice::Sources::ac
        constructor {name npNode nmNode args} {
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
            if {"-rser" in $args || "-cpar" in $args} {
                return -code error "Current source doesn't support rser and cpar parameters"
            }
            next $name i $npNode $nmNode {*}$args

        }
    }

    
####  Ipulse class 

    oo::class create Ipulse {
        superclass ::SpiceGenTcl::Ltspice::Sources::pulse
        constructor {name npNode nmNode args} {
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
            if {"-rser" in $args || "-cpar" in $args} {
                return -code error "Current source doesn't support rser and cpar parameters"
            }
            next $name i $npNode $nmNode {*}$args
        }
    }  
    
####  Isin class 

    oo::class create Isin {
        superclass ::SpiceGenTcl::Ltspice::Sources::sin
        constructor {name npNode nmNode args} {
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
            if {"-rser" in $args || "-cpar" in $args} {
                return -code error "Current source doesn't support rser and cpar parameters"
            }
            next $name i $npNode $nmNode {*}$args
        }
    }
    
####  Iexp class 

    oo::class create Iexp {
        superclass ::SpiceGenTcl::Ltspice::Sources::exp
        constructor {name npNode nmNode args} {
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
            next $name i $npNode $nmNode {*}$args
        }
    }
    
####  Ipwl class 

    oo::class create Ipwl {
        superclass ::SpiceGenTcl::Ltspice::Sources::pwl
        constructor {name npNode nmNode args} {
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
            next $name i $npNode $nmNode {*}$args
        }
    }    
    
####  Isffm class 

    oo::class create Isffm {
        superclass ::SpiceGenTcl::Ltspice::Sources::sffm
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
            # ```
            # Ixxx n+ n- SFFM(Ioff Iamp Fcar MDI Fsig)
            # ```
            # Example of class initialization:
            # ```
            # ::SpiceGenTcl::Ltspice::Sources::Isin new 1 net1 net2 -i0 0 -ia 1 -fc {freq -eq} -mdi 0 -fs 1e3
            # ```
            # Synopsis: name npNode nmNode -i0|ioff value -ia|iamp value -fc|fcar value -mdi value -fs|fsig value
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
            set arguments [argparse -inline {
                {-i= -forbid v}
                {-v= -forbid i}
                -ic=
                {-tripdv= -require tripdt}
                {-tripdt= -require tripdv}
                -laplace=
                {-window= -require laplace}
                {-nfft= -require laplace}
                {-mtol= -require laplace}
            }]
            if {[dexist $arguments i]} {
                lappend params "i [dget $arguments i] -eq"
            } elseif {[dexist $arguments v]} {
                lappend params "v [dget $arguments v] -eq"
            } else {
                return -code error "Equation must be specified as argument to -i or -v"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {i v}} {
                    lappend params "$paramName $value"
                }
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

namespace eval ::SpiceGenTcl::Ltspice::SemiconductorDevices {
    
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
            set arguments [argparse -inline {
                {-model= -required}
                -area=
                {-off -boolean}
                -m=
                -n=
                -temp=
            }]
            lappend params "model [dget $arguments model] -posnocheck"
            if {[dexist $arguments area]} {
                set areaVal [dget $arguments area]
                if {([llength $areaVal]>1) && ([@ $areaVal 1] eq "-eq")} {
                    lappend params "area [@ $areaVal 0] -poseq"
                } else {
                    lappend params "area $areaVal -pos"
                }
            }
            if {[dget $arguments off]==1} {
                lappend params "off -sw"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {model area off}} {
                    lappend params "$paramName $value"
                }
            }
            next d$name [list "np $npNode" "nm $nmNode"] $params
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
            set arguments [argparse -inline {
                {-model= -required}
                -area=
                {-off -boolean}
                -m=
                -temp=
                -ns=
            }]            
            lappend params "model [dget $arguments model] -posnocheck"
            if {[dexist $arguments area]} {
                set areaVal [dget $arguments area]
                if {([llength $areaVal]>1) && ([@ $areaVal 1] eq "-eq")} {
                    lappend params "area [@ $areaVal 0] -poseq"
                } else {
                    lappend params "area $areaVal -pos"
                }
            }
            if {[dget $arguments off]==1} {
                lappend params "off -sw"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {model area off ns}} {
                    lappend params "$paramName $value"
                }
            }
            set pinList [list "nc $ncNode" "nb $nbNode" "ne $neNode"]
            if {[dexist $arguments ns]} {
                lappend pinList "ns [dget $arguments ns]"
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
            set arguments [argparse -inline {
                {-model= -required}
                -area=
                -m=
                {-off -boolean}
                -temp=
            }]
            lappend params "model [dget $arguments model] -posnocheck"
            if {[dexist $arguments area]} {
                set areaVal [dget $arguments area]
                if {([llength $areaVal]>1) && ([@ $areaVal 1] eq "-eq")} {
                    lappend params "area [@ $areaVal 0] -poseq"
                } else {
                    lappend params "area $areaVal -pos"
                }
            }
            if {[dget $arguments off]==1} {
                lappend params "off -sw"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {model area off}} {
                    lappend params "$paramName $value"
                }
            }
            next j$name [list "nd $ndNode" "ng $ngNode" "ns $nsNode"] $params
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
            set arguments [argparse -inline {
                {-model= -required}
                -area=
                -m=
                {-off -boolean}
                -temp=
            }]
            lappend params "model [dget $arguments model] -posnocheck"
            if {[dexist $arguments area]} {
                set areaVal [dget $arguments area]
                if {([llength $areaVal]>1) && ([@ $areaVal 1] eq "-eq")} {
                    lappend params "area [@ $areaVal 0] -poseq"
                } else {
                    lappend params "area $areaVal -pos"
                }
            }
            if {[dget $arguments off]==1} {
                lappend params "off -sw"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {model area off}} {
                    lappend params "$paramName $value"
                }
            }
            next z$name [list "nd $ndNode" "ng $ngNode" "ns $nsNode"] $params
            
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
            set arguments [argparse -inline {
                {-model= -required}
                -m=
                {-area= -forbid n4}
                -l=
                -w=
                {-ad= -forbid nrd -require n4}
                {-as= -forbid nrs -require n4}
                {-pd= -require n4}
                {-ps= -require n4}
                {-nrd= -forbid ad}
                {-nrs= -forbid as}
                -temp=
                {-off -boolean}
                {-ic= -require n4 -validate {[llength $arg]==3}}
                -n4=
                {-n5= -require n4}
                {-n6= -require n5}
                {-n7= -require n7}
                {-custparams -catchall}
            }]
            lappend params "model [dget $arguments model] -posnocheck"
            if {[dget $arguments off]==1} {
                lappend params "off -sw"
            }
            if {[dexist $arguments ic]} {
                lappend params "ic [join [dget $arguments ic] ,] -nocheck"
            }
            dict for {paramName value} $arguments {
                if {$paramName ni {model off ic n4 n5 n6 n7 custparams}} {
                    lappend params "$paramName $value"
                }
            }
            if {[dget $arguments custparams] ne ""} {
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

####  M class 
    
    # alias for Mosfet class
    oo::class create M {
        superclass Mosfet
    }    
}



