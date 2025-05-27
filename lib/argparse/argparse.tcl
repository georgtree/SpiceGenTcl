# argparse.tcl --
#
# Feature-heavy argument parsing package
#
# Copyright (C) 2019 Andy Goth <andrew.m.goth@gmail.com>
# Copyright (C) 2025 George Yashin <georgtree@gmail.com>
# See the file "LICENSE" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.
package require Tcl 8.6-
package provide argparse 0.58
interp alias {} @ {} lindex
interp alias {} = {} expr
# argparse --
# Parses an argument list according to a definition list.  The result may be
# stored into caller variables or returned as a dict.
#
# For documentation please see README.md file

proc ::argparse {args} {
### Common validation helper routine.
    set validateHelper {apply {{name opt args} {
        if {[dict exists $opt enum]} {
            set command [list tcl::prefix match -message "$name value"\
                                 {*}[if {[uplevel 1 {info exists exact}]} {list -exact}] [dict get $opt enum]]
            set args [lmap arg $args {{*}$command $arg}]
        } elseif {[dict exists $opt validate]} {
            foreach arg $args [list if [dict get $opt validate] {} else {
                if {[dict exists $opt errormsg]} {
                    return -code error -level 2 [subst [dict get $opt errormsg]]
                } else {
                    return -code error -level 2 "$name value \"$arg\" fails [dict get $opt validateMsg]"
                }
            }]
        }
        return $args
    }}}
### Type checking routine
    set typeChecker {apply {{name opt args} {
        if {[dict exists $opt type]} {
            foreach arg $args {
                if {![string is [dict get $opt type] -strict $arg]} {
                    return -code error -level 2 "$name value \"$arg\" is not of the type [dict get $opt type]"
                }
            }
        }
        return $args
    }}}
### Check aliases
    set aliasesChecker {apply {{aliases opt} {
        foreach alias [dict get $opt alias] {
            if {[dict exists $aliases $alias]} {
                return false
            }
        }
        return true
    }}}
### Process arguments to argparse procedure
    set level 1
    set enum {}
    set validate {}
    set globalSwitches {-boolean -enum -equalarg -exact -inline -keep -level -long -mixed -normalize -pass -reciprocal\
                                -template -validate -help -helplevel -pfirst}
    for {set i 0} {$i<[llength $args]} {incr i} {
        if {[catch {regsub {^-} [tcl::prefix match -message switch $globalSwitches [@ $args $i]] {} switch} errorMsg]} {
            # Do not allow "--" or definition lists nested within the special
            # empty-string element containing extra overall switches.
            if {[info exists reparse]} {
                return -code error $msg
            }
            # Stop after "--" or at the first non-switch argument.
            if {[@ $args $i] eq {--}} {
                incr i
            }
            # Extract definition and args from the argument list, pulling from
            # the caller's args variable if the args parameter is omitted.
            switch [= {[llength $args]-$i}] {
            0 {
                break
            } 1 {
                set definition [@ $args end]
                set argv [uplevel 1 {::set args}]
            } 2 {
                set definition [@ $args end-1]
                set argv [@ $args end]
            } default {
                return -code error {too many arguments}
            }}
            # Convert any definition list elements named empty string to instead
            # be overall switches, and arrange to reparse those switches.  Also,
            # remove inline comments from the definition list.
            set args {}
            set reparse {}
            set i -1
            foreach elem $definition[set definition {}] {
                if {[@ $elem 0] eq "#"} {
                    if {[llength $elem] == 1} {
                        set comment {}
                    }
                } elseif {[info exists comment]} {
                    unset comment
                } elseif {[@ $elem 0] eq {}} {
                    lappend args {*}[lrange $elem 1 end]
                } else {
                    lappend definition $elem
                }
            }
        } elseif {$switch ni {enum level pass template validate help helplevel}} {
            # Process switches with no arguments.
            set $switch {}
        } elseif {$i == [llength $args]-1} {
            return -code error "-$switch requires an argument"
        } else {
            # Process switches with arguments.
            set $switch [@ $args [incr i]]
        }
    }
    # Fail if no definition argument was supplied.
    if {![info exists definition]} {
        return -code error {missing required parameter: definition}
    }
    # Forbid using -inline and -keep at the same time.
    if {[info exists inline] && [info exists keep]} {
        return -code error {-inline and -keep conflict}
    }
    # Forbid using -mixed and -pfirst at the same time.
    if {[info exists mixed] && [info exists pfirst]} {
        return -code error {-mixed and -pfirst conflict}
    }
### Parse element definition list.
    set def {}
    set aliases {}
    set order {}
    set switches {}
    set upvars {}
    set omitted {}
    foreach elem $definition {
####  Read element definition switches.
        set opt {}
        set defsSwitches {-alias -argument -boolean -catchall -default -enum -forbid -ignore -imply -keep -key -level\
                                  -optional -parameter -pass -reciprocal -require -required -standalone -switch -upvar\
                                  -validate -value -type -allow -help -errormsg -hsuppress}
        set defsSwitchesWArgs {alias default enum forbid imply key pass require validate value type allow help errormsg}
        for {set i 1} {$i<[llength $elem]} {incr i} {
            if {[set switch [regsub {^-} [tcl::prefix match $defsSwitches [@ $elem $i]] {}]] ni $defsSwitchesWArgs} {
#####   Process switches without arguments.
                dict set opt $switch {}
            } elseif {$i == [llength $elem]-1} {
                return -code error "-$switch requires an argument"
            } else {
#####   Process switches with arguments.
                incr i
                dict set opt $switch [@ $elem $i]
            }
        }
####  Process the first element of the element definition.
        if {![llength $elem]} {
            return -code error {element definition cannot be empty}
        } elseif {[dict exists $opt switch] && [dict exists $opt parameter]} {
            return -code error {-switch and -parameter conflict}
        } elseif {[info exists inline] && [dict exists $opt keep]} {
            return -code error {-inline and -keep conflict}
        } elseif {![dict exists $opt switch] && ![dict exists $opt parameter]} {
            # If -switch and -parameter are not used, parse shorthand syntax.
            if {![regexp -expanded {
                ^(?:(-)(?:(.*)\|)?)?(\w[\w-]*)([=?!*^]*)$
            } [@ $elem 0] _ minus alias name flags]} {
                return -code error "bad element shorthand: [@ $elem 0]"
            }
            if {$minus ne {}} {
                dict set opt switch {}
            } else {
                dict set opt parameter {}
            }
            if {$alias ne {}} {
                dict set opt alias [split $alias {|}]
            }
            foreach flag [split $flags {}] {
                dict set opt [dict get {= argument ? optional ! required * catchall ^ upvar} $flag] {}
            }
        } elseif {![regexp {^\w[\w-]*$} [@ $elem 0]]} {
            return -code error "bad element name: [@ $elem 0]"
        } else {
            # If exactly one of -switch or -parameter is used, the first element
            # of the definition is the element name, with no processing applied.
            set name [@ $elem 0]
        }
####  Check for collisions.
        if {[dict exists $def $name]} {
            return -code error "element name collision: $name"
        }
        if {[dict exists $opt switch]} {
####  Add -argument switch if particular switches are presented
            # -optional, -required, -catchall, and -upvar imply -argument when
            # used with switches.
            foreach switch {optional required catchall upvar type} {
                if {[dict exists $opt $switch]} {
                    dict set opt argument {}
                }
            }
        } else {
####  Add -required switch for parameters
            # Parameters are required unless -catchall or -optional are used.
            if {([dict exists $opt catchall] || [dict exists $opt optional]) && ![dict exists $opt required]} {
                dict set opt optional {}
            } else {
                dict set opt required {}
            }
        }
####  Check requirements and conflicts.
        foreach {switch other} {reciprocal require  level upvar  errormsg validate} {
            if {[dict exists $opt $switch] && ![dict exists $opt $other]} {
                return -code error "-$switch requires -$other"
            }
        }
        foreach {switch others} {
            parameter {alias boolean value argument imply}
            ignore    {key pass}
            required  {boolean default}
            argument  {boolean value}
            upvar     {boolean inline catchall}
            boolean   {default value}
            enum      validate
            type      {upvar boolean enum}
            allow     forbid
        } {
            if {[dict exists $opt $switch]} {
                foreach other $others {
                    if {[dict exists $opt $other]} {
                        return -code error "-$switch and -$other conflict"
                    }
                }
            }
        }
        if {[dict exists $opt upvar] && [info exists inline]} {
            return -code error {-upvar and -inline conflict}
        }
####  Check for disallowed combinations.
        foreach combination {
            {switch optional catchall}
            {switch optional upvar}
            {switch optional default}
            {switch optional boolean}
            {switch optional type}
            {parameter optional required}
        } {
            foreach switch [list {*}$combination {}] {
                if {$switch eq {}} {
                    return -code error "[join [lmap switch $combination {
                        string cat - $switch
                    }]] is a disallowed combination"
                } elseif {![dict exists $opt $switch]} {
                    break
                }
            }
        }
