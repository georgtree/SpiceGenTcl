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
            EmptyTrace RawFile Ic Nodeset ParameterNode ParameterNodeEquation Global Parser ParameterVector Save
    namespace export importNgspice importXyce importCommon importLtspice forgetNgspice forgetXyce forgetCommon\
            forgetLtspice

    proc importCommon {} {
        # Imports all ::SpiceGenTcl::Common commands to caller namespace
        uplevel 1 {foreach nameSpc [namespace children ::SpiceGenTcl::Common] {
            namespace import ${nameSpc}::*
        }}
    }
    proc forgetCommon {} {
        # Forgets all ::SpiceGenTcl::Common commands from caller namespace
        uplevel 1 {foreach nameSpc [namespace children ::SpiceGenTcl::Common] {
            namespace forget ${nameSpc}::*
        }}
    }
    proc importNgspice {} {
        # Imports all ::SpiceGenTcl::Ngspice commands to caller namespace
        uplevel 1 {foreach nameSpc [namespace children ::SpiceGenTcl::Ngspice] {
            namespace import ${nameSpc}::*
        }}
    }
    proc importLtspice {} {
        # Imports all ::SpiceGenTcl::Ltspice commands to caller namespace
        uplevel 1 {foreach nameSpc [namespace children ::SpiceGenTcl::Ltspice] {
            namespace import ${nameSpc}::*
        }}
    }
    proc forgetNgspice {} {
        # Forgets all ::SpiceGenTcl::Ngspice commands from caller namespace
        uplevel 1 {foreach nameSpc [namespace children ::SpiceGenTcl::Ngspice] {
            namespace forget ${nameSpc}::*
        }}
    }
    proc importXyce {} {
        # Imports all ::SpiceGenTcl::Xyce commands to caller namespace
        uplevel 1 {foreach nameSpc [namespace children ::SpiceGenTcl::Xyce] {
            namespace import ${nameSpc}::*
        }}
    }
    proc forgetXyce {} {
        # Forgets all ::SpiceGenTcl::Xyce commands from caller namespace
        uplevel 1 {foreach nameSpc [namespace children ::SpiceGenTcl::Xyce] {
            namespace forget ${nameSpc}::*
        }}
    }
    proc forgetLtspice {} {
        # Forgets all ::SpiceGenTcl::Ltspice commands from caller namespace
        uplevel 1 {foreach nameSpc [namespace children ::SpiceGenTcl::Ltspice] {
            namespace forget ${nameSpc}::*
        }}
    }

###  SPICEElement class definition

    oo::configurable create SPICEElement {
        self mixin -append oo::abstract
        # Abstract class of all elements of SPICE netlist
        #  and it forces implementation of genSPICEString method for all subclasses.
        variable name
        method genSPICEString {} {
            # Declaration of method common for all SPICE elements that generates
            #  representation of element in SPICE netlist. Not implemented in
            #  abstraction class.
            error "Not implemented"
        }
    }

###  Utility class definition

    oo::class create Utility {
        self mixin -append oo::abstract
        method ParamsProcess {paramsOrder arguments params} {
            upvar $params paramsLoc
            foreach param $paramsOrder {
                if {[dexist $arguments $param]} {
                    dict append argsOrdered $param [dget $arguments $param]
                }
            }
            dict for {paramName value} $argsOrdered {
                if {([llength $value]>1) && ([@ $value 1] eq {-eq})} {
                    lappend paramsLoc [list $paramName [@ $value 0] -poseq]
                } else {
                    lappend paramsLoc [list $paramName $value -pos]
                }
            }
            return
        }
        method NameProcess {arguments object} {
            upvar name name
            ##nagelfar ignore
            if {[dexist $arguments name]} {
                ##nagelfar ignore
                set name [dget $arguments name]
            } else {
                set name $object
            }
        }
        method AliasesKeysCheck {arguments keys} {
            foreach key $keys {
                if {[dexist $arguments $key]} {
                    return
                }
            }
            set formKeys [lmap key $keys {subst -$key}]
            return -code error "[join [lrange $formKeys 0 end-1] ", "] or [@ $formKeys end] must be presented"
        }
        method buildArgStr {paramsNames} {
            # Builds argument list for argparse.
            #  paramsNames - list of parameter names
            # Returns: string in form `-paramName= ...`, or `{-paramName= -forbid {alias0 alias1 ...}}`
            foreach paramName $paramsNames {
                if {[llength $paramName]>1} {
                    for {set i 0} {$i<[llength $paramName]} {incr i} {
                        set paramNameAlias [@ $paramName $i]
                        lappend paramDefList "\{-${paramNameAlias}= -forbid \{[lremove $paramName $i]\}\}"
                    }
                } else {
                    lappend paramDefList -${paramName}=
                }
            }
            set paramDefStr [join $paramDefList \n]
            return $paramDefStr
        }
        method buildSwArgStr {paramsNames} {
            # Builds argument list for argparse that doesn't need an argument value.
            #  paramsNames - list of parameter names
            # Returns: string in form *-paramName ...*
            foreach paramName $paramsNames {
                lappend paramDefList -${paramName}
            }
            set paramDefStr [join $paramDefList \n]
            return $paramDefStr
        }
        method argsPreprocess {paramsNames args} {
            # Calls argparse and constructs list for passing to Device constructor.
            #  paramsNames - list of parameter names, define alias for parameter name by
            #  using two element list {paramName aliasName}
            #  args - argument list with key names and it's values
            # Returns: list of parameters formatted for Device/Model constructor
            foreach paramName $paramsNames {
                if {[llength $paramName]>1} {
                    for {set i 0} {$i<[llength $paramName]} {incr i} {
                        set paramNameAlias [@ $paramName $i]
                        lappend paramDefList "\{-${paramNameAlias}= -forbid \{[lremove $paramName $i]\}\}"
                    }
                } else {
                    lappend paramDefList -${paramName}=
                }
            }
            set paramDefStr [join $paramDefList \n]
            set arguments [argparse -inline "
                $paramDefStr
            "]
            set params {}
            dict for {paramName value} $arguments {
                lappend params [list $paramName {*}$value]
            }
            return $params
        }
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
        method duplListCheckRet {list} {
            # Checks if list contains duplicates and return value of first duplicate.
            #  list - list to check
            # Returns: empty list if no duplicate or value of first duplicate.
            set itemDup {}
            set new {}
            foreach item $list {
                if {[lsearch $new $item] < 0} {
                    lappend new $item
                } else {
                    set itemDup $item
                    break
                }
            }
            return $itemDup
        }
    }

###  Pin class definition
    ##nagelfar subcmd+ _obj,Pin configure
    oo::configurable create Pin {
        superclass SPICEElement
        # name of the node connected to pin
        property nodename -set {
            if {![regexp {^(?![0-9]+[a-zA-Z])[^= %\(\),\[\]<>~]*$} $value]} {
                return -code error "Node name '${value}' is not a valid name"
            }
            set nodename [string tolower $value]
        }
        property name -set {
            if {$value eq {}} {
                return -code error "Pin must have a name, empty string was provided"
            } elseif {![regexp {^(?![0-9]+[a-zA-Z])[^= %\(\),\[\]<>~]*$} $value]} {
                return -code error "Pin name '$value' is not a valid name"
            }
            set name [string tolower $value]
        } -get {
            return $name
        }
        variable name nodename
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
            my configure -name $name -nodename $nodeName
        }
        method unsetNodeName {} {
            # Makes pin floating by setting `nodename` with empty string.
            my configure -nodename {}
        }
        method checkFloating {} {
            # Determines if pin is connected to the node.
            # Returns: `true` if connected and `false` if not
            if {[my configure -nodename] eq {}} {
                set floating true
            } else {
                set floating false
            }
            return $floating
        }
        method genSPICEString {} {
            # Creates string for SPICE netlist.
            # Returns: SPICE netlist's string
            if {[my checkFloating]} {
                return -code error "Pin '[my configure -name]' is not connected to the node so can't be netlisted"
            }
            return [my configure -nodename]
        }
    }

###  ParameterSwitch class definition
    ##nagelfar subcmd+ _obj,ParameterSwitch configure
    oo::configurable create ParameterSwitch {
        superclass SPICEElement
        property name -set {
            if {$value eq {}} {
                return -code error "Parameter must have a name, empty string was provided"
            } elseif {[regexp {[^A-Za-z0-9_]+} $value]} {
                return -code error "Parameter name '$value' is not a valid name"
            } elseif {[regexp {^[A-Za-z][A-Za-z0-9_]*} $value]} {
                set name [string tolower $value]
            } else {
                return -code error "Parameter name '$value' is not a valid name"
            }
        }
        variable name
        constructor {name} {
            # Creates object of class `ParameterSwitch` with parameter name.
            #  name - name of the parameter
            # Class models base parameter acting like a switch -
            # its presence gives us information that something it controls is on.
            # This parameter doesn't have a value, and it is the most basic class
            # in Parameter class family.
            my configure -name $name
        }
        method genSPICEString {} {
            # Creates string for SPICE netlist.
            # Returns: string '$name'
            return [my configure -name]
        }
    }

###  Parameter class definition

    oo::configurable create Parameter {
        superclass ParameterSwitch
        property value
        constructor {name value} {
            # Creates object of class `Parameter` with parameter name and value.
            #  name - name of the parameter
            #  value - value of the parameter
            # Class models parameter that has a name and a value - the most
            # common type of parameters in SPICE netlist. Its representation in netlist is
            # 'name=value', and can be called "keyword parameter".
            my configure -name $name -value $value
        }
        method genSPICEString {} {
            # Creates string for SPICE netlist.
            # Returns: SPICE netlist's string
            return [my configure -name]=[my configure -value]
        }
    }
    oo::define Parameter {
        variable value
        method <WriteProp-value> val {
            if {[regexp {^([+-]?\d*(\.\d+)?([eE][+-]?\d+)?)(f|p|n|u|m|k|g|t|meg)?([a-zA-Z]*)$} $val]} {
                set value [string tolower $val]
            } else {
                return -code error "Value '$val' is not a valid value"
            }
        }
    }

