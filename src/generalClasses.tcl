

namespace eval SpiceGenTcl {

    namespace export Pin ParameterSwitch Parameter ParameterNoCheck ParameterPositional ParameterPositionalNoCheck \
            ParameterDefault ParameterEquation ParameterPositionalEquation Device DeviceModel Model RawString Comment Include Options \
            ParamStatement Temp Netlist Circuit Library Subcircuit Analysis Simulator Dataset Axis Trace DummyTrace RawFile
    namespace export importNgspice
    
    proc importNgspice {} {
        # Imports all ::SpiceGenTcl::Ngspice commands to caller namespace
        uplevel 1 {foreach nameSpc [namespace children ::SpiceGenTcl::Ngspice] {
            namespace import ${nameSpc}::*
        }}
    }
    
    
   # ________________________ SPICEElement class definition _________________________ #
    
    oo::class create SPICEElement {
        # Abstract class of all elements of SPICE netlist
        #  and it forces implementation of genSPICEString method for all subclasses.
        variable Name
        method genSPICEString {} {
            # Declaration of method common for all SPICE elements that generates 
            #  representation of element in SPICE netlist. Not implemented in
            #  abstraction class.
            error "Not implemented"
        }
        method SetName {name} {
            # Declaration of method common for all SPICE elements that set name 
            #  of element. Not implemented in abstraction class.
            error "Not implemented"
        }
        method getName {} {
            # Gets the name of the SPICE element.
            # Returns: name of SPICE element
            return $Name
        }
        self unexport create new
    }
    
   # ________________________ DuplChecker class definition _________________________ #
   
    oo::class create DuplChecker {
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

   # ________________________ ParamNameChecker class definition _________________________ #
     
    oo::class create ParamNameChecker {
        method checkName {name} {
            # Checks parameter name for forbidden symbols.
            #  name - name to check
            if {$name==""} {
                error "Parameter must have a name, empty string was provided"
            } elseif {[regexp {[^A-Za-z0-9_]+} $name]} {
                error "Parameter name '$name' is not a valid name"
            } elseif {[regexp {^[A-Za-z][A-Za-z0-9]*} $name]} {
                return
            } else {
                error "Parameter name '$name' is not a valid name"
            }
            return
        }
    }

    # ________________________ ValueChecker class definition _________________________ #

    oo::class create ValueChecker {
        method checkValue {value} {
            # Checks the value.
            #  value - value to check
            if {[regexp {^[+\-]?(?=\.\d|\d)(?:0|[1-9]\d*)?(?:\.\d*)?(?:\d[eE][+\-]?\d+)?$} $value]} {
                return
            } else {
                error "Value '$value' is not a valid value"
            }
        }
    }

    # ________________________ KeyArgsBuilder class definition _________________________ #

    oo::class create KeyArgsBuilder {
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
    }
    
    # ________________________ Pin class definition _________________________ #

    oo::class create Pin {
        superclass SPICEElement
        # name of the node connected to pin
        variable NodeName
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
            my SetName $name
            my setNodeName $nodeName
        }
        method CheckNodeName {nodeName} {
            # Checks node name for forbidden symbols.
            #  nodeName - name of the node
            if {[regexp {[^A-Za-z0-9_]+} $nodeName]} {
                error "Node name '${nodeName}' is not a valid name"
            }
        }
        method checkName {name} {
            # Checks pin name for forbidden symbols.
            #  name - name of the pin
            if {$name==""} {
                error "Pin must have a name, empty string was provided"
            } elseif {[regexp {[^A-Za-z0-9_]+} $name]} {
                error "Pin name '$name' is not a valid name"
            }
        }

        method getNodeName {} {
            # Gets the name of the node connected to pin.
            # Returns: value of the node connected to pin
            return $NodeName
        }
        method setNodeName {nodeName} {
            # Sets the name of the node connected to this pin.
            #  nodeName - name of the node connected to pin
            my CheckNodeName $nodeName
            set NodeName [string tolower $nodeName]
            return
        }
        method SetName {name} {
            # Sets the name of the pin.
            #  name - name of the pin
            my variable Name
            my checkName $name
            set Name [string tolower $name]
            return
        }
        method unsetNodeName {} {
            # Makes pin floating by setting `NodeName` with empty string.
            my setNodeName {}
        }
        method checkFloating {} {
            # Determines if pin is connected to the node.
            # Returns: `true` if connected and `false` if not
            if {[my getNodeName]=={}} {
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
                error "Pin '[my getName]' is not connected to the node so can't be netlisted"
            }
            return "[my getNodeName]"
        }
    }
    
    # ________________________ ParameterSwitch class definition _________________________ #

    oo::class create ParameterSwitch {
        superclass ParamNameChecker SPICEElement
        constructor {name} {
            # Creates object of class `ParameterSwitch` with parameter name.
            #  name - name of the parameter
            # Class models base parameter acting like a switch - 
            # its presence gives us information that something it controls is on.
            # This parameter doesn't have a value, and it is the most basic class
            # in Parameter class family.
            my SetName $name
        }
        method SetName {name} {
            # Sets the name of the parameter.
            #  name - name of parameter
            my variable Name
            my checkName $name
            set Name [string tolower $name]
            return
        }
        method getValue {} {
            # Gets the value of the parameter.
            # Returns: empty string
            return {}
        }
        method genSPICEString {} {
            # Creates string for SPICE netlist.
            # Returns: string '$Name'
            return "[my getName]"
        }
    }
    # ________________________ Parameter class definition _________________________ #

    oo::class create Parameter {
        superclass ParameterSwitch ValueChecker 
        variable Value
        constructor {name value} {
            # Creates object of class `Parameter` with parameter name and value.
            #  name - name of the parameter
            #  value - value of the parameter
            # Class models parameter that has a name and a value - the most
            # common type of parameters in SPICE netlist. Its representation in netlist is
            # 'Name=Value', and can be called "keyword parameter".
            my SetName $name
            my setValue $value
        }
        method getValue {} {
            # Gets the value of the parameter.
            # Returns: value of parameter
            return $Value
        }
        method setValue {value} {
            # Sets value of the parameter.
            #  value - value of parameter
            my checkValue $value
            set Value $value
            return
        }
        method genSPICEString {} {
            # Creates string for SPICE netlist.
            # Returns: '$Name=$Value'
            return "[my getName]=[my getValue]"
        }
    }