####  Replace -boolean with "-default 0 -value 1".
        if {([info exists boolean] && [dict exists $opt switch] && ![dict exists $opt argument]\
                     && ![dict exists $opt upvar] && ![dict exists $opt default] && ![dict exists $opt value]\
                     && ![dict exists $opt required]) || [dict exists $opt boolean]} {
            dict set opt default 0
            dict set opt value 1
        }
####  Insert default -level if -upvar is used.
        if {[dict exists $opt upvar] && ![dict exists $opt level]} {
            dict set opt level $level
        }
####  Compute default output key if -ignore, -key, and -pass aren't used.
        if {![dict exists $opt ignore] && ![dict exists $opt key] && ![dict exists $opt pass]} {
            if {[info exists template]} {
                dict set opt key [string map [list \\\\ \\ \\% % % $name] $template]
            } else {
                dict set opt key $name
            }
        }
        if {[dict exists $opt parameter]} {
####  Keep track of parameter order.
            lappend order $name
####  Forbid more than one catchall parameter.
            if {[dict exists $opt catchall]} {
                if {[info exists catchall]} {
                    return -code error "multiple catchall parameters: $catchall and $name"
                } else {
                    set catchall $name
                }
            }
        } elseif {![dict exists $opt alias]} {
####  Build list of switches.
            lappend switches -$name
        } elseif {![regexp {^\w[\w-]*( \w[\w-]*)*$} [dict get $opt alias]]} {
            return -code error "bad alias: [dict get $opt alias]"
        } elseif {![{*}$aliasesChecker $aliases $opt]} {
            return -code error "element alias collision: [dict get $opt alias]"
        } else {
####  Build list of switches (with aliases), and link switch aliases.
            foreach alias [dict get $opt alias] {
                dict set aliases $alias $name
            }
            lappend switches -[join [list {*}[dict get $opt alias] $name] |]
        }