###  ParameterNode class definition

    oo::configurable create ParameterNode {
        superclass Parameter
        property name -set {
            if {$value eq {}} {
                return -code error "ParameterNode must have a name, empty string was provided"
            } elseif {[regexp {[^A-Za-z0-9_()]+} $value]} {
                return -code error "Parameter name '$value' is not a valid name"
            } elseif {[regexp {^[A-Za-z][A-Za-z0-9_()]*} $value]} {
                set name [string tolower $value]
            } else {
                return -code error "Parameter name '$value' is not a valid name"
            }
        }
        variable name
        constructor {name value} {
            # Creates object of class `ParameterNode` with parameter name and value.
            #  name - name of the parameter
            #  value - value of the parameter
            my configure -name $name -value $value
        }
        method genSPICEString {} {
            # Creates string for SPICE netlist.
            # Returns: SPICE netlist's string
            return [my configure -name]=[my configure -value]
        }
    }

###  ParameterNodeEquation class definition

    oo::configurable create ParameterNodeEquation {
        superclass ParameterNode
        constructor {name value} {
            # Creates object of class `ParameterNodeEquation` with parameter name and value.
            #  name - name of the parameter
            #  value - value of the parameter
            my configure -name $name -value $value
        }
        method genSPICEString {} {
            # Creates string for SPICE netlist.
            # Returns: SPICE netlist's string
            return "[my configure -name]=\{[my configure -value]\}"
        }
    }
    oo::define ParameterNodeEquation {
        variable value
        method <WriteProp-value> val {
            if {$val ne {}} {
                set value $val
            } else {
                return -code error "Parameter '[my configure -name]' equation can't be empty"
            }
        }
    }

###  ParameterVector class definition

    oo::configurable create ParameterVector {
        superclass ParameterSwitch
        property name -set {
            if {$value eq {}} {
                return -code error "ParameterVector must have a name, empty string was provided"
            } elseif {[regexp {^([a-zA-Z0-9]+|[vi]\([a-zA-Z0-9]+\)|[a-zA-Z0-9]+#[a-zA-Z0-9]+|@[a-zA-Z0-9]+\[[a-zA-Z0-9]+\])$} $value]} {
                set name [string tolower $value]
            } else {
                return -code error "Parameter name '$value' is not a valid name"
            }
        }
        variable name
    }

###  ParameterNoCheck class definition

    oo::configurable create ParameterNoCheck {
        superclass Parameter
        property value
        constructor {name value} {
            # Creates object of class `ParameterNoCheck` with parameter name and value.
            #  name - name of the parameter
            #  value - value of the parameter
            # Class models parameter the same as described by `Parameter` but without check for value form.
            next $name $value
        }
    }
    oo::define ParameterNoCheck {
        variable value
        method <WriteProp-value> val {
            if {$val eq {}} {
                return -code error "Value '$val' is not a valid value"
            }
            set value $val
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
            # Returns: SPICE netlist's string
            return [my configure -value]
        }
    }

###  ParameterPositionalNoCheck class definition

    oo::configurable create ParameterPositionalNoCheck {
        superclass ParameterPositional
        property value
        constructor {name value} {
            # Creates object of class `ParameterPositionalNoCheck`.
            #  name - name of parameter
            #  value - value of parameter
            # Class models parameter the same as described by `ParameterPositional` but without check for value form.
            next $name $value
        }
        method genSPICEString {} {
            # Creates string for SPICE netlist.
            # Results: SPICE netlist's string
            return [my configure -value]
        }
    }
    oo::define ParameterPositionalNoCheck {
        variable value
        method <WriteProp-value> val {
            if {$val eq {}} {
                return -code error "Value '$val' is not a valid value"
            }
            set value $val
        }
    }

###  ParameterDefault class definition

    oo::configurable create ParameterDefault {
        superclass Parameter
        property defvalue -set {
            if {[string is double -strict $value]} {
                set defvalue $value
            } else {
                if {[string tolower [string range $value end-2 end]] eq {meg}} {
                    if {[string is double -strict [string range $value 0 end-3]]} {
                        set defvalue [string tolower $value]
                    } else {
                        return -code error "Default value '$value' is not a valid value"
                    }
                } else {
                    set suffix [string tolower [string index $value end]]
                    if {$suffix in {f p n u m k g t}} {
                        if {[string is double -strict [string range $value 0 end-1]]} {
                            set defvalue [string tolower $value]
                        } else {
                            return -code error "Default value '$value' is not a valid value"
                        }
                    } else {
                        return -code error "Default value '$value' is not a valid value"
                    }
                }
            }
        }
        variable defvalue
        constructor {name value defValue} {
            # Creates object of class `ParameterDefault` with parameter name, value and default value.
            #  name - name of the parameter
            #  value - value of the parameter
            #  defValue - default value of the parameter
            # Class models parameter that has a name and a value, but it differs from
            # parent class in sense of having default value, so it has special ability to reset its value to default
            # value by special method `resetValue`.
            my configure -defvalue $defValue
            next $name $value
        }

        method resetValue {} {
            # Resets value of the parameter to it's default value.
            my configure -value [my configure -defvalue]
            return
        }
    }

###  ParameterEquation class definition

    oo::configurable create ParameterEquation {
        superclass Parameter
        property value
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
            # Returns: SPICE netlist's string
            return [my configure -name]=\{[my configure -value]\}
        }
    }
    oo::define ParameterEquation {
        variable value
        method <WriteProp-value> val {
            if {$val ne {}} {
                set value $val
            } else {
                return -code error "Parameter '[my configure -name]' equation can't be empty"
            }
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
            # Returns: SPICE netlist's string
            return \{[my configure -value]\}
        }
    }

###  Device class definition
    ##nagelfar subcmd+ _obj,Device AddPin addParam configure getParams
    oo::configurable create Device {
        superclass SPICEElement
        mixin Utility
        property name -set {
            if {[regexp {[^A-Za-z0-9_]+} $value]} {
                return -code error "Reference name '$value' is not a valid name"
            } elseif {[regexp {^[A-Za-z][A-Za-z0-9]*} $value]} {
                set name [string tolower $value]
            } else {
                return -code error "Reference name '$value' is not a valid name"
            }
        }
        variable name
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
            my configure -name $name
            # create Pins objects
            foreach pin $pins {
                my AddPin [@ $pin 0] [@ $pin 1]
            }
            #ruff
            # Each parameter definition could be modified by
            #  optional flags:
            #  - pos - parameter has strict position and only '$Value' is displayed in netlist
            #  - eq - parameter may contain equation in terms of functions and other parsmeters,
            #    printed as '$name={$equation}'
            #  - poseq - combination of both flags, print only '{$equation}'
            if {$params ne {}} {
                foreach param $params {
                    my addParam {*}$param
                }
            }
        }
        method getPins {} {
            # Gets the dictionary that contains pin name as keys and
            #  connected node name as the values.
            # Returns: parameters dictionary
            return [dict map {pinName pin} $Pins {$pin configure -nodename}]
        }
        method setPinNodeName {pinName nodeName} {
            # Sets node name of particular pin, so,
            #  in other words, connect particular pin to particular node.
            #  pinName - name of the pin
            #  nodeName - name of the node that we want connect to pin
            if {[catch {dget $Pins $pinName}]} {
                return -code error "Pin with name '$pinName' was not found in device's '[my configure -name]'\
                        list of pins '[dict keys [my getPins]]'"
            } else {
                set pin [dget $Pins $pinName]
            }
            $pin configure -nodename $nodeName
            return
        }
        method setParamValue {args} {
            # Sets (or change) value of particular parameters.
            #  name - name of the parameter
            #  value - value of the parameter
            # Synopsis: name value ?name value ...?
            if {[llength $args]%2!=0} {
                return -code error "Number of arguments to method '[dict get [info frame 0] method]' must be even"
            }
            for {set i 0} {$i<[llength $args]} {incr i 2} {
                set paramName [string tolower [@ $args [= {$i}]]]
                set paramValue [@ $args [= {$i+1}]]
                if {[catch {dget $Params $paramName}]} {
                    return -code error "Parameter with name '$paramName' was not found in element's\
                            '[my configure -name]' list of parameters '[dict keys [my getParams]]'"
                } else {
                    set param [dget $Params $paramName]
                }
                $param configure -value $paramValue
            }
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
                return -code error "Pins list '$pinList' has already contains pin with name '$pinName'"
            }
            dict append Pins $pinName [::SpiceGenTcl::Pin new $pinName $nodeName]
            return
        }
        method addParam {paramName value args} {
            # Adds new parameter to device, and throws error on dublicated names.
            #  paramName - name of parameter
            #  value - value of parameter
            #  -eq - parameter is of class [::SpiceGenTcl::ParameterEquation], optional, forbids other switches
            #  -poseq - parameter is of class [::SpiceGenTcl::ParameterPositionalEquation], optional, forbids other
            #    switches
            #  -posnocheck - parameter is of class [::SpiceGenTcl::ParameterPositionalNoCheck], optional, forbids other
            #    switches
            #  -pos - parameter is of class [::SpiceGenTcl::ParameterPositional], optional, forbids other switches
            #  -nocheck - parameter is of class [::SpiceGenTcl::ParameterNoCheck], optional, forbids other switches
            # Synopsis: paramName value ?-name value? ?-eq|-poseq|-posnocheck|-pos|-nocheck?
            argparse {
                {-pos -key paramQual -value pos}
                {-eq -key paramQual -value eq}
                {-poseq -key paramQual -value poseq}
                {-posnocheck -key paramQual -value posnocheck}
                {-nocheck -key paramQual -value nocheck -default {}}
            }
            # method adds new Parameter object to the list Params
            set paramName [string tolower $paramName]
            if {[info exists Params]} {
                set paramList [dict keys $Params]
            }
            lappend paramList $paramName
            if {[my duplListCheck $paramList]} {
                return -code error "Parameters list '$paramList' has already contains parameter with name '$paramName'"
            }
            # select parameter object according to parameter qualificator
            if {$value eq {-sw}} {
                dict append Params $paramName [::SpiceGenTcl::ParameterSwitch new $paramName]
            } else {
                ##nagelfar variable paramQual
                switch $paramQual {
                    pos {
                        dict append Params $paramName [::SpiceGenTcl::ParameterPositional new $paramName $value]
                    }
                    eq {
                        dict append Params $paramName [::SpiceGenTcl::ParameterEquation new $paramName $value]
                    }
                    poseq {
                        dict append Params $paramName [::SpiceGenTcl::ParameterPositionalEquation new $paramName $value]
                    }
                    posnocheck {
                        dict append Params $paramName [::SpiceGenTcl::ParameterPositionalNoCheck new $paramName $value]
                    }
                    nocheck {
                        dict append Params $paramName [::SpiceGenTcl::ParameterNoCheck new $paramName $value]
                    }
                    default {
                        dict append Params $paramName [::SpiceGenTcl::Parameter new $paramName $value]
                    }
                }
            }
            return
        }
        method deleteParam {paramName} {
            # Deletes existing `Parameter` object from list `Params`.
            #  paramName - name of parameter that will be deleted
            set paramName [string tolower $paramName]
            if {[catch {dget $Params $paramName}]} {
                return -code error "Parameter with name '$paramName' was not found in device's '[my configure -name]'\
                        list of parameters '[dict keys [my getParams]]'"
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
                if {[$pin checkFloating]} {
                    lappend floatingPins [$pin configure -name]
                }
            }
            return $floatingPins
        }
        method getParams {} {
            # Gets the dictionary that contains parameter name as keys and
            #  parameter values as the values.
            # Returns: parameters dictionary
            return [dict map {paramName param} $Params {$param configure -value}]
        }
        method genSPICEString {} {
            # Creates device string for SPICE netlist.
            # Returns: SPICE netlist's string
            if {[info exists Pins]} {
                dict for {pinName pin} $Pins {
                    if {![catch {$pin genSPICEString}]} {
                        lappend nodes [$pin genSPICEString]
                    } else {
                        return -code error "Device '[my configure -name]' can't be netlisted because '$pinName' pin is\
                                floating"
                    }
                }
            }
            if {[info exists Params]} {
                set params [lmap param [dict values $Params] {$param genSPICEString}]
                if {[info exists Pins]} {
                    return "[my configure -name] [join $nodes] [join $params]"
                } else {
                    return "[my configure -name] [join $params]"
                }
            } else {
                if {[info exists Pins]} {
                    return "[my configure -name] [join $nodes]"
                } else {
                    return [my configure -name]
                }
            }
        }
    }

