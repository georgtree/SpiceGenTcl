#  .|'''.|            ||                   ..|'''.|                   |''||''|         '||'
#  ||..  '  ... ...  ...    ....    ....  .|'     '    ....  .. ...      ||      ....   ||  
#   ''|||.   ||'  ||  ||  .|   '' .|...|| ||    .... .|...||  ||  ||     ||    .|   ''  ||  
# .     '||  ||    |  ||  ||      ||      '|.    ||  ||       ||  ||     ||    ||       ||  
# |'....|'   ||...'  .||.  '|...'  '|...'  ''|...'|   '|...' .||. ||.   .||.    '|...' .||. 
#            ||                                                                             
#           ''''                                                                            
# generalClasses.tcl
# Describes all general classes
#
# Copyright (c) 2024 George Yashin, georgtree@gmail.com
#
# MIT License
# See the file "LICENSE.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

namespace eval ::SpiceGenTcl {

    namespace export Pin ParameterSwitch Parameter ParameterNoCheck ParameterPositional ParameterPositionalNoCheck\
            ParameterDefault ParameterEquation ParameterPositionalEquation Device Model RawString Comment Include\
            Options ParamStatement Temp Netlist Circuit Library Subcircuit Analysis Simulator Dataset Axis Trace\
            EmptyTrace RawFile
    namespace export importNgspice importXyce importCommon
    
    proc importCommon {} {
        # Imports all ::SpiceGenTcl::Common commands to caller namespace
        uplevel 1 {foreach nameSpc [namespace children ::SpiceGenTcl::Common] {
            namespace import ${nameSpc}::*
        }}
    }
    
    proc importNgspice {} {
        # Imports all ::SpiceGenTcl::Ngspice commands to caller namespace
        uplevel 1 {foreach nameSpc [namespace children ::SpiceGenTcl::Ngspice] {
            namespace import ${nameSpc}::*
        }}
    }

    proc importXyce {} {
        # Imports all ::SpiceGenTcl::Xyce commands to caller namespace
        uplevel 1 {foreach nameSpc [namespace children ::SpiceGenTcl::Xyce] {
            namespace import ${nameSpc}::*
        }}
    }
    
###  SPICEElement class definition 
    
    oo::configurable create SPICEElement {
        self mixin -append oo::abstract
        # Abstract class of all elements of SPICE netlist
        #  and it forces implementation of genSPICEString method for all subclasses.
        variable Name
        method genSPICEString {} {
            # Declaration of method common for all SPICE elements that generates 
            #  representation of element in SPICE netlist. Not implemented in
            #  abstraction class.
            error "Not implemented"
        }
    }
    
###  DuplChecker class definition 
   
    oo::configurable create DuplChecker {
        self mixin -append oo::abstract
        method duplListCheck {list} {
            # Checks if list contains duplicates.
            #  list - list to check
            # Returns: 0 if there are no duplicates and 1 if there are.
            set flag 0
            set new {}
            foreach item $list {
                if {[lsearch $new $item] < 0} {
                    lappend new $item
                } else {
                    set flag 1
                    break
                }
            }
            return $flag
        }
    }

###  KeyArgsBuilder class definition 