    # ________________________ ParameterNoCheck class definition _________________________ #

    oo::class create ParameterNoCheck {
        superclass Parameter
        constructor {name value} {
            # Creates object of class `ParameterNoCheck` with parameter name and value.
            #  name - name of the parameter
            #  value - value of the parameter
            # Class models parameter the same as described by `Parameter` but without check for value form.
            next $name $value
        }
        method checkValue {value} {
            # Checks the value.
            #  value - value to check
            if {$value==""} {
                error "Value '$value' is not a valid value"
            } 
        }
        method setValue {value} {
            # Sets the value of the parameter.
            #  value - value of parameter
            my variable Value
            my checkValue $value
            set Value $value
            return
        }
    }    
    
    # ________________________ ParameterPositional class definition _________________________ #

    oo::class create ParameterPositional {
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
            return "[my getValue]"
        }
    }
    
    # ________________________ ParameterPositionalNoCheck class definition _________________________ #

    oo::class create ParameterPositionalNoCheck {
        superclass ParameterPositional
        constructor {name value} {
            # Creates object of class `ParameterPositionalNoCheck`.
            #  name - name of parameter
            #  value - value of parameter
            # Class models parameter the same as described by `ParameterPositional` but without check for value form.
            next $name $value
        }
        method setValue {value} {
            # Sets the value of the parameter.
            #  value - value of parameter
            my variable Value
            set Value $value
            return
        }
        method genSPICEString {} {
            # Creates string for SPICE netlist.
            # Results: '$Value'
            return "[my getValue]"
        }
    }
    
    # ________________________ ParameterDefault class definition _________________________ #

    oo::class create ParameterDefault {
        superclass Parameter
        variable DefValue
        constructor {name value defValue} {
            # Creates object of class `ParameterDefault` with parameter name, value and default value.
            #  name - name of the parameter
            #  value - value of the parameter
            #  defValue - default value of the parameter
            # Class models parameter that has a name and a value, but it differs from
            # parent class in sense of having default value, so it has special ability to reset its value to default
            # value by special method `resetValue`.
            my setDefValue $defValue
            next $name $value
        }
        method getDefValue {} {
            # Gets the default value of the parameter.
            # Returns: default parameter value
            return $DefValue
        }
        method setDefValue {defValue} {
            # Sets the default value of the parameter.
            #  defValue - default value of parameter
            my checkValue $defValue
            set DefValue $defValue
            return
        }
        method resetValue {} {
            # Resets value of the parameter to it's default value.
            my variable Value
            set Value $DefValue
            return
        }
    }
    
    # ________________________ ParameterEquation class definition _________________________ #

    oo::class create ParameterEquation {
        superclass Parameter
        constructor {name value} {
            # Creates object of class `ParameterEquation` with parameter name and value as an equation.
            #  name - name of the parameter
            #  value - value of the parameter
            # Class models parameter that has representation as an equation.
            # Example: R={R1+R2}
            next $name $value
        }
        method checkValue {value} {
            # Checks the value.
            #  value - value of parameter in form of equation
            if {$value!=""} {
                return
            } else {
                error "Parameter '[my getName]' equation can't be empty"
            }
        }
        method genSPICEString {} {
            # Creates string for SPICE netlist.
            # Returns: '$Name={$Value}'
            return "[my getName]=\{[my getValue]\}"
        }
    }  

    # ________________________ ParameterPositionalEquation class definition _________________________ #

    oo::class create ParameterPositionalEquation {
        superclass ParameterEquation
        constructor {name value} {
            # Creates object of class `ParameterPositionalEquation` with parameter name and value as an equation in positional form.
            #  name - name of the parameter
            #  value - value of the parameter
            # Class models parameter that has representation as an equation, but in form of
            # positional parameter. Example: {R1+R2}
            next $name $value
        }
        method genSPICEString {} {
            # Creates string for SPICE netlist.
            # Returns: '{$paramValue}'
            return "\{[my getValue]\}"
        }
    }
    
    # ________________________ Device class definition _________________________ #

    oo::class create Device {
        superclass SPICEElement
        mixin DuplChecker
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
            #  params - list of instance parameters in form `{{Name Value ?-pos|eq|poseq?} {Name Value ?-pos|eq|poseq?} {Name Value ?-pos|eq|poseq?} ...}`
            #   Parameter list can be empty if device doesn't have instance parameters.
            # Class models general device in SPICE, number of which 
            # must be assembled (connected) to get the circuit to simulate. This class provides basic machinery
            # for creating any device that can be connected to net in circuit. It can be instantiated to create
            # device that contains: 
            #  - reference name, like R1, L1, M1, etc;
            #  - list of pins in the order of appearence of device's definition, for example, 'drain gate source' for MOS
            #     transistor;
            #  - list of parameters, that could be positional (+equation), keyword (+equation) parameters, like `R1 nm np 100 tc1=1 tc2={tc0*tc12}`,
            #     where 100 - positional parameter, tc1 - keyword parameters and tc2 - keyword parameter with equation
            # This class accept definition that contains elements listed above, and generates classes: Pin, Parameter, PositionalParameter
            # with compositional relationship (has a).
            
            my SetName $name
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
                    if {[lindex $param 1]=="-sw"} {
                        my addParam [lindex $param 0] -sw 
                    } elseif {[lindex $param 2]=={}} {
                        my addParam [lindex $param 0] [lindex $param 1] 
                    } elseif {[lindex $param 2]=="-pos"} {
                        my addParam [lindex $param 0] [lindex $param 1] -pos 
                    } elseif {[lindex $param 2]=="-eq"} {
                        my addParam [lindex $param 0] [lindex $param 1] -eq
                    } elseif {[lindex $param 2]=="-poseq"} {
                        my addParam [lindex $param 0] [lindex $param 1] -poseq
                    } else {
                        error "Wrong parameter definition in device $name"
                    }  
                }
            } else {
                set Params ""
            }
        }
        method CheckName {name} {
            # Checks reference name of device for forbidden symbols.
            #  name - reference name of the device
            if {[regexp {[^A-Za-z0-9_]+} $name]} {
                error "Reference name '$name' is not a valid name"
            } elseif {[regexp {^[A-Za-z][A-Za-z0-9]+} $name]} {
                return
            } else {
                error "Reference name '$name' is not a valid name"
            }
        }
        method SetName {name} {
            # Sets the reference name of device.
            #  name - reference name of device
            my variable Name
            my CheckName $name
            set Name [string tolower $name]
            return
        }
        method getPins {} {
            # Gets the dictionary that contains pin name as keys and
            #  connected node name as the values.
            # Returns: parameters dictionary
            set tempDict [dict create]
            dict for {pinName pin} $Pins {
                dict append tempDict $pinName [$pin getNodeName]
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
                error "Pin with name '$pinName' was not found in device's '[my getName]' list of pins '[dict keys [my getPins]]'"
            } else {
                set pin [dict get $Pins $pinName]
            }
            $pin setNodeName $nodeName
        }
        method setParamValue {paramName value} {
            # Sets (or change) value of particular parameter.
            #  paramName - name of parameter
            #  value - new value of parameter
            set paramName [string tolower $paramName]
            set error [catch {dict get $Params $paramName}]
            if {$error>0} {
                error "Parameter with name '$paramName' was not found in device's '[my getName]' list of parameters '[dict keys [my getParams]]'"
            } else {
                set param [dict get $Params $paramName]
            }
            $param setValue $value   
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
            dict append Pins $pinName [SpiceGenTcl::Pin new $pinName $nodeName]
            return
        }
        method addParam {paramName value args} {
            # Adds new parameter to device, and throws error on dublicated names.
            #  paramName - name of parameter
            #  value - value of parameter
            #  args - optional arguments that adds qualificator to parameter: -pos - positional parameter,
            #   -eq - equational parameter, -poseq - positional equation parameter
            set arguments [argparse {
                {-pos -forbid {poseq}}
                {-eq -forbid {poseq}}
                {-poseq -forbid {pos eq}}
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
                dict append Params $paramName [SpiceGenTcl::ParameterSwitch new $paramName]
            } elseif {[info exists pos]} {
                dict append Params $paramName [SpiceGenTcl::ParameterPositional new $paramName $value]
            } elseif {[info exists eq]} {
                dict append Params $paramName [SpiceGenTcl::ParameterEquation new $paramName $value]
            } elseif {[info exists poseq]} {
                dict append Params $paramName [SpiceGenTcl::ParameterPositionalEquation new $paramName $value]
            } else {
                dict append Params $paramName [SpiceGenTcl::Parameter new $paramName $value]
            }
            return
        }
        method deleteParam {paramName} {
            # Deletes existing `Parameter` object from list `Params`.
            #  paramName - name of parameter that will be deleted
            set paramName [string tolower $paramName]
            set error [catch {dict get $Params $paramName}]
            if {$error>0} {
                error "Parameter with name '$paramName' was not found in device's '[my getName]' list of parameters '[dict keys [my getParams]]'"
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
                    lappend floatingPins [$pin getName]
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
                dict append tempDict $paramName [$param getValue]
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
                    error "Device '[my getName]' can't be netlisted because '$pinName' pin is floating"
                }
            }
            if {($Params=="") || ([info exists Params]==0)} {
                lappend params ""
                return "[my getName] [join $nodes]"
            } else {
                dict for {paramName param} $Params {
                    lappend params [$param genSPICEString]
                }
                return "[my getName] [join $nodes] [join $params]"
            }
            
        }
    }

    # ________________________ DeviceModel class definition _________________________ #

    oo::class create DeviceModel {
        superclass Device
        variable ModelName
        constructor {name pins modelName instParams} {
            # Creates object of class `DeviceModel`.
            #  name - name of the device
            #  pins - list of pins in the order they appear in SPICE device's definition together
            #   with connected node in form: `{{Name0 NodeName} {Name1 NodeName} {Name2 NodeName} ...}`
            #   Node string value could be empty.
            #  modelName - name of the model
            #  instParams - list of instance parameters in form `{{Name Value ?-pos|eq|poseq?} {Name Value ?-pos|eq|poseq?} {Name Value ?-pos|eq|poseq?} ...}`
            # Class is almost identical to the Deviceclass, but can model
            # devices that requires model definition in the netlist.
            my SetModelName $modelName
            next $name $pins $instParams
        }    
        method CheckModelName {modelName} {
            # Checks model name of device for forbidden symbols.
            #  modelName - name of device model to check
            if {$modelName==""} {
                error "DeviceModel must have a name of the model, empty string was provided"
            } elseif {[regexp {[^A-Za-z0-9_]+} $modelName]} {
                error "Model name '$modelName' is not a valid name"
            } 
        }
        method getModelName {} {
            # Gets model name of device.
            # Returns: model name
            return $ModelName
        }
        method SetModelName {modelName} {
            # Sets the model name of device.
            #  modelName - name of device model
            my CheckModelName $modelName
            set ModelName [string tolower $modelName]
            return
        }
        method genSPICEString {} {
            # Creates device string for SPICE netlist.
            # Returns: string '$Name $Nodes $ModelName $Params'
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
                return "[my getName] [join $nodes] [my getModelName] [join $params]"
            } 
        }
    }

    # ________________________ Model class definition _________________________ #

    oo::class create Model {
        superclass SPICEElement
        mixin DuplChecker
        # type of the model
        variable Type
        # list of model parameters objects
        variable Params
        constructor {name type params} {
            # Creates object of class `Model`.
            #  name - name of the model
            #  type - type of model, for example, diode, npn, etc
            #  instParams - list of instance parameters in form `{{Name Value ?-pos|eq|poseq?} {Name Value ?-pos|eq|poseq?} {Name Value ?-pos|eq|poseq?} ...}`
            # Class represents model card in SPICE netlist.
            my SetName $name
            my SetType $type
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
        method CheckName {name} {
            # Checks name of the model for forbidden symbols.
            #  name - name to check
            if {$name==""} {
                error "Model must have a name, empty string was provided"
            } elseif {[regexp {[^A-Za-z0-9_]+} $name]} {
                error "Model name '$name' is not a valid name"
            } else {
                return
            }
            return
        }
        method CheckType {type} {
            # Checks type of the model for forbidden symbols.
            #  type - type name to check
            if {$type==""} {
                error "Model must have a type, empty string was provided"
            } elseif {[regexp {[^A-Za-z0-9]+} $type]} {
                error "Model type '$type' is not a valid type"
            } else {
                return
            }
            return
        }
        method SetName {name} {
            # Sets the name of the model.
            #  name - name of the model card
            my variable Name
            my CheckName $name
            set Name [string tolower $name]
            return
        }
        method SetType {type} {
            # Sets the type of the model.
            #  type - type of the model
            my CheckType $type
            set Type [string tolower $type]
            return
        }
        method getType {} {
            # Gets type of the model.
            # Returns: type of the model
            return $Type
        }
        set def [info class definition SpiceGenTcl::Device addParam]
        method addParam [lindex $def 0] [lindex $def 1]
        set def [info class definition SpiceGenTcl::Device deleteParam]
        method deleteParam [lindex $def 0] [lindex $def 1]
        set def [info class definition SpiceGenTcl::Device setParamValue]
        method setParamValue [lindex $def 0] [lindex $def 1]            
        method getParams {} {
            # Gets the dictionary that contains parameter name as keys and
            #  parameter values as the values.
            # Returns: parameters dictionary
            set tempDict [dict create]
            dict for {paramName param} $Params {
                dict append tempDict $paramName [$param getValue]
            }
            return $tempDict
        }
        method genSPICEString {} {
            # Creates model string for SPICE netlist.
            # Returns: string '.model $Name $Type $Params'
            if {($Params=="") || ([info exists Params]==0)} {
                lappend params ""
                return ".model [my getName] [my getType]"
            } else {
                dict for {paramName param} $Params {
                    lappend params [$param genSPICEString]
                }
                return ".model [my getName] [my getType]([join $params])"
            }
        }
    }

    # ________________________ RawString class definition _________________________ #

    oo::class create RawString {
        superclass SPICEElement
        # value of the raw string
        variable Value
        constructor {value args} {
            # Creates object of class `RawString`.
            #  value - value of the raw string
            # Class represent arbitary string.
            #  It can be used to pass any string directly into netlist, 
            #  for example, it can add elements that doesn't have dedicated class.
            my variable Name
            set arguments [argparse {
                -name=
            }]
            if {[info exists name]} {
                my SetName $name
            } else {
                my SetName [self object]
            }
            my setValue $value
        }
        method SetName {name} {
            # Sets the name of the raw string.
            #  name - name of the string
            my variable Name
            set Name [string tolower $name]
            return
        }
        method getValue {} {
            # Gets the value of the string.
            # Returns: `Value`
            return $Value
        }
        method setValue {value} {
            # Sets the value of the string.
            #  value - string itself
            set Value $value
            return
        }
        method genSPICEString {} {
            # Creates raw string for SPICE netlist.
            # Returns: string '$Value'
            return [my getValue]
        }
    }

    # ________________________ Comment class definition _________________________ #

    oo::class create Comment {
        superclass RawString
        constructor {value args} {
            # Creates object of class `Comment`.
            #  value - value of the comment
            #  args - optional argument -name - represent name of comment string
            # Class represent comment string, it can be a multiline comment.
            my variable Name
            set arguments [argparse {
                -name=
            }]
            if {[info exists name]} {
                my SetName $name
            } else {
                my SetName [self object]
            }
            my setValue $value
        }
        method genSPICEString {} {
            # Creates comment string for SPICE netlist.
            # Returns: string '*$Value'
            set splitted [split [my getValue] "\n"]
            set prepared [join [lmap line $splitted {set result "*$line"}] \n]
            return "$prepared"
        }
    }    
    
    # ________________________ Include class definition _________________________ #

    oo::class create Include {
        superclass RawString
        constructor {value args} {
            # Creates object of class `Include`.
            #  value - value of the include path
            #  args - optional argument -name - represent name of include statement
            # This class represent .include statement.
            my variable Name
            set arguments [argparse {
                -name=
            }]
            if {[info exists name]} {
                my SetName $name
            } else {
                my SetName [self object]
            }
            my setValue $value
        }
        method genSPICEString {} {
            # Creates include string for SPICE netlist.
            # Returns: '.include $Value'
            return ".include [my getValue]"
        }
    }   
    
    # ________________________ Library class definition _________________________ #    
    
    oo::class create Library {
        superclass RawString
        # this variable contains selected library name inside sourced file
        variable LibValue
        constructor {value libValue args} {
            # Creates object of class `Library`.
            #  value - value of the include file
            #  libValue - value of selected library
            #  args - optional argument -name - represent name of library statement
            # Class represent .lib statement.
            my variable Name
            set arguments [argparse {
                -name=
            }]
            if {[info exists name]} {
                my SetName $name
            } else {
                my SetName [self object]
            }
            my setValue $value
            my setLibValue $libValue
        }
        method getLibValue {} {
            # Gets the value of the string.
            # Returns: library name inside included file
            return $LibValue
        }
        method setLibValue {value} {
            # Sets the value of the string.
            #  value - name of library
            set LibValue [string tolower $value]
            return
        }
        method genSPICEString {} {
            # Creates library string for SPICE netlist.
            # Returns: '.lib $Value $LibValue'
            return ".lib [my getValue] [my getLibValue]"
        }
    }   
    
    # ________________________ Options class definition _________________________ #
    
    oo::class create Options {
        superclass SPICEElement
        mixin DuplChecker
        # list of Parameter objects
        variable Params
        constructor {params args} {
            # Creates object of class `Options`.
            #  name - name of the parameter
            #  params - list of instance parameters in form `{{Name Value ?-sw?} {Name Value ?-sw?} {Name Value ?-sw?} ...}`
            #  args - optional argument -name - represent name of library statement
            # This class represent .options statement.
            my variable Name
            set arguments [argparse {
                -name=
            }]
            if {[info exists name]} {
                my SetName $name
            } else {
                my SetName [self object]
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
        method SetName {name} {
            # Sets the name of the options.
            #  name - name of .options element
            my variable Name
            set Name [string tolower $name]
            return
        }
        method getParams {} {
            # Gets the dictionary that contains parameter name as keys and
            #  parameter values as the values.
            # Returns: parameters dictionary
            set tempDict [dict create]
            dict for {paramName param} $Params {
                # check if parameter doesn't have value, it means that we return {} for switch parameter
                if {[catch {$param getValue}]} {
                    dict append tempDict $paramName ""
                } else {
                    dict append tempDict $paramName [$param getValue]
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
                dict append Params $paramName [SpiceGenTcl::ParameterSwitch new $paramName]
            } else {
                dict append Params $paramName [SpiceGenTcl::ParameterNoCheck new $paramName $value]
            }
            return
        }
        set def [info class definition SpiceGenTcl::Device deleteParam]
        method deleteParam [lindex $def 0] [lindex $def 1]
        method setParamValue {paramName value} {
            # Sets (or changes) value of particular parameter
            #  it throws a error if try to set a value of switch parameter.
            #  paramName - name of parameter
            #  value - new value of parameter
            set paramName [string tolower $paramName]
            set error [catch {dict get $Params $paramName}]
            if {$error>0} {
                error "Parameter with name '$paramName' was not found in options's '[my getName]' list of parameters '[dict keys [my getParams]]'"
            } else {
                set param [dict get $Params $paramName]
            }
            $param setValue $value
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
    
    # ________________________ ParamStatement class definition _________________________ #
    
    oo::class create ParamStatement {
        superclass SPICEElement
        mixin ValueChecker DuplChecker
        variable Params
        constructor {params args} {
            # Creates object of class `ParamStatement`.
            #  params - list of instance parameters in form `{{Name Value} {Name Value} {Name Equation -eq} ...}`
            #  args - optional argument -name - represent name of library statement
            # Class represent .param statement.
            my variable Name
            set arguments [argparse {
                -name=
            }]
            if {[info exists name]} {
                my SetName $name
            } else {
                my SetName [self object]
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
        method SetName {name} {
            # Sets the name of the params statement.
            #  name - name of .param statement
            my variable Name
            set Name [string tolower $name]
            return
        }
        method getParams {} {
            # Gets the dictionary that contains parameter name as keys and
            #  parameter values as the values.
            # Returns: parameters dictionary
            set tempDict [dict create]
            dict for {paramName param} $Params {
                dict append tempDict $paramName [$param getValue]
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
                dict append Params $paramName [SpiceGenTcl::ParameterEquation new $paramName $value]
            } else {
                dict append Params $paramName [SpiceGenTcl::Parameter new $paramName $value]
            }
            return
        }
        set def [info class definition SpiceGenTcl::Device deleteParam]
        method deleteParam [lindex $def 0] [lindex $def 1]
        method setParamValue {paramName value} {
            # Sets (or changes) value of particular parameter.
            #  paramName - name of parameter
            #  value - new value of parameter
            set paramName [string tolower $paramName]
            set error [catch {dict get $Params $paramName}]
            if {$error>0} {
                error "Parameter with name '$paramName' was not found in parameter statement's '[my getName]' list of parameters '[dict keys [my getParams]]'"
            } else {
                set param [dict get $Params $paramName]
            }
            $param setValue $value
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
    
    # ________________________ Temp class definition _________________________ #
    
    oo::class create Temp {
        superclass SPICEElement
        mixin ValueChecker
        variable Value
        constructor {value args} {
            # Creates object of class `Temp`.
            #  value - value of the temperature
            #  args - optional parameter qualificator -eq
            # This class represent .temp statement with temperature value.
            set arguments [argparse {
                {-eq -boolean}
            }]
            my SetName temp
            if {$eq} {
                my AddParam temp $value -eq
            } else {
                my AddParam temp $value
            }             
        }
        method SetName {name} {
            # Set the name of the temp statement.
            #  name - name of .temp statement
            my variable Name
            set Name [string tolower $name]
            return
        }
        method getValue {} {
            # Gets value of temperature.
            # Returns: temperature value
            return [$Value getValue]
        }
        method setValue {value args} {
            # Sets (or changes) value of temperature.
            #  value - value of temperature
            #  args - optional parameter qualificator -eq
            set arguments [argparse {
                {-eq -boolean}
            }]   
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
                set Value [SpiceGenTcl::ParameterPositionalEquation new $paramName $value]
            } else {
                set Value [SpiceGenTcl::ParameterPositional new $paramName $value]
            }
            return
        }
        method genSPICEString {} {
            # Creates .temp statement string for SPICE netlist.
            # Returns: '.temp $Value'
            return ".temp [$Value genSPICEString]"
        }
    }
        
    # ________________________ Netlist class definition _________________________ #
    
    oo::class create Netlist {
        superclass SPICEElement
        mixin DuplChecker
        variable Elements
        constructor {name} {
            # Creates object of class `Netlist`.
            #  name - name of the netlist
            # Class implements netlist as a collection of SPICE elements. Any element that has SPICEElement
            # as a parent class can be added to Netlist, except Options and Analysis.
            my SetName $name
        }
        method SetName {name} {
            # Sets the name of the netlist.
            #  name - name of netlist
            my variable Name
            set Name [string tolower $name]
            return
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
            set elemName [string tolower [$element getName]]
            if {[info exists Elements]} {
                set elemList [my getAllElemNames]
            }
            lappend elemList $elemName
            if {[my duplListCheck $elemList]} {
                error "Netlist '[my getName]' already contains element with name $elemName"
            }
            dict append Elements [$element getName] $element 
            return
        }
        method del {elemName} {
            # Deletes element from the netlist by its name.
            #  elemName - name of element to delete
            set elemName [string tolower $elemName]
            set error [catch {dict get $Elements $elemName}]
            if {$error>0} {
                error "Element with name '$elemName' was not found in netlist's '[my getName]' list of elements"
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
                error "Element with name '$elemName' was not found in netlist's '[my getName]' list of elements"
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

    
    # ________________________ Circuit class definition _________________________ #
    
    oo::class create Circuit {
        superclass Netlist
        # simulator object that run simulation
        variable Simulator
        # standard output of simulation
        variable Log
        # results of simulation in form of RawData object
        variable Data
        # flag that tells about Analysis element presence in Circuit
        variable ContainAnalysis
        constructor {name} {
            # Creates object of class `CircuitNetlist`.
            #  name - name of the tol-level circuit
            # Class implements a top level netlist which is run in SPICE. We should add `Simulator`
            # object reference to make it able to run simulation. Results of last simulation attached as `RawData` class object
            # and can be retrieved by `getData` method.
            next $name
        }
        method add {element} {
            # Adds elements object to Elements dictionary.
            #  element - element object reference
            my variable Elements
            set elemName [string tolower [$element getName]]
            if {([info object class $element {::SpiceGenTcl::Analysis}]) && ([info exists ContainAnalysis])} {
                error "Netlist '[my getName]' already contains Analysis element"
            } elseif {[info object class $element {::SpiceGenTcl::Analysis}]} {
                set ContainAnalysis ""
            }
            if {[info exists Elements]} {
                set elemList [my getAllElemNames]
            }
            lappend elemList $elemName
            if {[my duplListCheck $elemList]} {
                error "Netlist '[my getName]' already contains element with name $elemName"
            }
            dict append Elements [$element getName] $element 
            return
        }
        method del {elemName} {
            # Deletes element from the circuit by its name.
            #  elemName - name of element to delete
            my variable Elements
            set elemName [string tolower $elemName]
            set error [catch {dict get $Elements $elemName}]
            if {$error>0} {
                error "Element with name '$elemName' was not found in device's '[my getName]' list of elements"
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
                error "Element with name '$elemName' was not found in netlist's '[my getName]' list of elements"
            } else {
                set foundElem [dict get $Elements $elemName]
            }
            return $foundElem
        }
        method attachSimulator {simulator} {
            # Attachs `Simulator` object reference to `Circuit`.
            #  simulator - `Simulator` object reference
            set Simulator $simulator
            return
        }
        method detachSimulator {} {
            # Removes `Simulator` object reference from `Circuit`.
            unset Simulator
            return
        }
        method getSimulator {} {
            # Gets `Simulator` object reference.
            # Returns: object reference
            return $Simulator
        }
        method getData {} {
            # Method to get `RawData` object reference.
            # Returns: object reference
            return $Data
        }
        method getDataDict {} {
            # Method to get dictionary with raw data vectors.
            # Returns: dict with vectors data, keys - names of vectors
            return [$Data getTracesData]
        }
        method getLog {} {
            # Method to get simulation log.
            # Returns: log string
            return $Log
        }
        method genSPICEString {} {
            # Creates circuit string for SPICE netlist.
            # Returns: 'circuit string'
            my variable Elements
            lappend totalStr [my getName]
            dict for {elemName element} $Elements {
                lappend totalStr [$element genSPICEString]
            }
            return [join $totalStr \n]
        }
        method runAndRead {} {
            # Invokes 'runAndRead', 'getLog' and 'getData' methods from attached simulator.
            if {[info exists Simulator]==0} {
                error "Simulator is not attached to '[my getName]' circuit"
            }
            $Simulator runAndRead [my genSPICEString]
            set Log [$Simulator getLog]
            set Data [$Simulator getData]
        }
    }
    
    # ________________________ Subcircuit class definition _________________________ #
    
    oo::class create Subcircuit {
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
        set def [info class definition SpiceGenTcl::Device AddPin]
        method AddPin [lindex $def 0] [lindex $def 1]       
        set def [info class definition SpiceGenTcl::Device getPins]
        method getPins [lindex $def 0] [lindex $def 1] 
        set def [info class definition SpiceGenTcl::Device deleteParam]
        method deleteParam [lindex $def 0] [lindex $def 1] 
        set def [info class definition SpiceGenTcl::Device setParamValue]
        method setParamValue [lindex $def 0] [lindex $def 1]     
        set def [info class definition SpiceGenTcl::Device getParams]
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
            dict append Params $paramName [SpiceGenTcl::Parameter new $paramName $value]
            return
        }
        
        method add {element} {
            # Add element object reference to `Netlist`,
            # it extends add method to add check of element class because subcircuit can't contain particular elements inside,
            # like `Include`, `Library`, `Options` and `Anslysis`.
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
            set name [my getName]
            dict for {pinName pin} $Pins {
                lappend nodes [$pin getName]
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
    
    # ________________________ Analysis class definition _________________________ #
    
    oo::class create Analysis {
        superclass SPICEElement
        mixin DuplChecker
        # type of analysis, i.e. dc, ac, tran, etc
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
                my SetName $name
            } else {
                my SetName [self object]
            }
            my SetType $type
            # create Analysis objects
            foreach param $params {
                if {[lindex $param 2]=={}} {
                    my addParam [lindex $param 0] [lindex $param 1]    
                } elseif {[lindex $param 1]=="-sw"} {
                    my addParam [lindex $param 0] -sw 
                } elseif {[lindex $param 2]=="-eq"} {
                    my addParam [lindex $param 0] [lindex $param 1] -eq 
                } elseif {[lindex $param 2]=="-posnocheck"} {
                    my addParam [lindex $param 0] [lindex $param 1] -posnocheck 
                } else { 
                    error "Wrong parameter definition in Analysis '[my getName]'"
                }   
            }
        }
        method SetName {name} {
            # Sets the name of analysis.
            #  name - name of analysis object
            my variable Name
            set Name [string tolower $name]
            return
        }
        method SetType {type} {
            # Sets the type of the analysis.
            #  type - type of simulation
            set type [string tolower $type]
            my CheckType $type
            set Type $type
            return
        }
        method getType {} {
            # Gets the type of the analysis.
            # Returns: type of analysis
            return $Type
        }
        method CheckType {type} {
            # Checks the type of analysis.
            #  type - type value to check
            set suppAnalysis [list ac dc tran op disto noise pz sens sp tf]
            if {$type ni $suppAnalysis} {
                error "Type '$type' is not in supported list of analysis, should be one of '$suppAnalysis'"
            }
            return
        }
        method getParams {} {
            # Gets the dictionary that contains parameter name as keys and
            #  parameter values as the values
            # Returns: parameters dictionary
            set tempDict [dict create]
            dict for {paramName param} $Params {
                dict append tempDict $paramName [$param getValue]
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
                {-posnocheck -forbid {eq}}
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
                dict append Params $paramName [SpiceGenTcl::ParameterSwitch new $paramName]
            } elseif {[info exists eq]} {
                dict append Params $paramName [SpiceGenTcl::ParameterPositionalEquation new $paramName $value]
            } elseif {[info exists posnocheck]} {
                dict append Params $paramName [SpiceGenTcl::ParameterPositionalNoCheck new $paramName $value]
            } else {
                dict append Params $paramName [SpiceGenTcl::ParameterPositional new $paramName $value]
            }
            return
        }
        set def [info class definition SpiceGenTcl::Device deleteParam]
        method deleteParam [lindex $def 0] [lindex $def 1]
        method setParamValue {paramName value} {
            # Sets (or changes) value of particular parameter.
            #  paramName - name of parameter
            #  value - the new value of parameter
            set paramName [string tolower $paramName]
            set error [catch {dict get $Params $paramName}]
            if {$error>0} {
                error "Parameter with name '$paramName' was not found in parameter analysis's '[my getName]' list of parameters '[dict keys [my getParams]]'"
            } else {
                set param [dict get $Params $paramName]
            }
            $param setValue $value
            return
        }
        method genSPICEString {} {
            # Creates analysis for SPICE netlist.
            # Returns: string '.$Type $Params'
            dict for {paramName param} $Params {
                lappend params [$param genSPICEString]
            }
            return ".[my getType] [join $params]"
        }
    }

    # ________________________ Simulator class definition _________________________ #
    
    oo::class create Simulator {
        variable Name
        variable Command
        variable Path
        variable Log
        variable Data
        method SetName {name} {
            # Abstract class models general SPICE simulator.
            error "Not implemented"
        }
        method getName {} {
            # Gets the name of the simulator.
            # Returns: name of simulator object
            return $Name
        }
        method setPath {path} {
            # Sets path to simulator executable.
            #  path - path to executable
            set Path $path
            return
        }
        method getPath {} {
            # Gets path to simulator executable.
            # Returns: path to executable
            return $Path
        }
        method SetName {} {
            # Sets name of simulator object.
            error "Not implemented"
        }
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
        method getData {} {
            # Returns data of last completed simulation.
            error "Not implemented"
        }
        
        self unexport create new
    }     

    # ________________________ BinaryReader class definition _________________________ #
   
    oo::class create BinaryReader {
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
        self unexport create new
    }
    
    # ________________________ Dataset class _________________________ #
    
    oo::class create Dataset {
        # This class models general raw dataset
        variable Name
        # Type of dataset, could be voltage, vurrent, time or frequency
        variable Type
        # Numerical type of dataset, real, double or complex
        variable NumType
        # Number of points (length of dataset)
        variable Len
        # values at points
        variable DataPoints
        constructor {name type len {numType real}} {
            # initialize dataset
            #  name - name of the dataset
            #  type - type of dataset
            #  len - total number of points
            #  numType - numerical type of dataset
            my SetName $name
            my SetType $type
            my SetLen $len
            my SetNumType $numType
        }
        method SetName {name} {
            # method to set the name of the dataset
            set Name [string tolower $name]
            return
        }
        method SetType {type} {
            # method to set the type of the dataset
            set Type [string tolower $type]
            return
        }
        method SetLen {len} {
            # method to set the length of the dataset
            set Len $len
            return
        }
        method SetNumType {numType} {
            # method to set the numerical type of the dataset
            if {$numType ni [list real complex double]} {
                error "Unknown numerical type '$numType' of data"
            }
            set NumType $numType
            return
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
        method getName {} {
            return $Name
        }
        method getType {} {
            return $Type
        }
        method getNumType {} {
            return $NumType
        }
        method getLen {} {
            return $Len
        }
        method getDataPoints {} {
            if {[info exists DataPoints]} {
                return $DataPoints
            } else {
                error "Dataset with name '[my getName]' doesn't contain non-zero points"
            }
            return 
        }
        method getStr {} {
            return "Name: '[my getName]', Type: '[my getType]', Length: '[my getLen]', Numerical type: '[my getNumType]'"
        }
    }
    
    # ________________________ Axis class definition _________________________ #

    oo::class create Axis {
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
    
    # ________________________ Trace class definition _________________________ #

    oo::class create Trace {
        # class that represents trace in raw file
        superclass Dataset
        variable Axis
        constructor {name type len axis {numType real}} {
            # initialize trace
            #  name - name of the trace
            #  type - type of trace
            #  len - total number of points
            #  axis - name of axis that is linked to trace
            #  numType - numerical type of trace
            my SetAxis $axis
            next $name $type $len $numType
        }
        method SetAxis {axis} {
            # method to set the axis of the waveform
            set Axis [string tolower $axis]
            return
        }
    }
    
    # ________________________ DummyTrace class definition _________________________ #

    oo::class create DummyTrace {
        # class that represents empty trace (trace that was not readed) in raw file
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
    }
    
    # ________________________ RawFile class definition _________________________ #

    oo::class create RawFile {
        # class that represents raw file
        mixin BinaryReader
        # path to raw file including it's file name
        variable Path
        # parameters of raw file readed from it's header
        variable RawParams 
        # number of points in raw file
        variable NPoints 
        # number of variables in raw file
        variable NVariables
        # object reference of axis in raw file
        variable Axis 
        # objects references of traces in raw file
        variable Traces
        # binary block size in bytes that contains all variables at axis point value
        variable BlockSize
        constructor {path {traces2read *} {simulator ngspice}} {
            # constructor that creates RawFile object
            #  path - path to raw file including it's file name
            #  traces2read - list of traces that will be readed, default value is \*, 
            #   that means reading all traces
            #  simulator - simulator that produced this raw file, default is ngspice
            my SetPath $path
            set fileSize [file size $path]
            set file [open $path r]
            fconfigure $file -translation binary
            
            ## ________________________ read header _________________________ ##

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
            set RawParams [dict create Filename $path]
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
            
            ## ________________________ save header parameters _________________________ ##

            foreach line $header {
                set lineList [split $line ":"]
                if {[lindex $lineList 0]=="Variables"} {
                    break
                }
                dict append RawParams [lindex $lineList 0] [string trim [lindex $lineList 1]]
            }
            set NPoints [dict get $RawParams "No. Points"]
            set NVariables [dict get $RawParams "No. Variables"]
            if {[dict get $RawParams "Plotname"] in {"Operating Point" "Transfet Function"}} {
                set hasAxis 0
            } else {
                set hasAxis 1
            }
            set flags [split [dict get $RawParams "Flags"]]
            if {("complex" in $flags) || ([dict get $RawParams "Plotname"]=="AC Analysis")} {
                set numType complex
            } else {
                if {("double" in $flags) || ($simulator=="ngspice")} {
                    set numType double
                } else {
                    set numType real
                }
            }
            
            ## ________________________ parse variables _________________________ ##
            
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
                    set Axis [SpiceGenTcl::Axis new $name $varType $NPoints $axisNumType]
                    set trace $Axis
                } elseif {($traces2read=="*") || ($name in $traces2read)} {
                    if {$hasAxis} {
                        set trace [SpiceGenTcl::Trace new $name $varType $NPoints [$Axis getName] $numType]
                    } else {
                        set trace [SpiceGenTcl::Trace new $name $varType $NPoints {} $numType]
                    }
                } else {
                    set trace [SpiceGenTcl::DummyTrace new $name $varType $NPoints $numType]
                }
                lappend Traces $trace
                incr ivar
            }
            if {($traces2read=="") || ([llength $traces2read]==0)} {
                close $file
                return
            }
            
            ## ________________________ read data _________________________ ##
            
            if {$rawType=="Binary:"} {
                set BlockSize [expr {($fileSize - $binaryStart)/$NPoints}]
                set scanFunctions ""
                set calcBlockSize 0
                foreach trace $Traces {
                    if {[$trace getNumType]=="double"} {
                        incr calcBlockSize 8
                        if {[info object class $trace SpiceGenTcl::DummyTrace]} {
                            set fun skip8bytes 
                        } else {
                            set fun readFloat64
                        }
                    } elseif {[$trace getNumType]=="complex"} {
                        incr calcBlockSize 16
                        if {[info object class $trace SpiceGenTcl::DummyTrace]} {
                            set fun skip16bytes 
                        } else {
                            set fun readComplex 
                        }
                    } elseif {[$trace getNumType]=="real"} {
                        incr calcBlockSize 4
                        if {[info object class $trace SpiceGenTcl::DummyTrace]} {
                            set fun skip4bytes 
                        } else {
                            set fun readFloat32 
                        }
                    } else {
                        error "Invalid data type '[$trace getNumType]' for trace '[$trace getName]'"
                    }
                    lappend scanFunctions $fun
                }
                if {$calcBlockSize!=$BlockSize} {
                    error "Error in calculating the block size. Expected '$BlockSize' bytes, but found '$calcBlockSize' bytes"
                }
                 for {set i 0} {$i<$NPoints} {incr i} {
                    for {set j 0} {$j<[llength $Traces]} {incr j} {
                        set value [eval "my [lindex $scanFunctions $j]" $file] 
                        set trace [lindex $Traces $j]
                        if {[info object class $trace]!="SpiceGenTcl::DummyTrace"} {
                            $trace appendDataPoints $value 
                        }  
                    }
                }                 
            } elseif {$rawType=="Values:"} {
                for {set i 0} {$i<$NPoints} {incr i} {
                    set firstVar true
                    for {set j 0} {$j<[+ [llength $Traces] 1]} {incr j} {
                        set line [gets $file]
                        if {$line==""} {
                            continue
                        }
                        set lineList [textutil::split::splitx $line]
                        if {$firstVar=="true"} {
                            set firstVar false
                            set sPoint [lindex $lineList 1]
                            if {$i!=int($sPoint)} {
                                error "Error reading file"
                            }
                            if {$numType=="complex"} {
                                set value [split [lindex $lineList 2] ","]
                            } else {
                                set value [lindex $lineList 2]
                            } 
                        } else {
                            if {$numType=="complex"} {
                                set value [split [lindex $lineList 1] ","]
                            } else {
                                set value [lindex $lineList 1]
                            }
                        }
                        set trace [lindex $Traces $j]
                        $trace appendDataPoints $value 
                    }
                }
            }
            close $file
        }
        method SetPath {path} {
            # method to set the path of the waveform's file
            set Path $path
            return
        }
        method getPath {path} {
            # method to get the path of the waveform's file
            return $Path
        }
        method getTraces {} {
            # method returns all Traces objects references
            return $Traces
        }
        method getNPoints {} {
            # method returns number of points
            return $NPoints
        }
        method getNVariables {} {
            # method returns number of variables
            return $NVariables
        }
        method getAxis {} {
            # method returns axis object
            if {[info exists Axis]} {
                return $Axis
            } else {
                error "Raw file '[my getPath]' doesn't have an axis"
            }
        }
        method getTrace {traceName} {
            # method return trace object reference by it's name
            set traceFoundFlag false
            foreach trace $Traces {
                if {[$trace getName]==$traceName} {
                    set traceFound $trace
                    set traceFoundFlag true
                    break
                }
            }
            if {$traceFoundFlag==false} {
                error "Trace with name '$traceName' was not found in raw file '[my getPath]' list of traces"
            }
            return $traceFound
        }
        method getVariablesNames {} {
            # method returns list that contains names of all variables
            foreach trace $Traces {
                lappend tracesNames [$trace getName]
            }
            return $tracesNames
        }
        method getVoltagesNames {} {
            # method returns list that contains names of all voltage variables
            foreach trace $Traces {
                if {[$trace getType]=="voltage"} {
                    lappend voltNames [$trace getName]
                }
            }
            return $voltNames
        }
        method getCurrentsNames {} {
            # method returns list that contains names of all current variables
            foreach trace $Traces {
                if {[$trace getType]=="current"} {
                    lappend currNames [$trace getName]
                }
            }
            return $currNames
        }
        method getTracesStr {} {
            # method returns information about all Traces in raw file in form of string
            foreach trace $Traces {
                lappend tracesList "[$trace getName] [$trace getType] [$trace getNumType]"
            }
            return $tracesList
        }
        method getTracesData {} {
            # method returns dictionary that contains all data in value and name as a key
            set dict [dict create]
            foreach trace $Traces {
                dict append dict [$trace getName] [$trace getDataPoints]
            }
            return $dict
        }
        method getRawProperties {} {
            # method returns information all raw files properties
            return $RawParams
        }
    }
}