###  Model class definition
    ##nagelfar subcmd+ _obj,Model configure addParam
    oo::configurable create Model {
        superclass SPICEElement
        mixin Utility
        property name -set {
            if {$value eq {}} {
                return -code error "Model must have a name, empty string was provided"
            } elseif {[regexp {[^A-Za-z0-9_]+} $value]} {
                return -code error "Model name '$value' is not a valid name"
            } else {
                set name [string tolower $value]
            }
        }
        property type -set {
            if {$value eq {}} {
                return -code error "Model must have a type, empty string was provided"
            } elseif {[regexp {[^A-Za-z0-9]+} $value]} {
                return -code error "Model type '$value' is not a valid type"
            } else {
                set type [string tolower $value]
            }
        }
        variable name
        # type of the model
        variable type
        # list of model parameters objects
        variable Params
        constructor {name type params} {
            # Creates object of class `Model`.
            #  name - name of the model
            #  type - type of model, for example, diode, npn, etc
            #  instParams - list of instance parameters in form `{{name value ?-pos|eq|poseq?}
            #   {name value ?-pos|eq|poseq?} {name value ?-pos|eq|poseq?} ...}`
            # Class represents model card in SPICE netlist.
            my configure -name $name -type $type
            # create Params objects
            if {$params ne {}} {
                foreach param $params {
                    my addParam {*}$param
                }
            }
        }
        method addParam {*}[info class definition ::SpiceGenTcl::Device addParam]
        method deleteParam {*}[info class definition ::SpiceGenTcl::Device deleteParam]
        method setParamValue {*}[info class definition ::SpiceGenTcl::Device setParamValue]
        method getParams {*}[info class definition ::SpiceGenTcl::Device getParams]
        method genSPICEString {} {
            # Creates model string for SPICE netlist.
            # Returns: SPICE netlist's string
            if {![info exists Params]} {
                lappend params {}
                return ".model [my configure -name] [my configure -type]"
            } else {
                set params [lmap param [dict values $Params] {$param genSPICEString}]
                return ".model [my configure -name] [my configure -type]([join $params])"
            }
        }
    }

###  RawString class definition
    ##nagelfar subcmd+ _obj,RawString configure
    oo::configurable create RawString {
        superclass SPICEElement
        property name -set {
            set name $value
        }
        property value
        variable name
        # value of the raw string
        variable value
        constructor {value args} {
            # Creates object of class `RawString`.
            #  value - value of the raw string
            #  -name - name of the string that could be used to retrieve element from [::SpiceGenTcl::Netlist] object
            #    and its descendants, optional
            # Class represent arbitary string.
            #  It can be used to pass any string directly into netlist,
            #  for example, it can add elements that doesn't have dedicated class.
            # Synopsis: value ?-name value?
            argparse {
                -name=
            }
            if {[info exists name]} {
                my configure -name $name
            } else {
                my configure -name [self object]
            }
            my configure -value $value
        }
        method genSPICEString {} {
            # Creates raw string for SPICE netlist.
            # Returns: SPICE netlists string
            return [my configure -value]
        }
    }

###  Comment class definition

    oo::configurable create Comment {
        superclass RawString
        constructor {value args} {
            # Creates object of class `Comment`.
            #  value - value of the comment
            #  -name - name of the string that could be used to retrieve element from [::SpiceGenTcl::Netlist] object
            #    and its descendants, optional
            # Class represent comment string, it can be a multiline comment.
            # Synopsis: value ?-name value?
            argparse {
                -name=
            }
            if {[info exists name]} {
                my configure -name $name
            } else {
                my configure -name [self object]
            }
            my configure -value $value
        }
        method genSPICEString {} {
            # Creates comment string for SPICE netlist.
            # Returns: SPICE netlist's string
            set splitted [split [my configure -value] "\n"]
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
            #  -name - name of the string that could be used to retrieve element from [::SpiceGenTcl::Netlist] object
            #    and its descendants, optional
            # This class represent .include statement.
            # Synopsis: value ?-name value?
            argparse {
                -name=
            }
            if {[info exists name]} {
                my configure -name $name
            } else {
                my configure -name [self object]
            }
            my configure -value $value
        }
        method genSPICEString {} {
            # Creates include string for SPICE netlist.
            # Returns: SPICE netlist's string
            return ".include [my configure -value]"
        }
    }

###  Library class definition

    oo::configurable create Library {
        superclass RawString
        # this variable contains selected library name inside sourced file
        property libvalue -set {
            set libvalue [string tolower $value]
        }
        variable libvalue
        constructor {value libValue args} {
            # Creates object of class `Library`.
            #  value - value of the include file
            #  libValue - value of selected library
            #  -name - name of the string that could be used to retrieve element from [::SpiceGenTcl::Netlist] object
            #    and its descendants, optional
            # Class represent .lib statement.
            # Synopsis: value libValue ?-name value?
            argparse {
                -name=
            }
            if {[info exists name]} {
                my configure -name $name
            } else {
                my configure -name [self object]
            }
            my configure -value $value -libvalue $libValue
        }
        method genSPICEString {} {
            # Creates library string for SPICE netlist.
            # Returns: SPICE netlist's string
            return ".lib [my configure -value] [my configure -libvalue]"
        }
    }

###  Options class definition
    ##nagelfar subcmd+ _obj,Options configure addParam
    oo::configurable create Options {
        superclass SPICEElement
        mixin Utility
        property name -set {
            set name [string tolower $value]
        }
        variable name
        variable Params
        constructor {params args} {
            # Creates object of class `Options`.
            #  params - list of instance parameters in form `{{name value ?-sw?} {name value ?-sw?}
            #   {name value ?-sw?} ...}`
            #  -name - name of the string that could be used to retrieve element from [::SpiceGenTcl::Netlist] object
            #    and its descendants, optional
            # This class represent .options statement.
            # Synopsis: params ?-name value?
            argparse {
                -name=
            }
            if {[info exists name]} {
                my configure -name $name
            } else {
                my configure -name [self object]
            }
            foreach param $params {
                if {[llength $param]<2} {
                    error "Value '$param' is not a valid value"
                } else {
                    my addParam {*}$param
                }
            }
        }
        method getParams {} {
            # Gets the dictionary that contains parameter name as keys and
            #  parameter values as the values.
            # Returns: parameters dictionary
            return [dict map {paramName param} $Params\
                            {expr {[catch {$param configure -value}] ? {} : [$param configure -value]}}]
        }
        method addParam {paramName value args} {
            # Creates new parameter object and add it to the list `Params`.
            #  paramName - name of parameter
            #  value - value of parameter, could be equal to -sw, or with optional qualificator -eq
            argparse {
                -eq
            }
            set paramName [string tolower $paramName]
            if {[info exists Params]} {
                set paramList [dict keys $Params]
            }
            lappend paramList $paramName
            if {[my duplListCheck $paramList]} {
                return -code error "Parameters list '$paramList' has already contains parameter with name '$paramName'"
            }
            if {$value eq {-sw}} {
                dict append Params $paramName [::SpiceGenTcl::ParameterSwitch new $paramName]
            } elseif {[info exists eq]} {
                dict append Params $paramName [::SpiceGenTcl::ParameterEquation new $paramName $value]
            } else {
                dict append Params $paramName [::SpiceGenTcl::ParameterNoCheck new $paramName $value]
            }
            return
        }
        method deleteParam {*}[info class definition ::SpiceGenTcl::Device deleteParam]
        method setParamValue {*}[info class definition ::SpiceGenTcl::Device setParamValue]
        method genSPICEString {} {
            # Creates options string for SPICE netlist.
            # Returns: SPICE netlist's string
            return ".options [join [lmap param [dict values $Params] {$param genSPICEString}]]"
        }
    }

###  ParamStatement class definition
    ##nagelfar subcmd+ _obj,ParamStatement configure addParam
    oo::configurable create ParamStatement {
        superclass SPICEElement
        mixin Utility
        property name -set {
            set name [string tolower $value]
        }
        variable name
        variable Params
        constructor {params args} {
            # Creates object of class `ParamStatement`.
            #  params - list of instance parameters in form `{{name value} {name value} {name equation -eq} ...}`
            #  -name - name of the library that could be used to retrieve element from [::SpiceGenTcl::Netlist] object
            #    and its descendants, optional
            # Class represent .param statement.
            # Synopsis: params ?-name value?
            argparse {
                -name=
            }
            if {[info exists name]} {
                my configure -name $name
            } else {
                my configure -name [self object]
            }
            foreach param $params {
                if {[llength $param]<2} {
                    error "Value '$param' is not a valid value"
                } else {
                    my addParam {*}$param
                }
            }
        }
        method getParams {*}[info class definition ::SpiceGenTcl::Device getParams]
        method addParam {paramName value args} {
            # Adds new Parameter object to the list Params.
            #  paramName - name of parameter
            #  value - value of parameter
            #  -eq - optional parameter qualificator
            # Synopsis: paramName value ?-eq?
            argparse {
                -eq
            }
            set paramName [string tolower $paramName]
            if {[info exists Params]} {
                set paramList [dict keys $Params]
            }
            lappend paramList $paramName
            if {[my duplListCheck $paramList]} {
                return -code error "Parameters list '$paramList' has already contains parameter with name '$paramName'"
            }
            if {[info exists eq]} {
                dict append Params $paramName [::SpiceGenTcl::ParameterEquation new $paramName $value]
            } else {
                dict append Params $paramName [::SpiceGenTcl::Parameter new $paramName $value]
            }
            return
        }
        method deleteParam {*}[info class definition ::SpiceGenTcl::Device deleteParam]
        method setParamValue {*}[info class definition ::SpiceGenTcl::Device setParamValue]
        method genSPICEString {} {
            # Creates parameter statement string for SPICE netlist.
            # Returns: SPICE netlist's string
            return ".param [join [join [lmap param [dict values $Params] {$param genSPICEString}]]]"
        }
    }