####  Check for collision between alias and other switch name
        if {$name in [dict keys $aliases]} {
            return -code error "collision of switch -[dict get $aliases $name] alias with the -$name switch"
        }
####  Map from upvar keys back to element names, and forbid collisions.
        if {[dict exists $opt upvar] && [dict exists $opt key]} {
            if {[dict exists $upvars [dict get $opt key]]} {
                return -code error "multiple upvars to the same variable: [dict get $upvars [dict get $opt key]] $name"
            }
            dict set upvars [dict get $opt key] $name
        }
####  Look up named enumeration lists and validation expressions.
        if {[dict exists $opt enum] && [dict exists $enum [dict get $opt enum]]} {
            dict set opt enum [dict get $enum [dict get $opt enum]]
        } elseif {[dict exists $opt validate]} {
            if {[dict exists $validate [dict get $opt validate]]} {
                dict set opt validateMsg "[dict get $opt validate] validation"
                dict set opt validate [dict get $validate [dict get $opt validate]]
            } else {
                dict set opt validateMsg "validation: [dict get $opt validate]"
            }
        }
####  Check for allowed arguments to -type
        if {[dict exists $opt type]} {
            set allowedTypes {alnum alpha ascii boolean control dict digit double graph integer list lower print punct\
                                      space upper wideinteger wordchar xdigit}
            if {[dict get $opt type] ni $allowedTypes} {
                return -code error "type [dict get $opt type] is not in the list of allowed types, must be\
                        [join [lrange $allowedTypes 0 end-1] {, }] or [@ $allowedTypes end]"
            }
        }
####  Save element definition.
        dict set def $name $opt
####  Prepare to identify omitted elements.
        dict set omitted $name {}
    }
