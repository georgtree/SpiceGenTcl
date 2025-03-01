#  .|'''.|            ||                   ..|'''.|                   |''||''|         '||'
#  ||..  '  ... ...  ...    ....    ....  .|'     '    ....  .. ...      ||      ....   ||  
#   ''|||.   ||'  ||  ||  .|   '' .|...|| ||    .... .|...||  ||  ||     ||    .|   ''  ||  
# .     '||  ||    |  ||  ||      ||      '|.    ||  ||       ||  ||     ||    ||       ||  
# |'....|'   ||...'  .||.  '|...'  '|...'  ''|...'|   '|...' .||. ||.   .||.    '|...' .||. 
#            ||                                                                             
#           ''''                                                                            
# netlistParserClassNgspice.tcl
# Describes parser class for Ngspice netlists
#
# Copyright (c) 2024 George Yashin, georgtree@gmail.com
#
# MIT License
# See the file "LICENSE.txt" for information on usage and redistribution
# of this file, and for a DISCLAIMER OF ALL WARRANTIES.

namespace eval ::SpiceGenTcl::Ngspice {

    namespace export Parser
    namespace import ::SpiceGenTcl::*
    importNgspice



    oo::configurable create Parser {
        property Name
        variable Name
        property filepath
        variable filepath
        property FileData
        variable FileData
        property SubcktsBoundaries
        variable SubcktsBoundaries
        property elemsMethods
        variable elemsMethods
        property elemsMethods
        variable dotsMethods
        property dotsMethods
        variable supModelsTypes
        property supModelsTypes
        property Netlist
        variable Netlist
        variable ModelNames
        variable ModelTemplate
        variable SubcircuitTemplate

        constructor {name filepath} {
            my configure -Name $name -filepath $filepath
            my configure -elemsMethods [dcreate b CreateBehSource c CreateCap d CreateDio e CreateVCVS f CreateCCCS\
                                                g CreateVCCS h CreateCCVS i CreateVIsource j CreateJFET k CreateCoupInd\
                                                l CreateInd m CreateMOSFET n CreateVeriloga q CreateBJT r CreateRes\
                                                s CreateVSwitch v CreateVIsource w CreateCSwitch x CreateSubcktInst\
                                                z CreateMESFET]
            my configure -dotsMethods [dcreate ac CreateAc dc CreateDc func CreateFunc global CreateGlobal ic CreateIc\
                                               include CreateInclude model CreateModel nodeset CreateNodeset op CreateOp\
                                               options CreateOptions param CreateParam sens CreateSens sp CreateSp\
                                               temp CreateTemp tran CreateTran params CreateParam]
            my configure -supModelsTypes {r c l sw csw d npn pnp njf pjf nmos pmos nmf pmf}
            my configure -Netlist [Netlist new [file tail $filepath]]
            set ModelTemplate {oo::class create @type@ {
                superclass Model
                constructor {name args} {
                    set paramsNames [list @paramsList@]
                    next $name @type@ [my argsPreprocess $paramsNames {*}$args]
                }
            }}
            set SubcircuitTemplate {oo::class create @classname@ {
                superclass Subcircuit
                constructor {} {
                    set pins @pins@
                    set params @params@
                    next @subname@ $pins $params
                }
            }}
        }
        method AddModelName {name} {
            lappend ModelNames $name
        }
        method GetModelNames {name} {
            if {[info exists ModelNames]} {
                return $ModelNames
            } else {
                return {}
            }
        }
        method readFile {} {
            # Reads netlist file and prepare for parsing: remove redundant white space characters, collapse continuation
            # lines and remove comments lines
            set file [open [my configure -filepath] r]
            set fileData [split [read $file] "\n"]
            close $file
            set fileData [lrange $fileData 1 end]
            # replace all sequences of white space characters with single space character
            foreach line $fileData {
                set processedLine [regsub -all {[[:space:]]+} [string trim $line] { }]
                if {$processedLine ne {}} {
                    lappend lines [string tolower $processedLine]
                }
            }
            # find continuations and move them to line that is the start of continuation
            set fileData $lines
            set contFlag false
            # create a dictionary like `2 {3 4 5} 6 {7} 8 {} 9 {} 10 {} {11 12} 13 {}...` where keys are start lines,
            # indexes and values are the lists of lines indexes that are the continuation of the line with key index
            # also, skip the first line of the netlist
            for {set i 0} {$i<[llength $fileData]} {incr i} {
                set line [@ $fileData $i]
                if {[string index $line 0] eq "+"} {
                    if {$contFlag} {
                        dict lappend continLinesIndex $startIndex $i
                        continue
                    }
                    dict append continLinesIndex [= {$i-1}]
                    set startIndex [= {$i-1}]
                    dict lappend continLinesIndex $startIndex $i
                    set contFlag true
                } else {
                    set contFlag false
                    dict append continLinesIndex $i
                }
            }
            # append continuation lines to start line of each continuation list with first symbol removal (it is assumed
            # to be `+` symbol)
            if {[info exists continLinesIndex]} {
                dict map {lineIndex contLinesIndexes} $continLinesIndex {
                    if {$contLinesIndexes eq {}} {
                        lappend finalList [@ $fileData $lineIndex]
                    } else {
                        set locList [@ $fileData $lineIndex]
                        foreach contLineIndex $contLinesIndexes {
                            lappend locList [string trim [string range [@ $fileData $contLineIndex] 1 end]]
                        }
                        lappend finalList [join $locList]
                    }
                }
            } else {
                set finalList $fileData
            }
            # remove all comments that start with `*` symbol
            set finalList [lsearch -all -inline -not -glob $finalList {\**}]
            # remove control section that starts with .control and ends with .endc
            for {set i 0} {$i<[llength $finalList]} {incr i} {
                set line [@ $finalList $i]
                if {[regexp {^\.control\s?} $line]} {
                    set controlStart $i
                } elseif {[regexp {^\.endc\s?} $line]} {
                    set controlEnd $i    
                }
                if {[info exists controlStart] && [info exists controlEnd]} {
                    break
                }
            }
            if {[info exists controlStart] && [info exists controlEnd]} {
                set finalList [lreplace $finalList $controlStart $controlEnd]
            }
            # remove spaces after `{` and before `}`, replace `= `, ` = ` and ` =` with single `=`
            foreach line $finalList {
                lappend finalList1 [string map {"{ " "{" " }" "}" " = " "=" " =" "=" "= " "="} $line]
            }
            my configure -FileData $finalList1
            return
        }
        method getSubcircuitLines {} {
            # Parses line by line and get start and the end of subcircuits
            if {![info exists FileData]} {
                error "Parser object '[my configure -name]' doesn't have prepared data"
            }
            set fileData [my configure -FileData]
            for {set i 0} {$i<[llength $fileData]} {incr i} {
                set lineList [split [@ $fileData $i]]
                if {[string match -nocase {.subckt} [@ $lineList 0]]} {
                    if {[@ $lineList 1] ne {}} {
                        dappend subckts [@ $lineList 1] $i
                    } else {
                        error "Subcircuit couldn't be defined without a name"
                    }
                } elseif {[string match -nocase {.ends} [@ $lineList 0]]} {
                    try {
                        dict lappend subckts [@ [dkeys $subckts] end] $i
                    } on error {} {
                        error ".ends statement appears on line $i (pre-processed netlist) before definition of\
                                subcircuit begins"
                    }
                }
            }
            if {[info exists subckts]} {
                dict for {subcktName subcktIndexes} $subckts {
                    if {[llength $subcktIndexes]!=2} {
                        if {[llength $subcktIndexes]==1} {
                            error "Subcircuit '$subcktName' doesn't have matched .ends statement"
                        } elseif {[llength $subcktIndexes]>1} {
                            error "Netlist contains mismatched .subckt .ends statements near definition of '$subcktName'"
                        }
                    }
                }
            }
            if {[info exists subckts]} {
                my configure -SubcktsBoundaries $subckts
            }
            return
        }
        method buildTopNetlist {} {
            # Builds top netlist corresponding to parsed netlist file
            set allLines [my configure -FileData]
            set topNetlist [my configure -Netlist]
            my getSubcircuitLines
            # parse found subcircuits definitions first
            if {![catch {my configure -SubcktsBoundaries}]} {
                set subcktsBoundaries [my configure -SubcktsBoundaries]
                dict for {subcktName subcktBounds} $subcktsBoundaries {
                    my buildSubcktFromDef $subcktName $subcktBounds
                    lappend lines2remove {*}[lseq [@ $subcktBounds 0] [@ $subcktBounds 1]]
                    
                }
                set allLines [lremove $allLines {*}$lines2remove]
            }
            
            my buildNetlist $allLines $topNetlist
            return
        }
        method buildSubcktFromDef {subcktName subcktBounds} {
            # Builds subcircuit definition object from passed lines and add it to top circuit
            #   subcktName - name of subcircuit
            #   subcktBounds - boundaries of subcircuit
            set allLines [my configure -FileData]
            set topNetlist [my configure -Netlist]

            # parse definition line of subcircuit
            set defLine [@ $allLines [@ $subcktBounds 0]]
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
            eval [string map [list @classname@ $subcktClassName @pins@ [list $pinList] @params@ [list $params]\
                                      @subname@ $subName] $SubcircuitTemplate]
            set subcktInst [$subcktClassName new]
            $topNetlist add $subcktInst
            my buildNetlist [lrange $allLines [= {[@ $subcktBounds 0]+1}] [= {[@ $subcktBounds 1]-1}]] $subcktInst
            return
        }
        method buildNetlist {lines netlistObj} {
            # Builds netlist from passed lines and add it to passed object
            #   lines - list of lines to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` and its childrens
            set elems [dkeys [my configure -elemsMethods]]
            set dots [dkeys [my configure -dotsMethods]]
            for {set i 0} {$i<[llength $lines]} {incr i} {
                set line [@ $lines $i]
                set lineList [split $line]
                set firstWord [@ $lineList 0]
                set firstChar [string index $firstWord 0]
                set restChars [string range $firstWord 1 end]
                if {$firstChar eq {.}} {
                    if {$restChars in $dots} {
                        my [dict get [my configure -dotsMethods] $restChars] $line $netlistObj
                    } else {
                        puts "Line '$lineList' contains unsupported dot statement '$firstWord', skip that line"
                        continue
                    }
                } elseif {[string match {[a-z]} $firstChar]} {
                    if {$firstChar in $elems} {
                        my [dict get [my configure -elemsMethods] $firstChar] $line $netlistObj
                    } else {
                        puts "Line '$lineList' contains unsupported element '$firstWord', skip that line"
                        continue
                    }
                } else {
                    puts "Line '$lineList' starts with illegal character '$firstChar', skip that line"
                    continue
                }
            }
            return
        }
        method CreateModel {line netlistObj} {
            # Creates model object from passed line and add it to netlist
            #   line - line to parse
            set line [regsub -all {[[:space:]]+} [string trim [string map {"(" " " ")" " "} $line]] { }]
            set lineList [lrange [split $line] 1 end]
            lassign $lineList name type
            if {![my CheckModelName $name]} {
                return -code error "Model name '${name}' contains illegal characters"
            }
            set paramsList [my ParseParams $lineList 2]
            if {$type ni [my configure -supModelsTypes]} {
                set modelClassName [string totitle $type]Model
                puts "Model type '${type}' is not in the list of supported types, custom type '${modelClassName}' was\
                        created"
                set paramString [string map {- {}} [join [dkeys $paramsList]]]
                eval [string map [list @type@ $modelClassName @paramsList@ $paramString] $ModelTemplate]
                $netlistObj add [$modelClassName new $name {*}$paramsList]
            } else {
                switch $type {
                    r {
                        $netlistObj add [RModel new $name {*}$paramsList]
                    }
                    c {
                        $netlistObj add [CModel new $name {*}$paramsList]
                    }
                    l {
                        $netlistObj add [LModel new $name {*}$paramsList]
                    }
                    sw {
                        $netlistObj add [VSwitchModel new $name {*}$paramsList]
                    }
                    csw {
                        $netlistObj add [CSwitchModel new $name {*}$paramsList]
                    }
                    d {
                        $netlistObj add [DiodeModel new $name {*}$paramsList]
                    }
                    npn -
                    pnp {
                        if {{-level} in [dkeys $paramsList]} {
                            set level [dget $paramsList -level]
                            if {$level==1} {
                                set paramsList [dict remove $paramsList -level]
                                $netlistObj add [BjtGPModel new $name $type {*}$paramsList]
                            } elseif {$level in {4 8}} {
                                puts "Level '${level}' of type '${type}' model '${name}' is not in the list of\
                                        SpiceGenTcl supported levels, custom level model was created"
                                set paramString [string map {- {}} [join [dkeys $paramsList]]]
                                set modelClassName [string totitle $type]Model
                                eval [string map [list @type@ $modelClassName @paramsList@ $paramString] $ModelTemplate]
                                $netlistObj add [$modelClassName new $name {*}$paramsList]
                            } else {
                                puts "Level '${level}' of BJT model in line '${line}' is not supported, skip that line"
                            }
                        } else {
                            $netlistObj add [BjtGPModel new $name $type {*}$paramsList]
                        }
                    }
                    njf -
                    pjf {
                        if {{-level} in [dkeys $paramsList]} {
                            set level [dget $paramsList -level]
                            if {$level==1} {
                                set paramsList [dict remove $paramsList -level]
                                $netlistObj add [Jfet1Model new $name $type {*}$paramsList]
                            } elseif {$level==2} {
                                set paramsList [dict remove $paramsList -level]
                                $netlistObj add [Jfet2Model new $name $type {*}$paramsList]
                            } else {
                                puts "Level '${level}' of JFET model in line '${line}' is not supported, skip that line"
                            }
                        } else {
                            $netlistObj add [Jfet1Model new $name $type {*}$paramsList]
                        }
                    }
                    nmf -
                    pmf {
                        if {{-level} in [dkeys $paramsList]} {
                            set level [dget $paramsList -level]
                            if {$level==1} {
                                set paramsList [dict remove $paramsList -level]
                                $netlistObj add [Mesfet1Model new $name $type {*}$paramsList]
                            } else {
                                puts "Level '${level}' of MESFET in line '${line}' is not supported, skip that line"
                            }
                        } else {
                            $netlistObj add [Mesfet1Model new $name $type {*}$paramsList]
                        }
                    }
                }
            }
            return
        }
        method CreateOp {line netlistObj} {
            $netlistObj add [Op new]
            return
        }
        method CreateAc {line netlistObj} {
            set lineList [lrange [split $line] 1 end]
            $netlistObj add [Ac new {*}[my ParsePosParams $lineList {variation n fstart fstop}]]
            return
        }
        method CreateDc {line netlistObj} {
            set lineList [lrange [split $line] 1 end]
            set paramsNames {src start stop incr}
            if {[llength $lineList]>[llength $paramsNames]} {
                puts "DC analysis with multiple sources is not supported in SpiceGenTcl, skip the other sources in line\
                        '${line}'"
            }
            $netlistObj add [Dc new {*}[my ParsePosParams $lineList $paramsNames]]
            return
        }
        method CreateTran {line netlistObj} {
            set lineList [lrange [split $line] 1 end]
            set paramsNames {tstep tstop tstart tmax}
            if {[set index [lsearch -exact $lineList uic]]!=-1} {
                set lineList [lremove $lineList $index]
                set configParams [linsert [my ParsePosParams $lineList $paramsNames] end -uic]
                $netlistObj add [Tran new {*}$configParams]
            } else {
                $netlistObj add [Tran new {*}[my ParsePosParams $lineList $paramsNames]]
            }
            return
        }
        method CreateSens {line netlistObj} {
            if {[regexp {(v|i)\(([^{}()=]+)\)} $line]} {
                set line [regsub -command {(v|i)\(([^{}()=]+)\)} $line {apply {{- a b} {
                    format %s(%s) $a [string map {" " ""} $b]
                }}}]
                set lineList [lrange [split $line] 1 end]
                if {[@ $lineList 1] eq {}} {
                    $netlistObj add [SensDc new -outvar [@ $lineList 0]]
                } elseif {[@ $lineList 1] eq {ac}} {
                    set lineList [lremove $lineList 1]
                    set paramsNames {outvar variation n fstart fstop}
                    $netlistObj add [SensAc new {*}[my ParsePosParams $lineList $paramsNames]]
                } else {
                    error "Sense analysis has usupported type '[@ $lineList 1]'"
                }
            } else {
                error "Sense analysis in line '${line}' doesn't have output variable with proper syntax"
            }
            return
        }
        method CreateSp {line netlistObj} {
            set lineList [lrange [split $line] 1 end]
            set paramsNames {variation n fstart fstop}
            if {[@ $lineList 4]==1} {
                set lineList [lremove $lineList 4]
                set configParams [linsert [my ParsePosParams $lineList $paramsNames] end -donoise]
                $netlistObj add [Sp new {*}$configParams]
            } else {
                $netlistObj add [Sp new {*}[my ParsePosParams $lineList $paramsNames]]
            }
            return
        }
        method CreateFunc {line netlistObj} {

        }
        method CreateGlobal {line netlistObj} {

        }
        method CreateIc {line netlistObj} {

        }
        method CreateInclude {line netlistObj} {

        }
        method CreateNodeset {line netlistObj} {

        }
        method CreateOptions {line netlistObj} {

        }
        method CreateParam {line netlistObj} {
            set lineList [lrange [split $line] 1 end]
            $netlistObj add [ParamStatement new [my ParseParams $lineList 0 {} list]]
            return
        }
        method CreateTemp {line netlistObj} {

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
                        set name -$name
                    } elseif {$format eq {list}} {
                        set nameValue [list $name $value]
                    }
                } elseif {[my CheckBracedWithEqual $elem]} {
                    lassign [my ParseBracedWithEqual $elem] name value
                    if {$format eq {arg}} {
                        set name -$name
                        set value [list $value -eq]
                    } elseif {$format eq {list}} {
                        set nameValue [list $name $value -eq]
                    }
                } else {
                    return -code error "Parameter '${elem}' parsing failed"
                }
                if {$format eq {arg}} {
                    if {$name ni [lmap nameExc $exclude {subst "-$nameExc"}]} {
                        if {$value eq {}} {
                            return -code error "Parameter '${elem}' parsing failed: value is empty"
                        }
                        lappend results $name $value
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
            # Unbrace input string, `{value}` to `value`, value inside braces must not contain `{`, `}` and `=` symbols and 
            # be empty
            #   string - input braced string
            # Returns: string without braces, 
            if {[my CheckBraced $string]} {
                return [@ [regexp -inline {^\{([^={}]+)\}$} $string] 1]
            } else {
                return -code error "String '${string}' isn't of form {string}, string must not contain '{' and '}'\
                        symbols"
            }
        }
        method CheckBracedWithEqual {string} {
            # Checks if string has form `name={value}`, value must not contain `{`, `}` and `=` symbols and be empty, names 
            # can containonly alphanumeric characters and `_` symbol
            #   string - input string
            return [regexp {^([a-zA-Z_][a-zA-Z0-9_]*)=\{([^={}]+)\}$} $string]
        }
        method ParseBracedWithEqual {string} {
            # Parse input string in form `name={value}` to list {name value}, value must not contain `{`, `}` and `=` symbols
            # and be empty, names can contain only alphanumeric characters and `_` symbol
            #   string - input string
            # Returns: list in form {name value}
            if {[my CheckBracedWithEqual $string]} {
                regexp {^([a-zA-Z_][a-zA-Z0-9_]*)=\{([^={}]+)\}$} $string match name value
                return [list $name $value]
            } else {
                return -code error "String '${string}' isn't of form 'name={value}', value must not contain '{' or '}'\ 
                        symbols, name must contain only alphanumeric characters and '_' symbol"
            }
        }
        method CheckEqual {string} {
            # Checks if string has form `name=value`, value must not contain `{`, `}` and `=` symbols and be empty, names can 
            # contain only alphanumeric characters and `_` symbol
            #   string - input string
            return [regexp {^([a-zA-Z_][a-zA-Z0-9_]*)=([^={}]+)$} $string]
        }
        method ParseWithEqual {string} {
            # Parse input string in form `name=value` to list `{name value}`.
            #   string - input string
            # Returns: list in form {name value}
            if {[my CheckEqual $string]} {
                regexp {^([a-zA-Z_][a-zA-Z0-9_]*)=([^={}]+)$} $string match name value
                return [list $name $value]
            } else {
                return -code error "String '${string}' isn't of form 'name=value', value must not contain '{' or '}'\ 
                        symbols, name must contain only alphanumeric characters and '_' symbol"
            }
        }
        method CheckNumber {string} {
            # Checks if string is a valid float string, acceptable by SPICE syntax
            #   string - input string
            if {[string is double -strict $string]} {
                return true
            } else {
                if {[string tolower [string range $string end-2 end]] eq {meg}} {
                    if {[string is double -strict [string range $string 0 end-3]]} {
                        return true
                    } else {
                        return false
                    } 
                } else {
                    set suffix [string tolower [string index $string end]]
                    if {$suffix in {f p n u m k g t}} {
                        if {[string is double -strict [string range $string 0 end-1]]} {
                            return true
                        } else {
                            return false
                        } 
                    } else {
                        return false
                    }
                }
            }
        }
        method CheckModelName {string} {
            # Checks if string is a valid model name acceptable by SPICE syntax
            #   string - input string
            if {$string eq {}} {
                return false
            } elseif {[regexp {[^A-Za-z0-9_]+} $string]} {
                return false
            } else {
                return true
            }
        }
        method CreateRes {line netlistObj} {
            # Creates resistor object from passed line and add it to netlist
            #   line - line to parse
            # Supports behavioural resistor only in canonical form `r={equation}` and only braced form `name={value}` of 
            # parameters.
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 rval fourth
            set elemName [string range $elemName 1 end]
            set excludePars {r model beh}
            if {[my CheckModelName $fourth]} {
                # check if fourth element in line is a valid model name. It process the case when resistor with model
                # also specified with resistance value
                if {[my CheckBraced $rval]} {
                    # check if rval has form '{param}'
                    set rval [list [my Unbrace $rval] -eq]
                    $netlistObj add [R new $elemName $pin1 $pin2 -r $rval -model $fourth\
                                                         {*}[my ParseParams $lineList 5 $excludePars]]
                } elseif {[my CheckNumber $rval]} {
                    # check if rval is a valid float value
                    $netlistObj add [R new $elemName $pin1 $pin2 -r $rval -model $fourth\
                                                         {*}[my ParseParams $lineList 5 $excludePars]]
                } else {
                    return -code error "Creating resistor object from line '${line}' failed due to wrong or incompatible\
                            syntax"
                }
            } else {
                if {[regexp {^r=\{([^{}]*)\}$} $rval]} {
                    # check if rval has form `r={expression}`
                    regexp {^r=\{([^{}]*)\}$} $rval match value
                    set rval $value
                    $netlistObj add [R new $elemName $pin1 $pin2 -r $rval -beh\
                                                         {*}[my ParseParams $lineList 4 $excludePars]]
                } elseif {[my CheckBraced $rval]} {
                    # check if rval has form `{param}`
                    set rval [list [my Unbrace $rval] -eq]
                    $netlistObj add [R new $elemName $pin1 $pin2 -r $rval\
                                                         {*}[my ParseParams $lineList 4 $excludePars]]
                } elseif {[my CheckNumber $rval]} {
                    # check if rval is a valid float value
                    $netlistObj add [R new $elemName $pin1 $pin2 -r $rval\
                                                         {*}[my ParseParams $lineList 4 $excludePars]]
                } elseif {[my CheckModelName $rval]} {
                    # check if rval contains valid model value
                    $netlistObj add [R new $elemName $pin1 $pin2 -model $rval\
                                                         {*}[my ParseParams $lineList 4 $excludePars]]
                } else {
                    return -code error "Creating resistor object from line '${line}' failed due to wrong or incompatible\
                            syntax"
                }
            }
            return
        }
        method CreateCap {line netlistObj} {
            # Creates capacitor object from passed line and add it to netlist
            #   line - line to parse
            # Supports behavioural capacitor only in canonical form `c={equation}` or `q={equation}` and only braced 
            # form `name={value}` of parameters.
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 cval fourth
            set elemName [string range $elemName 1 end]
            set excludePars {c q model beh}
            if {[my CheckModelName $fourth]} {
                if {[my CheckBraced $cval]} {
                    set cval [list [my Unbrace $cval] -eq]
                    $netlistObj add [C new $elemName $pin1 $pin2 -c $cval -model $fourth\
                                                         {*}[my ParseParams $lineList 5 $excludePars]]
                } elseif {[my CheckNumber $rval]} {
                    $netlistObj add [C new $elemName $pin1 $pin2 -c $cval -model $fourth\
                                                         {*}[my ParseParams $lineList 5 $excludePars]]
                } else {
                    return -code error "Creating capacitor object from line '${line}' failed due to wrong or\
                            incompatible syntax"
                }
            } else {
                if {[regexp {^c=\{([^{}]*)\}$} $cval]} {
                    regexp {^c=\{([^{}]*)\}$} $cval match value
                    set cval $value
                    $netlistObj add [C new $elemName $pin1 $pin2 -c $cval -beh\
                                                         {*}[my ParseParams $lineList 4 $excludePars]]
                } elseif {[regexp {^q=\{([^{}]*)\}$} $cval]} {
                    regexp {^q=\{([^{}]*)\}$} $cval match value
                    set qval $value
                    $netlistObj add [C new $elemName $pin1 $pin2 -q $qval -beh\
                                                         {*}[my ParseParams $lineList 4 $excludePars]]
                } elseif {[my CheckBraced $cval]} {
                    set cval [list [my Unbrace $cval] -eq]
                    $netlistObj add [C new $elemName $pin1 $pin2 -c $cval\
                                                         {*}[my ParseParams $lineList 4 $excludePars]]
                } elseif {[my CheckNumber $cval]} {
                    $netlistObj add [C new $elemName $pin1 $pin2 -c $cval\
                                                         {*}[my ParseParams $lineList 4 $excludePars]]
                } elseif {[my CheckModelName $cval]} {
                    $netlistObj add [C new $elemName $pin1 $pin2 -model $cval\
                                                         {*}[my ParseParams $lineList 4 $excludePars]]
                } else {
                    return -code error "Creating capacitor object from line '${line}' failed due to wrong or\
                            incompatible syntax"
                }
            }
            return
        }
        method CreateBehSource {line netlistObj} {
            # Creates behavioural source object from passed line and add it to netlist
            #   line - line to parse
            # Supports behavioural sources only in canonical form `v|i={equation}` and only braced form `name={value}` of 
            # parameters.
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 val
            set elemName [string range $elemName 1 end]
            if {[regexp {^(i|v)=\{([^{}]*)\}$} $val]} {
                regexp {^(i|v)=\{([^{}]*)\}$} $val match type value
                $netlistObj add [B new $elemName $pin1 $pin2 -$type $value {*}[my ParseParams $lineList 4 {}]]
            } else {
                return -code error "Creating behavioural source object from line '${line}' failed due to wrong or\
                            incompatible syntax"
            }
            return
        }
        method CreateDio {line netlistObj} {
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 modelVal
            set elemName [string range $elemName 1 end]
            if {[set offIndex [lsearch -exact $lineList off]]!=-1} {
                lappend paramsList -off
                set lineList [lremove $lineList $offIndex]
            }
            if {[my CheckModelName $modelVal]} {
                lappend paramsList {*}[my ParseParams [lrange $lineList 1 end] 3 {}]
                $netlistObj add [D new $elemName $pin1 $pin2 -model $modelVal {*}$paramsList]
            }
        }
        method CreateVCVS {line netlistObj} {
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 pin3 pin4 val
            set elemName [string range $elemName 1 end]
            if {[my CheckBraced $val]} {
                set val [list [my Unbrace $val] -eq]
                $netlistObj add [E new $elemName $pin1 $pin2 $pin3 $pin4 -gain $val]
            } elseif {[my CheckNumber $val]} {
                $netlistObj add [E new $elemName $pin1 $pin2 $pin3 $pin4 -gain $val]
            } else {
                return -code error "Creating VCVS object from line '${line}' failed due to wrong or incompatible syntax"
            }
            return
        }
        method CreateCCCS {line netlistObj} {
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 vnam val
            set elemName [string range $elemName 1 end]
            if {[my CheckBraced $val]} {
                set val [list [my Unbrace $val] -eq]
                $netlistObj add [F new $elemName $pin1 $pin2 -consrc $vnam -gain $val\
                                                     {*}[my ParseParams $lineList 6]]
            } elseif {[my CheckNumber $val]} {
                $netlistObj add [F new $elemName $pin1 $pin2 -consrc $vnam -gain $val\
                                                     {*}[my ParseParams $lineList 6]]
            } else {
                return -code error "Creating CCCS object from line '${line}' failed due to wrong or incompatible syntax"
            }
            return
        }
        method CreateVCCS {line netlistObj} {
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 pin3 pin4 val
            set elemName [string range $elemName 1 end]
            if {[my CheckBraced $val]} {
                set val [list [my Unbrace $val] -eq]
                $netlistObj add [G new $elemName $pin1 $pin2 $pin3 $pin4 -trcond $val\
                                                     {*}[my ParseParams $lineList 6]]
            } elseif {[my CheckNumber $val]} {
                $netlistObj add [G new $elemName $pin1 $pin2 $pin3 $pin4 -trcond $val\
                                                     {*}[my ParseParams $lineList 6]]
            } else {
                return -code error "Creating VCCS object from line '${line}' failed due to wrong or incompatible syntax"
            }
            return
        }
        method CreateCCVS {line netlistObj} {
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 vnam val
            set elemName [string range $elemName 1 end]
            if {[my CheckBraced $val]} {
                set val [list [my Unbrace $val] -eq]
                $netlistObj add [H new $elemName $pin1 $pin2 -consrc $vnam -transr $val]
            } elseif {[my CheckNumber $val]} {
                $netlistObj add [H new $elemName $pin1 $pin2 -consrc $vnam -transr $val]
            } else {
                return -code error "Creating CCVS object from line '${line}' failed due to wrong or incompatible syntax"
            }
            return
        }
        method CreateJFET {line netlistObj} {
            set line [string map {", " "," " ," "," " , " ","} $line]
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 pin3 modelVal
            set lineList [lremove $lineList 0 1 2 3 4]
            set elemName [string range $elemName 1 end]
            if {[set offIndex [lsearch -exact $lineList off]]!=-1} {
                lappend paramsList -off
                set lineList [lremove $lineList $offIndex]
            }
            set i 0
            foreach word $lineList {
                if {[regexp {ic=([^,]+),([^,]+)} $word match val1 val2]} {
                    lappend paramsList -ic [list $val1 $val2]
                    set lineList [lremove $lineList $i]
                    break
                }
                incr i
            }
            if {[my CheckBraced [@ $lineList 0]]} {
                lappend paramsList -area [list [my Unbrace [@ $lineList 0]] -eq]
                set lineList [lremove $lineList 0]
            } elseif {[my CheckNumber [@ $lineList 0]]} {
                lappend paramsList -area [@ $lineList 0]
                set lineList [lremove $lineList 0]
            }
            if {[my CheckModelName $modelVal]} {
                lappend paramsList {*}[my ParseParams $lineList 0 {}]
                $netlistObj add [J new $elemName $pin1 $pin2 $pin3 -model $modelVal {*}$paramsList]
            } else {
                return -code error "Creating JFET object from line '${line}' failed due to wrong or incompatible syntax"
            }
        }
        method CreateCoupInd {line netlistObj} {

        }
        method CreateInd {line netlistObj} {
            # Creates inductor object from passed line and add it to netlist
            #   line - line to parse
            # Supports behavioural inductor only in canonical form `l={equation}` and only braced form `name={value}`
            # of parameters.
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 lval fourth
            set elemName [string range $elemName 1 end]
            set excludePars {l model beh}
            if {[my CheckModelName $fourth]} {
                if {[my CheckBraced $lval]} {
                    set lval [list [my Unbrace $lval] -eq]
                    $netlistObj add [L new $elemName $pin1 $pin2 -l $lval -model $fourth\
                                                         {*}[my ParseParams $lineList 5 $excludePars]]
                } elseif {[my CheckNumber $lval]} {
                    $netlistObj add [L new $elemName $pin1 $pin2 -l $lval -model $fourth\
                                                         {*}[my ParseParams $lineList 5 $excludePars]]
                } else {
                    return -code error "Creating inductor object from line '${line}' failed due to wrong or\
                            incompatible syntax"
                }
            } else {
                if {[regexp {^l=\{([^{}]*)\}$} $lval]} {
                    regexp {^l=\{([^{}]*)\}$} $lval match value
                    set lval $value
                    $netlistObj add [L new $elemName $pin1 $pin2 -l $lval -beh\
                                                         {*}[my ParseParams $lineList 4 $excludePars]]
                } elseif {[my CheckBraced $lval]} {
                    set lval [list [my Unbrace $lval] -eq]
                    $netlistObj add [L new $elemName $pin1 $pin2 -l $lval\
                                                         {*}[my ParseParams $lineList 4 $excludePars]]
                } elseif {[my CheckNumber $lval]} {
                    $netlistObj add [L new $elemName $pin1 $pin2 -l $lval\
                                                         {*}[my ParseParams $lineList 4 $excludePars]]
                } elseif {[my CheckModelName $lval]} {
                    $netlistObj add [L new $elemName $pin1 $pin2 -model $lval\
                                                         {*}[my ParseParams $lineList 4 $excludePars]]
                } else {
                    return -code error "Creating inductor object from line '${line}' failed due to wrong or\
                            incompatible syntax"
                }
            }
            return
        }
        method CreateMOSFET {line netlistObj} {
            set line [string map {", " "," " ," "," " , " ","} $line]
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 pin3
            set lineList [lremove $lineList 0 1 2 3]
            set elemName [string range $elemName 1 end]
            if {[set offIndex [lsearch -exact $lineList off]]!=-1} {
                lappend paramsList -off
                set lineList [lremove $lineList $offIndex]
            }
            set i 0
            foreach word $lineList {
                if {[regexp {ic=([^,]+),([^,]+),([^,]+)} $word match val1 val2 val3]} {
                    lappend paramsList -ic [list $val1 $val2 $val3]
                    set lineList [lremove $lineList $i]
                    break
                }
                incr i
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
            switch $paramsStartIndex {
                1 {
                    set modelVal [@ $lineList 0]
                }
                2 {
                    lappend paramsList -n4 [@ $lineList 0]
                    set modelVal [@ $lineList 1]
                }
                3 {
                    lappend paramsList -n4 [@ $lineList 0] -n5 [@ $lineList 1]
                    set modelVal [@ $lineList 2]
                }
                4 {
                    lappend paramsList -n4 [@ $lineList 0] -n5 [@ $lineList 1] -n6 [@ $lineList 2]
                    set modelVal [@ $lineList 3] 
                }
                5 {
                    lappend paramsList -n4 [@ $lineList 0] -n5 [@ $lineList 1] -n6 [@ $lineList 2] -n7 [@ $lineList 3]
                    set modelVal [@ $lineList 4]
                }
            }
            if {[my CheckModelName $modelVal]} {
                lappend paramsList {*}[my ParseParams $lineList $paramsStartIndex {}]
                $netlistObj add [M new $elemName $pin1 $pin2 $pin3 -model $modelVal {*}$paramsList]
            } else {
                return -code error "Creating MOSFET object from line '${line}' failed due to wrong or incompatible\
                        syntax"
            }
        }
        method CreateVeriloga {line netlistObj} {

        }
        method CreateBJT {line netlistObj} {
            set line [string map {", " "," " ," "," " , " ","} $line]
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 pin3
            set lineList [lremove $lineList 0 1 2 3]
            set elemName [string range $elemName 1 end]
            if {[set offIndex [lsearch -exact $lineList off]]!=-1} {
                lappend paramsList -off
                set lineList [lremove $lineList $offIndex]
            }
            set i 0
            foreach word $lineList {
                if {[regexp {ic=([^,]+),([^,]+)} $word match val1 val2]} {
                    lappend paramsList -ic [list $val1 $val2]
                    set lineList [lremove $lineList $i]
                    break
                }
                incr i
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
            switch $paramsStartIndex {
                1 {
                    set modelVal [@ $lineList 0]
                }
                2 {
                    lappend paramsList -ns [@ $lineList 0]
                    set modelVal [@ $lineList 1]
                }
                3 {
                    lappend paramsList -ns [@ $lineList 0] -tj [@ $lineList 1]
                    set modelVal [@ $lineList 2]
                }
            }
            if {[my CheckModelName $modelVal]} {
                lappend paramsList {*}[my ParseParams $lineList $paramsStartIndex {}]
                $netlistObj add [Q new $elemName $pin1 $pin2 $pin3 -model $modelVal {*}$paramsList]
            } else {
                return -code error "Creating BJT object from line '${line}' failed due to wrong or incompatible syntax"
            }
        }
        method CreateVSwitch {line netlistObj} {
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 pin3 pin4 model state
            set elemName [string range $elemName 1 end]
            set paramsList {}
            if {$state in {on off}} {
                lappend paramsList -$state
            }
            $netlistObj add [S new $elemName $pin1 $pin2 $pin3 $pin4 -model $model {*}$paramsList]
            return
        }
        method CreateVIsource {line netlistObj} {
            # remove `(` and `)` symbols from string
            set line [regsub -all {[[:space:]]+} [string trim [string map {"(" " " ")" " "} $line]] { }]
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2
            set lineList [lrange $lineList 3 end]
            set type [string index $elemName 0]
            set elemName [string range $elemName 1 end]

            # check if the first value is DC value without DC selector
            if {[my CheckBraced [@ $lineList 0]] || [my CheckNumber [@ $lineList 0]]} {
                set dcVal [@ $lineList 0]
                if {[my CheckBraced $dcVal]} {
                    lappend paramsList -dc [list [my Unbrace $dcVal] -eq]
                } else {
                    lappend paramsList -dc $dcVal
                }
                set lineList [lremove $lineList 0]
            }
            # fine possible DC selector
            if {[set dcIndex [lsearch -exact $lineList dc]]!=-1} {
                set dcValue [@ $lineList [= {$dcIndex+1}]]
                if {[my CheckBraced $dcValue]} {
                    lappend paramsList -dc [list [my Unbrace $dcValue] -eq]
                } else {
                    lappend paramsList -dc $dcValue
                }
                set lineList [lremove $lineList $dcIndex [= {$dcIndex+1}]]
            }
            # find possible AC selector
            set acType false
            if {[set acIndex [lsearch -exact $lineList ac]]!=-1} {
                set acType true
                set acValue [@ $lineList [= {$acIndex+1}]]
                if {[my CheckBraced $acValue]} {
                    set acValue [list [my Unbrace $acValue] -eq]
                }
                set possibleAcPhase [@ $lineList [= {$acIndex+2}]]
                if {[my CheckNumber $possibleAcPhase] || [my CheckBraced $possibleAcPhase]} {
                    set acPhase $possibleAcPhase
                    if {[my CheckBraced $acPhase]} {
                        set acPhase [list [my Unbrace $acPhase] -eq]
                    }
                    set lineList [lremove $lineList $acIndex [= {$acIndex+1}] [= {$acIndex+2}]]
                    lappend paramsList -ac $acValue -acphase $acPhase
                } else {
                    set lineList [lremove $lineList $acIndex [= {$acIndex+1}]]
                    lappend paramsList -ac $acValue
                }
            }
            set functsDict [dcreate pulse {low high td tr tf pw per np} sin {v0 va freq td theta phase}\
                                    exp {v1 v2 td1 tau1 td2 tau2} pwl {seq} sffm {v0 va fc mdi fs phasec phases}\
                                    am {v0 va mf fc td phases}]
            switch [@ $lineList 0] {
                pulse {
                    lappend paramsList {*}[my ParsePosParams [lrange $lineList 1 end] [dget $functsDict pulse]]
                    $netlistObj add [[string toupper ${type}]pulse new $elemName $pin1 $pin2 {*}$paramsList]
                }
                sin {
                    lappend paramsList {*}[my ParsePosParams [lrange $lineList 1 end] [dget $functsDict sin]]
                    $netlistObj add [[string toupper ${type}]sin new $elemName $pin1 $pin2 {*}$paramsList]
                }
                exp {
                    lappend paramsList {*}[my ParsePosParams [lrange $lineList 1 end] [dget $functsDict exp]]
                    $netlistObj add [[string toupper ${type}]exp new $elemName $pin1 $pin2 {*}$paramsList]
                }
                pwl {
                    foreach value [lrange $lineList 1 end] {
                        if {[my CheckBraced $value]} {
                            set value [list [my Unbrace $value] -eq]
                        } 
                        lappend seqList $value
                    }
                    lappend paramsList -seq $seqList
                    $netlistObj add [[string toupper ${type}]pwl new $elemName $pin1 $pin2 {*}$paramsList]
                }
                sffm {
                    lappend paramsList {*}[my ParsePosParams [lrange $lineList 1 end] [dget $functsDict sffm]]
                    $netlistObj add [[string toupper ${type}]sffm new $elemName $pin1 $pin2 {*}$paramsList]
                }
                am {
                    lappend paramsList {*}[my ParsePosParams [lrange $lineList 1 end] [dget $functsDict am]]
                    $netlistObj add [[string toupper ${type}]am new $elemName $pin1 $pin2 {*}$paramsList]
                }
                portnum {
                    if {$type ne {v}} {
                        return -code error "RF port could be only voltage type in line '${line}'"
                    }
                    set portnumVal [@ $lineList 1]
                    if {[@ $lineList 2] eq {z0}} {
                        set z0Val [@ $lineList 3]
                        if {[my CheckBraced $z0Val]} {
                            lappend paramsList -z0 [list [my Unbrace $z0Val] -eq]
                        } else {
                            lappend paramsList -z0 $z0Val
                        }
                    }
                    $netlistObj add [Vport new $elemName $pin1 $pin2 -portnum $portnumVal {*}$paramsList]
                }
                default {
                    if {$acType} {
                        $netlistObj add [[string toupper ${type}]ac new $elemName $pin1 $pin2 {*}$paramsList]
                    } else {
                        $netlistObj add [[string toupper ${type}]dc new $elemName $pin1 $pin2 {*}$paramsList]
                    }
                }
            }
            return
        }
        method CreateCSwitch {line netlistObj} {
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 vnam model state
            set elemName [string range $elemName 1 end]
            set paramsList {}
            if {$state in {on off}} {
                lappend paramsList -$state
            }
            $netlistObj add [W new $elemName $pin1 $pin2 -icntrl $vnam -model $model {*}$paramsList]
            return
        }
        method CreateSubcktInst {line netlistObj} {
            set lineList [split $line]
            lassign $lineList elemName
            set elemName [string range $elemName 1 end]
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
            set subName [@ $lineList [= {$paramsStartIndex-1}]]
            set pinList [lrange $lineList 1 [= {$paramsStartIndex-2}]]
            set i 0
            foreach pin $pinList {
                lappend pins [list p$i $pin]
                incr i
            }
            $netlistObj add [X new $elemName $pins $subName [my ParseParams $lineList $paramsStartIndex {} list]]
            return
        }
        method CreateMESFET {line netlistObj} {
            set line [string map {", " "," " ," "," " , " ","} $line]
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 pin3 modelVal
            set lineList [lremove $lineList 0 1 2 3 4]
            set elemName [string range $elemName 1 end]
            set paramsList {}
            if {[set offIndex [lsearch -exact $lineList off]]!=-1} {
                lappend paramsList -off
                set lineList [lremove $lineList $offIndex]
            }
            set i 0
            foreach word $lineList {
                if {[regexp {ic=([^,]+),([^,]+)} $word match val1 val2]} {
                    lappend paramsList -ic [list $val1 $val2]
                    set lineList [lremove $lineList $i]
                    break
                }
                incr i
            }
            if {[my CheckBraced [@ $lineList 0]]} {
                lappend paramsList -area [list [my Unbrace [@ $lineList 0]] -eq]
                set lineList [lremove $lineList 0]
            } elseif {[my CheckNumber [@ $lineList 0]]} {
                lappend paramsList -area [@ $lineList 0]
                set lineList [lremove $lineList 0]
            }
            if {[my CheckModelName $modelVal]} {
                $netlistObj add [Z new $elemName $pin1 $pin2 $pin3 -model $modelVal {*}$paramsList]
            } else {
                return -code error "Creating MESFET object from line '${line}' failed due to wrong or incompatible\
                        syntax"
            }
        }
    }

}
