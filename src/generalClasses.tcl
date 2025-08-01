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
            EmptyTrace RawFile Ic Nodeset ParameterNode ParameterNodeEquation Global Parser ParameterVector Save\
            Function
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
    proc importLtspice {} {
        # Imports all ::SpiceGenTcl::Ltspice commands to caller namespace
        uplevel 1 {foreach nameSpc [namespace children ::SpiceGenTcl::Ltspice] {
            namespace import ${nameSpc}::*
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
            error {Not implemented}
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
                if {([llength $value]>1) && ([@ $value 0] eq {-eq})} {
                    lappend paramsLoc [list -poseq $paramName [@ $value 1]]
                } else {
                    lappend paramsLoc [list -pos $paramName $value]
                }
            }
            return
        }
        method ParamsProcessM {paramsOrder arguments params} {
            upvar $params paramsLoc
            foreach param $paramsOrder {
                if {[dexist $arguments $param]} {
                    dict append argsOrdered $param [dget $arguments $param]
                }
            }
            set paramsLoc [dvalues $argsOrdered]
            return
        }
        method NameProcess {arguments object} {
            upvar name name
            ##nagelfar ignore #2 {Found constant "name"}
            if {[dexist $arguments name]} {
                set name [dget $arguments name]
            } else {
                set name $object
            }
        }
        method BuildArgStr {paramsNames} {
            # Builds argument list for argparse.
            #  paramsNames - list of parameter names
            # Returns: string in form `-paramName= ...`, or `{-paramName= -forbid {alias0 alias1 ...}}`
            foreach paramName $paramsNames {
                if {[llength $paramName]>1} {
                    lappend paramDefList -[join $paramName |]=
                } else {
                    lappend paramDefList -${paramName}=
                }
            }
            set paramDefStr [join $paramDefList \n]
            return $paramDefStr
        }
        method BuildSwArgStr {paramsNames} {
            # Builds argument list for argparse that doesn't need an argument value.
            #  paramsNames - list of parameter names
            # Returns: string in form *-paramName ...*
            foreach paramName $paramsNames {
                lappend paramDefList -${paramName}
            }
            set paramDefStr [join $paramDefList \n]
            return $paramDefStr
        }
        method ArgsPreprocess {switchesNames paramsNames suppHelpElems args} {
            # Calls argparse and constructs list for passing to Device constructor.
            #  switchesNames - list of switches names, define alias for switch name by
            #  using two element list {switchName aliasName}
            #  args - argument list with key names and it's values
            #  paramsNames - list of parameters in order it should be parsed by argparse
            # Returns: list of parameters formatted for Device/Model constructor
            foreach switchName $switchesNames {
                if {[llength $switchName]>1} {
                    if {[@ $switchName 0] ni $suppHelpElems} {
                        lappend paramDefList -[join $switchName |]=
                    } else {
                        lappend paramDefList  "\{-[join $switchName |]= -hsuppress\}"
                    }
                } else {
                    if {$switchName ni $suppHelpElems} {
                        lappend paramDefList -${switchName}=
                    } else {
                        lappend paramDefList "\{-${switchName}= -hsuppress\}"
                    }
                }
            }
            if {$paramsNames ne {}} {
                foreach paramName $paramsNames {
                    if {$paramName ni $suppHelpElems} {
                        lappend paramDefList $paramName
                    } else {
                        lappend paramDefList "\{$paramName -hsuppress\}"
                    }
                }
            }
            set paramDefStr [join $paramDefList \n]
            set arguments [argparse -helplevel 3 -inline -help {} -pfirst "
                $paramDefStr
            " $args]
            set switches {}
            set params {}
            dict for {name value} $arguments {
                if {$name ni $paramsNames} {
                    if {[@ $value 0] eq {-eq}} {
                        lappend switches [list -eq $name [@ $value 1]]
                    } else {
                        lappend switches [list $name $value]
                    }
                }
            }
            foreach param $paramsNames {
                if {[dexist $arguments $param]} {
                    dict append argsOrdered $param [dget $arguments $param]
                }
            }
            return [list {*}[dvalues $argsOrdered] $switches]
        }
        method DuplListCheck {list} {
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
        method DuplListCheckRet {list} {
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
        method FormPinNodeList {nodes pins} {
            return [lmap pin $pins {list $pin [dget $nodes $pin]}]
        }
    }

###  Pin class definition
    ##nagelfar subcmd+ _obj,Pin configure
    oo::configurable create Pin {
        superclass SPICEElement
        # name of the node connected to pin
        property node -set {
            if {![regexp {^(?![0-9]+[a-zA-Z])[^= %\(\),\[\]<>~]*$} $value]} {
                return -code error "Node name '$value' is not a valid name"
            }
            set node [string tolower $value]
        }
        property name -set {
            if {$value eq {}} {
                return -code error {Pin must have a name, empty string was provided}
            } elseif {![regexp {^(?![0-9]+[a-zA-Z])[^= %\(\),\[\]<>~]*$} $value]} {
                return -code error "Pin name '$value' is not a valid name"
            }
            set name [string tolower $value]
        } -get {
            return $name
        }
        variable name node
        constructor {args} {
            # Creates object of class `Pin` with name and connected node
            #  name - name of the pin
            #  node - name of the node that connected to pin
            # Class models electrical pin of device/subcircuit,
            # it has name and name of the node connected to it.
            # It has general interface method `genSPICEString` that returns
            # name of the node connected to it, this method must be called only
            # in method with the same name in other classes. We can check if pin is
            # floating by checking the name of connected node in method `checkFloating` -
            # if is contains empty string it is floating.
            # Floating pin can't be netlisted, so it throws error when try to
            # do so. Set pin name empty by special method `unsetNodeName`.
            # Synopsis: name node
            set arguments [argparse -inline -help {Creates object of class 'Pin' with name and connected node} {
                {name -help {Name of the pin}}
                {node -help {Name of the node that connected to pin}}
            }]
            dict for {elName elValue} $arguments {
                my configure -$elName $elValue
            }
        }
        method unsetNodeName {args} {
            # Makes pin floating by setting name of the node to empty string.
            argparse -help {Makes pin floating by setting name of the node to empty string} {}
            my configure -node {}
            return
        }
        method checkFloating {args} {
            # Determines if pin is connected to the node.
            # Returns: `true` if connected and `false` if not
            argparse -help {Determines if pin is connected to the node. Returns: 'true' if connected and 'false' if\
                                    not} {}
            if {[my configure -node] eq {}} {
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
            return [my configure -node]
        }
    }

###  ParameterSwitch class definition
    ##nagelfar subcmd+ _obj,ParameterSwitch configure
    oo::configurable create ParameterSwitch {
        superclass SPICEElement
        property name -set {
            if {$value eq {}} {
                return -code error {Parameter must have a name, empty string was provided}
            } elseif {[regexp {[^A-Za-z0-9_]+} $value]} {
                return -code error "Parameter name '$value' is not a valid name"
            } elseif {[regexp {^[A-Za-z][A-Za-z0-9_]*} $value]} {
                set name [string tolower $value]
            } else {
                return -code error "Parameter name '$value' is not a valid name"
            }
        }
        property value
        variable name value
        constructor {args} {
            # Creates object of class `ParameterSwitch` with parameter name.
            #  name - name of the parameter
            # Class models base parameter acting like a switch -
            # its presence gives us information that something it controls is on.
            # This parameter doesn't have a value, and it is the most basic class
            # in Parameter class family.
            set arguments [argparse -inline -help {Creates object of class 'ParameterSwitch' with parameter name} {
                {name -help {Name of the parameter}}
            }]
            my configure -name [dget $arguments name] -value {}
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
        constructor {args} {
            # Creates object of class `Parameter` with parameter name and value.
            #  name - name of the parameter
            #  value - value of the parameter
            # Class models parameter that has a name and a value - the most
            # common type of parameters in SPICE netlist. Its representation in netlist is
            # 'name=value', and can be called "keyword parameter".
            set arguments [argparse -inline -help {Creates object of class 'Parameter' with parameter name and value} {
                {name -help {Name of the parameter}}
                {value -help {Value of the parameter}}
            }]
            dict for {elName elValue} $arguments {
                my configure -$elName $elValue
            }
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
                return -code error {ParameterNode must have a name, empty string was provided}
            } elseif {[regexp {[^A-Za-z0-9_()]+} $value]} {
                return -code error "Parameter name '$value' is not a valid name"
            } elseif {[regexp {^[A-Za-z][A-Za-z0-9_()]*} $value]} {
                set name [string tolower $value]
            } else {
                return -code error "Parameter name '$value' is not a valid name"
            }
        }
        variable name
        constructor {args} {
            # Creates object of class `ParameterNode` with parameter name and value.
            #  name - name of the parameter
            #  value - value of the parameter
            set arguments [argparse -inline -help {Creates object of class 'ParameterNode' with parameter name and\
                                                           value} {
                {name -help {Name of the parameter}}
                {value -help {Value of the parameter}}
            }]
            dict for {elName elValue} $arguments {
                my configure -$elName $elValue
            }
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
        constructor {args} {
            # Creates object of class `ParameterNodeEquation` with parameter name and value.
            #  name - name of the parameter
            #  value - value of the parameter
            set arguments [argparse -inline -help {Creates object of class 'ParameterNodeEquation' with parameter name\
                                                           and value} {
                {name -help {Name of the parameter}}
                {value -help {Value of the parameter}}
            }]
            dict for {elName elValue} $arguments {
                my configure -$elName $elValue
            }
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
                return -code error {ParameterVector must have a name, empty string was provided}
            } elseif {[regexp -expanded {^([a-zA-Z0-9]+|[vi]\([a-zA-Z0-9]+\)|[a-zA-Z0-9]+\#[a-zA-Z0-9]+|@[a-zA-Z0-9]+
                                           \[[a-zA-Z0-9]+\])$} $value]} {
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
        constructor {args} {
            # Creates object of class `ParameterNoCheck` with parameter name and value.
            #  name - name of the parameter
            #  value - value of the parameter
            # Class models parameter the same as described by `Parameter` but without check for value form.
            set arguments [argparse -inline -help {Creates object of class 'ParameterNoCheck' with parameter name and\
                                                           value} {
                {name -help {Name of the parameter}}
                {value -help {Value of the parameter}}
            }]
            next {*}[dvalues $arguments]
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
        constructor {args} {
            # Creates object of class `ParameterPositional` with parameter name and value.
            #  name - name of parameter
            #  value - value of parameter
            # Class models parameter that has a name and a value, but it differs from
            # parent class in the sense of netlist representation: this parameter represents only
            # by the value in the netlist. It's meaning for holding element is taken from
            # it's position in the element's definition, for example, R1 np nm 100 tc1=1 tc2=0 - resistor
            # with positional parameter R=100, you can't put it after parameters tc1 and tc2, it must be placed
            # right after the pins definition.
            set arguments [argparse -inline -help {Creates object of class 'ParameterPositional' with parameter name\
                                                           and value} {
                {name -help {Name of the parameter}}
                {value -help {Value of the parameter}}
            }]
            next {*}[dvalues $arguments]
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
        constructor {args} {
            # Creates object of class `ParameterPositionalNoCheck`.
            #  name - name of parameter
            #  value - value of parameter
            # Class models parameter the same as described by `ParameterPositional` but without check for value form.
            set arguments [argparse -inline -help {Creates object of class 'ParameterPositionalNoCheck' with parameter\
                                                           name and value} {
                {name -help {Name of the parameter}}
                {value -help {Value of the parameter}}
            }]
            next {*}[dvalues $arguments]
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
        constructor {args} {
            # Creates object of class `ParameterDefault` with parameter name, value and default value.
            #  name - name of the parameter
            #  value - value of the parameter
            #  defValue - default value of the parameter
            # Class models parameter that has a name and a value, but it differs from
            # parent class in sense of having default value, so it has special ability to reset its value to default
            # value by special method `resetValue`.
            set arguments [argparse -inline -help {Creates object of class 'ParameterDefault' with parameter name and\
                                                           value} {
                {name -help {Name of the parameter}}
                {value -help {Value of the parameter}}
                {defValue -help {Default of the parameter}}
            }]
            my configure -defvalue [dget $arguments defValue]
            next [dget $arguments name] [dget $arguments value]
        }

        method resetValue {args} {
            # Resets value of the parameter to it's default value.
            argparse -help {Resets value of the parameter to it's default value} {}
            my configure -value [my configure -defvalue]
            return
        }
    }

###  ParameterEquation class definition
    oo::configurable create ParameterEquation {
        superclass Parameter
        property value
        constructor {args} {
            # Creates object of class `ParameterEquation` with parameter name and value as an equation.
            #  name - name of the parameter
            #  value - value of the parameter
            # Class models parameter that has representation as an equation.
            # Example: R={R1+R2}
            set arguments [argparse -inline -help {Creates object of class 'ParameterEquation' with parameter name and\
                                                           value as an equation} {
                {name -help {Name of the parameter}}
                {value -help {Value of the parameter}}
            }]
            next {*}[dvalues $arguments]
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
        constructor {args} {
            # Creates object of class `ParameterPositionalEquation` with parameter name and value as an equation in
            # positional form.
            #  name - name of the parameter
            #  value - value of the parameter
            # Class models parameter that has representation as an equation, but in form of
            # positional parameter. Example: {R1+R2}
            set arguments [argparse -inline -help {Creates object of class 'ParameterPositionalEquation' with\
                                                           parameter name and value as anequation} {
                {name -help {Name of the parameter}}
                {value -help {Value of the parameter}}
            }]
            next {*}[dvalues $arguments]
        }
        method genSPICEString {} {
            # Creates string for SPICE netlist.
            # Returns: SPICE netlist's string
            return \{[my configure -value]\}
        }
    }

###  Device class definition
    ##nagelfar subcmd+ _obj,Device actOnPin actOnParam configure
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
        variable name Params Pins
        constructor {args} {
            # Creates object of class `Device`.
            #  name - name of the device
            #  pins - list of pins in the order they appear in SPICE device's definition together
            #   with connected node in form: `{{Name0 NodeName} {Name1 NodeName} {Name2 NodeName} ...}`
            #   Nodes string values could be empty.
            #  params - list of instance parameters in form `{{Name Value ?-sw|pos|eq|poseq|posnocheck|nocheck?} 
            #   {Name Value ?-sw|pos|eq|poseq|posnocheck|nocheck?} {Name Value ?-sw|pos|eq|poseq|posnocheck|nocheck?}
            #    ...}`
            #   Parameter list can be empty if device doesn't have instance parameters.
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
            set arguments [argparse -inline -help {Creates object of class 'Device'} {
                {name -help {Name of the device}}
                {pins -help {List of pins in the order they appear in SPICE device's definition together with connected\
                                     node in form: '{{Name0 NodeName} {Name1 NodeName} {Name2 NodeName} ...}'. Nodes\
                                     string values could be empty. Nodes list can be empty if device doesn't have pins}\
                         -type list}
                {params -help {List of instance parameters in form\
                                       '{{Name0 Value0 ?-sw|pos|eq|poseq|posnocheck|nocheck?}\
                                                 {Name1 Value1 ?-sw|pos|eq|poseq|posnocheck|nocheck?}\
                                                 {Name2 Value2 ?-sw|pos|eq|poseq|posnocheck|nocheck?} ...}'.\
                                       Parameter list can be empty if device doesn't have instance parameters}\
                         -type list}
            }]
            my configure -name [dget $arguments name]
            # create Pins objects
            foreach pin [dget $arguments pins] {
                my actOnPin -add {*}$pin
            }
            #ruff
            # Each parameter definition could be modified by
            #  optional flags:
            #  -pos - parameter has strict position and only '$Value' is displayed in netlist
            #  -eq - parameter may contain equation in terms of functions and other parsmeters,
            #    printed as '$name={$equation}'
            #  -poseq - combination of both flags, print only '{$equation}'
            #  -posnocheck - positional parameter without check
            #  -nocheck - normal parameter without check
            foreach param [dget $arguments params] {
                my actOnParam -add {*}$param
            }
        }
        destructor {
            # Destroy object of class `Device`, and its parameters and pins objects.
            if {[info exists Params]} {
                foreach param [dict values $Params] {
                    $param destroy
                }
            }
            if {[info exists Pins]} {
                foreach pin [dict values $Pins] {
                    $pin destroy
                }
            }
        }
        method actOnPin {args} {
            # Acts on `Pin` object with selected action
            #  -add - add new pin to the device, requires pin and node arguments
            #  -get - get node name connected to pin, requires pin argument
            #  -set - set node name connected to pin, requires pin and node arguments
            #  -all - option for getting the dictionary that contains pin name as keys and connected node name as the 
            #    values, requires -get
            #  pin - name of the pin
            #  node - name of the node connected to pin
            # Synopsis: -add pin node
            # Synopsis: -set pin node
            # Synopsis: -get pin
            # Synopsis: -get -all
             argparse -help {Applied selected actions on pin of the device} {
                {-add -key action -value add -require {pin node} -help {Add new pin to the device}}
                {-get -key action -value get -help {Get node name connected to pin}}
                {-set -key action -value set -require {pin node} -help {Set node name connected to pin}}
                {-all -require get -forbid {pin node} -help {Option for getting the dictionary that contains pin name\
                                                                     as keys and connected node name as the values}}
                {pin -optional -help {Name of the pin}}
                {node -optional -help {Name of the node connected to pin}}
            }
            switch $action {
                add {
                    set pin [string tolower $pin]
                    set node [string tolower $node]
                    if {[info exists Pins]} {
                        set pins [dkeys $Pins]
                    }
                    lappend pins $pin
                    if {[my DuplListCheck $pins]} {
                        return -code error "Pins list '$pins' has already contains pin with name '$pin'"
                    }
                    dappend Pins $pin [::SpiceGenTcl::Pin new $pin $node]
                }
                get {
                    if {![info exists Pins]} {
                        return
                    }
                    if {[info exists all]} {
                        return [dict map {pinName pin} $Pins {$pin configure -node}]
                    } elseif {[info exists pin]} {
                        set pin [string tolower $pin]
                        if {[dexist $Pins $pin]} {
                            return [dget $Pins $pin]
                        } else {
                            return -code error "Device '$name' doesn't have pin with name '$pin'"
                        }
                    } else {
                        return -code error "'-get' action requires 'pin' parameter or '-all' option"
                    }
                }
                set {
                    set pin [string tolower $pin]
                    set node [string tolower $node]
                    if {![info exists Pins]} {
                        return -code error "Device '$name' doesn't have pins"
                    }
                    if {[dexist $Pins $pin]} {
                        [dget $Pins $pin] configure -node $node
                    } else {
                        return -code error "Pin with name '$pin' was not found in device's '$name' list of pins\
                                '[dkeys $Pins]'"
                    }
                }
            }
            return
        }
        method actOnParam {args} {
            # Acts on `Parameter` object with selected action
            #  -add - add new parameter to the device, requires pname argument
            #  -get - get parameter value, requires pname argument
            #  -set - set (or change) value of particular parameters, requires pname and value arguments
            #  -delete - delete existing parameter
            #  -all - option for getting the dictionary that contains parameters names as keys and parameters values\
            #    as the dictionary values, requires -get
            #  -pos - parameter has strict position and only '$Value' is displayed in netlist, requires -add
            #  -eq - Parameter may contain equation in terms of functions and other parameters, printed as 
            #    '$name={$equation}', requires -add
            #  -poseq - combination of both flags, print only, requires -add
            #  -posnocheck - positional parameter without check, requires -add
            #  -nocheck - normal parameter without check, requires -add
            #  -sw - switch parameter, requires -add
            #  -node - node parameter, requires -add
            #  -nodeeq - node parameter equation, requires -add
            #  pname - name of parameter
            #  value - value of parameter
            #  arguments - optional pairs of name-value for -set action, requires -set
            # Synopsis: -add ?-pos|eq|poseq|posnocheck|nocheck|sw|node|nodeeq? name value
            # Synopsis: -set name value ?name value ...?
            # Synopsis: -get name
            # Synopsis: -get -all
            # Synopsis: -delete name
            argparse -help {Applied selected actions on parameters of the device} {
                # {Actions selectors}
                {-add -key action -value add -require pname -help {Add new parameter to device}}
                {-get -key action -value get -help {Get parameter value}}
                {-set -key action -value set -require {pname value} -help {Sets (or change) value of particular\
                                                                                   parameters}}
                {-delete -key action -value delete -require pname -help {Delete existing parameter}}
                {-all -require get -forbid {pname value} -help {Option for getting the dictionary that contains\
                                                                        parameters names as keys and parameters values\
                                                                        as the dictionary values}}
                # {Param qualificators}
                {-pos -key paramQual -value pos -require add -help {Parameter has strict position and only '$Value' is\
                                                                            displayed in netlist}}
                {-eq -key paramQual -value eq -require add -help {Parameter may contain equation in terms of functions\
                                                                          and other parameters, printed as\
                                                                          '$name={$equation}'}}
                {-poseq -key paramQual -value poseq -require add -help {Combination of both flags, print only\
                                                                                '{$equation}'}}
                {-posnocheck -key paramQual -value posnocheck -require add -help {Positional parameter without check}}
                {-nocheck -key paramQual -value nocheck -default {} -require add -help {Normal parameter without check}}
                {-sw -key paramQual -value sw -require add -help {Switch parameter}}
                {-node -key paramQual -value node -require add -help {Node parameter}}
                {-nodeeq -key paramQual -value nodeeq -require add -help {Node parameter equation}}
                # {Actual name(s) and value(s) of Param}
                {pname -optional -help {Name of parameter}}
                {value -optional -help {Value of parameter}}
                {arguments -catchall -require set -help {Optional pairs of name-value for -set action}}
            }
            switch $action {
                add {
                    set pname [string tolower $pname]
                    if {[info exists Params]} {
                        set params [dict keys $Params]
                    }
                    lappend params $pname
                    if {[my DuplListCheck $params]} {
                        return -code error "Parameters list '$params' has already contains parameter with name '$pname'"
                    }
                    switch $paramQual {
                        sw {
                            dict append Params $pname [::SpiceGenTcl::ParameterSwitch new $pname]
                        }
                        pos {
                            dict append Params $pname [::SpiceGenTcl::ParameterPositional new $pname $value]
                        }
                        eq {
                            dict append Params $pname [::SpiceGenTcl::ParameterEquation new $pname $value]
                        }
                        poseq {
                            dict append Params $pname [::SpiceGenTcl::ParameterPositionalEquation new $pname $value]
                        }
                        posnocheck {
                            dict append Params $pname [::SpiceGenTcl::ParameterPositionalNoCheck new $pname $value]
                        }
                        nocheck {
                            dict append Params $pname [::SpiceGenTcl::ParameterNoCheck new $pname $value]
                        }
                        node {
                            dict append Params $pname [::SpiceGenTcl::ParameterNode new $pname $value]
                        }
                        nodeeq {
                            dict append Params $pname [::SpiceGenTcl::ParameterNodeEquation new $pname $value]
                        }
                        default {
                            dict append Params $pname [::SpiceGenTcl::Parameter new $pname $value]
                        }
                    }
                }
                get {
                    if {![info exists Params]} {
                        return
                    }
                    if {[info exists all]} {
                        return [dict map {paramName param} $Params {$param configure -value}]
                    } elseif {[info exists pname]} {
                        set pname [string tolower $pname]
                        if {[dexist $Params $pname]} {
                            return [dget $Params $pname]
                        } else {
                            return -code error "Device '$name' doesn't have parameter with name '$pname'"
                        }
                    } else {
                        return -code error "'-get' action requires 'pname' parameter or '-all' option"
                    }
                }
                set {
                    set arguments [list $pname $value {*}$arguments]
                    if {[llength $arguments]%2!=0} {
                        return -code error "Number of arguments to method '[dict get [info frame 0] method]' with\
                                '-set' switch must be even"
                    }
                    for {set i 0} {$i<[llength $arguments]} {incr i 2} {
                        set paramName [string tolower [@ $arguments $i]]
                        set paramValue [@ $arguments [= {$i+1}]]
                        if {[catch {dget $Params $paramName}]} {
                            return -code error "Parameter with name '$paramName' was not found in element's\
                                    '$name' list of parameters '[dkeys $Params]'"
                        } else {
                            set param [dget $Params $paramName]
                        }
                        $param configure -value $paramValue
                    }
                }
                delete {
                    set pname [string tolower $pname]
                    if {[catch {dget $Params $pname}]} {
                        return -code error "Parameter with name '$pname' was not found in device's '$name'\
                                list of parameters '[dkeys $Params]'"
                    } else {
                        set Params [dict remove $Params $pname]
                    }
                }
            }
            return
        }
        method checkFloatingPins {args} {
            # Check if some pin device doesn't have connected nodes and return list of them.
            # Returns: list of floating pins
            argparse -help {Check if some pin device doesn't have connected nodes and return list of them} {}
            set floatingPins {}
            dict for {pinName pin} $Pins {
                if {[$pin checkFloating]} {
                    lappend floatingPins [$pin configure -name]
                }
            }
            return $floatingPins
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
                return -code error {Model must have a name, empty string was provided}
            } elseif {[regexp {[^A-Za-z0-9_]+} $value]} {
                return -code error "Model name '$value' is not a valid name"
            } else {
                set name [string tolower $value]
            }
        }
        property type -set {
            if {$value eq {}} {
                return -code error {Model must have a type, empty string was provided}
            } elseif {[regexp {[^A-Za-z0-9]+} $value]} {
                return -code error "Model type '$value' is not a valid type"
            } else {
                set type [string tolower $value]
            }
        }
        variable name type Params
        constructor {args} {
            # Creates object of class `Model`.
            #  name - name of the model
            #  type - type of model, for example, diode, npn, etc
            #  instParams - list of instance parameters in form `{{name value ?-pos|eq|poseq?}
            #   {name value ?-pos|eq|poseq?} {name value ?-pos|eq|poseq?} ...}`
            # Class represents model card in SPICE netlist.
            set arguments [argparse -inline -help {Creates object of class 'Model'} -pfirst {
                {name -help {Name of the model}}
                {type -help {Type of model, for example, diode, npn, etc}}
                {params -optional -help {{List of instance parameters in form\
                                                  '{{Name0 Value0 ?-pos|eq|poseq|posnocheck|nocheck?}\
                                                  {Name1 Value1 ?-pos|eq|poseq|posnocheck|nocheck?}\
                                                  {Name2 Value2 ?-pos|eq|poseq|posnocheck|nocheck?} ...}'}} -type list}
            }]
            my configure -name [dget $arguments name] -type [dget $arguments type]
            # create Params objects
            if {[dexist $arguments params]} {
                foreach param [dget $arguments params] {
                    my actOnParam -add {*}$param
                }
            }
        }
        destructor {
            # Destroy object of class `Model`, and its parameters objects.
            if {[info exists Params]} {
                foreach param [dict values $Params] {
                    $param destroy
                }
            }
        }
        method actOnParam {*}[info class definition ::SpiceGenTcl::Device actOnParam]
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
        variable name value
        constructor {args} {
            # Creates object of class `RawString`.
            #  value - value of the raw string
            #  -name - name of the string that could be used to retrieve element from [::SpiceGenTcl::Netlist] object
            #    and its descendants, optional
            # Class represent arbitary string.
            #  It can be used to pass any string directly into netlist,
            #  for example, it can add elements that doesn't have dedicated class.
            # Synopsis: value ?-name value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'RawString'} {
                {value -help {Value of the raw string}}
                {-name= -help {Name of the string that could be used to retrieve element from [::SpiceGenTcl::Netlist]\
                                       and its descendants object}}
            }]
            if {[dexist $arguments name]} {
                my configure -name [dget $arguments name]
            } else {
                my configure -name [self object]
            }
            my configure -value [dget $arguments value]
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
        constructor {args} {
            # Creates object of class `Comment`.
            #  value - value of the comment
            #  -name - name of the string that could be used to retrieve element from [::SpiceGenTcl::Netlist] object
            #    and its descendants, optional
            # Class represent comment string, it can be a multiline comment.
            # Synopsis: value ?-name value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Comment'} {
                {value -help {Value of the comment}}
                {-name= -help {Name of the string that could be used to retrieve element from [::SpiceGenTcl::Netlist]\
                                       object and its descendants}}
            }]
            if {[dexist $arguments name]} {
                my configure -name [dget $arguments name]
            } else {
                my configure -name [self object]
            }
            my configure -value [dget $arguments value]
        }
        method genSPICEString {} {
            # Creates comment string for SPICE netlist.
            # Returns: SPICE netlist's string
            set splitted [split [my configure -value] \n]
            set prepared [join [lmap line $splitted {set result *$line}] \n]
            return $prepared
        }
    }

###  Include class definition
    oo::configurable create Include {
        superclass RawString
        constructor {args} {
            # Creates object of class `Include`.
            #  value - value of the include path
            #  -name - name of the string that could be used to retrieve element from [::SpiceGenTcl::Netlist] object
            #    and its descendants, optional
            # This class represent .include statement.
            # Synopsis: value ?-name value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Include'} {
                {value -help {Value of the include path}}
                {-name= -help {Name of the string that could be used to retrieve element from [::SpiceGenTcl::Netlist]\
                                       object and its descendants}}
            }]
            if {[dexist $arguments name]} {
                my configure -name [dget $arguments name]
            } else {
                my configure -name [self object]
            }
            my configure -value [dget $arguments value]
        }
        method genSPICEString {} {
            # Creates include string for SPICE netlist.
            # Returns: SPICE netlist's string
            return ".include [my configure -value]"
        }
    }

###  Func class definition
    oo::configurable create Function {
        superclass SPICEElement
        property declaration 
        property body
        property name
        variable name declaration body
        constructor {args} {
            # Creates object of class `Function`.
            #  declaration - function declaration
            #  body - body of the function
            #  -name - name of the string that could be used to retrieve element from [::SpiceGenTcl::Netlist] object
            #    and its descendants, optional
            # This class represent .func statement.
            # Synopsis: declaration body ?-name value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Function'} {
                {declaration -help {Function declaration}}
                {body -help {Body of the function}}
                {-name= -help {Name of the string that could be used to retrieve element from [::SpiceGenTcl::Netlist]\
                                       object and its descendants}}
            }]
            if {[dexist $arguments name]} {
                my configure -name [dget $arguments name]
            } else {
                my configure -name [self object]
            }
            my configure -declaration [dget $arguments declaration] -body [dget $arguments body]
        }
        method genSPICEString {} {
            # Creates func string for SPICE netlist.
            # Returns: SPICE netlist's string
            return ".func [my configure -declaration] \{[my configure -body]\}"
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
        constructor {args} {
            # Creates object of class `Library`.
            #  value - value of the include file
            #  libvalue - value of selected library
            #  -name - name of the string that could be used to retrieve element from [::SpiceGenTcl::Netlist] object
            #    and its descendants, optional
            # Class represent .lib statement.
            # Synopsis: value libvalue ?-name value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Library'} {
                {value -help {Value of the include path}}
                {libvalue -help {Value of selected library}}
                {-name= -help {Name of the string that could be used to retrieve element from [::SpiceGenTcl::Netlist]\
                                       object and its descendants}}
            }]
            if {[dexist $arguments name]} {
                my configure -name [dget $arguments name]
            } else {
                my configure -name [self object]
            }
            my configure -value [dget $arguments value] -libvalue [dget $arguments libvalue]
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
        variable name Params
        constructor {args} {
            # Creates object of class `Options`.
            #  params - list of instance parameters in form `{{name value ?-sw?} {name value ?-sw?}
            #   {name value ?-sw?} ...}`
            #  -name - name of the string that could be used to retrieve element from [::SpiceGenTcl::Netlist] object
            #    and its descendants, optional
            # This class represent .options statement.
            # Synopsis: params ?-name value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Options'} {
                {params -help {list of instance parameters in form '{{name value ?-sw?} {name value ?-sw?}\
                                                                             {name value ?-sw?} ...}'}}
                {-name= -help {Name of the string that could be used to retrieve element from [::SpiceGenTcl::Netlist]\
                                       object and its descendants}}
            }]
            if {[dexist $arguments name]} {
                my configure -name [dget $arguments name]
            } else {
                my configure -name [self object]
            }
            foreach param [dget $arguments params] {
                if {[llength $param]<2} {
                    error "Value '$param' is not a valid value"
                } else {
                    my actOnParam -add {*}$param
                }
            }
        }
        destructor {
            # Destroy object of class `Options`, and its parameters objects.
            if {[info exists Params]} {
                foreach param [dict values $Params] {
                    $param destroy
                }
            }
        }
        method actOnParam {*}[info class definition ::SpiceGenTcl::Device actOnParam]
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
        variable name Params
        constructor {args} {
            # Creates object of class `ParamStatement`.
            #  params - list of instance parameters in form `{{name value ?-eq?} {name value ?-eq?} ...}`
            #  -name - name of the library that could be used to retrieve element from [::SpiceGenTcl::Netlist] object
            #    and its descendants, optional
            # Class represent .param statement.
            # Synopsis: params ?-name value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'ParamStatement'} {
                {params -help {list of instance parameters in form '{{name value ?-eq?} {name value ?-eq?} ...}'}\
                         -type list}
                {-name= -help {Name of the string that could be used to retrieve element from [::SpiceGenTcl::Netlist]\
                                       object and its descendants}}
            }]
            if {[dexist $arguments name]} {
                my configure -name [dget $arguments name]
            } else {
                my configure -name [self object]
            }
            foreach param [dget $arguments params] {
                if {[llength $param]<2} {
                    error "Value '$param' is not a valid value"
                } else {
                    my actOnParam -add {*}$param
                }
            }
        }
        destructor {
            # Destroy object of class `ParamStatement`, and its parameters objects.
            if {[info exists Params]} {
                foreach param [dict values $Params] {
                    $param destroy
                }
            }
        }
        method actOnParam {*}[info class definition ::SpiceGenTcl::Device actOnParam]
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
        variable name Vectors
        constructor {args} {
            # Creates object of class `ParamStatement`.
            #  vectors - list of vectors in form `{vec0 vec1 vec2 ...}`
            #  -name - name of the library that could be used to retrieve element from [::SpiceGenTcl::Netlist] object
            #    and its descendants, optional
            # Class represent .save statement.
            # Synopsis: vectors ?-name value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'ParamStatement'} {
                {vectors -help {List of vectors in form '{vec0 vec1 vec2 ...}'} -type list}
                {-name= -help {Name of the string that could be used to retrieve element from [::SpiceGenTcl::Netlist]\
                                       object and its descendants}}
            }]
            if {[dexist $arguments name]} {
                my configure -name [dget $arguments name]
            } else {
                my configure -name [self object]
            }
            foreach vector [dget $arguments vectors] {
                if {[llength $vector]>1} {
                    error "Name '$vector' is not a valid name of the vector"
                } else {
                    my addVector {*}$vector
                }
            }
        }
        destructor {
            # Destroy object of class `Save`, and its vectors objects.
            if {[info exists Vectors]} {
                foreach vector [dict values $Vectors] {
                    $vector destroy
                }
            }
        }
        method getVectors {args} {
            # Gets the dictionary of vector names
            # Returns: vectors dictionary
            argparse -help {Gets the dictionary of vector names. Returns: vectors dictionary} {}
            return $Vectors
        }
        method addVector {args} {
            # Adds new `ParameterVector` object to the dictionary Vectors.
            #  vname - name of vector
            argparse -help {Adds new 'ParameterVector' object to the list 'Vectors'} {
                {vname -help {Name of vector}}
            }
            set vname [string tolower $vname]
            if {[info exists Vectors]} {
                set vectors [dict keys $Vectors]
            }
            lappend vectors $vname
            if {[my DuplListCheck $vectors]} {
                return -code error "Vectors list '$vectors' has already contains vector with name '$vname'"
            }
            dict append Vectors $vname [::SpiceGenTcl::ParameterVector new $vname]
            return
        }
        method deleteVector {args} {
            # Deletes existing `ParameterVector` object from dictionary `Vectors`.
            #  vname - name of parameter that will be deleted
            argparse -help {Deletes existing 'ParameterVector' object from dictionary 'Vectors'} {
                {vname -help {Name of vector}}
            }
            set vname [string tolower $vname]
            if {[catch {dget $Vectors $vname}]} {
                return -code error "Vector with name '$vname' was not found in device's '[my configure -name]'\
                        list of parameters '[dict keys $Vectors]'"
            } else {
                set Vectors [dict remove $Vectors $vname]
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
        variable name Params
        constructor {args} {
            # Creates object of class `Ic`.
            #  params - list of instance parameters in form `{{name value} {name value} {name equation -eq} ...}`
            #  -name - name of the library that could be used to retrieve element from [::SpiceGenTcl::Netlist] object
            #    and its descendants, optional
            # Class represent .ic statement.
            # Synopsis: params ?-name value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Ic'} {
                {params -help {list of instance parameters in form '{{name value ?-eq?} {name value ?-eq?} ...}'}\
                         -type list}
                {-name= -help {Name of the string that could be used to retrieve element from [::SpiceGenTcl::Netlist]\
                                       object and its descendants}}
            }]
            if {[dexist $arguments name]} {
                my configure -name [dget $arguments name]
            } else {
                my configure -name [self object]
            }
            foreach param [dget $arguments params] {
                if {[llength $param]<2} {
                    error "Value '$param' is not a valid value"
                } else {
                    if {[@ $param 0] eq {-eq}} {
                        my actOnParam -add -nodeeq [@ $param 1] [@ $param 2]
                    } else {
                        my actOnParam -add -node {*}$param
                    }
                }
            }
        }
        destructor {
            # Destroy object of class `Ic`, and its parameters objects.
            if {[info exists Params]} {
                foreach param [dict values $Params] {
                    $param destroy
                }
            }
        }
        method actOnParam {*}[info class definition ::SpiceGenTcl::Device actOnParam]
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
        variable name Nets
        constructor {args} {
            # Creates object of class `Global`.
            #  nets - list of nets in form `{net0 net1 ...}`
            #  -name - name of the library that could be used to retrieve element from [::SpiceGenTcl::Netlist] object
            #    and its descendants, optional
            # Class represent .global statement.
            # Synopsis: nets ?-name value?
            set arguments [argparse -inline -pfirst -help {Creates object of class 'Global'} {
                {nets -help {List of nets in form '{net0 net1 ...}'} -type list}
                {-name= -help {Name of the string that could be used to retrieve element from [::SpiceGenTcl::Netlist]\
                                       object and its descendants}}
            }]
            if {[dexist $arguments name]} {
                my configure -name [dget $arguments name]
            } else {
                my configure -name [self object]
            }
            my addNets [dget $arguments nets]
        }
        method addNets {args} {
            argparse -help {Adds nets to the class} {
                {nets -help {List of nets} -type list}
            }
            if {[info exists Nets]} {
                set netsList $Nets
            }
            foreach net $nets {
                if {$net ne {}} {
                    lappend netsList $net
                    if {[my DuplListCheck $netsList]} {
                        error "Net with name '$net' is already attached to the object '[my configure -name]'"
                    }
                } else {
                    return -code error {Net name couldn't be empty}
                }
            }
            set Nets $netsList
            return
        }
        method deleteNet {args} {
            argparse -help {Deletes net from the 'Nets' list} {
                {net -help {Name of the net}}
            }
            set netsList $Nets
            if {[set index [lsearch -exact $netsList $net]] !=-1} {
                set netsList [lremove $netsList $index]
            } else {
                error "Global statement '$name' doesn't have attached net with name '$net'"
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
        constructor {args} {
            # Creates object of class `Temp`.
            #  value - value of the temperature
            #  -eq - optional parameter qualificator
            # This class represent .temp statement with temperature value.
            # Synopsis: value ?-eq?
            set arguments [argparse -inline -help {Creates object of class 'Temp'} {
                {value -help {Value of the temperature}}
                {-eq -help {Optional parameter qualificator}}
            }]
            my configure -name temp
            ##nagelfar variable eq
            if {[dexist $arguments eq]} {
                my AddParam -eq temp [dget $arguments value]
            } else {
                my AddParam temp [dget $arguments value]
            }
        }
        method AddParam {args} {
            # Adds temperature parameter.
            #  pname - name of temperature parameter
            #  value - value of temperature
            #  -eq - optional parameter qualificator
            # Synopsis: pname value ?-eq?
            set arguments [argparse -inline -help {Adds temperature parameter} {
                {pname -help {Name of temperature parameter}}
                {value -help {Value of the temperature}}
                {-eq -help {Optional parameter qualificator}}
            }]
            if {[dict exists $arguments eq]} {
                set [my varname value] [::SpiceGenTcl::ParameterPositionalEquation new [dget $arguments pname]\
                                                [dget $arguments value]]
            } else {
                set [my varname value] [::SpiceGenTcl::ParameterPositional new [dget $arguments pname]\
                                                [dget $arguments value]]
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
            if {[llength $val]>1} {
                lassign $val eq value
                if {$eq eq {-eq}} {
                    my AddParam -eq temp $value
                } elseif {$eq eq {}} {
                    my AddParam temp $value
                } else {
                    return -code error "Wrong value '$eq' of qualifier"
                }
            } else {
                my AddParam temp $val
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
        variable name Elements
        constructor {args} {
            # Creates object of class `Netlist`.
            #  name - name of the netlist
            # Class implements netlist as a collection of SPICE elements. Any element that has SPICEElement
            # as a parent class can be added to Netlist, except Options and Analysis.
            set arguments [argparse -inline -help {Creates object of class 'Netlist'} {
                {name -help {Name of the netlist}}
            }]
            my configure -name [dget $arguments name]
        }
        method add {args} {
            # Adds elements objects to Elements dictionary.
            #  elements - elements objects references
            # Synopsis: element ?element ...?
            argparse -help {Adds elements objects to 'Elements' dictionary} {
                {elements -catchall -help {Elements objects references}}
            }
            foreach element $elements {
                lappend elementsNamesList [string tolower [$element configure -name]]
            }
            if {[info exists Elements]} {
                lappend elementsNamesList {*}[my getAllElemNames]
            }
            set dup [my DuplListCheckRet $elementsNamesList]
            if {$dup ne {}} {
                return -code error "Netlist '[my configure -name]' already contains element with name $dup"
            }
            foreach element $elements {
                set elemName [$element configure -name]
                dict append Elements $elemName $element
            }
            return
        }
        method del {args} {
            # Deletes elements from the netlist by its name.
            #  elementsNames - names of elements to delete
            # Synopsis: elementName ?elementName ...?
            argparse -help {Deletes elements from the netlist by its name} {
                {elementsNames -catchall -help {Elements names}}
            }
            if {![info exists Elements]} {
                return -code error "Netlist '[my configure -name]' doesn't have attached elements"
            }
            foreach elemName $elementsNames {
                set elemName [string tolower $elemName]
                if {[catch {dget $Elements $elemName}]} {
                    return -code error "Element with name '$elemName' was not found in netlist's '[my configure -name]'\
                        list of elements"
                } else {
                    set Elements [dict remove $Elements $elemName]
                }
            }
            return
        }
        method getElement {args} {
            # Gets particular element object reference by its name.
            #  elemName - name of element
            # Synopsis: elemName
            argparse -help {Gets particular element object reference by its name} {
                {elemName -help {Name of element}}
            }
            set elemName [string tolower $elemName]
            if {[catch {dget $Elements $elemName}]} {
                return -code error "Element with name '$elemName' was not found in netlist's '[my configure -name]'\
                        list of elements"
            } else {
                set foundElem [dget $Elements $elemName]
            }
            return $foundElem
        }
        method getAllElemNames {args} {
            # Gets names of all elements in netlist.
            # Returns: list of elements names
            argparse -help {Gets names of all elements in netlist. Returns: list of elements names} {}
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
        # standard output of simulation
        property log
        # results of simulation in form of RawData object
        property data
        # flag that tells about Analysis element presence in Circuit
        variable simulator log data ContainAnalysis Elements
        constructor {args} {
            # Creates object of class `CircuitNetlist`.
            #  name - name of the tol-level circuit
            # Class implements a top level netlist which is run in SPICE. We should add [::SpiceGenTcl::Simulator]
            # object reference to make it able to run simulation.
            # Synopsis: name
            set arguments [argparse -inline -help {Creates object of class 'CircuitNetlist'} {
                {name -help {Name of the tol-level circuit}}
            }]
            next [dget $arguments name]
        }
        method add {args} {
            # Adds elements object to Circuit `Elements` dictionary.
            #  elements - elements objects references
            # Synopsis: element ?element ...?
            argparse -help {Adds elements objects to Circuit 'Elements' dictionary} {
                {elements -catchall -help {Elements objects references}}
            }
            foreach element $elements {
                if {([info object class $element {::SpiceGenTcl::Analysis}]) && ([info exists ContainAnalysis])} {
                    return -code error "Netlist '[my configure -name]' already contains Analysis element"
                } elseif {[info object class $element {::SpiceGenTcl::Analysis}]} {
                    set ContainAnalysis {}
                }
                lappend elementsNamesList [string tolower [$element configure -name]]
            }
            if {[info exists Elements]} {
                lappend elementsNamesList {*}[my getAllElemNames]
            }
            set dup [my DuplListCheckRet $elementsNamesList]
            if {$dup ne {}} {
                return -code error "Netlist '[my configure -name]' already contains element with name $dup"
            }
            foreach element $elements {
                set elemName [$element configure -name]
                dict append Elements $elemName $element
            }
            return
        }
        method del {args} {
            # Deletes elements from the circuit by its name.
            #  args - elements names
            # Synopsis: elementName ?elementName ...?
            argparse -help {Deletes elements from the circuit by its name} {
                {elementsNames -catchall -help {Elements names}}
            }
            if {![info exists Elements]} {
                return -code error "Netlist '[my configure -name]' doesn't have attached elements"
            }
            foreach elemName $elementsNames {
                set elemName [string tolower $elemName]
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
        method detachSimulator {args} {
            # Removes `Simulator` object reference from `Circuit`.
            argparse -help {Removes 'Simulator' object reference from 'Circuit'} {}
            unset simulator
            return
        }
        method getDataDict {args} {
            # Gets dictionary with raw data vectors.
            # Returns: dict with vectors data, keys - names of vectors
            argparse -help {Gets dictionary with raw data vectors. Returns: dict with vectors data, keys - names of\
                                    vectors} {}
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
            # Invokes `runAndRead`, `configure -log` and `configure -data` methods from attached simulator.
            #  -nodelete - flag to forbid simulation file deletion
            # Synopsis: ?-nodelete?
            argparse -help {Invokes 'runAndRead', 'configure -log' and 'configure -data' methods from attached\
                                    simulator.} {
                {-nodelete -help {Flag to forbid simulation file deletion}}
            }
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
    ##nagelfar subcmd+ _obj,Subcircuit addPin addParam
    oo::configurable create Subcircuit {
        superclass Netlist
        variable Pins Params
        constructor {args} {
            # Creates object of class `Subcircuit`.
            #  name - name of the subcircuit
            #  pins - list of pins in the order they appear in SPICE subcircuits definition together
            #   in form: `{pinName0 pinName1 pinName2 ...}`
            #  params - list of input parameters in form `{{name value} {name value} {name value} ...}`
            # This class implements subcircuit, it is subclass of netlist because it holds list of elements
            # inside subcircuit, together with header and connection of elements inside.
            set arguments [argparse -inline -help {Creates object of class 'Device'} {
                {name -help {Name of the subcircuit}}
                {pins -help {List of pins in the order they appear in SPICE subcircuits definition together in form:\
                                     '{pinName0 pinName1 ...}'} -type list}
                {params -help {List of input parameters in form '{{name value} {name value} {name value} ...}'}\
                         -type list}
            }]
            # create Pins objects, nodes are set to empty string
            foreach pin [dget $arguments pins] {
                my actOnPin -add [@ $pin 0] {}
            }
            # create Params objects that are input parameters of subcircuit
            foreach param [dget $arguments params] {
                if {[llength $param]<=2} {
                    my actOnParam -add {*}$param
                } else {
                    error "Wrong parameter '$param' definition in subcircuit '[dget $arguments name]'"
                }
            }
            next [dget $arguments name]
        }
        destructor {
            # Destroy object of class `Subcircuit`, and its parameters and pins objects.
            if {[info exists Params]} {
                foreach param [dict values $Params] {
                    $param destroy
                }
            }
            if {[info exists Pins]} {
                foreach pin [dict values $Pins] {
                    $pin destroy
                }
            }
        }
        # copy methods of Device to manipulate header .subckt definition elements
        method actOnPin {*}[info class definition ::SpiceGenTcl::Device actOnPin]
        method actOnParam {*}[info class definition ::SpiceGenTcl::Device actOnParam]
        method add {args} {
            # Add elements objects references to `Subcircuit`, it extends add method to add check of element class 
            # because subcircuit can't contain particular elements inside, like [::SpiceGenTcl::Include],
            # [::SpiceGenTcl::Library], [::SpiceGenTcl::Options] and [::SpiceGenTcl::Analysis].
            #  args - elements objects references
            argparse -help {Add elements objects references to 'Subcircuit'} {
                {elements -catchall -help {Elements objects references}}
            }
            foreach element $elements {
                set argClass [info object class $element]
                set argSuperclass [info class superclasses $argClass]
                if {$argClass in {::SpiceGenTcl::Include ::SpiceGenTcl::Library ::SpiceGenTcl::Options}} {
                    return -code error "$argClass element can't be included in subcircuit"
                } elseif {[string match *::Analysis* $argSuperclass] || [string match *::Analyses* $argSuperclass]} {
                    return -code error "Analysis element can't be included in subcircuit"
                }
            }
            next {*}$elements
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
        # type of analysis, i.e. dc, ac, tran, etc
        property type -set {
            set type [string tolower $value]
            set suppAnalysis [list ac dc tran op disto noise pz sens sp tf]
            if {$value ni $suppAnalysis} {
                return -code error "Type '$value' is not in supported list of analysis, should be one of\
                        '$suppAnalysis'"
            }
            set type $value
        }
        variable name type Params
        constructor {args} {
            # Creates object of class `Analysis`.
            #  type - type of analysis, for example, tran, ac, dc, etc
            #  params - list of instance parameters in form
            #   `{{name value} {name -sw} {name Value -eq} {name Value -posnocheck} ...}`
            #  -name - name of the string that could be used to retrieve element from [::SpiceGenTcl::Netlist] object
            #    and its descendants, optional
            # Class models analysis statement.
            # Synopsis: type params ?-name value?
            my variable name
            set arguments [argparse -inline -help {Creates object of class 'Analysis'} -pfirst {
                {type -help {Type of analysis, for example, tran, ac, dc, etc}}
                {params -help {List of instance parameters in form '{{name value} {name -sw} {name Value -eq}\
                                                                             {name Value -posnocheck} ...}'} -type list}
                {-name= -help {Name of the string that could be used to retrieve element from [::SpiceGenTcl::Netlist]\
                                       object and its descendants}}
            }]
            if {[dexist $arguments name]} {
                my configure -name [dget $arguments name]
            } else {
                my configure -name [self object]
            }
            my configure -type [dget $arguments type]
            # create Analysis objects
            foreach param [dget $arguments params] {
                if {[llength $param]<2} {
                    return -code error "Value '$param' is not a valid value"
                } else {
                    my actOnParam -add {*}$param
                }
            }
        }
        destructor {
            # Destroy object of class `Analysis`, and its parameters objects.
            if {[info exists Params]} {
                foreach param [dict values $Params] {
                    $param destroy
                }
            }
        }
        method actOnParam {*}[info class definition ::SpiceGenTcl::Device actOnParam]
        method genSPICEString {} {
            # Creates analysis for SPICE netlist.
            # Returns: string SPICE netlist's string
            if {[info exists Params]} {
                return ".[my configure -type] [join [lmap param [dict values $Params] {$param genSPICEString}]]"
            } else {
                return .[my configure -type]
            }
        }
    }

###  Simulator class definition
    oo::configurable create Simulator {
        self mixin -append oo::abstract
        property name
        property log
        property data
        variable name Command log data
        method run {} {
            # Runs simulation.
            error {Not implemented}
        }
        method readLog {} {
            # Reads log file of completed simulations.
            error {Not implemented}
        }
        method getLog {} {
            # Returns log file of completed simulations.
            error {Not implemented}
        }
        method readData {} {
            # Reads raw data file of last simulation.
            error {Not implemented}
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
        # Type of dataset, could be voltage, vurrent, time or frequency
        property type -set {
            set type [string tolower $value]
        }
        # Numerical type of dataset, real, double or complex
        property numtype -set {
            # method to set the numerical type of the dataset
            if {$value ni {real complex double}} {
                error "Unknown numerical type '$value' of data"
            }
            set numtype $value
        }
        # Number of points (length of dataset)
        property len
         # values at points
        variable name type numtype len DataPoints
        constructor {args} {
            # initialize dataset
            #  name - name of the dataset
            #  type - type of dataset
            #  len - total number of points
            #  numtype - numerical type of dataset
            set arguments [argparse -inline -help {Initialize object 'Dataset'} {
                {name -help {Name of the dataset}}
                {type -help {Type of dataset}}
                {len -help {Total number of points}}
                {numtype -optional -default real -help {Numerical type of dataset}}
            }]
            dict for {elName elValue} $arguments {
                my configure -$elName $elValue
            }
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
        method getDataPoints {args} {
            argparse -help {Gets all data points} {}
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
    }

###  Trace class definition
    oo::configurable create Trace {
        # class that represents trace in raw file
        superclass Dataset
        property axis
        variable axis
        constructor {args} {
            # initialize trace
            #  name - name of the trace
            #  type - type of trace
            #  len - total number of points
            #  axis - name of axis that is linked to trace
            #  numtype - numerical type of trace
            set arguments [argparse -inline -help {Initialize object 'Dataset'} {
                {name -pass rest -help {Name of the trace}}
                {type -pass rest -help {Type of trace}}
                {len -pass rest -help {Total number of points}}
                {axis -help {Name of axis that is linked to trace}}
                {numtype -pass rest -optional -default real -help {Numerical type of trace}}
            }]
            my configure -axis [dget $arguments axis]
            next {*}[dget $arguments rest]
        }
    }

###  EmptyTrace class definition
    oo::configurable create EmptyTrace {
        # Class represents empty trace (trace that was not readed) in raw file
        superclass Dataset
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
        ##nagelfar ignore {Wrong number of arguments}
        mixin BinaryReader Utility
        # path to raw file including it's file name
        property path
        # parameters of raw file readed from it's header
        property rawparams
        # number of points in raw file
        property npoints
        # number of variables in raw file
        property nvariables
        # object reference of axis in raw file
        property axis -get {
            if {[info exists axis]} {
                return $axis
            } else {
                return -code error "Raw file '[my configure -path]' doesn't have an axis"
            }
        }
        variable path rawparams npoints nvariables axis Traces BlockSize
        constructor {args} {
            # Creates RawFile object.
            #  path - path to raw file including it's file name
            #  traces2read - list of traces that will be readed, default value is \*,
            #   that means reading all traces
            #  simulator - simulator that produced this raw file, default is ngspice
            set arguments [argparse -inline -help {Creates 'RawFile' object} {
                {path -help {path to raw file including it's file name}}
                {traces2read -optional -default * -help {List of traces that will be readed, default value is *,\
                                                                 that means reading all traces}}
                {simulator -optional -default ngspice -help {Total number of points}}
            }]
            my configure -path [dget $arguments path]
            set fileSize [file size $path]
            set file [open $path r]
            fconfigure $file -translation binary
####   read header
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
                        set line [string trimright $line \r]
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
####   save header parameters
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
                set numtype complex
            } else {
                if {({double} in $flags) || ([dget $arguments simulator] eq {ngspice}) ||\
                            ([dget $arguments simulator] eq {xyce})} {
                    set numtype double
                } else {
                    set numtype real
                }
            }
####   parse variables
            set i [lsearch $header Variables:]
            set ivar 0
            foreach line [lrange $header [+ $i 1] end-1] {
                set lineList [split [string trim $line] \t]
                lassign $lineList idx name varType
                if {$ivar==0} {
                    if {([dget $arguments simulator] eq {ltspice}) && ($name eq {time})} {
                        # workaround for bug with negative values in time axis
                        set axisIsTime true
                    }
                    if {$numtype eq {real}} {
                        set axisNumType double
                    } else {
                        set axisNumType $numtype
                    }
                    my configure -axis [::SpiceGenTcl::Axis new $name $varType $npoints $axisNumType]
                    ##nagelfar ignore #12 {Found constant "traces"}
                    dappend Traces [string tolower $name] [my configure -axis]
                } elseif {([dget $arguments traces2read] eq {*}) || ($name in [dget $arguments traces2read])} {
                    if {$hasAxis} {
                        dappend Traces [string tolower $name] [::SpiceGenTcl::Trace new $name $varType $npoints\
                                                                       [[my configure -axis] configure -name] $numtype]
                    } else {
                        dappend Traces [string tolower $name]\
                                [::SpiceGenTcl::Trace new $name $varType $npoints {} $numtype]
                    }
                } else {
                    dappend Traces [string tolower $name]\
                            [::SpiceGenTcl::EmptyTrace new $name $varType $npoints $numtype]
                }
                incr ivar
            }
            if {([dget $arguments traces2read] eq {}) || ![llength [dget $arguments traces2read]]} {
                close $file
                return
            }
####   read data
            if {$rawType eq {Binary:}} {
                set BlockSize [= {($fileSize - $binaryStart)/$npoints}]
                set scanFunctions {}
                set calcBlockSize 0
                foreach trace [dvalues $Traces] {
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
                    error "Error in calculating the block size. Expected '$BlockSize' bytes, but found\
                            '$calcBlockSize' bytes"
                }
                 for {set i 0} {$i<$npoints} {incr i} {
                    for {set j 0} {$j<[dict size $Traces]} {incr j} {
                        set value [eval "my [@ $scanFunctions $j]" $file]
                        set trace [@ [dvalues $Traces] $j]
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
                    for {set j 0} {$j<[dict size $Traces]} {incr j} {
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
                            if {$numtype eq {complex}} {
                                set value [split [@ $lineList 1] ,]
                            } else {
                                set value [@ $lineList 1]
                            }
                        } else {
                            if {$numtype eq {complex}} {
                                set value [split [@ $lineList 1] ,]
                            } else {
                                set value [@ $lineList 1]
                            }
                        }
                        set trace [@ [dvalues $Traces] $j]
                        $trace appendDataPoints $value
                    }
                }
            }
            close $file
        }
        destructor {
            # Destroy object of class `RawFile`, and its traces objects.
            if {[info exists Traces]} {
                foreach trace [dict values $Traces] {
                    $trace destroy
                }
            }
        }
        method getTrace {traceName} {
            # Returns trace object reference by it's name
            set traceFoundFlag false
            foreach trace [dvalues $Traces] {
                if {[$trace configure -name] eq $traceName} {
                    set traceFound $trace
                    set traceFoundFlag true
                    break
                }
            }
            if {!$traceFoundFlag} {
                return -code error "Trace with name '$traceName' was not found in raw file '[my configure -path]' list\
                        of traces"
            }
            return $traceFound
        }
        method getVariablesNames {args} {
            # Returns list that contains names of all variables
            argparse -help {Returns list that contains names of all variables} {}
            return [dkeys $Traces]
        }
        method getVoltagesNames {args} {
            # Returns list that contains names of all voltage variables
            argparse -help {Returns list that contains names of all voltage variables} {}
            return [lmap trace [dvalues $Traces]\
                            {expr {[string match -nocase *voltage* [$trace configure -type]] ?\
                                           [$trace configure -name] : [continue]}}]
        }
        method getCurrentsNames {args} {
            # Returns list that contains names of all current variables
            argparse -help {Returns list that contains names of all current variables} {}
            return [lmap trace [dvalues $Traces]\
                            {expr {[string match -nocase *current* [$trace configure -type]] ?\
                                           [$trace configure -name] : [continue]}}]
        }
        method getTracesStr {args} {
            # Returns information about all Traces in raw file in form of string
            argparse -help {Returns information about all Traces in raw file in form of string} {}
            return [lmap trace [dvalues $Traces]\
                            {join [list [$trace configure -name] [$trace configure -type] [$trace configure -numtype]]}]
        }
        method getTracesData {args} {
            # Returns dictionary that contains all data in value and name as a key
            argparse -help {Returns dictionary that contains all data in value and name as a key} {}
            set dict {}
            dict for {traceName trace} $Traces {
                dict append dict $traceName [$trace getDataPoints]
            }
            return $dict
        }
        method getTracesCsv {args} {
            # Returns string with csv formatting containing all data
            #  -all - select all traces, optional
            #  -traces - select names of traces to return, optional
            #  -sep - separator of columns, default is comma, optional
            # Synopsis: ?-all? ?-traces list? ?-sep value?
            set arguments [argparse -inline -help {Returns string with csv formatting containing all data} {
                {-all -forbid traces -help {Select all traces}}
                {-traces -catchall -forbid all -help {Select names of traces to return}}
                {-sep= -default , -help {Separator of columns}}
            }]
            if {[dexist $arguments all]} {
                set tracesDict [my getTracesData]
                set tracesList [list [dict keys $tracesDict]]
                for {set i 0} {$i<[my configure -npoints]} {incr i} {
                    lappend tracesList [lmap traceValues [dict values $tracesDict] {@ $traceValues $i}]
                }
            ##nagelfar ignore #12 {Found constant "traces"}
            } elseif {[dget $arguments traces] ne {}} {
                foreach traceName [dget $arguments traces] {
                    set traceObj [my getTrace $traceName]
                    dict append tracesDict [$traceObj configure -name] [$traceObj getDataPoints]
                }
                set tracesList [list [dict keys $tracesDict]]
                for {set i 0} {$i<[my configure -npoints]} {incr i} {
                    lappend tracesList [lmap traceValues [dict values $tracesDict] {@ $traceValues $i}]
                }
            } else {
                return -code error {Arguments '-all' or '-traces traceName1 traceName2 ...' must be provided to\
                                            'getTracesCsv' method}
            }
            return [::csv::joinlist $tracesList [dget $arguments sep]]
        }
        method measure {args} {
            return [::tclmeasure::measure -xname [[my configure -axis] configure -name] -data [my getTracesData]\
                            {*}$args]
        }
    }

###  Parser class definition
    ##nagelfar subcmd+ _obj,Parser configure CheckEqual Unbrace ParseWithEqual CheckBraced CheckBracedWithEqual\
            ParseBracedWithEqual BuildNetlist buildTopNetlist ParseParams
    oo::configurable create Parser {
        property name
        property filepath
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
        property topnetlist
        property definitions
        variable name filepath FileData SubcktsTree ElemsMethods DotsMethods SupModelsTypes topnetlist definitions\
                NamespacePath
        initialize {
            variable ModelTemplate {oo::class create @type@ {
                superclass ::SpiceGenTcl::Model
                constructor {args} {
                    set paramsNames [list @paramsList@]
                    next {*}[my ArgsPreprocess $paramsNames {name type} @hsuppress@ {*}$args]
                }
            }}
            variable SubcircuitTemplate {oo::class create @classname@ {
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
        constructor {args} {
            # Creates object of class `Parser` that do parsing of valid simulator netlist.
            #   name - name of the object
            #   filepath - path to file that should be parsed
            set arguments [argparse -inline -help {Creates object of class `Parser` that do parsing of valid simulator\
                                                           netlist} {
                {name -help {Name of the object}}
                {filepath -help {Path to file that should be parsed}}
            }]
            my configure -name [dget $arguments name]
            my configure -filepath [dget $arguments filepath]
            my configure -topnetlist [::SpiceGenTcl::Netlist new [file tail [dget $arguments filepath]]]
        }
        method readFile {} {
            error {Not implemented}
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
                error "Parser object '[my configure -name]' doesn't have prepared data"
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
            classvariable SubcircuitTemplate
            if {![info exists FileData]} {
                error "Parser object '[my configure -name]' doesn't have prepared data"
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
                                                @definitions@ [join $definitionsLoc \n]\
                                                @elements@ [join $elements \n]]\
                                    $SubcircuitTemplate]
            ##nagelfar ignore {Found constant "definition"}
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
                error "Parser object '[my configure -name]' doesn't have prepared data"
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
                ##nagelfar ignore {Found constant "end"}
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
                        set nameValue [list -$name [list -eq $value]]
                    } else {
                        set nameValue [list -eq $name $value]
                    }
                } else {
                    return -code error "Parameter '$elem' parsing failed"
                }
                if {$format eq {arg}} {
                    if {$name ni [lmap nameExc $exclude {subst $nameExc}]} {
                        if {$value eq {}} {
                            return -code error "Parameter '$elem' parsing failed: value is empty"
                        }
                        lappend results {*}$nameValue
                    }
                } elseif {$format eq {list}} {
                    if {$name ni [lmap nameExc $exclude {subst $nameExc}]} {
                        if {$value eq {}} {
                            return -code error "Parameter '$elem' parsing failed: value is empty"
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
                        set nameValue [list -$name [list -eq $value]]
                    } else {
                        set nameValue [list -eq $name $value]
                    }
                } elseif {[regexp {^[a-zA-Z0-9]+$} $elem]} {
                    set name $elem
                    set value {}
                    if {$format eq {arg}} {
                        set nameValue -$name
                    } else {
                        set nameValue [list -sw $name]
                    }
                    set switch true
                } else {
                    return -code error "Parameter '$elem' parsing failed"
                }
                if {$format eq {arg}} {
                    if {$name ni [lmap nameExc $exclude {subst -$nameExc}]} {
                        if {$value eq {} && !$switch} {
                            return -code error "Parameter '$elem' parsing failed: value is empty"
                        }
                        lappend results {*}$nameValue
                    }
                } else {
                    if {$name ni [lmap nameExc $exclude {subst $nameExc}]} {
                        if {$value eq {} && !$switch} {
                            return -code error "Parameter '$elem' parsing failed: value is empty"
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
                    set value [list -eq [my Unbrace $elem]]
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
                return -code error "String '$string' isn't of form {string}, string must not contain '{' and '}'\
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
                return -code error "String '$string' isn't of form 'string', string must not contain ''' and '''\
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
                return -code error "String '$string' isn't of form 'name={value}', value must not contain '{' or '}'\
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
                return -code error "String '$string' isn't of form 'name=value', value must not contain '{' or '}'\
                        symbols, name must contain only alphanumeric characters and '_' symbol"
            }
        }
    }
}