### Process constraints and shared key logic.
    dict for {name opt} $def {
####  Verify constraint references.
        foreach constraint {require forbid allow} {
            if {[dict exists $opt $constraint]} {
                foreach otherName [dict get $opt $constraint] {
                    if {![dict exists $def $otherName]} {
                        return -code error "$name -$constraint references undefined element: $otherName"
                    }
                }
            }
        }
####  Create reciprocal requirements.
        if {([info exists reciprocal] || [dict exists $opt reciprocal]) && [dict exists $opt require]} {
            foreach other [dict get $opt require] {
                dict update def $other otherOpt {
                    dict lappend otherOpt require $name
                }
            }
        }
####  Perform shared key logic.
        if {[dict exists $opt key]} {
            dict for {otherName otherOpt} $def {
                if {$name ne $otherName && [dict exists $otherOpt key] && ([dict get $otherOpt key] eq\
                                                                                   [dict get $opt key])} {
#####   Limit when shared keys may be used.
                    if {[dict exists $opt parameter]} {
                        return -code error "$name cannot be a parameter because it shares a key with $otherName"
                    } elseif {[dict exists $opt argument]} {
                        return -code error "$name cannot use -argument because it shares a key with $otherName"
                    } elseif {[dict exists $opt catchall]} {
                        return -code error "$name cannot use -catchall because it shares a key with $otherName"
                    } elseif {[dict exists $opt default] && [dict exists $otherOpt default]} {
                        return -code error "$name and $otherName cannot both use -default because they share a key"
                    }
#####   Create forbid constraints on shared keys.
                    if {![dict exists $otherOpt forbid] || ($name ni [dict get $otherOpt forbid])} {
                        dict update def $otherName otherOpt {
                            dict lappend otherOpt forbid $name
                        }
                    }
#####   Set default -value for shared keys.
                    if {![dict exists $opt value]} {
                        dict set def $name value $name
                    }
                }
            }
        }
    }