###  Save class definition
    ##nagelfar subcmd+ _obj,Save configure addParam addVector
    oo::configurable create Save {
        superclass SPICEElement
        mixin Utility
        property name -set {
            set name [string tolower $value]
        }
        variable name
        variable Vectors
        constructor {vectors args} {
            # Creates object of class `ParamStatement`.
            #  vectors - list of vectors in form `{vec0 vec1 vec2 ...}`
            #  -name - name of the library that could be used to retrieve element from [::SpiceGenTcl::Netlist] object
            #    and its descendants, optional
            # Class represent .save statement.
            # Synopsis: vectors ?-name value?
            argparse {
                -name=
            }
            if {[info exists name]} {
                my configure -name $name
            } else {
                my configure -name [self object]
            }
            foreach vector $vectors {
                if {[llength $vector]>1} {
                    error "Name '$vector' is not a valid name of the vector"
                } else {
                    my addVector {*}$vector
                }
            }
        }
        method getVectors {} {
            # Gets the dictionary of vector names
            # Returns: vectors dictionary
            return $Vectors
        }
        method addVector {vectorName} {
            # Adds new `ParameterVector` object to the list Vectors.
            #  vectorName - name of vector
            set vectorName [string tolower $vectorName]
            if {[info exists Vectors]} {
                set vectorList [dict keys $Vectors]
            }
            lappend vectorList $vectorName
            if {[my duplListCheck $vectorList]} {
                return -code error "Vectors list '$vectorList' has already contains vector with name '$vectorName'"
            }
            dict append Vectors $vectorName [::SpiceGenTcl::ParameterVector new $vectorName]
            return
        }
        method deleteVector {vectorName} {
            # Deletes existing `ParameterVector` object from dictionary `Vectors`.
            #  vectorName - name of parameter that will be deleted
            set vectorName [string tolower $vectorName]
            if {[catch {dget $Vectors $vectorName}]} {
                return -code error "Vector with name '$vectorName' was not found in device's '[my configure -name]'\
                        list of parameters '[dict keys $Vectors]'"
            } else {
                set Vectors [dict remove $Vectors $vectorName]
            }
            return
        }
        method genSPICEString {} {
            # Creates save statement string for SPICE netlist.
            # Returns: SPICE netlist's string
            return ".save [join [join [lmap vector [dict values $Vectors] {$vector genSPICEString}]]]"
        }
    }

###  Ic class definition
    ##nagelfar subcmd+ _obj,Ic configure addParam
    oo::configurable create Ic {
        superclass SPICEElement
        mixin Utility
        property name -set {
            set name [string tolower $value]
        }
        variable name
        variable Params
        constructor {params args} {
            # Creates object of class `Ic`.
            #  params - list of instance parameters in form `{{name value} {name value} {name equation -eq} ...}`
            #  -name - name of the library that could be used to retrieve element from [::SpiceGenTcl::Netlist] object
            #    and its descendants, optional
            # Class represent .ic statement.
            # Synopsis: params ?-name value?
            argparse {
                -name=
            }
            if {[info exists name]} {
                my configure -name $name
            } else {
                my configure -name [self object]
            }
            foreach param $params {
                if {[llength $param]<2} {
                    error "Value '$param' is not a valid value"
                } else {
                    my addParam {*}$param
                }
            }
        }
        method getParams {*}[info class definition ::SpiceGenTcl::Device getParams]
        method addParam {paramName value args} {
            # Adds new Parameter object to the list Params.
            #  paramName - name of parameter
            #  value - value of parameter
            #  -eq - optional parameter qualificator
            # Synopsis: paramName value ?-eq?
            argparse {
                -eq
            }
            set paramName [string tolower $paramName]
            if {[info exists Params]} {
                set paramList [dict keys $Params]
            }
            lappend paramList $paramName
            if {[my duplListCheck $paramList]} {
                return -code error "Parameters list '$paramList' has already contains parameter with name '$paramName'"
            }
            if {[info exists eq]} {
                dict append Params $paramName [::SpiceGenTcl::ParameterNodeEquation new $paramName $value]
            } else {
                dict append Params $paramName [::SpiceGenTcl::ParameterNode new $paramName $value]
            }
            return
        }
        method deleteParam {*}[info class definition ::SpiceGenTcl::Device deleteParam]
        method setParamValue {*}[info class definition ::SpiceGenTcl::Device setParamValue]
        method genSPICEString {} {
            # Creates ic statement string for SPICE netlist.
            # Returns: SPICE netlist's string
            return ".ic [join [join [lmap param [dict values $Params] {$param genSPICEString}]]]"
        }
    }

###  Nodeset class definition

    oo::configurable create Nodeset {
        superclass Ic
        mixin Utility
        variable Params
        method genSPICEString {} {
            # Creates nodeset statement string for SPICE netlist.
            # Returns: SPICE netlist's string
            return ".nodeset [join [join [lmap param [dict values $Params] {$param genSPICEString}]]]"
        }
    }