    oo::class create KeyArgsBuilder {
        self mixin -append oo::abstract
        method buildArgStr {paramsNames} {
            # Builds argument list for argparse.
            #  paramsNames - list of parameter names, define alias for parameter name by
            #  using two element list {paramName aliasName}
            # Returns: string in form *-paramName= \n {-paramName= -alias aliasName} \n ...*
            foreach paramName $paramsNames {
                if {[llength $paramName]>1} { 
                    lappend paramDefList "\{-[lindex $paramName 0]= -alias [lindex $paramName 1]\}"
                } else {
                    lappend paramDefList "-${paramName}="
                }
            }
            set paramDefStr [join $paramDefList \n]
            return $paramDefStr
        }
        method argsPreprocess {paramsNames args} {
            # Calls argparse and constructs list for passing to Device constructor.
            #  paramsNames - list of parameter names, define alias for parameter name by
            #  using two element list {paramName aliasName}
            #  args - argument list with key names and it's values
            # Returns: string in form *-paramName= \n {-paramName= -alias aliasName} \n ...*
            set paramDefList [my buildArgStr $paramsNames]
            set arguments [argparse -inline "
                $paramDefList
            "]
            set params ""
            dict for {paramName value} $arguments {
                lappend params "$paramName $value"
            }
            return $params
        }
    }
    
###  Pin class definition 

    oo::configurable create Pin {
        superclass SPICEElement
        # name of the node connected to pin
        property NodeName -set {
            if {[regexp {[^A-Za-z0-9_]+} $value]} {
                error "Node name '${value}' is not a valid name"
            }
            set NodeName [string tolower $value]
        }
        property Name -set {
            if {$value==""} {
                error "Pin must have a name, empty string was provided"
            } elseif {[regexp {[^A-Za-z0-9_]+} $value]} {
                error "Pin name '$value' is not a valid name"
            }
            set Name [string tolower $value]
        } -get {
            return $Name
        }
        variable Name NodeName
        constructor {name nodeName} {
            # Creates object of class `Pin` with name and connected node
            #  name - name of the pin
            #  nodeName - name of the node that connected to pin
            # Class models electrical pin of device/subcircuit,
            # it has name and name of the node connected to it.
            # It has general interface method `genSPICEString` that returns
            # name of the node connected to it, this method must be called only
            # in method with the same name in other classes. We can check if pin is
            # floating by checking the name of connected node in method `checkFloating` - 
            # if is contains empty string it is floating.
            # Floating pin can't be netlisted, so it throws error when try to
            # do so. Set pin name empty by special method `unsetNodeName`.
            my configure -Name $name
            my configure -NodeName $nodeName
        }
        method unsetNodeName {} {
            # Makes pin floating by setting `NodeName` with empty string.
            my configure -NodeName {}
        }
        method checkFloating {} {
            # Determines if pin is connected to the node.
            # Returns: `true` if connected and `false` if not
            if {[my configure -NodeName]=={}} {
                set floating true
            } else {
                set floating false
            }
            return $floating
        }
        method genSPICEString {} {
            # Creates string for SPICE netlist.
            # Returns: string '*$NodeName*'
            if {[my checkFloating]=="true"} {
                error "Pin '[my configure -Name]' is not connected to the node so can't be netlisted"
            }
            return "[my configure -NodeName]"
        }
    }
    
###  ParameterSwitch class definition 

    oo::configurable create ParameterSwitch {
        superclass SPICEElement
        property Name -set {
            if {$value==""} {
                error "Parameter must have a name, empty string was provided"
            } elseif {[regexp {[^A-Za-z0-9_]+} $value]} {
                error "Parameter name '$value' is not a valid name"
            } elseif {[regexp {^[A-Za-z][A-Za-z0-9_]*} $value]} {
                set Name [string tolower $value]
            } else {
                error "Parameter name '$value' is not a valid name"
            }
        }
        variable Name
        constructor {name} {
            # Creates object of class `ParameterSwitch` with parameter name.
            #  name - name of the parameter
            # Class models base parameter acting like a switch - 
            # its presence gives us information that something it controls is on.
            # This parameter doesn't have a value, and it is the most basic class
            # in Parameter class family.
            my configure -Name $name
        }
        method genSPICEString {} {
            # Creates string for SPICE netlist.
            # Returns: string '$Name'
            return "[my configure -Name]"
        }
    }
    
###  Parameter class definition 

    oo::configurable create Parameter {
        superclass ParameterSwitch 
        property Value -set {
            if {[string is double -strict $value]} {
                set Value $value
            } else {
                if {[string tolower [string range $value end-2 end]]=={meg}} {
                    if {[string is double -strict [string range $value 0 end-3]]} {
                        set Value [string tolower $value]
                    } else {
                        error "Value '$value' is not a valid value"
                    } 
                } else {
                    set suffix [string tolower [string index $value end]]
                    if {$suffix in {f p n u m k g t}} {
                        if {[string is double -strict [string range $value 0 end-1]]} {
                            set Value [string tolower $value]
                        } else {
                            error "Value '$value' is not a valid value"
                        } 
                    } else {
                        error "Value '$value' is not a valid value"
                    }
                }
            }
        }
        variable Value
        constructor {name value} {
            # Creates object of class `Parameter` with parameter name and value.
            #  name - name of the parameter
            #  value - value of the parameter
            # Class models parameter that has a name and a value - the most
            # common type of parameters in SPICE netlist. Its representation in netlist is
            # 'Name=Value', and can be called "keyword parameter".
            my configure -Name $name
            my configure -Value $value
        }
        method genSPICEString {} {
            # Creates string for SPICE netlist.
            # Returns: '$Name=$Value'
            return "[my configure -Name]=[my configure -Value]"
        }
    }

###  ParameterNoCheck class definition 

    oo::configurable create ParameterNoCheck {
        superclass Parameter
        property Value -set {
            if {$value==""} {
                error "Value '$value' is not a valid value"
            } 
            set Value $value
        }
        variable Value
        constructor {name value} {
            # Creates object of class `ParameterNoCheck` with parameter name and value.
            #  name - name of the parameter
            #  value - value of the parameter
            # Class models parameter the same as described by `Parameter` but without check for value form.
            next $name $value
        }
    }    
    
###  ParameterPositional class definition 

    oo::configurable create ParameterPositional {
        superclass Parameter
        constructor {name value} {
            # Creates object of class `ParameterPositional` with parameter name and value.
            #  name - name of parameter
            #  value - value of parameter
            # Class models parameter that has a name and a value, but it differs from
            # parent class in the sense of netlist representation: this parameter represents only 
            # by the value in the netlist. It's meaning for holding element is taken from
            # it's position in the element's definition, for example, R1 np nm 100 tc1=1 tc2=0 - resistor
            # with positional parameter R=100, you can't put it after parameters tc1 and tc2, it must be placed 
            # right after the pins definition.
            next $name $value
        }
        method genSPICEString {} {
            # Creates string for SPICE netlist.
            # Returns: '$Value'
            return "[my configure -Value]"
        }
    }
    
###  ParameterPositionalNoCheck class definition 

    oo::configurable create ParameterPositionalNoCheck {
        superclass ParameterPositional
        property Value -set {
            if {$value==""} {
                error "Value '$value' is not a valid value"
            } 
            set Value $value
        }
        variable Value
        constructor {name value} {
            # Creates object of class `ParameterPositionalNoCheck`.
            #  name - name of parameter
            #  value - value of parameter
            # Class models parameter the same as described by `ParameterPositional` but without check for value form.
            next $name $value
        }
        method genSPICEString {} {
            # Creates string for SPICE netlist.
            # Results: '$Value'
            return "[my configure -Value]"
        }
    }
    
###  ParameterDefault class definition 

    oo::configurable create ParameterDefault {
        superclass Parameter
        property DefValue -set {
            if {[string is double -strict $value]} {
                set DefValue $value
            } else {
                if {[string tolower [string range $value end-2 end]]=={meg}} {
                    if {[string is double -strict [string range $value 0 end-3]]} {
                        set DefValue [string tolower $value]
                    } else {
                        error "Default value '$value' is not a valid value"
                    } 
                } else {
                    set suffix [string tolower [string index $value end]]
                    if {$suffix in {f p n u m k g t}} {
                        if {[string is double -strict [string range $value 0 end-1]]} {
                            set DefValue [string tolower $value]
                        } else {
                            error "Default value '$value' is not a valid value"
                        } 
                    } else {
                        error "Default value '$value' is not a valid value"
                    }
                }
            }
        }
        variable DefValue Value
        constructor {name value defValue} {
            # Creates object of class `ParameterDefault` with parameter name, value and default value.
            #  name - name of the parameter
            #  value - value of the parameter
            #  defValue - default value of the parameter
            # Class models parameter that has a name and a value, but it differs from
            # parent class in sense of having default value, so it has special ability to reset its value to default
            # value by special method `resetValue`.
            my configure -DefValue $defValue
            next $name $value
        }
        
        method resetValue {} {
            # Resets value of the parameter to it's default value.
            my configure -Value [my configure -DefValue]
            return
        }
    }
    
###  ParameterEquation class definition 

    oo::configurable create ParameterEquation {
        superclass Parameter
        property Value -set {
            if {$value!=""} {
                set Value $value
            } else {
                error "Parameter '[my configure -Name]' equation can't be empty"
            }
        }
        variable Value
        constructor {name value} {
            # Creates object of class `ParameterEquation` with parameter name and value as an equation.
            #  name - name of the parameter
            #  value - value of the parameter
            # Class models parameter that has representation as an equation.
            # Example: R={R1+R2}
            next $name $value
        }
        method genSPICEString {} {
            # Creates string for SPICE netlist.
            # Returns: '$Name={$Value}'
            return "[my configure -Name]=\{[my configure -Value]\}"
        }
    }  

###  ParameterPositionalEquation class definition 

    oo::configurable create ParameterPositionalEquation {
        superclass ParameterEquation
        constructor {name value} {
            # Creates object of class `ParameterPositionalEquation` with parameter name and value as an equation in
            # positional form.
            #  name - name of the parameter
            #  value - value of the parameter
            # Class models parameter that has representation as an equation, but in form of
            # positional parameter. Example: {R1+R2}
            next $name $value
        }
        method genSPICEString {} {
            # Creates string for SPICE netlist.
            # Returns: '{$paramValue}'
            return "\{[my configure -Value]\}"
        }
    }
    
###  Device class definition 

    oo::configurable create Device {
        superclass SPICEElement
        mixin DuplChecker
        property Name -set {
            if {[regexp {[^A-Za-z0-9_]+} $value]} {
                error "Reference name '$value' is not a valid name"
            } elseif {[regexp {^[A-Za-z][A-Za-z0-9]+} $value]} {
                set Name [string tolower $value]
            } else {
                error "Reference name '$value' is not a valid name"
            }
        }
        variable Name
        # list of Pin objects references
        variable Pins
        # list of Parameter objects references
        variable Params
        constructor {name pins params} {
            # Creates object of class `Device`.
            #  name - name of the device
            #  pins - list of pins in the order they appear in SPICE device's definition together
            #   with connected node in form: `{{Name0 NodeName} {Name1 NodeName} {Name2 NodeName} ...}`
            #   Nodes string values could be empty.
            #  params - list of instance parameters in form `{{Name Value ?-pos|eq|poseq?} {Name Value ?-pos|eq|poseq?}
            #   {Name Value ?-pos|eq|poseq?} ...}` Parameter list can be empty if device doesn't have instance
            #   parameters.
            # Class models general device in SPICE, number of which 
            # must be assembled (connected) to get the circuit to simulate. This class provides basic machinery
            # for creating any device that can be connected to net in circuit. It can be instantiated to create
            # device that contains: 
            #  - reference name, like R1, L1, M1, etc;
            #  - list of pins in the order of appearence of device's definition, for example, 'drain gate source' for 
            #     MOS transistor;
            #  - list of parameters, that could be positional (+equation), keyword (+equation) parameters, like
            #     `R1 nm np 100 tc1=1 tc2={tc0*tc12}`, where 100 - positional parameter, tc1 - keyword parameters and
            #     tc2 - keyword parameter with equation
            # This class accept definition that contains elements listed above, and generates classes: Pin, Parameter, 
            # PositionalParameter with compositional relationship (has a).
            
            my configure -Name $name
            # create Pins objects
            foreach pin $pins {
                my AddPin [lindex $pin 0] [lindex $pin 1]
            }
            #ruff
            # Each parameter definition could be modified by 
            #  optional flags:
            #  - pos - parameter has strict position and only '$Value' is displayed in netlist
            #  - eq - parameter may contain equation in terms of functions and other parsmeters,
            #    printed as '$Name={$Equation}'
            #  - poseq - combination of both flags, print only '{$Equation}'
            if {$params!=""} {
                foreach param $params {
                    if {[lindex $param 2]=={}} {
                        my addParam [lindex $param 0] [lindex $param 1] 
                    } elseif {[lindex $param 1]=="-sw"} {
                        my addParam [lindex $param 0] -sw 
                    } else {
                        my addParam {*}$param
                    } 
                }
            } else {
                set Params ""
            }
        }
        method getPins {} {
            # Gets the dictionary that contains pin name as keys and
            #  connected node name as the values.
            # Returns: parameters dictionary
            set tempDict [dict create]
            dict for {pinName pin} $Pins {
                dict append tempDict $pinName [$pin configure -NodeName]
            }
            return $tempDict
        }
        method setPinNodeName {pinName nodeName} {
            # Sets node name of particular pin, so,
            #  in other words, connect particular pin to particular node.
            #  pinName - name of the pin
            #  nodeName - name of the node that we want connect to pin
            set error [catch {dict get $Pins $pinName}]
            if {$error>0} {
                error "Pin with name '$pinName' was not found in device's '[my configure -Name]' list of pins\
                        '[dict keys [my getPins]]'"
            } else {
                set pin [dict get $Pins $pinName]
            }
            $pin configure -NodeName $nodeName
            return
        }
        method setParamValue {paramName value} {
            # Sets (or change) value of particular parameter.
            #  paramName - name of parameter
            #  value - new value of parameter
            set paramName [string tolower $paramName]
            set error [catch {dict get $Params $paramName}]
            if {$error>0} {
                error "Parameter with name '$paramName' was not found in device's '[my configure -Name]' list of\
                        parameters '[dict keys [my getParams]]'"
            } else {
                set param [dict get $Params $paramName]
            }
            $param configure -Value $value
            return
        }
        method AddPin {pinName nodeName} {
            # Adds new Pin object to the dictionary of `Pins`.
            #  pinName - name of the pin
            #  nodeName - name of the node connected to pin
            set pinName [string tolower $pinName]
            set nodeName [string tolower $nodeName]
            if {[info exists Pins]} {
                set pinList [dict keys $Pins]
            }
            lappend pinList $pinName
            if {[my duplListCheck $pinList]} {
                error "Pins list '$pinList' has already contains pin with name '$pinName'"
            }
            dict append Pins $pinName [::SpiceGenTcl::Pin new $pinName $nodeName]
            return
        }
        method addParam {paramName value args} {
            # Adds new parameter to device, and throws error on dublicated names.
            #  paramName - name of parameter
            #  value - value of parameter
            #  args - optional arguments that adds qualificator to parameter: -pos - positional parameter, -eq - 
            #  equational parameter, -poseq - positional equation parameter
            set arguments [argparse {
                {-pos -forbid {poseq}}
                {-eq -forbid {poseq}}
                {-poseq -forbid {pos eq}}
                {-posnocheck -forbid {poseq eq pos}}
                {-nocheck -forbid {pos eq poseq}}
            }]
            # method adds new Parameter object to the list Params
            set paramName [string tolower $paramName]
            if {[info exists Params]} {
                set paramList [dict keys $Params]
            }
            lappend paramList $paramName
            if {[my duplListCheck $paramList]} {
                error "Parameters list '$paramList' has already contains parameter with name '$paramName'"
            }
            # select parameter object according to parameter qualificator
            if {$value=="-sw"} {
                dict append Params $paramName [::SpiceGenTcl::ParameterSwitch new $paramName]
            } elseif {[info exists pos]} {
                dict append Params $paramName [::SpiceGenTcl::ParameterPositional new $paramName $value]
            } elseif {[info exists eq]} {
                dict append Params $paramName [::SpiceGenTcl::ParameterEquation new $paramName $value]
            } elseif {[info exists poseq]} {
                dict append Params $paramName [::SpiceGenTcl::ParameterPositionalEquation new $paramName $value]
            } elseif {[info exists posnocheck]} {
                dict append Params $paramName [::SpiceGenTcl::ParameterPositionalNoCheck new $paramName $value]
            } elseif {[info exists nocheck]} {
                dict append Params $paramName [::SpiceGenTcl::ParameterNoCheck new $paramName $value]
            } else {
                dict append Params $paramName [::SpiceGenTcl::Parameter new $paramName $value]
            }
            return
        }
        method deleteParam {paramName} {
            # Deletes existing `Parameter` object from list `Params`.
            #  paramName - name of parameter that will be deleted
            set paramName [string tolower $paramName]
            set error [catch {dict get $Params $paramName}]
            if {$error>0} {
                error "Parameter with name '$paramName' was not found in device's '[my configure -Name]' list of\
                        parameters '[dict keys [my getParams]]'"
            } else {
                set Params [dict remove $Params $paramName]
            }
            return
        }
        method checkFloatingPins {} {
            # Check if some pin device doesn't have connected nodes and return list of them.
            # Returns: list of floating pins
            set floatingPins {}
            dict for {pinName pin} $Pins {
                if {[$pin checkFloating]=="true"} {
                    lappend floatingPins [$pin configure -Name]
                }
            }
            return $floatingPins
        }
        method getParams {} {
            # Gets the dictionary that contains parameter name as keys and
            #  parameter values as the values.
            # Returns: parameters dictionary
            set tempDict [dict create]
            dict for {paramName param} $Params {
                dict append tempDict $paramName [$param configure -Value]
            }
            return $tempDict
        }
        method genSPICEString {} {
            # Creates device string for SPICE netlist.
            # Returns: string '$Name $Nodes $Params'
            dict for {pinName pin} $Pins {
                set error [catch {$pin genSPICEString} errStr] 
                if {$error!=1} {
                    lappend nodes [$pin genSPICEString]
                } else {
                    error "Device '[my configure -Name]' can't be netlisted because '$pinName' pin is floating"
                }
            }
            if {($Params=="") || ([info exists Params]==0)} {
                lappend params ""
                return "[my configure -Name] [join $nodes]"
            } else {
                dict for {paramName param} $Params {
                    lappend params [$param genSPICEString]
                }
                return "[my configure -Name] [join $nodes] [join $params]"
            }
        }
    }

###  Model class definition 

    oo::configurable create Model {
        superclass SPICEElement
        mixin DuplChecker
        property Name -set {
            if {$value==""} {
                error "Model must have a name, empty string was provided"
            } elseif {[regexp {[^A-Za-z0-9_]+} $value]} {
                error "Model name '$value' is not a valid name"
            } else {
                set Name [string tolower $value]
            }
        }
        property Type -set {
            if {$value==""} {
                error "Model must have a type, empty string was provided"
            } elseif {[regexp {[^A-Za-z0-9]+} $value]} {
                error "Model type '$value' is not a valid type"
            } else {
                set Type [string tolower $value]
            }
        }
        variable Name
        # type of the model
        variable Type
        # list of model parameters objects
        variable Params
        constructor {name type params} {
            # Creates object of class `Model`.
            #  name - name of the model
            #  type - type of model, for example, diode, npn, etc
            #  instParams - list of instance parameters in form `{{Name Value ?-pos|eq|poseq?}
            #   {Name Value ?-pos|eq|poseq?} {Name Value ?-pos|eq|poseq?} ...}`
            # Class represents model card in SPICE netlist.
            my configure -Name $name
            my configure -Type $type
            # create Params objects
            if {$params!=""} {
                foreach param $params {
                    if {[lindex $param 2]=={}} {
                        my addParam [lindex $param 0] [lindex $param 1] 
                    } elseif {[lindex $param 2]=="-eq"} {
                        my addParam [lindex $param 0] [lindex $param 1] -eq
                    } else {
                        error "Wrong parameter definition in model $name"
                    }  
                }
            } else {
                set Params ""
            }
        }
        set def [info class definition ::SpiceGenTcl::Device addParam]
        method addParam [lindex $def 0] [lindex $def 1]
        set def [info class definition ::SpiceGenTcl::Device deleteParam]
        method deleteParam [lindex $def 0] [lindex $def 1]
        set def [info class definition ::SpiceGenTcl::Device setParamValue]
        method setParamValue [lindex $def 0] [lindex $def 1]            
        method getParams {} {
            # Gets the dictionary that contains parameter name as keys and
            #  parameter values as the values.
            # Returns: parameters dictionary
            set tempDict [dict create]
            dict for {paramName param} $Params {
                dict append tempDict $paramName [$param configure -Value]
            }
            return $tempDict
        }
        method genSPICEString {} {
            # Creates model string for SPICE netlist.
            # Returns: string '.model $Name $Type $Params'
            if {($Params=="") || ([info exists Params]==0)} {
                lappend params ""
                return ".model [my configure -Name] [my configure -Type]"
            } else {
                dict for {paramName param} $Params {
                    lappend params [$param genSPICEString]
                }
                return ".model [my configure -Name] [my configure -Type]([join $params])"
            }
        }
    }

###  RawString class definition 

    oo::configurable create RawString {
        superclass SPICEElement
        property Name -set {
            set Name [string tolower $value]
        }
        property Value -set {
            set Value $value
        }
        variable Name
        # value of the raw string
        variable Value
        constructor {value args} {
            # Creates object of class `RawString`.
            #  value - value of the raw string
            # Class represent arbitary string.
            #  It can be used to pass any string directly into netlist, 
            #  for example, it can add elements that doesn't have dedicated class.
            set arguments [argparse {
                -name=
            }]
            if {[info exists name]} {
                my configure -Name $name
            } else {
                my configure -Name [self object]
            }
            my configure -Value $value
        }
        method genSPICEString {} {
            # Creates raw string for SPICE netlist.
            # Returns: string '$Value'
            return [my configure -Value]
        }
    }

###  Comment class definition 

    oo::configurable create Comment {
        superclass RawString
        constructor {value args} {
            # Creates object of class `Comment`.
            #  value - value of the comment
            #  args - optional argument -name - represent name of comment string
            # Class represent comment string, it can be a multiline comment.
            set arguments [argparse {
                -name=
            }]
            if {[info exists name]} {
                my configure -Name $name
            } else {
                my configure -Name [self object]
            }
            my configure -Value $value
        }
        method genSPICEString {} {
            # Creates comment string for SPICE netlist.
            # Returns: string '*$Value'
            set splitted [split [my configure -Value] "\n"]
            set prepared [join [lmap line $splitted {set result "*$line"}] \n]
            return $prepared
        }
    }    
    
###  Include class definition 

    oo::configurable create Include {
        superclass RawString
        constructor {value args} {
            # Creates object of class `Include`.
            #  value - value of the include path
            #  args - optional argument -name - represent name of include statement
            # This class represent .include statement.
            set arguments [argparse {
                -name=
            }]
            if {[info exists name]} {
                my configure -Name $name
            } else {
                my configure -Name [self object]
            }
            my configure -Value $value
        }
        method genSPICEString {} {
            # Creates include string for SPICE netlist.
            # Returns: '.include $Value'
            return ".include [my configure -Value]"
        }
    }   
    
###  Library class definition     
    
    oo::configurable create Library {
        superclass RawString
        # this variable contains selected library name inside sourced file
        property LibValue -set {
            set LibValue [string tolower $value]
        }
        variable LibValue
        constructor {value libValue args} {
            # Creates object of class `Library`.
            #  value - value of the include file
            #  libValue - value of selected library
            #  args - optional argument -name - represent name of library statement
            # Class represent .lib statement.
            set arguments [argparse {
                -name=
            }]
            if {[info exists name]} {
                my configure -Name $name
            } else {
                my configure -Name [self object]
            }
            my configure -Value $value
            my configure -LibValue $libValue
        }
        method genSPICEString {} {
            # Creates library string for SPICE netlist.
            # Returns: '.lib $Value $LibValue'
            return ".lib [my configure -Value] [my configure -LibValue]"
        }
    }   
    
###  Options class definition 
    
    oo::configurable create Options {
        superclass SPICEElement
        mixin DuplChecker
        property Name -set {
            set Name [string tolower $value]
        }
        variable Name
        # list of Parameter objects
        variable Params
        constructor {params args} {
            # Creates object of class `Options`.
            #  name - name of the parameter
            #  params - list of instance parameters in form `{{Name Value ?-sw?} {Name Value ?-sw?}
            #   {Name Value ?-sw?} ...}`
            #  args - optional argument -name - represent name of library statement
            # This class represent .options statement.
            set arguments [argparse {
                -name=
            }]
            if {[info exists name]} {
                my configure -Name $name
            } else {
                my configure -Name [self object]
            }
            foreach param $params {
                if {[lindex $param 2]=={}} {
                    if {[lindex $param 1]=="-sw"} {
                        my addParam [lindex $param 0] -sw  
                    } else {
                        my addParam [lindex $param 0] [lindex $param 1] 
                    }
                } else {
                    error "Wrong parameter definition in Options"
                }   
            }
        }
        method getParams {} {
            # Gets the dictionary that contains parameter name as keys and
            #  parameter values as the values.
            # Returns: parameters dictionary
            set tempDict [dict create]
            dict for {paramName param} $Params {
                # check if parameter doesn't have value, it means that we return {} for switch parameter
                if {[catch {$param configure -Value}]} {
                    dict append tempDict $paramName ""
                } else {
                    dict append tempDict $paramName [$param configure -Value]
                }
            }
            return $tempDict
        }
        method addParam {paramName value} {
            # Creates new parameter object and add it to the list `Params`.
            #  paramName - name of parameter
            #  value - value of parameter, with optional qualificator -eq
            set paramName [string tolower $paramName]
            if {[info exists Params]} {
                set paramList [dict keys $Params]
            }
            lappend paramList $paramName
            if {[my duplListCheck $paramList]} {
                error "Parameters list '$paramList' has already contains parameter with name '$paramName'"
            }
            if {$value=="-sw"} {
                dict append Params $paramName [::SpiceGenTcl::ParameterSwitch new $paramName]
            } else {
                dict append Params $paramName [::SpiceGenTcl::ParameterNoCheck new $paramName $value]
            }
            return
        }
        set def [info class definition ::SpiceGenTcl::Device deleteParam]
        method deleteParam [lindex $def 0] [lindex $def 1]
        method setParamValue {paramName value} {
            # Sets (or changes) value of particular parameter
            #  it throws a error if try to set a value of switch parameter.
            #  paramName - name of parameter
            #  value - new value of parameter
            set paramName [string tolower $paramName]
            set error [catch {dict get $Params $paramName}]
            if {$error>0} {
                error "Parameter with name '$paramName' was not found in options's '[my configure -Name]' list of\
                        parameters '[dict keys [my getParams]]'"
            } else {
                set param [dict get $Params $paramName]
            }
            $param configure -Value $value
            return
        }
        method genSPICEString {} {
            # Creates options string for SPICE netlist.
            # Returns: '.options $Params'
            dict for {paramName param} $Params {
                lappend params [$param genSPICEString]
            }
            return ".options [join $params]"
        }
    }
    
###  ParamStatement class definition 
    
    oo::configurable create ParamStatement {
        superclass SPICEElement
        mixin DuplChecker
        property Name -set {
            set Name [string tolower $value]
        }
        variable Name
        variable Params
        constructor {params args} {
            # Creates object of class `ParamStatement`.
            #  params - list of instance parameters in form `{{Name Value} {Name Value} {Name Equation -eq} ...}`
            #  args - optional argument -name - represent name of library statement
            # Class represent .param statement.
            set arguments [argparse {
                -name=
            }]
            if {[info exists name]} {
                my configure -Name $name
            } else {
                my configure -Name [self object]
            }
            foreach param $params {
                if {[lindex $param 2]=={}} {
                    my addParam [lindex $param 0] [lindex $param 1]    
                } elseif {[lindex $param 2]=="-eq"} {
                    my addParam [lindex $param 0] [lindex $param 1] -eq  
                } else { 
                    error "Wrong parameter definition in ParamStatement"
                }   
            }
        }
        method getParams {} {
            # Gets the dictionary that contains parameter name as keys and
            #  parameter values as the values.
            # Returns: parameters dictionary
            set tempDict [dict create]
            dict for {paramName param} $Params {
                dict append tempDict $paramName [$param configure -Value]
            }
            return $tempDict
        }
        method addParam {paramName value args} {
            # Adds new Parameter object to the list Params.
            #  paramName - name of parameter
            #  value - value of parameter
            #  args - optional parameter qualificator -eq
            set arguments [argparse {
                -eq
            }]
            set paramName [string tolower $paramName]
            if {[info exists Params]} {
                set paramList [dict keys $Params]
            }
            lappend paramList $paramName
            if {[my duplListCheck $paramList]} {
                error "Parameters list \{$paramList\} has already contains parameter with name \{$paramName\}"
            }
            if {[info exists eq]} {
                dict append Params $paramName [::SpiceGenTcl::ParameterEquation new $paramName $value]
            } else {
                dict append Params $paramName [::SpiceGenTcl::Parameter new $paramName $value]
            }
            return
        }
        set def [info class definition ::SpiceGenTcl::Device deleteParam]
        method deleteParam [lindex $def 0] [lindex $def 1]
        method setParamValue {paramName value} {
            # Sets (or changes) value of particular parameter.
            #  paramName - name of parameter
            #  value - new value of parameter
            set paramName [string tolower $paramName]
            set error [catch {dict get $Params $paramName}]
            if {$error>0} {
                error "Parameter with name '$paramName' was not found in parameter statement's '[my configure -Name]'\
                        list of parameters '[dict keys [my getParams]]'"
            } else {
                set param [dict get $Params $paramName]
            }
            $param configure -Value $value
            return
        }
        method genSPICEString {} {
            # Creates parameter statement string for SPICE netlist.
            # Returns: '.param $Params'
            dict for {paramName param} $Params {
                lappend params [$param genSPICEString]
            }
            return ".param [join $params]"
        }
    }
    
###  Temp class definition 
    
    oo::configurable create Temp {
        superclass SPICEElement
        property Name -set {
            set Name [string tolower $value]
        }
        property Value -set {
            lassign $value value eq
            if {$eq=="-eq"} {
                my AddParam temp $value -eq
            } elseif {$eq==""} {
                my AddParam temp $value
            } else {
                error "Wrong value '$eq' of qualifier"
            }
        } -get {
            return [$Value configure -Value]
        }
        variable Name
        variable Value
        constructor {value args} {
            # Creates object of class `Temp`.
            #  value - value of the temperature
            #  args - optional parameter qualificator -eq
            # This class represent .temp statement with temperature value.
            set arguments [argparse {
                {-eq -boolean}
            }]
            my configure -Name temp
            if {$eq} {
                my AddParam temp $value -eq
            } else {
                my AddParam temp $value
            }             
        }       
        method AddParam {paramName value args} {
            # Adds temperature parameter.
            #  paramName - name of temperature parameter
            #  value - value of temperature
            #  args - optional parameter qualificator -eq
            set arguments [argparse {
                {-eq -boolean} 
            }]
            if {$eq} {
                set Value [::SpiceGenTcl::ParameterPositionalEquation new $paramName $value]
            } else {
                set Value [::SpiceGenTcl::ParameterPositional new $paramName $value]
            }
            return
        }
        method genSPICEString {} {
            # Creates .temp statement string for SPICE netlist.
            # Returns: '.temp $Value'
            return ".temp [$Value genSPICEString]"
        }
    }
        
###  Netlist class definition 
    
    oo::configurable create Netlist {
        superclass SPICEElement
        mixin DuplChecker
        property Name -set {
            set Name [string tolower $value]
        }
        variable Name
        variable Elements
        constructor {name} {
            # Creates object of class `Netlist`.
            #  name - name of the netlist
            # Class implements netlist as a collection of SPICE elements. Any element that has SPICEElement
            # as a parent class can be added to Netlist, except Options and Analysis.
            my configure -Name $name
        }
        method add {element} {
            # Adds elements object to Elements dictionary.
            #  element - element object reference
            set elementClass [info object class $element]
            if {$elementClass=={::SpiceGenTcl::Options}} {
                error "Options element can't be included in general netlist, only top-level Circuit"
            } elseif {$elementClass=={::SpiceGenTcl::Analysis}} {
                error "Analysis element can't be included in general netlist, only top-level Circuit"
            }
            set elemName [string tolower [$element configure -Name]]
            if {[info exists Elements]} {
                set elemList [my getAllElemNames]
            }
            lappend elemList $elemName
            if {[my duplListCheck $elemList]} {
                error "Netlist '[my configure -Name]' already contains element with name $elemName"
            }
            dict append Elements [$element configure -Name] $element 
            return
        }
        method del {elemName} {
            # Deletes element from the netlist by its name.
            #  elemName - name of element to delete
            set elemName [string tolower $elemName]
            set error [catch {dict get $Elements $elemName}]
            if {$error>0} {
                error "Element with name '$elemName' was not found in netlist's '[my configure -Name]' list of elements"
            } else {
                set Elements [dict remove $Elements $elemName]
            }
            return
        }
        method getElement {elemName} {
            # Gets particular element object reference by its name.
            #  elemName - name of element
            set elemName [string tolower $elemName]
            set error [catch {dict get $Elements $elemName}]
            if {$error>0} {
                error "Element with name '$elemName' was not found in netlist's '[my configure -Name]' list of elements"
            } else {
                set foundElem [dict get $Elements $elemName]
            }
            return $foundElem
        }
        method getAllElemNames {} {
            # Gets names of all elements in netlist.
            # Returns: list of elements names
            dict for {elemName elem} $Elements {
                lappend names $elemName
            }
            return $names
        }
        method genSPICEString {} {
            # Creates netlist string for SPICE netlist.
            # Returns: 'netlist string'
            dict for {elemName element} $Elements {
                lappend totalStr [$element genSPICEString]
            }
            return [join $totalStr \n]
        }
    }

    
###  Circuit class definition 
    
    oo::configurable create Circuit {
        superclass Netlist
        # simulator object that run simulation
        property Simulator
        variable Simulator
        # standard output of simulation
        property Log
        variable Log
        # results of simulation in form of RawData object
        property Data
        variable Data
        # flag that tells about Analysis element presence in Circuit
        variable ContainAnalysis
        constructor {name} {
            # Creates object of class `CircuitNetlist`.
            #  name - name of the tol-level circuit
            # Class implements a top level netlist which is run in SPICE. We should add `Simulator`
            # object reference to make it able to run simulation. Results of last simulation attached as `RawData`
            # class object and can be retrieved by `getData` method.
            next $name
        }
        method add {element} {
            # Adds elements object to Elements dictionary.
            #  element - element object reference
            my variable Elements
            set elemName [string tolower [$element configure -Name]]
            if {([info object class $element {::SpiceGenTcl::Analysis}]) && ([info exists ContainAnalysis])} {
                error "Netlist '[my configure -Name]' already contains Analysis element"
            } elseif {[info object class $element {::SpiceGenTcl::Analysis}]} {
                set ContainAnalysis ""
            }
            if {[info exists Elements]} {
                set elemList [my getAllElemNames]
            }
            lappend elemList $elemName
            if {[my duplListCheck $elemList]} {
                error "Netlist '[my configure -Name]' already contains element with name $elemName"
            }
            dict append Elements [$element configure -Name] $element 
            return
        }
        method del {elemName} {
            # Deletes element from the circuit by its name.
            #  elemName - name of element to delete
            my variable Elements
            set elemName [string tolower $elemName]
            set error [catch {dict get $Elements $elemName}]
            if {$error>0} {
                error "Element with name '$elemName' was not found in device's '[my configure -Name]' list of elements"
            } else {
                set Elements [dict remove $Elements $elemName]
                if {[info object class [dict get $Elements $elemName] {::SpiceGenTcl::Analysis}]} {
                    unset ContainAnalysis
                }
            }
            return
        }
        method getElement {elemName} {
            # Gets particular element object reference by its name.
            #  elemName - name of element
            my variable Elements
            set elemName [string tolower $elemName]
            set error [catch {dict get $Elements $elemName}]
            if {$error>0} {
                error "Element with name '$elemName' was not found in netlist's '[my configure -Name]' list of elements"
            } else {
                set foundElem [dict get $Elements $elemName]
            }
            return $foundElem
        }
        method detachSimulator {} {
            # Removes `Simulator` object reference from `Circuit`.
            unset Simulator
            return
        }
        method getDataDict {} {
            # Method to get dictionary with raw data vectors.
            # Returns: dict with vectors data, keys - names of vectors
            return [[my configure -Data] getTracesData]
        }
        method getDataCsv {args} {
            # Returns string with csv formatting containing all data
            #  -all - select all traces
            #  -traces - select names of traces to return
            #  -sep - separator of columns, default is comma
            return [[my configure -Data] getTracesCsv {*}$args]
        }
        method genSPICEString {} {
            # Creates circuit string for SPICE netlist.
            # Returns: 'circuit string'
            my variable Elements
            lappend totalStr [my configure -Name]
            dict for {elemName element} $Elements {
                lappend totalStr [$element genSPICEString]
            }
            return [join $totalStr \n]
        }
        method runAndRead {args} {
            # Invokes 'runAndRead', 'configure -Log' and 'configure -Data' methods from attached simulator.
            #  -nodelete - flag to forbid simulation file deletion
            set arguments [argparse {
                -nodelete
            }]
            if {[info exists Simulator]==0} {
                error "Simulator is not attached to '[my configure -Name]' circuit"
            }
            if {[info exists nodelete]} {
                $Simulator runAndRead [my genSPICEString] -nodelete
            } else {
                $Simulator runAndRead [my genSPICEString]
            }
            my configure -Log [$Simulator configure -Log]
            my configure -Data [$Simulator configure -Data]
        }
    }
    
###  Subcircuit class definition 
    
    oo::configurable create Subcircuit {
        superclass Netlist
        # pins that printed on definition line of subcircuit
        variable Pins
        # params that printed on definition line of subcircuit
        variable Params
        constructor {name pins params} {
            # Creates object of class `Subcircuit`.
            #  name - name of the subcircuit
            #  pins - list of pins in the order they appear in SPICE subcircuits definition together
            #   in form: `{pinName0 pinName1 pinName2 ...}`
            #  params - list of input parameters in form `{{Name Value} {Name Value} {Name Value} ...}`
            # This class implements subcircuit, it is subclass of netlist because it holds list of elements
            # inside subcircuit, together with header and connection of elements inside.
            
            # create Pins objects, nodes are set to empty line
            foreach pin $pins {
                my AddPin [lindex $pin 0] {}
            }
            # create Params objects that are input parameters of subcircuit
            if {$params!=""} {
                foreach param $params {
                    if {[llength $param]<=2} {
                        my addParam [lindex $param 0] [lindex $param 1] 
                    } else {
                        error "Wrong parameter '[lindex $param 0]' definition in subcircuit $name"
                    }  
                }
            } else {
                set Params ""
            }
            # pass name of subcircuit to Netlist constructor
            next $name
        }
        # copy methods of Device to manipulate header .subckt definition elements
        set def [info class definition ::SpiceGenTcl::Device AddPin]
        method AddPin [lindex $def 0] [lindex $def 1]       
        set def [info class definition ::SpiceGenTcl::Device getPins]
        method getPins [lindex $def 0] [lindex $def 1] 
        set def [info class definition ::SpiceGenTcl::Device deleteParam]
        method deleteParam [lindex $def 0] [lindex $def 1] 
        set def [info class definition ::SpiceGenTcl::Device setParamValue]
        method setParamValue [lindex $def 0] [lindex $def 1]     
        set def [info class definition ::SpiceGenTcl::Device getParams]
        method getParams [lindex $def 0] [lindex $def 1]  
        method addParam {paramName value} {
            # Adds new parameter to subcircuit, and throws error
            #  on dublicated names.
            #  paramName - name of parameter
            #  value - value of parameter
            set paramName [string tolower $paramName]
            if {[info exists Params]} {
                set paramList [dict keys $Params]
            }
            lappend paramList $paramName
            if {[my duplListCheck $paramList]} {
                error "Parameters list '$paramList' has already contains parameter with name '$paramName'"
            }
            dict append Params $paramName [::SpiceGenTcl::Parameter new $paramName $value]
            return
        }
        
        method add {element} {
            # Add element object reference to `Netlist`, it extends add method to add check of element class because
            # subcircuit can't contain particular elements inside, like `Include`, `Library`, `Options` and `Analysis`.
            #  element - element object reference
            set elementClass [info object class $element]
            set elementClassSuperclass [info class superclasses $elementClass]
            if {$elementClass=={::SpiceGenTcl::Include}} {
                error "Include element can't be included in subcircuit"
            } elseif {$elementClass=={::SpiceGenTcl::Library}} {
                error "Library element can't be included in subcircuit"
            } elseif {$elementClass=={::SpiceGenTcl::Options}} {
                error "Options element can't be included in subcircuit"
            } elseif {$elementClassSuperclass=={::SpiceGenTcl::Analysis}} {
                error "Analysis element can't be included in subcircuit"
            }
            next $element
        }
        method genSPICEString {} {
            # Creates subcircuit string for SPICE subcircuit.
            # Returns: '.subckt $Pins $Params'
            set name [my configure -Name]
            dict for {pinName pin} $Pins {
                lappend nodes [$pin configure -Name]
            }
            if {$Params==""} {
                lappend params ""
                set header ".subckt $name [join $nodes]"
            } else {
                dict for {paramName param} $Params {
                    lappend params [$param genSPICEString]
                }
                set header ".subckt $name [join $nodes] [join $params]"
            }
            # get netlist elements from netlist genSPICEString method 
            set resStr [next]
            set end ".ends"
            return [join [list $header $resStr $end] \n]
        }
    }
    
###  Analysis class definition 
    
    oo::configurable create Analysis {
        superclass SPICEElement
        mixin DuplChecker
        property Name -set {
            set Name [string tolower $value]
        }
        variable Name
        # type of analysis, i.e. dc, ac, tran, etc
        property Type -set {
            set type [string tolower $value]
            set suppAnalysis [list ac dc tran op disto noise pz sens sp tf]
            if {$value ni $suppAnalysis} {
                error "Type '$value' is not in supported list of analysis, should be one of '$suppAnalysis'"
            }
            set Type $value
        }
        variable Type
        # list of Parameter objects
        variable Params
        constructor {type params args} {
            # Creates object of class `Analysis`.
            #  type - type of analysis, for example, tran, ac, dc, etc
            #  params - list of instance parameters in form 
            #   `{{Name Value} {Name -sw} {Name Value -eq} {Name Value -posnocheck} ...}`
            #  args - optional argument *-name*
            # Class models analysis statement.
            my variable Name
            set arguments [argparse {
                -name=
            }]
            if {[info exists name]} {
                my configure -Name $name
            } else {
                my configure -Name [self object]
            }
            my configure -Type $type
            # create Analysis objects
            foreach param $params {
                if {[lindex $param 2]=={}} {
                    my addParam [lindex $param 0] [lindex $param 1]    
                } elseif {[lindex $param 1]=="-sw"} {
                    my addParam [lindex $param 0] -sw 
                } else {
                    my addParam {*}$param
                } 
            }
        }
        method getParams {} {
            # Gets the dictionary that contains parameter name as keys and
            #  parameter values as the values
            # Returns: parameters dictionary
            set tempDict [dict create]
            dict for {paramName param} $Params {
                dict append tempDict $paramName [$param configure -Value]
            }
            return $tempDict
        }
        method addParam {paramName value args} {
            # Adds new Parameter object to the list `Params`.
            #  paramName - name of parameter
            #  value - value of parameter
            #  args - optional arguments *-eq* or *-posnocheck* as parameter qualificators
            set arguments [argparse {
                {-eq -forbid {posnocheck}}
                {-poseq -forbid {posnocheck}}
                {-posnocheck -forbid {eq}}
                {-pos -forbid {eq}}
                {-nocheck -forbid {eq}}
            }]
            set paramName [string tolower $paramName]
            if {[info exists Params]} {
                set paramList [dict keys $Params]
            }
            lappend paramList $paramName
            if {[my duplListCheck $paramList]} {
                error "Parameters list \{$paramList\} has already contains parameter with name \{$paramName\}"
            }
            if {$value=="-sw"} {
                dict append Params $paramName [::SpiceGenTcl::ParameterSwitch new $paramName]
            } elseif {[info exists eq]} {
                dict append Params $paramName [::SpiceGenTcl::ParameterEquation new $paramName $value]
            } elseif {[info exists poseq]} {
                dict append Params $paramName [::SpiceGenTcl::ParameterPositionalEquation new $paramName $value]
            } elseif {[info exists posnocheck]} {
                dict append Params $paramName [::SpiceGenTcl::ParameterPositionalNoCheck new $paramName $value]
            } elseif {[info exists pos]} {
                dict append Params $paramName [::SpiceGenTcl::ParameterPositional new $paramName $value]
            } elseif {[info exists nocheck]} {
                dict append Params $paramName [::SpiceGenTcl::ParameterNoCheck new $paramName $value]
            } else {
                dict append Params $paramName [::SpiceGenTcl::Parameter new $paramName $value]
            }
            return
        }
        set def [info class definition ::SpiceGenTcl::Device deleteParam]
        method deleteParam [lindex $def 0] [lindex $def 1]
        method setParamValue {paramName value} {
            # Sets (or changes) value of particular parameter.
            #  paramName - name of parameter
            #  value - the new value of parameter
            set paramName [string tolower $paramName]
            set error [catch {dict get $Params $paramName}]
            if {$error>0} {
                error "Parameter with name '$paramName' was not found in parameter analysis's '[my configure -Name]'\
                        list of parameters '[dict keys [my getParams]]'"
            } else {
                set param [dict get $Params $paramName]
            }
            $param configure -Value $value
            return
        }
        method genSPICEString {} {
            # Creates analysis for SPICE netlist.
            # Returns: string '.$Type $Params'
            if {[info exists Params]} {
                dict for {paramName param} $Params {
                    lappend params [$param genSPICEString]
                }
                return ".[my configure -Type] [join $params]"
            } else {
                return ".[my configure -Type]"
            }
        }
    }

###  Simulator class definition 
    
    oo::configurable create Simulator {
        self mixin -append oo::abstract
        property Name
        variable Name
        property Command
        variable Command
        property Log
        variable Log
        property Data
        variable Data
        method run {} {
            # Runs simulation.
            error "Not implemented"
        }
        method readLog {} {
            # Reads log file of completed simulations.
            error "Not implemented"
        }
        method getLog {} {
            # Returns log file of completed simulations.
            error "Not implemented"
        }
        method readData {} {
            # Reads raw data file of last simulation.
            error "Not implemented"
        }
    }     

###  BinaryReader class definition 
   
    oo::configurable create BinaryReader {
        self mixin -append oo::abstract
        method readFloat64 {file} {
            # Reads 8 bytes number from file .
            #  file - file handler
            # Returns: value of number.
            set s [read $file 8]
            binary scan $s "d" num
            return $num
        }
        method readComplex {file} {
            # Reads two 8 byte numbers from file.
            #  file - file handler
            # Returns: list of two values.
            set s [read $file 16]
            binary scan $s "dd" re im
            return [list $re $im]
        }
        method readFloat32 {file} {
            # Reads 4 bytes number from file.
            #  file - file handler
            # Returns: value of number.
            set s [read $file 4]
            binary scan $s "f" num
            return $num
        }
        method skip4bytes {file} {
            # Moves pointer of position in file forward in 4 bytes.
            #  file - file handler
            read $file 4
            return
        }
        method skip8bytes {file} {
            # Moves pointer of position in file forward in 8 bytes.
            #  file - file handler
            read $file 8
            return
        }
        method skip16bytes {file} {
            # Moves pointer of position in file forward in 16 bytes.
            #  file - file handler
            read $file 16
            return
        }
    }
    
###  Dataset class 
    
    oo::configurable create Dataset {
        # This class models general raw dataset
        property Name -set {
            set Name [string tolower $value]
        }
        variable Name
        # Type of dataset, could be voltage, vurrent, time or frequency
        property Type -set {
            set Type [string tolower $value]
        }
        variable Type
        # Numerical type of dataset, real, double or complex
        property NumType -set {
            # method to set the numerical type of the dataset
            if {$value ni [list real complex double]} {
                error "Unknown numerical type '$value' of data"
            }
            set NumType $value
        }
        variable NumType
        # Number of points (length of dataset)
        property Len
        variable Len
        # values at points
        variable DataPoints
        constructor {name type len {numType real}} {
            # initialize dataset
            #  name - name of the dataset
            #  type - type of dataset
            #  len - total number of points
            #  numType - numerical type of dataset
            my configure -Name $name
            my configure -Type $type
            my configure -Len $len
            my configure -NumType $numType
        }
        method setDataPoints {dataPoints} {
            # method to set the data points
            set DataPoints $dataPoints
            return
        }
        method appendDataPoints {dataPoint} {
            # method to set the data points
            lappend DataPoints $dataPoint
            return
        }
        method getDataPoints {} {
            if {[info exists DataPoints]} {
                return $DataPoints
            } else {
                error "Dataset with name '[my configure -Name]' doesn't contain non-zero points"
            }
            return 
        }
        method getStr {} {
            return "Name: '[my configure -Name]', Type: '[my configure -Type]',\
                    Length: '[my configure -Len]', Numerical type: '[my configure -NumType]'"
        }
    }
    
###  Axis class definition 

    oo::configurable create Axis {
        # class that represents axis in raw file
        superclass Dataset
        constructor {name type len {numType real}} {
            # initialize axis
            #  name - name of the axis
            #  type - type of axis
            #  len - total number of points
            #  numType - numerical type of axis
            next $name $type $len $numType
        }
    }
    
###  Trace class definition 

    oo::configurable create Trace {
        # class that represents trace in raw file
        superclass Dataset
        property Axis
        variable Axis
        constructor {name type len axis {numType real}} {
            # initialize trace
            #  name - name of the trace
            #  type - type of trace
            #  len - total number of points
            #  axis - name of axis that is linked to trace
            #  numType - numerical type of trace
            my configure -Axis $axis
            next $name $type $len $numType
        }
    }
    
###  EmptyTrace class definition 

    oo::configurable create EmptyTrace {
        # Class represents empty trace (trace that was not readed) in raw file
        superclass Dataset
        constructor {name type len {numType real}} {
            # initialize dummy trace
            #  name - name of the dummy trace
            #  type - type of dummy trace
            #  len - total number of points
            #  axis - name of axis that is linked to dummy trace
            #  numType - numerical type of dummy trace
            next $name $type $len $numType
        }
        method getDataPoints {} {
            if {[info exists DataPoints]} {
                return ""
            }
            return 
        }
    }
    
###  RawFile class definition 

    oo::configurable create RawFile {
        # Class represents raw file
        mixin BinaryReader
        # path to raw file including it's file name
        property Path
        variable Path
        # parameters of raw file readed from it's header
        property RawParams
        variable RawParams 
        # number of points in raw file
        property NPoints
        variable NPoints 
        # number of variables in raw file
        property NVariables
        variable NVariables
        # object reference of axis in raw file
        property Axis -get {
            if {[info exists Axis]} {
                return $Axis
            } else {
                error "Raw file '[my configure -Path]' doesn't have an axis"
            }
        }
        variable Axis 
        # objects references of traces in raw file
        property Traces
        variable Traces
        # binary block size in bytes that contains all variables at axis point value
        property BlockSize
        variable BlockSize
        constructor {path {traces2read *} {simulator ngspice}} {
            # Creates RawFile object.
            #  path - path to raw file including it's file name
            #  traces2read - list of traces that will be readed, default value is \*, 
            #   that means reading all traces
            #  simulator - simulator that produced this raw file, default is ngspice
            my configure -Path $path
            set fileSize [file size $path]
            set file [open $path r]
            fconfigure $file -translation binary
            
####  read header 

            set ch [read $file 6]
            if {$ch=={Title:}} {
                set encSize 1
                set encode "utf-8"
                set line "Title:"
            } elseif {$ch=={Tit}} {
                set encSize 2
                set encode "utf-16-le"
                set line "Tit"
            } else {
                error "Unknown encoding"
            }
            my configure -RawParams [dict create Filename $path]
            set header ""
            set binaryStart 6            
            while true {
                set ch [read $file $encSize]
                incr binaryStart $encSize
                if {$ch=="\n"} {
                    if {$encode=="utf-8"} {
                        set line [string trimright $line "\r"]
                    }
                    lappend header $line
                    if {$line in {Binary: Values:}} {
                        set rawType $line
                        break
                    }
                    set line ""
                } else {
                    append line $ch
                }
            }

####  save header parameters 

            foreach line $header {
                set lineList [split $line ":"]
                if {[lindex $lineList 0]=="Variables"} {
                    break
                }
                dict append RawParams [lindex $lineList 0] [string trim [lindex $lineList 1]]
            }
            my configure -NPoints [dict get [my configure -RawParams] "No. Points"]
            my configure -NVariables [dict get [my configure -RawParams] "No. Variables"]
            if {[dict get [my configure -RawParams] "Plotname"] in {"Operating Point" "Transfet Function"}} {
                set hasAxis 0
            } else {
                set hasAxis 1
            }
            set flags [split [dict get [my configure -RawParams] "Flags"]]
            if {("complex" in $flags) || ([dict get [my configure -RawParams] "Plotname"]=="AC Analysis")} {
                set numType complex
            } else {
                if {("double" in $flags) || ($simulator=="ngspice")} {
                    set numType double
                } else {
                    set numType real
                }
            }
            
####  parse variables 
            
            set i [lsearch $header "Variables:"]
            set ivar 0
            foreach line [lrange $header [+ $i 1] end-1] {
                set lineList [split [string trim $line] \t]
                lassign $lineList idx name varType
                if {$ivar==0} {
                    if {$numType=="real"} {
                        set axisNumType double
                    } else {
                        set axisNumType $numType
                    }
                    my configure -Axis [::SpiceGenTcl::Axis new $name $varType $NPoints $axisNumType]
                    set trace $Axis
                } elseif {($traces2read=="*") || ($name in $traces2read)} {
                    if {$hasAxis} {
                        set trace [::SpiceGenTcl::Trace new $name $varType $NPoints\
                                           [[my configure -Axis] configure -Name] $numType]
                    } else {
                        set trace [::SpiceGenTcl::Trace new $name $varType $NPoints {} $numType]
                    }
                } else {
                    set trace [::SpiceGenTcl::EmptyTrace new $name $varType $NPoints $numType]
                }
                lappend Traces $trace
                incr ivar
            }
            if {($traces2read=="") || ([llength $traces2read]==0)} {
                close $file
                return
            }
            
####  read data 
            
            if {$rawType=="Binary:"} {
                my configure -BlockSize [expr {($fileSize - $binaryStart)/$NPoints}]
                set scanFunctions ""
                set calcBlockSize 0
                foreach trace [my configure -Traces] {
                    if {[$trace configure -NumType]=="double"} {
                        incr calcBlockSize 8
                        if {[info object class $trace ::SpiceGenTcl::EmptyTrace]} {
                            set fun skip8bytes 
                        } else {
                            set fun readFloat64
                        }
                    } elseif {[$trace configure -NumType]=="complex"} {
                        incr calcBlockSize 16
                        if {[info object class $trace ::SpiceGenTcl::EmptyTrace]} {
                            set fun skip16bytes 
                        } else {
                            set fun readComplex 
                        }
                    } elseif {[$trace configure -NumType]=="real"} {
                        incr calcBlockSize 4
                        if {[info object class $trace ::SpiceGenTcl::EmptyTrace]} {
                            set fun skip4bytes 
                        } else {
                            set fun readFloat32 
                        }
                    } else {
                        error "Invalid data type '[$trace configure -NumType]' for trace '[$trace configure -Name]'"
                    }
                    lappend scanFunctions $fun
                }
                if {$calcBlockSize!=[my configure -BlockSize]} {
                    error "Error in calculating the block size. Expected '[my configure -BlockSize]' bytes, but found\
                            '$calcBlockSize' bytes"
                }
                 for {set i 0} {$i<$NPoints} {incr i} {
                    for {set j 0} {$j<[llength [my configure -Traces]]} {incr j} {
                        set value [eval "my [lindex $scanFunctions $j]" $file] 
                        set trace [lindex [my configure -Traces] $j]
                        if {[info object class $trace]!="::SpiceGenTcl::EmptyTrace"} {
                            $trace appendDataPoints $value 
                        }  
                    }
                }                 
            } elseif {$rawType=="Values:"} {
                for {set i 0} {$i<$NPoints} {incr i} {
                    set firstVar true
                    for {set j 0} {$j<[llength [my configure -Traces]]} {incr j} {
                        set line [gets $file]
                        if {$line==""} {
                            continue
                        }
                        set lineList [textutil::split::splitx $line]
                        #puts $lineList
                        if {$firstVar=="true"} {
                            set firstVar false
                            set sPoint [lindex $lineList 0]
                            #puts "$sPoint $i"
                            if {$i!=int($sPoint)} {
                                error "Error reading file"
                            }
                            if {$numType=="complex"} {
                                set value [split [lindex $lineList 1] ","]
                            } else {
                                set value [lindex $lineList 1]
                            } 
                        } else {
                            if {$numType=="complex"} {
                                set value [split [lindex $lineList 1] ","]
                            } else {
                                set value [lindex $lineList 1]
                            }
                        }
                        set trace [lindex [my configure -Traces] $j]
                        $trace appendDataPoints $value 
                    }
                }
            }
            close $file
        }
        method getTrace {traceName} {
            # Returns trace object reference by it's name
            set traceFoundFlag false
            foreach trace [my configure -Traces] {
                if {[$trace configure -Name]==$traceName} {
                    set traceFound $trace
                    set traceFoundFlag true
                    break
                }
            }
            if {$traceFoundFlag==false} {
                error "Trace with name '$traceName' was not found in raw file '[my configure -Path]' list of traces"
            }
            return $traceFound
        }
        method getVariablesNames {} {
            # Returns list that contains names of all variables
            foreach trace [my configure -Traces] {
                lappend tracesNames [$trace configure -Name]
            }
            return $tracesNames
        }
        method getVoltagesNames {} {
            # Returns list that contains names of all voltage variables
            foreach trace [my configure -Traces] {
                if {[$trace configure -Type]=="voltage"} {
                    lappend voltNames [$trace configure -Name]
                }
            }
            return $voltNames
        }
        method getCurrentsNames {} {
            # Returns list that contains names of all current variables
            foreach trace [my configure -Traces] {
                if {[$trace configure -Type]=="current"} {
                    lappend currNames [$trace configure -Name]
                }
            }
            return $currNames
        }
        method getTracesStr {} {
            # Returns information about all Traces in raw file in form of string
            foreach trace [my configure -Traces] {
                lappend tracesList "[$trace configure -Name] [$trace configure -Type] [$trace configure -NumType]"
            }
            return $tracesList
        }
        method getTracesData {} {
            # Returns dictionary that contains all data in value and name as a key
            set dict [dict create]
            foreach trace [my configure -Traces] {
                dict append dict [$trace configure -Name] [$trace getDataPoints]
            }
            return $dict
        }
        method getTracesCsv {args} {
            # Returns string with csv formatting containing all data
            #  -all - select all traces
            #  -traces - select names of traces to return
            #  -sep - separator of columns, default is comma
            set arguments [argparse -inline {
                {-all -forbid {traces}}
                {-traces -catchall -forbid {all}}
                {-sep= -default {,}}
            }]
            if {[dict exists $arguments all]} {
                set tracesDict [my getTracesData]
                set tracesList [list [dict keys $tracesDict]]
                for {set i 0} {$i<[my configure -NPoints]} {incr i} {
                    dict for {traceName traceValues} $tracesDict {
                        lappend row [lindex $traceValues $i]
                    }
                    lappend tracesList $row
                    unset row
                }
            } elseif {[dict get $arguments traces]!=""} {
                foreach traceName [dict get $arguments traces] {
                    set traceObj [my getTrace $traceName]
                    dict append tracesDict [$traceObj configure -Name] [$traceObj getDataPoints]
                }
                set tracesList [list [dict keys $tracesDict]]
                for {set i 0} {$i<[my configure -NPoints]} {incr i} {
                    dict for {traceName traceValues} $tracesDict {
                        lappend row [lindex $traceValues $i]
                    }
                    lappend tracesList $row
                    unset row
                }
            } else {
                error "Arguments '-all' or '-traces traceName1 traceName2 ...' must be provided to 'getTracesCsv'\
                        method"
            }
            return [::csv::joinlist $tracesList [dict get $arguments sep]]
        }
    }
}