####  Build help string
    if {[info exists help]} {
        package require textutil::adjust
        namespace import textutil::adjust::*
        if {({-help} in $argv) || ([info exists long] && ({--help} in $argv))} {
            set enumStrBuild {apply {{name opt} {
                if {[llength [dict get $opt $name]]>2} {
                    set str "[join [lrange [dict get $opt $name] 0 end-1] {, }] or [@ [dict get $opt $name] end]"
                } elseif {[llength [dict get $opt $name]]==2} {
                    set str "[@ [dict get $opt $name] 0] or [@ [dict get $opt $name] end]"
                } else {
                    set str [@ [dict get $opt $name] 0]
                }
                return $str
            }}}
            if {$help ne {}} {
                set providedHelp [adjust $help -length 80].
                lappend description $providedHelp
            }
            if {[info exists exact]} {
                lappend description {Doesn't accept prefixes instead of switches names.}
            } else {
                lappend description {Can accepts unambiguous prefixes instead of switches names.}
            }
            if {[info exists mixed]} {
                lappend description {Allows switches to appear after parameters.}
            } elseif {![info exists pfirst]} {
                lappend description {Accepts switches only before parameters.}
            }
            if {[info exists pfirst]} {
                lappend description {Required parameters must appear before switches.}
            }
            if {[info exists long]} {
                lappend description {Recognizes --switch long option alternative syntax.}
            }
            if {[info exists equalarg]} {
                lappend description {Recognizes -switch=arg inline argument alternative syntax.}
            }
            dict for {name opt} $def {
                # basic element string building
                if {[dict exists $opt hsuppress]} {
                    continue
                }
                if {[dict exists $opt switch]} {
                    if {[dict exists $opt required]} {
                        lappend elementDescr required,
                    } elseif {[dict exists $opt boolean]} {
                        lappend elementDescr boolean,
                    }
                    if {[dict exists $opt argument]} {
                        if {[dict exists $opt optional]} {
                            lappend elementDescr expects optional argument
                        } else {
                            lappend elementDescr expects argument                          
                        }
                    }
                    set type switch
                } else {
                    if {[dict exists $opt optional]} {
                        lappend elementDescr optional
                    }
                    set type parameter
                }
                # element constraints string building
                if {[dict exists $opt require]} {
                    lappend constraints [join [list Requires [{*}$enumStrBuild require $opt]]].
                } elseif {[dict exists $opt allow]} {
                    lappend constraints [join [list Allows [{*}$enumStrBuild allow $opt]]].
                }
                if {[dict exists $opt forbid]} {
                    lappend constraints [join [list Forbids [{*}$enumStrBuild forbid $opt]]].
                }
                # element description building
                if {[info exists elementDescr]} {
                    lappend combined [string totitle [join $elementDescr] 0 2].
                }
                if {[dict exists $opt help]} {
                    lappend combined [dict get $opt help].
                }
                if {[info exists constraints]} {
                    lappend combined {*}$constraints
                }
                if {[dict exists $opt default] && [dict exists $opt argument]} {
                    lappend combined "Default value is [dict get $opt default]."
                }
                if {[dict exists $opt alias]} {
                    if {[llength [dict get $opt alias]]>1} {
                        lappend combined "Aliases are [{*}$enumStrBuild alias $opt]."
                    } else {
                        lappend combined "Alias is [dict get $opt alias]."
                    }
                }
                if {[dict exists $opt catchall]} {
                    lappend combined {Collects unassigned arguments.}
                }
                if {[dict exists $opt upvar]} {
                    lappend combined {Links caller variable.}
                }
                if {[dict exists $opt type]} {
                    lappend combined "Type [dict get $opt type]."
                }
                if {[dict exists $opt enum]} {
                    lappend combined "Value must be one of: [{*}$enumStrBuild enum $opt]."
                }
                if {[dict exists $opt imply]} {
                    lappend combined {Expects two arguments.}
                }
                if {$type eq {switch}} {
                    if {[info exists combined]} {
                        set combined "-$name - [join $combined { }]"
                    } else {
                        set combined -$name
                    }
                    lappend descriptionSwitches [indent [indent [adjust $combined -length 72] {    } 1] {        }]
                } else {
                    if {[info exists combined]} {
                        set combined "$name - [join $combined { }]"
                    } else {
                        set combined $name
                    }
                    lappend descriptionParameters [indent [indent [adjust $combined -length 72] {    } 1] {        }]
                }
                unset -nocomplain elementDescr constraints combined
            }
            set description [adjust [join $description] -length 80]
            if {[info exists descriptionSwitches] && [info exists descriptionParameters]} {
                puts [string totitle [string map {{,;} {;} {,.} {.}}\
                                              [join [list $description [indent Switches: {    }]\
                                                             {*}$descriptionSwitches [indent Parameters: {    }]\
                                                             {*}$descriptionParameters] \n]] 0 1]
            } elseif {[info exists descriptionSwitches]} {
                puts [string totitle [string map {{,;} {;} {,.} {.}}\
                                              [join [list $description [indent Switches: {    }]\
                                                             {*}$descriptionSwitches] \n]] 0 1]
            } elseif {[info exists descriptionParameters]} {
                puts [string totitle [string map {{,;} {;} {,.} {.}}\
                                              [join [list $description [indent Parameters: {    }]\
                                                             {*}$descriptionParameters] \n]] 0 1]
            } else {
                puts [string totitle [string map {{,;} {;} {,.} {.}} $providedHelp] 0 1]
            }
            if {[info exists helplevel]} {
                return -level $helplevel
            } else {
                return -level 2
            }
        }
    }
### Handle default pass-through switch by creating a dummy element.
    if {[info exists pass]} {
        dict set def {} pass $pass
    }
### Reorder parameters to have required parameters first if -pfirst global switch is specified
    if {[info exists pfirst]} {
        foreach name $order {
            if {[dict exists $def $name required]} {
                lappend orderReq $name
            } else {
                lappend orderOpt $name
            }
        }
        if {[info exists orderReq] && [info exists orderOpt]} {
            set order [list {*}$orderReq {*}$orderOpt]
        } elseif {[info exists orderReq]} {
            set order $orderReq
        } elseif {[info exists orderOpt]} {
            set order $orderReq
        }
    }
### Force required parameters to bypass switch logic.
    set end [= {[llength $argv]-1}]
    set start 0
    if {![info exists mixed]} {
        if {[info exists pfirst]} {
            foreach name $order {
                if {[dict exists $def $name required]} {
                    incr start
                }
            }
            set force [lreplace $argv $start end]
            set argv [lrange $argv $start end]
        } else {
            foreach name $order {
                if {[dict exists $def $name required]} {
                    incr end -1
                }
            }
            set force [lreplace $argv 0 $end]
            set argv [lrange $argv 0 $end]
        }
    } else {
        set force [lreplace $argv $start end]
        set argv [lrange $argv $start end]
    }
    
### Perform switch logic.
    set result {}
    set missing {}
    if {$switches ne {}} {
####  Build regular expression to match switches.
        set re ^-
        if {[info exists long]} {
            append re -?
        }
        append re {(\w[\w-]*)}
        if {[info exists equalarg]} {
            append re (?:(=)(.*))?
        } else {
            append re ()()
        }
        append re $
####  Process switches, and build the list of parameter arguments.
        set params {}
        while {$argv ne {}} {
#####   Check if this argument appears to be a switch.
            set argv [lassign $argv arg]
            if {[regexp $re $arg _ name equal val]} {
                # This appears to be a switch.  Fall through to the handler.
            } elseif {$arg eq {--}} {
                # If this is the special "--" switch to end all switches, all
                # remaining arguments are parameters.
                set params $argv
                break
            } elseif {[info exists mixed] || [info exists pfirst]} {
                # If -mixed is used and this is not a switch, it is a parameter.
                # Add it to the parameter list, then go to the next argument.
                lappend params $arg
                continue
            } else {
                # If this is not a switch, terminate switch processing, and
                # process this and all remaining arguments as parameters.
                set params [linsert $argv 0 $arg]
                break
            }
#####   Process switch aliases.
            if {[dict exists $aliases $name]} {
                set name [dict get $aliases $name]
            }
#####   Preliminary guess for the normalized switch name.
            set normal -$name
#####   Perform switch name lookup.
            if {[dict exists $def $name switch]} {
                # Exact match.  No additional lookup needed.
            } elseif {![info exists exact] &&\
                              ![catch {tcl::prefix match -message switch\
                                               [lmap {key data} $def {
                                                   if {[dict exists $data switch]} {
                                                       set key
                                                   } else {
                                                       continue
                                                   }
                                               }] $name
                              } name]} {
                # Use the switch whose prefix unambiguously matches.
                set normal -$name
            } elseif {[dict exists $def {}]} {
                # Use default pass-through if defined.
                set name {}
            } else {
                # Fail if this is an invalid switch.
                set switches [lsort $switches]
                if {[llength $switches]>1} {
                    lset switches end "or [@ $switches end]"
                }
                set switches [join $switches {*}[if {[llength $switches]>2} {list ", "}]]
                return -code error "bad switch \"$arg\": must be $switches"
            }
#####   If the switch is standalone, ignore all constraints.
            if {[dict exists $def $name standalone]} {
                foreach other [dict keys $def] {
                    dict unset def $other required
                    dict unset def $other require
                    dict unset def $other forbid
                    dict unset def $other allow
                    if {[dict exists $def $other parameter]} {
                        dict set def $other optional {}
                    }
                }
            }
#####   Keep track of which elements are present.
            dict set def $name present {}
            # If the switch value was set using -switch=value notation, insert
            # the value into the argument list to be handled below.
            if {$equal eq {=}} {
                set argv [linsert $argv 0 $val]
            }
#####   Load key and pass into local variables for easy access.
            unset -nocomplain key pass
            foreach var {key pass} {
                if {[dict exists $def $name $var]} {
                    set $var [dict get $def $name $var]
                }
            }
#####   Keep track of which switches have been seen.
            dict unset omitted $name
#####   Validate switch arguments and store values into the result dict.
            if {[dict exists $def $name catchall]} {
                # The switch is catchall, so store all remaining arguments.
                set argv [{*}$validateHelper $normal [dict get $def $name] {*}$argv]
                set argv [{*}$typeChecker $normal [dict get $def $name] {*}$argv]
                if {[info exists key]} {
                    dict set result $key $argv
                }
                if {[info exists pass]} {
                    if {[info exists normalize]} {
                        dict lappend result $pass $normal {*}$argv
                    } else {
                        dict lappend result $pass $arg {*}$argv
                    }
                }
                break
            } elseif {![dict exists $def $name argument]} {
                # The switch expects no arguments.
                if {$equal eq {=}} {
                    return -code error "$normal doesn't allow an argument"
                }
                if {[info exists key]} {
                    if {[dict exists $def $name value]} {
                        dict set result $key [dict get $def $name value]
                    } else {
                        dict set result $key {}
                    }
                }
                if {[info exists pass]} {
                    if {[info exists normalize]} {
                        dict lappend result $pass $normal
                    } else {
                        dict lappend result $pass $arg
                    }
                }
            } elseif {$argv ne {}} {
                # The switch was given the expected argument.
                set argv0 [@ [{*}$validateHelper $normal [dict get $def $name] [@ $argv 0]] 0]
                set argv0 [@ [{*}$typeChecker $normal [dict get $def $name] [@ $argv 0]] 0]
                if {[info exists key]} {
                    if {[dict exists $def $name optional]} {
                        dict set result $key [list {} $argv0]
                    } else {
                        dict set result $key $argv0
                    }
                }
                if {[info exists pass]} {
                    if {[info exists normalize]} {
                        dict lappend result $pass $normal $argv0
                    } elseif {$equal eq {=}} {
                        dict lappend result $pass $arg
                    } else {
                        dict lappend result $pass $arg [@ $argv 0]
                    }
                }
                set argv [lrange $argv 1 end]
            } else {
                # The switch was not given the expected argument.
                if {![dict exists $def $name optional]} {
                    return -code error "$normal requires an argument"
                }
                if {[info exists key]} {
                    dict set result $key {}
                }
                if {[info exists pass]} {
                    if {[info exists normalize]} {
                        dict lappend result $pass $normal
                    } else {
                        dict lappend result $pass $arg
                    }
                }
            }

            # Insert this switch's implied arguments into the argument list.
            if {[dict exists $def $name imply]} {
                set argv [concat [dict get $def $name imply] $argv]
                dict unset def $name imply
            }
        }
#####   Build list of missing required switches.
        dict for {name opt} $def {
            if {[dict exists $opt switch] && ![dict exists $opt present] && [dict exists $opt required]} {
                if {[dict exists $opt alias]} {
                    lappend missing -[join [list {*}[dict get $opt alias] $name] |]
                } else {
                    lappend missing -$name
                }
            }
        }
#####   Fail if at least one required switch is missing.
        if {$missing ne {}} {
            set missing [lsort $missing]
            if {[llength $missing]>1} {
                lset missing end "and [@ $missing end]"
            }
            set missing [join $missing {*}[if {[llength $missing]>2} {list ", "}]]
            return -code error [string cat "missing required switch"\
                    {*}[if {[llength $missing]>1} {list es}] ": " $missing]
        }
    } else {
        # If no switches are defined, bypass the switch logic and process all
        # arguments using the parameter logic.
        set params $argv
    }
### Allocate one argument to each required parameter, including catchalls.
    set alloc {}
    if {[info exists pfirst]} {
        set params [linsert $params 0 {*}$force]
    } else {
        lappend params {*}$force
    }
    set count [llength $params]
    set i 0
    foreach name $order {
        if {[dict exists $def $name required]} {
            if {$count} {
                dict set alloc $name 1
                dict unset omitted $name
                dict set def $name present {}
                incr count -1
            } else {
                lappend missing $name
            }
        }
        incr i
    }
### Fail if at least one required parameter is missing.
    if {$missing ne {}} {
        if {[llength $missing]>1} {
            lset missing end "and [@ $missing end]"
        }
        return -code error [string cat "missing required parameter" {*}[if {[llength $missing]>1} {list s}] ": "\
                                    [join $missing {*}[if {[llength $missing]>2} {list ", "}]]]
    }
### Try to allocate one argument to each optional, non-catchall parameter, until there are no arguments left.
    if {$count} {
        foreach name $order {
            if {![dict exists $def $name required] && ![dict exists $def $name catchall]} {
                dict set alloc $name 1
                dict unset omitted $name
                dict set def $name present {}
                if {![incr count -1]} {
                    break
                }
            }
        }
    }
### Process excess arguments.
    if {$count} {
        if {[info exists catchall]} {
            # Allocate remaining arguments to the catchall parameter.
            dict incr alloc $catchall $count
            dict unset omitted $catchall
        } elseif {[dict exists $def {}]} {
            # If there is no catchall parameter, instead allocate to the default
            # pass-through result key.
            lappend order {}
            dict set alloc {} $count
        } else {
            return -code error {too many arguments}
        }
    }
### Check constraints.
    dict for {name opt} $def {
        if {[dict exists $opt present]} {
            foreach {match condition description} {1 require requires 0 forbid {conflicts with}} {
                if {[dict exists $opt $condition]} {
                    foreach otherName [dict get $opt $condition] {
                        if {[dict exists $def $otherName present]!=$match} {
                            foreach var {name otherName} {
                                if {[dict exists $def [set $var] switch]} {
                                    set $var -[set $var]
                                }
                            }
                            return -code error "$name $description $otherName"
                        }
                    }
                }
            }
        }
    }
    dict for {name opt} $def {
        if {[dict exists $opt present]} {
            lappend presentedNames $name
        }
    }
    dict for {name opt} $def {
        if {[dict exists $opt present]} {
            if {[dict exists $opt allow]} {
                set allowedNames [dict get $opt allow]
                foreach presentedName $presentedNames {
                    if {$presentedName eq $name} {
                        continue
                    }
                    if {$presentedName ni $allowedNames} {
                        return -code error "$name doesn't allow $presentedName"
                    }
                }
            }
        }
    }
### If normalization is enabled, explicitly store into the pass-through keys
    # all omitted switches that have a pass-through key, accept an argument, and
    # have a default value.
    if {[info exists normalize]} {
        dict for {name opt} $def {
            if {[dict exists $opt switch] && [dict exists $opt pass] && [dict exists $opt argument] &&\
                        [dict exists $opt default] && [dict exists $omitted $name]} {
                dict lappend result [dict get $opt pass] -$name [dict get $opt default]
            }
        }
    }
### Validate parameters and store in result dict.
    set i 0
    foreach name $order {
        set opt [dict get $def $name]
        if {[dict exists $alloc $name]} {
            if {![dict exists $opt catchall] && $name ne {}} {
                set val [@ [{*}$validateHelper $name $opt [@ $params $i]] 0]
                set val [@ [{*}$typeChecker $name $opt [@ $params $i]] 0]
                if {[dict exists $opt pass]} {
                    if {([string index $val 0] eq {-}) && ![dict exists $result [dict get $opt pass]]} {
                        dict lappend result [dict get $opt pass] --
                    }
                    dict lappend result [dict get $opt pass] $val
                }
                incr i
            } else {
                set step [dict get $alloc $name]
                set val [lrange $params $i [= {$i+$step-1}]]
                if {$name ne {}} {
                    set val [{*}$validateHelper $name $opt {*}$val]
                    set val [{*}$typeChecker $name $opt {*}$val]
                }
                if {[dict exists $opt pass]} {
                    if {([string index [@ $val 0] 0] eq {-}) && ![dict exists $result [dict get $opt pass]]} {
                        dict lappend result [dict get $opt pass] --
                    }
                    dict lappend result [dict get $opt pass] {*}$val
                }
                incr i $step
            }
            if {[dict exists $opt key]} {
                dict set result [dict get $opt key] $val
            }
        } elseif {[info exists normalize] && [dict exists $opt default] && [dict exists $opt pass]} {
            # If normalization is enabled and this omitted parameter has both a
            # default value and a pass-through key, explicitly store the default
            # value in the pass-through key, located in the correct position so
            # that it can be recognized again later.
            if {([string index [dict get $opt default] 0] eq {-}) && ![dict exists $result [dict get $opt pass]]} {
                dict lappend result [dict get $opt pass] --
            }
            dict lappend result [dict get $opt pass] [dict get $opt default]
        }
    }
### Create default values for missing elements.
    dict for {name opt} $def {
        if {[dict exists $opt key] && ![dict exists $result [dict get $opt key]]} {
            if {[dict exists $opt default]} {
                dict set result [dict get $opt key] [dict get $opt default]
            } elseif {[dict exists $opt catchall]} {
                dict set result [dict get $opt key] {}
            }
        }
        if {[dict exists $opt pass] && ![dict exists $result [dict get $opt pass]]} {
            dict set result [dict get $opt pass] {}
        }
    }
    if {[info exists inline]} {
####  Return result dict.
        return $result
    } else {
####  Unless -keep was used, unset caller variables for omitted elements.
        if {![info exists keep]} {
            dict for {name val} $omitted {
                set opt [dict get $def $name]
                if {![dict exists $opt keep] && [dict exists $opt key] && ![dict exists $result [dict get $opt key]]} {
                    uplevel 1 [list ::unset -nocomplain [dict get $opt key]]
                }
            }
        }
####  Process results.
        dict for {key val} $result {
            if {[dict exists $upvars $key]} {
                # If this element uses -upvar, link to the named variable.
                uplevel 1 [list ::upvar [dict get $def [dict get $upvars $key] level] $val $key]
            } else {
                # Store result into caller variables.
                uplevel 1 [list ::set $key $val]
            }
        }
    }
}