###  Global class definition
    ##nagelfar subcmd+ _obj,Global configure addNets
    oo::configurable create Global {
        superclass SPICEElement
        mixin Utility
        property name -set {
            set name [string tolower $value]
        }
        variable name
        variable Nets
        constructor {nets args} {
            # Creates object of class `Global`.
            #  params - list of nets in form `{net0 net1 ...}`
            #  -name - name of the library that could be used to retrieve element from [::SpiceGenTcl::Netlist] object
            #    and its descendants, optional
            # Class represent .global statement.
            # Synopsis: nets ?-name value?
            argparse {
                -name=
            }
            if {[info exists name]} {
                my configure -name $name
            } else {
                my configure -name [self object]
            }
            my addNets $nets
        }
        method addNets {nets} {
            if {[info exists Nets]} {
                set netsList $Nets
            }
            foreach net $nets {
                if {$net ne {}} {
                    lappend netsList $net
                    if {[my duplListCheck $netsList]} {
                        error "Net with name '${net}' is already attached to the object '[my configure -name]'"
                    }
                } else {
                    error {Net name couldn't be empty}
                }
            }
            set Nets $netsList
            return
        }
        method deleteNet {net} {
            set netsList $Nets
            if {[set index [lsearch -exact $netsList $net]] !=-1} {
                set netsList [lremove $netsList $index]
            } else {
                error "Global statement '${name}' doesn't have attached net with name '${net}'"
            }
            set Nets $netsList
            return
        }
        method genSPICEString {} {
            # Creates global statement string for SPICE netlist.
            # Returns: SPICE netlist's string
            return ".global [join $Nets]"
        }
    }

###  Temp class definition
    ##nagelfar subcmd+ _obj,Temp configure AddParam
    oo::configurable create Temp {
        superclass SPICEElement
        property name -set {
            set name [string tolower $value]
        }
        property value -get {
            return [$value configure -value]
        }
        variable name value
        constructor {value args} {
            # Creates object of class `Temp`.
            #  value - value of the temperature
            #  -eq - optional parameter qualificator
            # This class represent .temp statement with temperature value.
            # Synopsis: value ?-eq?
            argparse {
                {-eq -boolean}
            }
            #set [my varname value] $value
            my configure -name temp
            ##nagelfar variable eq
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
            #  -eq - optional parameter qualificator
            # Synopsis: paramName value ?-eq?
            set arguments [argparse {
                {-eq -boolean}
            }]
            ##nagelfar variable eq
            if {$eq} {
                set [my varname value] [::SpiceGenTcl::ParameterPositionalEquation new $paramName $value]
            } else {
                set [my varname value] [::SpiceGenTcl::ParameterPositional new $paramName $value]
            }
            return
        }
        method genSPICEString {} {
            # Creates .temp statement string for SPICE netlist.
            # Returns: SPICE netlist's string
            return ".temp [$value genSPICEString]"
        }
    }
    oo::define Temp {
        method <WriteProp-value> val {
            lassign $val value eq
            if {$eq eq {-eq}} {
                my AddParam temp $value -eq
            } elseif {$eq eq {}} {
                my AddParam temp $value
            } else {
                return -code error "Wrong value '$eq' of qualifier"
            }
        }
    }

###  Netlist class definition
    ##nagelfar subcmd+ _obj,Netlist configure getAllElemNames
    oo::configurable create Netlist {
        superclass SPICEElement
        mixin Utility
        property name -set {
            set name [string tolower $value]
        }
        variable name
        variable Elements
        constructor {name} {
            # Creates object of class `Netlist`.
            #  name - name of the netlist
            # Class implements netlist as a collection of SPICE elements. Any element that has SPICEElement
            # as a parent class can be added to Netlist, except Options and Analysis.
            my configure -name $name
        }
        method add {args} {
            # Adds elements objects to Elements dictionary.
            #  args - elements objects references
            foreach arg $args {
                lappend elementsNamesList [string tolower [$arg configure -name]]
            }
            if {[info exists Elements]} {
                lappend elementsNamesList {*}[my getAllElemNames]
            }
            set dup [my duplListCheckRet $elementsNamesList]
            if {$dup ne {}} {
                return -code error "Netlist '[my configure -name]' already contains element with name $dup"
            }
            foreach arg $args {
                set elemName [$arg configure -name]
                dict append Elements $elemName $arg
            }
            return
        }
        method del {args} {
            # Deletes elements from the netlist by its name.
            #  args - names of elements to delete
            if {![info exists Elements]} {
                return -code error "Netlist '[my configure -name]' doesn't have attached elements"
            }
            foreach arg $args {
                set elemName [string tolower $arg]
                if {[catch {dget $Elements $elemName}]} {
                    return -code error "Element with name '$elemName' was not found in netlist's '[my configure -name]'\
                        list of elements"
                } else {
                    set Elements [dict remove $Elements $elemName]
                }
            }
            return
        }
        method getElement {elemName} {
            # Gets particular element object reference by its name.
            #  elemName - name of element
            set elemName [string tolower $elemName]
            if {[catch {dget $Elements $elemName}]} {
                return -code error "Element with name '$elemName' was not found in netlist's '[my configure -name]'\
                        list of elements"
            } else {
                set foundElem [dget $Elements $elemName]
            }
            return $foundElem
        }
        method getAllElemNames {} {
            # Gets names of all elements in netlist.
            # Returns: list of elements names
            if {![info exists Elements]} {
                return -code error "Netlist '[my configure -name]' doesn't have attached elements"
            }
            return [dict keys $Elements]
        }
        method genSPICEString {} {
            # Creates netlist string for SPICE netlist.
            # Returns: SPICE netlist's string
            if {![info exists Elements]} {
                return -code error "Netlist '[my configure -name]' doesn't have attached elements"
            }
            return [join [lmap element [dict values $Elements] {$element genSPICEString}] \n]
        }
    }


###  Circuit class definition

    oo::configurable create Circuit {
        superclass Netlist
        # simulator object that run simulation
        property simulator
        variable simulator
        # standard output of simulation
        property log
        variable log
        # results of simulation in form of RawData object
        property data
        variable data
        # flag that tells about Analysis element presence in Circuit
        variable ContainAnalysis Elements
        constructor {name} {
            # Creates object of class `CircuitNetlist`.
            #  name - name of the tol-level circuit
            # Class implements a top level netlist which is run in SPICE. We should add [::SpiceGenTcl::Simulator]
            # object reference to make it able to run simulation.
            next $name
        }
        method add {args} {
            # Adds elements object to Circuit `Elements` dictionary.
            #  args - elements objects references
            foreach arg $args {
                if {([info object class $arg {::SpiceGenTcl::Analysis}]) && ([info exists ContainAnalysis])} {
                    return -code error "Netlist '[my configure -name]' already contains Analysis element"
                } elseif {[info object class $arg {::SpiceGenTcl::Analysis}]} {
                    set ContainAnalysis {}
                }
                lappend elementsNamesList [string tolower [$arg configure -name]]
            }
            if {[info exists Elements]} {
                lappend elementsNamesList {*}[my getAllElemNames]
            }
            set dup [my duplListCheckRet $elementsNamesList]
            if {$dup ne {}} {
                return -code error "Netlist '[my configure -name]' already contains element with name $dup"
            }
            foreach arg $args {
                set elemName [$arg configure -name]
                dict append Elements $elemName $arg
            }
            return
        }
        method del {args} {
            # Deletes elements from the circuit by its name.
            #  args - name of element to delete
            if {![info exists Elements]} {
                return -code error "Netlist '[my configure -name]' doesn't have attached elements"
            }
            foreach arg $args {
                set elemName [string tolower $arg]
                if {[catch {dget $Elements $elemName}]} {
                    return -code error "Element with name '$elemName' was not found in circuit's '[my configure -name]'\
                        list of elements"
                } else {
                    if {[info object class [dget $Elements $elemName] {::SpiceGenTcl::Analysis}]} {
                        unset ContainAnalysis
                    }
                    set Elements [dict remove $Elements $elemName]
                }
            }
            return
        }
        method detachSimulator {} {
            # Removes `Simulator` object reference from `Circuit`.
            unset simulator
            return
        }
        method getDataDict {} {
            # Method to get dictionary with raw data vectors.
            # Returns: dict with vectors data, keys - names of vectors
            return [[my configure -data] getTracesData]
        }
        method getDataCsv {args} {
            # Returns string with csv formatting containing all data
            #  -all - select all traces
            #  -traces - select names of traces to return
            #  -sep - separator of columns, default is comma
            # Synopsis: ?-all? ?-traces list? ?-sep value?
            return [[my configure -data] getTracesCsv {*}$args]
        }
        method genSPICEString {} {
            # Creates circuit string for SPICE netlist.
            # Returns: SPICE netlist's string
            lappend totalStr [my configure -name] {*}[lmap element [dict values $Elements] {$element genSPICEString}]
            return [join $totalStr \n]
        }
        method runAndRead {args} {
            # Invokes 'runAndRead', 'configure -log' and 'configure -data' methods from attached simulator.
            #  -nodelete - flag to forbid simulation file deletion
            # Synopsis: ?-nodelete?
            set arguments [argparse {
                -nodelete
            }]
            if {![info exists simulator]} {
                return -code error "Simulator is not attached to '[my configure -name]' circuit"
            }
            if {[info exists nodelete]} {
                $simulator runAndRead [my genSPICEString] -nodelete
            } else {
                $simulator runAndRead [my genSPICEString]
            }
            my configure -log [$simulator configure -log] -data [$simulator configure -data]
        }
    }

###  Subcircuit class definition
    ##nagelfar subcmd+ _obj,Subcircuit AddPin addParam
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
            #  params - list of input parameters in form `{{name value} {name value} {name value} ...}`
            # This class implements subcircuit, it is subclass of netlist because it holds list of elements
            # inside subcircuit, together with header and connection of elements inside.

            # create Pins objects, nodes are set to empty line
            foreach pin $pins {
                my AddPin [@ $pin 0] {}
            }
            # create Params objects that are input parameters of subcircuit
            if {$params ne {}} {
                foreach param $params {
                    if {[llength $param]<=2} {
                        my addParam [@ $param 0] [@ $param 1]
                    } else {
                        error "Wrong parameter '[@ $param 0]' definition in subcircuit $name"
                    }
                }
            }
            next $name
        }
        # copy methods of Device to manipulate header .subckt definition elements
        method AddPin {*}[info class definition ::SpiceGenTcl::Device AddPin]
        method getPins {*}[info class definition ::SpiceGenTcl::Device getPins]
        method deleteParam {*}[info class definition ::SpiceGenTcl::Device deleteParam]
        method setParamValue {*}[info class definition ::SpiceGenTcl::Device setParamValue]
        method getParams {*}[info class definition ::SpiceGenTcl::Device getParams]
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
                return -code error "Parameters list '$paramList' has already contains parameter with name '$paramName'"
            }
            dict append Params $paramName [::SpiceGenTcl::Parameter new $paramName $value]
            return
        }

        method add {args} {
            # Add element object reference to `Netlist`, it extends add method to add check of element class because
            # subcircuit can't contain particular elements inside, like [::SpiceGenTcl::Include],
            # [::SpiceGenTcl::Library], [::SpiceGenTcl::Options] and [::SpiceGenTcl::Analysis].
            #  args - elements objects references
            foreach arg $args {
                set argClass [info object class $arg]
                set argSuperclass [info class superclasses $argClass]
                if {$argClass in {::SpiceGenTcl::Include ::SpiceGenTcl::Library ::SpiceGenTcl::Options}} {
                    return -code error "$argClass element can't be included in subcircuit"
                } elseif {[string match *::Analysis* $argSuperclass] || [string match *::Analyses* $argSuperclass]} {
                    return -code error "Analysis element can't be included in subcircuit"
                }
            }
            next {*}$args
        }
        method genSPICEString {} {
            # Creates subcircuit string for SPICE subcircuit.
            # Returns: SPICE netlist's string
            set name [my configure -name]
            set nodes [lmap pin [dict values $Pins] {$pin configure -name}]
            if {![info exists Params]} {
                set header ".subckt $name [join $nodes]"
            } else {
                set params [lmap param [dict values $Params] {$param genSPICEString}]
                set header ".subckt $name [join $nodes] [join $params]"
            }
            # get netlist elements from netlist genSPICEString method
            set resStr [next]
            return [join [list $header $resStr ".ends $name"] \n]
        }
    }

###  Analysis class definition
    ##nagelfar subcmd+ _obj,Analysis configure addParam
    oo::configurable create Analysis {
        superclass SPICEElement
        mixin Utility
        property name -set {
            set name [string tolower $value]
        }
        variable name
        # type of analysis, i.e. dc, ac, tran, etc
        property type -set {
            set type [string tolower $value]
            set suppAnalysis [list ac dc tran op disto noise pz sens sp tf]
            if {$value ni $suppAnalysis} {
                return -code error "Type '$value' is not in supported list of analysis, should be one of '$suppAnalysis'"
            }
            set type $value
        }
        variable type
        # list of Parameter objects
        variable Params
        constructor {type params args} {
            # Creates object of class `Analysis`.
            #  type - type of analysis, for example, tran, ac, dc, etc
            #  params - list of instance parameters in form
            #   `{{name value} {name -sw} {name Value -eq} {name Value -posnocheck} ...}`
            #  -name - name of the string that could be used to retrieve element from [::SpiceGenTcl::Netlist] object
            #    and its descendants, optional
            # Class models analysis statement.
            # Synopsis: type params ?-name value?
            my variable name
            set arguments [argparse {
                -name=
            }]
            if {[info exists name]} {
                my configure -name $name
            } else {
                my configure -name [self object]
            }
            my configure -type $type
            # create Analysis objects
            foreach param $params {
                if {[llength $param]<2} {
                    error "Value '$param' is not a valid value"
                } else {
                    my addParam {*}$param
                }
            }
        }
        method getParams {*}[info class definition ::SpiceGenTcl::Device getParams]
        method addParam {*}[info class definition ::SpiceGenTcl::Device addParam]
        method deleteParam {*}[info class definition ::SpiceGenTcl::Device deleteParam]
        method setParamValue {*}[info class definition ::SpiceGenTcl::Device setParamValue]
        method genSPICEString {} {
            # Creates analysis for SPICE netlist.
            # Returns: string SPICE netlist's string
            if {[info exists Params]} {
                return ".[my configure -type] [join [lmap param [dict values $Params] {$param genSPICEString}]]"
            } else {
                return ".[my configure -type]"
            }
        }
    }

###  Simulator class definition

    oo::configurable create Simulator {
        self mixin -append oo::abstract
        property name
        variable name
        variable Command
        property log
        variable log
        property data
        variable data
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
            binary scan $s d num
            return $num
        }
        method readComplex {file} {
            # Reads two 8 byte numbers from file.
            #  file - file handler
            # Returns: list of two values.
            set s [read $file 16]
            binary scan $s dd re im
            return [list $re $im]
        }
        method readFloat32 {file} {
            # Reads 4 bytes number from file.
            #  file - file handler
            # Returns: value of number.
            set s [read $file 4]
            binary scan $s f num
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
    ##nagelfar subcmd+ _obj,Dataset configure
    oo::configurable create Dataset {
        # This class models general raw dataset
        property name -set {
            set name [string tolower $value]
        }
        variable name
        # Type of dataset, could be voltage, vurrent, time or frequency
        property type -set {
            set type [string tolower $value]
        }
        variable type
        # Numerical type of dataset, real, double or complex
        property numtype -set {
            # method to set the numerical type of the dataset
            if {$value ni {real complex double}} {
                error "Unknown numerical type '$value' of data"
            }
            set numtype $value
        }
        variable numtype
        # Number of points (length of dataset)
        property len
        variable len
        # values at points
        variable DataPoints
        constructor {name type len {numType real}} {
            # initialize dataset
            #  name - name of the dataset
            #  type - type of dataset
            #  len - total number of points
            #  numType - numerical type of dataset
            my configure -name $name -type $type -len $len -numtype $numType
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
                return -code error "Dataset with name '[my configure -name]' doesn't contain non-zero points"
            }
            return
        }
        method getStr {} {
            return "Name: '[my configure -name]', Type: '[my configure -type]', Length: '[my configure -len]',\
                    Numerical type: '[my configure -numtype]'"
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
        property axis
        variable axis
        constructor {name type len axis {numType real}} {
            # initialize trace
            #  name - name of the trace
            #  type - type of trace
            #  len - total number of points
            #  axis - name of axis that is linked to trace
            #  numType - numerical type of trace
            my configure -axis $axis
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
                return {}
            }
            return
        }
    }

###  RawFile class definition
    ##nagelfar subcmd+ _obj,RawFile configure
    oo::configurable create RawFile {
        # Class represents raw file
        mixin BinaryReader
        # path to raw file including it's file name
        property path
        variable path
        # parameters of raw file readed from it's header
        property rawparams
        variable rawparams
        # number of points in raw file
        property npoints
        variable npoints
        # number of variables in raw file
        property nvariables
        variable nvariables
        # object reference of axis in raw file
        property axis -get {
            if {[info exists axis]} {
                return $axis
            } else {
                return -code error "Raw file '[my configure -path]' doesn't have an axis"
            }
        }
        variable axis
        # objects references of traces in raw file
        property traces
        variable traces
        # binary block size in bytes that contains all variables at axis point value
        variable BlockSize
        constructor {path {traces2read *} {simulator ngspice}} {
            # Creates RawFile object.
            #  path - path to raw file including it's file name
            #  traces2read - list of traces that will be readed, default value is \*,
            #   that means reading all traces
            #  simulator - simulator that produced this raw file, default is ngspice
            my configure -path $path
            set fileSize [file size $path]
            set file [open $path r]
            fconfigure $file -translation binary

####  read header

            set ch [read $file 6]
            if {[encoding convertfrom utf-8 $ch] eq {Title:}} {
                set encSize 1
                set encode utf-8
                set line Title:
            } elseif {[encoding convertfrom utf-16le $ch] eq {Tit}} {
                set encSize 2
                set encode utf-16le
                set line Tit
            } else {
                close $file
                error {Unknown encoding}
            }
            my configure -rawparams [dcreate Filename $path]
            set header {}
            set binaryStart 6
            while true {
                set ch [encoding convertfrom $encode [read $file $encSize]]
                incr binaryStart $encSize
                if {$ch eq "\n"} {
                    if {$encode eq {utf-8}} {
                        set line [string trimright $line "\r"]
                    }
                    lappend header $line
                    if {$line in {Binary: Values:}} {
                        set rawType $line
                        break
                    }
                    set line {}
                } else {
                    append line $ch
                }
            }

####  save header parameters

            foreach line $header {
                set lineList [split $line :]
                if {[@ $lineList 0] eq {Variables}} {
                    break
                }
                dict append rawparams [@ $lineList 0] [string trim [@ $lineList 1]]
            }
            my configure -npoints [dget [my configure -rawparams] {No. Points}] -nvariables\
                    [dget [my configure -rawparams] {No. Variables}]
            if {[dget [my configure -rawparams] Plotname] in {{Operating Point} {Transfet Function}}} {
                set hasAxis 0
            } else {
                set hasAxis 1
            }
            set flags [split [dget [my configure -rawparams] Flags]]
            if {({complex} in $flags) || ([dget [my configure -rawparams] Plotname] eq {AC Analysis})} {
                set numType complex
            } else {
                if {({double} in $flags) || ($simulator eq {ngspice}) || ($simulator eq {xyce})} {
                    set numType double
                } else {
                    set numType real
                }
            }

####  parse variables

            set i [lsearch $header Variables:]
            set ivar 0
            foreach line [lrange $header [+ $i 1] end-1] {
                set lineList [split [string trim $line] \t]
                lassign $lineList idx name varType
                if {$ivar==0} {
                    if {$simulator eq {ltspice} && $name eq {time}} {
                        # workaround for bug with negative values in time axis
                        set axisIsTime true
                    }
                    if {$numType eq {real}} {
                        set axisNumType double
                    } else {
                        set axisNumType $numType
                    }
                    my configure -axis [::SpiceGenTcl::Axis new $name $varType $npoints $axisNumType]
                    set trace [my configure -axis]
                } elseif {($traces2read eq {*}) || ($name in $traces2read)} {
                    if {$hasAxis} {
                        set trace [::SpiceGenTcl::Trace new $name $varType $npoints\
                                           [[my configure -axis] configure -name] $numType]
                    } else {
                        set trace [::SpiceGenTcl::Trace new $name $varType $npoints {} $numType]
                    }
                } else {
                    set trace [::SpiceGenTcl::EmptyTrace new $name $varType $npoints $numType]
                }
                lappend traces $trace
                incr ivar
            }
            if {($traces2read eq {}) || ![llength $traces2read]} {
                close $file
                return
            }

####  read data
            if {$rawType eq {Binary:}} {
                set BlockSize [= {($fileSize - $binaryStart)/$npoints}]
                set scanFunctions {}
                set calcBlockSize 0
                foreach trace [my configure -traces] {
                    if {[$trace configure -numtype] eq {double}} {
                        incr calcBlockSize 8
                        if {[info object class $trace ::SpiceGenTcl::EmptyTrace]} {
                            set fun skip8bytes
                        } else {
                            set fun readFloat64
                        }
                    } elseif {[$trace configure -numtype] eq {complex}} {
                        incr calcBlockSize 16
                        if {[info object class $trace ::SpiceGenTcl::EmptyTrace]} {
                            set fun skip16bytes
                        } else {
                            set fun readComplex
                        }
                    } elseif {[$trace configure -numtype] eq {real}} {
                        incr calcBlockSize 4
                        if {[info object class $trace ::SpiceGenTcl::EmptyTrace]} {
                            set fun skip4bytes
                        } else {
                            set fun readFloat32
                        }
                    } else {
                        close $file
                        error "Invalid data type '[$trace configure -numtype]' for trace '[$trace configure -name]'"
                    }
                    lappend scanFunctions $fun
                }
                if {$calcBlockSize!=$BlockSize} {
                    close $file
                    error "Error in calculating the block size. Expected '${BlockSize}' bytes, but found\
                            '$calcBlockSize' bytes"
                }
                 for {set i 0} {$i<$npoints} {incr i} {
                    for {set j 0} {$j<[llength [my configure -traces]]} {incr j} {
                        set value [eval "my [@ $scanFunctions $j]" $file]
                        set trace [@ [my configure -traces] $j]
                        if {$j==0} {
                            # workaround for bug with negative values in time axis
                            if {[info exists axisIsTime]} {
                                set value [= {abs($value)}]
                            }
                        }
                        if {[info object class $trace] ne {::SpiceGenTcl::EmptyTrace}} {
                            $trace appendDataPoints $value
                        }
                    }
                 }
            } elseif {$rawType eq {Values:}} {
                for {set i 0} {$i<$npoints} {incr i} {
                    set firstVar true
                    for {set j 0} {$j<[llength [my configure -traces]]} {incr j} {
                        set line [gets $file]
                        if {$line eq {}} {
                            continue
                        }
                        set lineList [textutil::split::splitx $line]
                        if {$firstVar} {
                            set firstVar false
                            set sPoint [@ $lineList 0]
                            if {$i!=int($sPoint)} {
                                close $file
                                error {Error reading file}
                            }
                            if {$numType eq {complex}} {
                                set value [split [@ $lineList 1] ","]
                            } else {
                                set value [@ $lineList 1]
                            }
                        } else {
                            if {$numType eq {complex}} {
                                set value [split [@ $lineList 1] ","]
                            } else {
                                set value [@ $lineList 1]
                            }
                        }
                        set trace [@ [my configure -traces] $j]
                        $trace appendDataPoints $value
                    }
                }
            }
            close $file
        }
        method getTrace {traceName} {
            # Returns trace object reference by it's name
            set traceFoundFlag false
            foreach trace [my configure -traces] {
                if {[$trace configure -name] eq $traceName} {
                    set traceFound $trace
                    set traceFoundFlag true
                    break
                }
            }
            if {$traceFoundFlag==false} {
                return -code error "Trace with name '$traceName' was not found in raw file '[my configure -path]' list\
                        of traces"
            }
            return $traceFound
        }
        method getVariablesNames {} {
            # Returns list that contains names of all variables
            return [lmap trace [my configure -traces] {$trace configure -name}]
        }
        method getVoltagesNames {} {
            # Returns list that contains names of all voltage variables
            return [lmap trace [my configure -traces]\
                            {expr {[string match -nocase {*voltage*} [$trace configure -type]] ?\
                                           [$trace configure -name] : [continue]}}]
        }
        method getCurrentsNames {} {
            # Returns list that contains names of all current variables
            return [lmap trace [my configure -traces]\
                            {expr {[string match -nocase {*current*} [$trace configure -type]] ?\
                                           [$trace configure -name] : [continue]}}]
        }
        method getTracesStr {} {
            # Returns information about all Traces in raw file in form of string
            return [lmap trace [my configure -traces]\
                            {join [list [$trace configure -name] [$trace configure -type] [$trace configure -numtype]]}]
        }
        method getTracesData {} {
            # Returns dictionary that contains all data in value and name as a key
            set dict {}
            foreach trace [my configure -traces] {
                dict append dict [$trace configure -name] [$trace getDataPoints]
            }
            return $dict
        }
        method getTracesCsv {args} {
            # Returns string with csv formatting containing all data
            #  -all - select all traces, optional
            #  -traces - select names of traces to return, optional
            #  -sep - separator of columns, default is comma, optional
            # Synopsis: ?-all? ?-traces list? ?-sep value?
            set arguments [argparse -inline {
                {-all -forbid {traces}}
                {-traces -catchall -forbid {all}}
                {-sep= -default {,}}
            }]
            if {[dexist $arguments all]} {
                set tracesDict [my getTracesData]
                set tracesList [list [dict keys $tracesDict]]
                for {set i 0} {$i<[my configure -npoints]} {incr i} {
                    lappend tracesList [lmap traceValues [dict values $tracesDict] {@ $traceValues $i}]
                }
            ##nagelfar ignore
            } elseif {[dget $arguments traces] ne {}} {
                ##nagelfar ignore
                foreach traceName [dget $arguments traces] {
                    set traceObj [my getTrace $traceName]
                    dict append tracesDict [$traceObj configure -name] [$traceObj getDataPoints]
                }
                set tracesList [list [dict keys $tracesDict]]
                for {set i 0} {$i<[my configure -npoints]} {incr i} {
                    lappend tracesList [lmap traceValues [dict values $tracesDict] {@ $traceValues $i}]
                }
            } else {
                return -code error "Arguments '-all' or '-traces traceName1 traceName2 ...' must be provided to\
                        'getTracesCsv' method"
            }
            return [::csv::joinlist $tracesList [dget $arguments sep]]
        }
    }

###  Parser class definition
    ##nagelfar subcmd+ _obj,Parser configure CheckEqual Unbrace ParseWithEqual CheckBraced CheckBracedWithEqual\
            ParseBracedWithEqual BuildNetlist buildTopNetlist ParseParams
    oo::configurable create Parser {
        property parsername
        variable parsername
        property filepath
        variable filepath
        variable FileData
        # The SubcktsTree contains a tree object from the `struct::tree` library, representing a hierarchical subcircuit
        # structure with possible nested subcircuits. Each node's name corresponds to the full path of a particular 
        # subcircuit in the hierarchy. For example, `/topsubckt/middlesubckt/innersubckt` represents the subcircuit
        # `innersubckt`, defined inside `middlesubckt`, which is itself defined within `topsubckt`.
        # Each node has the following attributes:
        #   startLine - The line number in the processed netlist where the subcircuit definition (.subckt) begins.
        #   endLine - The line number in the processed netlist where the subcircuit definition (.ends) ends.
        #   definition - A code string containing the subcircuit's definition corresponding to the node. This is built 
        #     from the bottom up, meaning the definition of the top subcircuit includes the definitions of its child 
        #     subcircuits in its constructor and local namespace. Each child subcircuit's definition, in turn, includes 
        #     the definitions of its own children, continuing down the hierarchy.
        variable SubcktsTree
        variable ElemsMethods
        variable DotsMethods
        variable SupModelsTypes
        property topnetlist
        variable topnetlist
        variable definitions
        property definitions
        variable ModelTemplate
        variable SubcircuitTemplate
        variable NamespacePath

        constructor {name filepath} {
            # Creates object of class `Parser` that do parsing of valid simulator netlist.
            #   name - name of the object
            #   filepath - path to file that should be parsed
            my configure -parsername $name
            my configure -filepath $filepath
            my configure -topnetlist [::SpiceGenTcl::Netlist new [file tail $filepath]]
            set ModelTemplate {oo::class create @type@ {
                superclass ::SpiceGenTcl::Model
                constructor {name args} {
                    set paramsNames [list @paramsList@]
                    next $name @type@ [my argsPreprocess $paramsNames {*}$args]
                }
            }}
            set SubcircuitTemplate {oo::class create @classname@ {
                superclass ::SpiceGenTcl::Subcircuit
                constructor {} {
                    @definitions@
                    @elements@
                    set pins @pins@
                    set params @params@
                    next @subname@ $pins $params
                }
            }}
        }
        method readFile {} {
            error "Not implemented"
        }
        method readAndParse {args} {
            # Calls methods `readFile` and `buildTopNetlist` in a sequence
            my readFile
            return [my buildTopNetlist {*}$args]
        }
        method GetSubcircuitLines {} {
            # Parses line by line and creates tree with each node represent subcircuit that can contain
            #   other subcircuits as it's children. As attributes we have number of start and end lines of subcircuit.
            if {![info exists FileData]} {
                error "Parser object '[my configure -parsername]' doesn't have prepared data"
            }
            set fileData $FileData
            set tree [::struct::tree]
            $tree rename root /
            set lineNum 0
            set stack /
            set currentPath /
            foreach line $fileData {
                # Check if line starts with .subckt
                if {[regexp {^\.subckt\s+(\S+)} $line -> subcktName]} {
                    # Build hierarchical path
                    if {$currentPath eq {/}} {
                        set newPath /$subcktName
                    } else {
                        set newPath $currentPath/$subcktName
                    }
                    # Create new node in tree - use full path as node name
                    set currentNode [lindex $stack end]
                    $tree insert $currentNode end $newPath
                    $tree set $newPath startLine $lineNum
                    # Update stack and current path
                    lappend stack $newPath
                    set currentPath $newPath
                }
                if {[regexp {^\.ends} $line]} {
                    if {[llength $stack] > 1} {  # > 1 because root is always in stack
                        set currentNode [lindex $stack end]
                        $tree set $currentNode endLine $lineNum
                        # Pop from stack and restore parent path
                        set stack [lrange $stack 0 end-1]
                        set currentPath [lindex $stack end]
                    } else {
                        # .ends without matching .subckt
                        error {.ends statement without matching .subckt}
                    }
                }
                incr lineNum
            }
            # Check for unclosed .subckt statements
            if {[llength $stack] > 1} {  # > 1 because root is always in stack
                set unclosedNode [lindex $stack end]
                set line [$tree get $unclosedNode startLine]
                error "Unclosed .subckt '$unclosedNode' started at line [@ $fileData $line]"
            }
            set SubcktsTree $tree
            return
        }
        method BuildSubcktFromDef {subcktPath} {
            # Builds subcircuit definition code from passed lines and save it to attribute `definition` of corresponding
            # node.
            #   subcktPath - subcircuit as a name of the tree node
            if {![info exists FileData]} {
                error "Parser object '[my configure -parsername]' doesn't have prepared data"
            }
            set allLines $FileData
            set startLine [$SubcktsTree get $subcktPath startLine]
            set endLine [$SubcktsTree get $subcktPath endLine]
            set children [$SubcktsTree children $subcktPath]
            # parse definition line of subcircuit
            set defLine [@ $allLines $startLine]
            set defLine [string map {" :" ":"} $defLine]
            set lineList [split $defLine]
            lassign $lineList elemName
            set elemName [string range $elemName 1 end]
            if {[set paramsStatIndex [lsearch -exact $lineList params:]]!=-1} {
                set lineList [lremove $lineList $paramsStatIndex]
            }
            set i 0
            foreach word $lineList {
                if {[my CheckEqual $word] || [my CheckBracedWithEqual $word]} {
                    set paramsStartIndex $i
                    break
                }
                incr i
            }
            if {![info exists paramsStartIndex]} {
                set paramsStartIndex [llength $lineList]
            }
            set subName [@ $lineList 1]
            set pinList [lrange $lineList 2 [= {$paramsStartIndex-1}]]
            set params [my ParseParams $lineList $paramsStartIndex {} list]
            # create instance of subcircuit
            set subcktClassName [string totitle $subName]
            set definitionsLoc {}
            foreach child $children {
                lappend definitionsLoc [$SubcktsTree get $child definition]
                set objString "\[[string totitle [file tail $child]] new\]"
                lappend definitionsLoc "my add $objString"
            }
            # find lines to add to subcircuit, excluding nested subcircuits lines
            set lines2remove {}
            foreach child $children {
                lappend lines2remove {*}[lseq [= {[$SubcktsTree get $child startLine]-$startLine}]\
                                                 [= {[$SubcktsTree get $child endLine]-$startLine}]]
            }
            set netlist [my BuildNetlist [lremove [lrange $allLines [= {$startLine}] [= {$endLine}]]\
                                                        {*}$lines2remove] true]
            set elements {}
            foreach element $netlist {
                if {$element eq {}} {
                    continue
                }
                if {[regexp {^oo::class\s+(\S+)} $element]} {
                    lappend elements $element
                } else {
                    lappend elements "my add \[$element\]"
                }
            }
            set definition [string map [list @classname@ $subcktClassName\
                                                @pins@ [list $pinList]\
                                                @params@ [list $params]\
                                                @subname@ $subName\
                                                @definitions@ [join $definitionsLoc "\n"]\
                                                @elements@ [join $elements "\n"]]\
                                    $SubcircuitTemplate]
            ##nagelfar ignore
            $SubcktsTree append $subcktPath definition $definition
            return
        }
        method buildTopNetlist {args} {
            # Builds top netlist corresponding to parsed netlist file.
            # For unknowns to SpiceGenTcl models the new model class is created during the parsing and evaluated in
            # a caller context. For each subcircuit (and nested subcircuits) the corresponding class is created
            # and evaluated in a caller context.
            # Returns: [::SpiceGenTcl::Netlist] object with attached elements succesfully parsed in input netlist file.
            argparse {
                -noeval
            }
            if {![info exists FileData]} {
                error "Parser object '[my configure -parsername]' doesn't have prepared data"
            }
            set allLines $FileData
            set topNetlist [my configure -topnetlist]
            my GetSubcircuitLines
            # parse found subcircuits definitions first
            if {[info exists SubcktsTree]} {
                set lines2remove {}
                $SubcktsTree walk / -order post -type bfs node {
                    if {$node eq {/}} {
                        continue
                    }
                    my BuildSubcktFromDef $node
                    if {[$SubcktsTree parent $node] eq {/}} {
                        set definition [$SubcktsTree get $node definition]
                        lappend definitions $definition
                        if {![info exists noeval]} {
                            uplevel 1 $definition
                        }
                        set definition [list [string totitle [file tail $node]] new]
                        lappend definitions $definition
                        if {![info exists noeval]} {
                            $topNetlist add [eval {*}$definition]
                        }
                    }
                    set startLine [$SubcktsTree get $node startLine]
                    set endLine [$SubcktsTree get $node endLine]
                    set children [$SubcktsTree children $node]
                    lappend lines2remove {*}[lseq $startLine $endLine]
                }
                set allLines [lremove $allLines {*}$lines2remove]
            }
            set topDefinitions [my BuildNetlist $allLines]
            lappend definitions {*}$topDefinitions
            if {![info exists noeval]} {
                foreach element $topDefinitions {
                    # check the netlist string for presence of class definition
                    if {$element eq {}} {
                        continue
                    }
                    if {[regexp {^oo::class\s+(\S+)} $element]} {
                        uplevel 1 $element
                    } else {
                        $topNetlist add [eval $element]
                    }
                }
            }
            if {[info exists noeval]} {
                return $definitions
            } else {
                return $topNetlist
            }
        }
        method BuildNetlist {lines {subckt false}} {
            # Builds netlist from passed lines
            #   lines - list of lines to parse
            # Returns: code string for objects creation
            set elems [dkeys $ElemsMethods]
            set dots [dkeys $DotsMethods]
            if {$subckt} {
                set start 1
                set end [= {[llength $lines]-1}]
            } else {
                set start 0
                set end [llength $lines]
            }
            set netlist {}
            for {set i $start} {$i<$end} {incr i} {
                set line [@ $lines $i]
                set lineList [split $line]
                set firstWord [@ $lineList 0]
                set firstChar [string index $firstWord 0]
                ##nagelfar ignore
                set restChars [string range $firstWord 1 end]
                if {$firstChar eq {.}} {
                    set restChars [string tolower $restChars]
                    if {$restChars in $dots} {
                        if {$restChars eq {model}} {
                            ##nagelfar ignore Non static subcommand
                            set modelCommands [my [dict get $DotsMethods $restChars] $line]
                            if {[llength $modelCommands]==2} {
                                lappend netlist [@ $modelCommands 0]
                                lappend netlist [@ $modelCommands 1]
                            } else {
                                ##nagelfar ignore Non static subcommand
                                lappend netlist [my [dict get $DotsMethods $restChars] $line]
                            }
                        } else {
                            ##nagelfar ignore Non static subcommand
                            lappend netlist [my [dict get $DotsMethods $restChars] $line]
                        }
                    } else {
                        puts "Line '$lineList' contains unsupported dot statement '$firstWord', skip that line"
                        continue
                    }
                } elseif {[string match {[a-z]} $firstChar]} {
                    if {$firstChar in $elems} {
                        ##nagelfar ignore Non static subcommand
                        lappend netlist [my [dict get $ElemsMethods $firstChar] $line]
                    } else {
                        puts "Line '$lineList' contains unsupported element '$firstWord', skip that line"
                        continue
                    }
                } else {
                    puts "Line '$lineList' starts with illegal character '$firstChar', skip that line"
                    continue
                }
            }
            return $netlist
        }
        method ParseParams {list start {exclude {}} {format arg}} {
            # Parses parameters from the list starts from `start` that is in form `name=value`, or `name={value}`.
            #   list - input list
            #   start - start index
            #   exclude - list of parameters names that should be omitted from output
            #   format - select format of output list, arg: `{-name1 value1 -name2 value2 ...}`, list:
            #    `{{name1 value1 ?qual?} {name2 value2 ?qual?} ...}`
            # Returns: formatted list of parameters
            set results {}
            foreach elem [lrange $list $start end] {
                if {[my CheckEqual $elem]} {
                    lassign [my ParseWithEqual $elem] name value
                    if {$format eq {arg}} {
                        set nameValue [list -$name $value]
                    } else {
                        set nameValue [list $name $value]
                    }
                } elseif {[my CheckBracedWithEqual $elem]} {
                    lassign [my ParseBracedWithEqual $elem] name value
                    if {$format eq {arg}} {
                        set nameValue [list -$name [list $value -eq]]
                    } else {
                        set nameValue [list $name $value -eq]
                    }
                } else {
                    return -code error "Parameter '${elem}' parsing failed"
                }
                if {$format eq {arg}} {
                    if {$name ni [lmap nameExc $exclude {subst "$nameExc"}]} {
                        if {$value eq {}} {
                            return -code error "Parameter '${elem}' parsing failed: value is empty"
                        }
                        lappend results {*}$nameValue
                    }
                } elseif {$format eq {list}} {
                    if {$name ni [lmap nameExc $exclude {subst "$nameExc"}]} {
                        if {$value eq {}} {
                            return -code error "Parameter '${elem}' parsing failed: value is empty"
                        }
                        lappend results $nameValue
                    }
                }
            }
            return $results
        }
        method ParseMixedParams {list start {exclude {}} {format arg}} {
            # Parses parameters from the list starts from `start` that is in form `name=value`, `name={value}` or `name`.
            #   list - input list
            #   start - start index
            #   exclude - list of parameters names that should be omitted from output
            #   format - select format of output list, arg: `{-name1 value1 -name2 value2 ...}`, list:
            #    `{{name1 value1 ?qual?} {name2 value2 ?qual?} ...}`
            # Returns: formatted list of parameters
            set results {}
            foreach elem [lrange $list $start end] {
                set switch false
                if {[my CheckEqual $elem]} {
                    lassign [my ParseWithEqual $elem] name value
                    if {$format eq {arg}} {
                        set nameValue [list -$name $value]
                    } else {
                        set nameValue [list $name $value]
                    }
                } elseif {[my CheckBracedWithEqual $elem]} {
                    lassign [my ParseBracedWithEqual $elem] name value
                    if {$format eq {arg}} {
                        set nameValue [list -$name [list $value -eq]]
                    } else {
                        set nameValue [list $name $value -eq]
                    }
                } elseif {[regexp {^[a-zA-Z0-9]+$} $elem]} {
                    set name $elem
                    set value {}
                    if {$format eq {arg}} {
                        set nameValue -$name
                    } else {
                        set nameValue [list $name -sw]
                    }
                    set switch true
                } else {
                    return -code error "Parameter '${elem}' parsing failed"
                }
                if {$format eq {arg}} {
                    if {$name ni [lmap nameExc $exclude {subst "-$nameExc"}]} {
                        if {$value eq {} && !$switch} {
                            return -code error "Parameter '${elem}' parsing failed: value is empty"
                        }
                        lappend results {*}$nameValue
                    }
                } else {
                    if {$name ni [lmap nameExc $exclude {subst "$nameExc"}]} {
                        if {$value eq {} && !$switch} {
                            return -code error "Parameter '${elem}' parsing failed: value is empty"
                        }
                        lappend results $nameValue
                    }
                }
            }
            return $results
        }
        method ParsePosParams {list names} {
            # Parses parameters from the list starts from `start` that is in form `value` or `{value}`.
            #   list - input list of parameters in order of elements in `names` list
            #   names - names of parameters
            # Returns: list of the form `{-name1 value1 -name2 value2 ...}`
            set results {}
            if {[llength $list]!=[llength $names]} {
                if {[llength $list]>[llength $names]} {
                    set upperBound [llength $names]
                } else {
                    set upperBound [llength $list]
                }
            } else {
                set upperBound [llength $list]
            }
            for {set i 0} {$i<$upperBound} {incr i} {
                set elem [@ $list $i]
                set name [@ $names $i]
                if {[my CheckBraced $elem]} {
                    set value [list [my Unbrace $elem] -eq]
                    set name -$name
                } else {
                    set name -$name
                    set value $elem
                }
                lappend results $name $value
            }
            return $results
        }
        method CheckBraced {string} {
            # Checks if string is braced, string inside braces must not contain `{`, `}` and `=` symbols and be empty
            #   string - input string
            return [regexp {^\{([^={}]+)\}$} $string]
        }
        method Unbrace {string} {
            # Unbraces input string, `{value}` to `value`, value inside braces must not contain `{`, `}` and `=` symbols,
            # and be empty
            #   string - input braced string
            # Returns: string without braces
            if {[my CheckBraced $string]} {
                return [@ [regexp -inline {^\{([^={}]+)\}$} $string] 1]
            } else {
                return -code error "String '${string}' isn't of form {string}, string must not contain '{' and '}'\
                        symbols"
            }
        }
        method CheckQuoted {string} {
            # Checks if string is single quoted, string inside braces must not contain `'`, `'` and `=` symbols and be empty
            #   string - input string
            return [regexp {^\'([^='']+)\'$} $string]
        }
        method Unquote {string} {
            # Unquotes input string, `'value'` to `value`, value inside braces must not contain `'`, `'` and `=` symbols,
            # and be empty
            #   string - input braced string
            # Returns: string without braces,
            if {[my CheckQuoted $string]} {
                return [@ [regexp -inline {^\'([^='']+)\'$} $string] 1]
            } else {
                return -code error "String '${string}' isn't of form 'string', string must not contain ''' and '''\
                        symbols"
            }
        }
        method CheckBracedWithEqual {string} {
            # Checks if string has form `name={value}`, value must not contain `{`, `}` and `=` symbols and be empty,
            # names can containonly alphanumeric characters and `_` symbol
            #   string - input string
            return [regexp {^([a-zA-Z_][a-zA-Z0-9_()]*)=\{([^={}]+)\}$} $string]
        }
        method ParseBracedWithEqual {string} {
            # Parse input string in form `name={value}` to list {name value}, value must not contain `{`, `}` and `=`
            # symbols and be empty, names can contain only alphanumeric characters and `_` symbol
            #   string - input string
            # Returns: list in form {name value}
            if {[my CheckBracedWithEqual $string]} {
                regexp {^([a-zA-Z_][a-zA-Z0-9_()]*)=\{([^={}]+)\}$} $string match name value
                return [list $name $value]
            } else {
                return -code error "String '${string}' isn't of form 'name={value}', value must not contain '{' or '}'\
                        symbols, name must contain only alphanumeric characters and '_' symbol"
            }
        }
        method CheckEqual {string} {
            # Checks if string has form `name=value`, value must not contain `{`, `}` and `=` symbols and be empty,
            # names can contain only alphanumeric characters and `_` symbol
            #   string - input string
            return [regexp {^([a-zA-Z_][a-zA-Z0-9_()]*)=([^={}]+)$} $string]
        }
        method ParseWithEqual {string} {
            # Parse input string in form `name=value` to list `{name value}`.
            #   string - input string
            # Returns: list in form {name value}
            if {[my CheckEqual $string]} {
                regexp {^([a-zA-Z_][a-zA-Z0-9_()]*)=([^={}]+)$} $string match name value
                return [list $name $value]
            } else {
                return -code error "String '${string}' isn't of form 'name=value', value must not contain '{' or '}'\
                        symbols, name must contain only alphanumeric characters and '_' symbol"
            }
        }
    }
}
