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

    oo::configurable create Parser {
        variable Name
        property filepath
        variable filepath
        variable FileData
        variable SubcktsBoundaries
        variable ElemsMethods
        variable DotsMethods
        variable SupModelsTypes
        property topnetlist
        variable topnetlist
        variable ModelTemplate
        variable SubcircuitTemplate
        variable NamespacePath

        constructor {name filepath} {
            set Name $name 
            my configure -filepath $filepath
            set ElemsMethods [dcreate b CreateBehSource c CreateCap d CreateDio e CreateVCVS f CreateCCCS\
                                      g CreateVCCS h CreateCCVS i CreateVIsource j CreateJFET k CreateCoupling\
                                      l CreateInd m CreateMOSFET n CreateVeriloga q CreateBJT r CreateRes\
                                      s CreateVSwitch v CreateVIsource w CreateCSwitch x CreateSubcktInst\
                                      z CreateMESFET]
            set DotsMethods [dcreate ac CreateAc dc CreateDc func CreateFunc global CreateGlobal ic CreateIc\
                                     include CreateInclude model CreateModel nodeset CreateNodeset op CreateOp\
                                     options CreateOptions param CreateParam sens CreateSens sp CreateSp\
                                     temp CreateTemp tran CreateTran params CreateParam lib CreateLib\
                                     option CreateOptions]
            set SupModelsTypes {r c l sw csw d npn pnp njf pjf nmos pmos nmf pmf}
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
                    set pins @pins@
                    set params @params@
                    next @subname@ $pins $params
                }
            }}
            set NamespacePath ::SpiceGenTcl::Ngspice
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
            # remove all end of line comments that starts with symbols \;, \$ and //
            foreach line $finalList {
                if {[set index [string first {;} $line]]!=-1} {
                    set line [string trim [string range $line 0 [= {$index-1}]]]
                } elseif {[set index [string first {$} $line]]!=-1} {
                    set line [string trim [string range $line 0 [= {$index-1}]]]
                } elseif {[set index [string first {//} $line]]!=-1} {
                    set line [string trim [string range $line 0 [= {$index-1}]]]
                }
                lappend tempList $line
            }
            set finalList $tempList
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
                lappend finalList1 [string map [list "\{ " "\{" " \}" "\}" " = " "=" " =" "=" "= " "="] $line]
            }
            set FileData $finalList1
            return
        }
        method getSubcircuitLines {} {
            # Parses line by line and get start and the end of subcircuits
            if {![info exists FileData]} {
                error "Parser object '[my configure -name]' doesn't have prepared data"
            }
            set fileData $FileData
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
                set SubcktsBoundaries $subckts
            }
            return
        }
        method buildTopNetlist {} {
            # Builds top netlist corresponding to parsed netlist file
            set allLines $FileData
            set topNetlist [my configure -topnetlist]
            my getSubcircuitLines
            # parse found subcircuits definitions first
            if {[info exists SubcktsBoundaries]} {
                set subcktsBoundaries $SubcktsBoundaries
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
            set allLines $FileData
            set topNetlist [my configure -topnetlist]
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
            set elems [dkeys $ElemsMethods]
            set dots [dkeys $DotsMethods]
            for {set i 0} {$i<[llength $lines]} {incr i} {
                set line [@ $lines $i]
                set lineList [split $line]
                set firstWord [@ $lineList 0]
                set firstChar [string index $firstWord 0]
                set restChars [string range $firstWord 1 end]
                if {$firstChar eq {.}} {
                    if {$restChars in $dots} {
                        my [dict get $DotsMethods $restChars] $line $netlistObj
                    } else {
                        puts "Line '$lineList' contains unsupported dot statement '$firstWord', skip that line"
                        continue
                    }
                } elseif {[string match {[a-z]} $firstChar]} {
                    if {$firstChar in $elems} {
                        my [dict get $ElemsMethods $firstChar] $line $netlistObj
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
                    } elseif {$format eq {list}} {
                        set nameValue [list $name $value]
                    }
                } elseif {[my CheckBracedWithEqual $elem]} {
                    lassign [my ParseBracedWithEqual $elem] name value
                    if {$format eq {arg}} {
                        set nameValue [list -$name [list $value -eq]]
                    } elseif {$format eq {list}} {
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
                    } elseif {$format eq {list}} {
                        set nameValue [list $name $value]
                    }
                } elseif {[my CheckBracedWithEqual $elem]} {
                    lassign [my ParseBracedWithEqual $elem] name value
                    if {$format eq {arg}} {
                        set nameValue [list -$name [list $value -eq]]
                    } elseif {$format eq {list}} {
                        set nameValue [list $name $value -eq]
                    }
                } elseif {[regexp {^[a-zA-Z0-9]+$} $elem]} {
                    set name $elem
                    set value {}
                    if {$format eq {arg}} {
                        set nameValue -$name
                    } elseif {$format eq {list}} {
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
                } elseif {$format eq {list}} {
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
            # Returns: string without braces, 
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
        method CheckNumber {string} {
            # Checks if string is a valid float string, acceptable by SPICE syntax
            #   string - input string
            # Returns: boolean value
            if {[regexp {^([+-]?\d+(\.\d*)?([eE][+-]?\d+)?)(f|p|n|u|m|k|g|t|meg)?([a-zA-Z]*)$} $string]} {
                return true
            } else {
                return false
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
        method CreateModel {line netlistObj} {
            # Creates model object from passed line and add it to netlist
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #     element should be attached.
            set line [regsub -all {[[:space:]]+} [string trim [string map {"(" " " ")" " "} $line]] { }]
            set lineList [lrange [split $line] 1 end]
            lassign $lineList name type
            if {![my CheckModelName $name]} {
                return -code error "Model name '${name}' contains illegal characters"
            }
            set paramsList [my ParseParams $lineList 2]
            if {$type ni $SupModelsTypes} {
                set modelClassName [string totitle $type]Model
                puts "Model type '${type}' is not in the list of supported types, custom type '${modelClassName}' was\
                        created"
                set paramString [string map {- {}} [join [dkeys $paramsList]]]
                eval [string map [list @type@ $modelClassName @paramsList@ $paramString] $ModelTemplate]
                $netlistObj add [$modelClassName new $name {*}$paramsList]
            } else {
                switch $type {
                    r {
                        $netlistObj add [${NamespacePath}::BasicDevices::RModel new $name {*}$paramsList]
                    }
                    c {
                        $netlistObj add [${NamespacePath}::BasicDevices::CModel new $name {*}$paramsList]
                    }
                    l {
                        $netlistObj add [${NamespacePath}::BasicDevices::LModel new $name {*}$paramsList]
                    }
                    sw {
                        $netlistObj add [${NamespacePath}::BasicDevices::VSwitchModel new $name {*}$paramsList]
                    }
                    csw {
                        $netlistObj add [${NamespacePath}::BasicDevices::CSwitchModel new $name {*}$paramsList]
                    }
                    d {
                        $netlistObj add [${NamespacePath}::SemiconductorDevices::DiodeModel new $name {*}$paramsList]
                    }
                    npn -
                    pnp {
                        if {{-level} in [dkeys $paramsList]} {
                            set level [dget $paramsList -level]
                            if {$level==1} {
                                set paramsList [dict remove $paramsList -level]
                                $netlistObj add [${NamespacePath}::SemiconductorDevices::BjtGPModel new $name\
                                                         $type {*}$paramsList]
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
                            $netlistObj add [${NamespacePath}::SemiconductorDevices::BjtGPModel new $name $type\
                                                     {*}$paramsList]
                        }
                    }
                    njf -
                    pjf {
                        if {{-level} in [dkeys $paramsList]} {
                            set level [dget $paramsList -level]
                            if {$level==1} {
                                set paramsList [dict remove $paramsList -level]
                                $netlistObj add [${NamespacePath}::SemiconductorDevices::Jfet1Model new $name $type\
                                                         {*}$paramsList]
                            } elseif {$level==2} {
                                set paramsList [dict remove $paramsList -level]
                                $netlistObj add [${NamespacePath}::SemiconductorDevices::Jfet2Model new $name $type\
                                                         {*}$paramsList]
                            } else {
                                puts "Level '${level}' of JFET model in line '${line}' is not supported, skip that line"
                            }
                        } else {
                            $netlistObj add [${NamespacePath}::SemiconductorDevices::Jfet1Model new $name $type\
                                                     {*}$paramsList]
                        }
                    }
                    nmf -
                    pmf {
                        if {{-level} in [dkeys $paramsList]} {
                            set level [dget $paramsList -level]
                            if {$level==1} {
                                set paramsList [dict remove $paramsList -level]
                                $netlistObj add [${NamespacePath}::SemiconductorDevices::Mesfet1Model new $name $type\
                                                         {*}$paramsList]
                            } else {
                                puts "Level '${level}' of MESFET in line '${line}' is not supported, skip that line"
                            }
                        } else {
                            $netlistObj add [${NamespacePath}::SemiconductorDevices::Mesfet1Model new $name $type\
                                                     {*}$paramsList]
                        }
                    }
                }
            }
            return
        }
        method CreateOp {line netlistObj} {
            # Creates `::SpiceGenTcl::Ngspice::` object from passed line and add it to netlist
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
            $netlistObj add [${NamespacePath}::Analyses::Op new]
            return
        }
        method CreateAc {line netlistObj} {
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
            set lineList [lrange [split $line] 1 end]
            $netlistObj add [${NamespacePath}::Analyses::Ac new\
                                     {*}[my ParsePosParams $lineList {variation n fstart fstop}]]
            return
        }
        method CreateDc {line netlistObj} {
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
            set lineList [lrange [split $line] 1 end]
            set paramsNames {src start stop incr}
            if {[llength $lineList]>[llength $paramsNames]} {
                puts "DC analysis with multiple sources is not supported in SpiceGenTcl, skip the other sources in line\
                        '${line}'"
            }
            $netlistObj add [${NamespacePath}::Analyses::Dc new {*}[my ParsePosParams $lineList $paramsNames]]
            return
        }
        method CreateTran {line netlistObj} {
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
            set lineList [lrange [split $line] 1 end]
            set paramsNames {tstep tstop tstart tmax}
            if {[set index [lsearch -exact $lineList uic]]!=-1} {
                set lineList [lremove $lineList $index]
                set configParams [linsert [my ParsePosParams $lineList $paramsNames] end -uic]
                $netlistObj add [${NamespacePath}::Analyses::Tran new {*}$configParams]
            } else {
                $netlistObj add [${NamespacePath}::Analyses::Tran new {*}[my ParsePosParams $lineList $paramsNames]]
            }
            return
        }
        method CreateSens {line netlistObj} {
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
            if {[regexp {(v|i)\(([^{}()=]+)\)} $line]} {
                set line [regsub -command {(v|i)\(([^{}()=]+)\)} $line {apply {{- a b} {
                    format %s(%s) $a [string map {" " ""} $b]
                }}}]
                set lineList [lrange [split $line] 1 end]
                if {[@ $lineList 1] eq {}} {
                    $netlistObj add [${NamespacePath}::Analyses::SensDc new -outvar [@ $lineList 0]]
                } elseif {[@ $lineList 1] eq {ac}} {
                    set lineList [lremove $lineList 1]
                    set paramsNames {outvar variation n fstart fstop}
                    $netlistObj add [${NamespacePath}::Analyses::SensAc new\
                                             {*}[my ParsePosParams $lineList $paramsNames]]
                } else {
                    error "Sense analysis has usupported type '[@ $lineList 1]'"
                }
            } else {
                error "Sense analysis in line '${line}' doesn't have output variable with proper syntax"
            }
            return
        }
        method CreateSp {line netlistObj} {
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
            set lineList [lrange [split $line] 1 end]
            set paramsNames {variation n fstart fstop}
            if {[@ $lineList 4]==1} {
                set lineList [lremove $lineList 4]
                set configParams [linsert [my ParsePosParams $lineList $paramsNames] end -donoise]
                $netlistObj add [${NamespacePath}::Analyses::Sp new {*}$configParams]
            } else {
                $netlistObj add [${NamespacePath}::Analyses::Sp new {*}[my ParsePosParams $lineList $paramsNames]]
            }
            return
        }
        method CreateFunc {line netlistObj} {

        }
        method CreateGlobal {line netlistObj} {
            set lineList [lrange [split $line] 1 end]
            $netlistObj add [::SpiceGenTcl::Global new $lineList]
            return
        }
        method CreateIc {line netlistObj} {
            set lineList [lrange [split $line] 1 end]
            $netlistObj add [::SpiceGenTcl::Ic new [my ParseParams $lineList 0 {} list]]
            return
        }
        method CreateInclude {line netlistObj} {
            set value [join [lrange [split $line] 1 end]]
            $netlistObj add [::SpiceGenTcl::Include new $value]
            return
        }
        method CreateLib {line netlistObj} {
            set lineList [split $line]
            set value [lrange $lineList 1 end-1]
            set libValue [@ $lineList end]
            $netlistObj add [::SpiceGenTcl::Library new $value $libValue]
            return
        }
        method CreateNodeset {line netlistObj} {
            set lineList [lrange [split $line] 1 end]
            $netlistObj add [::SpiceGenTcl::Nodeset new [my ParseParams $lineList 0 {} list]]
            return 
        }
        method CreateOptions {line netlistObj} {
            set lineList [lrange [split $line] 1 end]
            $netlistObj add [::SpiceGenTcl::Ngspice::Misc::OptionsNgspice new\
                                     {*}[my ParseMixedParams $lineList 0 {} arg]]
            return
        }
        method CreateParam {line netlistObj} {
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
            set lineList [lrange [split $line] 1 end]
            $netlistObj add [::SpiceGenTcl::ParamStatement new [my ParseParams $lineList 0 {} list]]
            return
        }
        method CreateTemp {line netlistObj} {
            set lineList [lrange [split $line] 1 end]
            lassign $lineList value
            if {[my CheckBraced $value]} {
                set value [list [my Unbrace $value] -eq]
            }
            $netlistObj add [::SpiceGenTcl::Temp new {*}$value]
            return
        }
        method CreateRes {line netlistObj} {
            # Creates resistor object from passed line and add it to netlist
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
            # Supports behavioural resistor in form `r={equation}`, `r=equation` or `r='equation'` and only braced form
            # `name={value}` of parameters.
            set origLine $line
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 rval fourth
            set elemName [string range $elemName 1 end]
            set excludePars {r model beh}
            set nmspPath ${NamespacePath}::BasicDevices::R
            set pattern {(r=([^\r\n=]+(?:\s*[\+\-\*\/]\s*[^\r\n=]+)*))\s*(?:\s+\S+\s*=\s*\S+)*?\s*$}
            set line [join [lrange $lineList 3 end]]
            if {[regexp $pattern $line match expr value]} {
                if {[my CheckBraced $value]} {
                    set value [my Unbrace $value]
                } elseif {[my CheckQuoted $value]} {
                    set value [my Unquote $value]
                }
                set line [string trim [string map [list $expr {}] $line]]
                $netlistObj add [$nmspPath new $elemName $pin1 $pin2 -r $value -beh\
                                         {*}[my ParseParams [split $line] 0 {}]]
            } elseif {[my CheckModelName $fourth]} {
                # check if fourth element in line is a valid model name. It process the case when resistor with model
                # also specified with resistance value
                if {[my CheckBraced $rval]} {
                    # check if rval has form '{param}'
                    set rval [list [my Unbrace $rval] -eq]
                    $netlistObj add [$nmspPath new $elemName $pin1 $pin2 -r $rval -model $fourth\
                                             {*}[my ParseParams $lineList 5 $excludePars]]
                } elseif {[my CheckNumber $rval]} {
                    # check if rval is a valid float value
                    $netlistObj add [$nmspPath new $elemName $pin1 $pin2 -r $rval -model $fourth\
                                             {*}[my ParseParams $lineList 5 $excludePars]]
                } else {
                    return -code error "Creating resistor object from line '${origLine}' failed due to wrong or\
                            incompatible syntax"
                }
            } else {
                if {[my CheckBraced $rval]} {
                    # check if rval has form `{param}`
                    set rval [list [my Unbrace $rval] -eq]
                    $netlistObj add [$nmspPath new $elemName $pin1 $pin2 -r $rval\
                                             {*}[my ParseParams $lineList 4 $excludePars]]
                } elseif {[my CheckNumber $rval]} {
                    # check if rval is a valid float value
                    $netlistObj add [$nmspPath new $elemName $pin1 $pin2 -r $rval\
                                             {*}[my ParseParams $lineList 4 $excludePars]]
                } elseif {[my CheckModelName $rval]} {
                    # check if rval contains valid model value
                    $netlistObj add [$nmspPath new $elemName $pin1 $pin2 -model $rval\
                                             {*}[my ParseParams $lineList 4 $excludePars]]
                } else {
                    return -code error "Creating resistor object from line '${origLine}' failed due to wrong or\
                            incompatible syntax"
                }
            }
            return
        }
        method CreateCap {line netlistObj} {
            # Creates capacitor object from passed line and add it to netlist
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
            # Supports behavioural capacitor in form `q|c={equation}`, `q|c=equation` or `q|c='equation'` and only braced 
            # form `name={value}` of parameters.
            set origLine $line
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 cval fourth
            set elemName [string range $elemName 1 end]
            set excludePars {c q model beh}
            set nmspPath ${NamespacePath}::BasicDevices::C
            set pattern {((q|c)=([^\r\n=]+(?:\s*[\+\-\*\/]\s*[^\r\n=]+)*))\s*(?:\s+\S+\s*=\s*\S+)*?\s*$}
            set line [join [lrange $lineList 3 end]]
            if {[regexp $pattern $line match expr type value]} {
                if {[my CheckBraced $value]} {
                    set value [my Unbrace $value]
                } elseif {[my CheckQuoted $value]} {
                    set value [my Unquote $value]
                }
                set line [string trim [string map [list $expr {}] $line]]
                $netlistObj add [$nmspPath new $elemName $pin1 $pin2 -$type $value -beh\
                                         {*}[my ParseParams [split $line] 0 {}]]
            } elseif {[my CheckModelName $fourth]} {
                if {[my CheckBraced $cval]} {
                    set cval [list [my Unbrace $cval] -eq]
                    $netlistObj add [$nmspPath new $elemName $pin1 $pin2 -c $cval -model\
                                             $fourth {*}[my ParseParams $lineList 5 $excludePars]]
                } elseif {[my CheckNumber $rval]} {
                    $netlistObj add [$nmspPath new $elemName $pin1 $pin2 -c $cval -model\
                                             $fourth {*}[my ParseParams $lineList 5 $excludePars]]
                } else {
                    return -code error "Creating capacitor object from line '${origLine}' failed due to wrong or\
                            incompatible syntax"
                }
            } else {
                if {[my CheckBraced $cval]} {
                    set cval [list [my Unbrace $cval] -eq]
                    $netlistObj add [$nmspPath new $elemName $pin1 $pin2 -c $cval\
                                             {*}[my ParseParams $lineList 4 $excludePars]]
                } elseif {[my CheckNumber $cval]} {
                    $netlistObj add [$nmspPath new $elemName $pin1 $pin2 -c $cval\
                                             {*}[my ParseParams $lineList 4 $excludePars]]
                } elseif {[my CheckModelName $cval]} {
                    $netlistObj add [$nmspPath new $elemName $pin1 $pin2 -model $cval\
                                             {*}[my ParseParams $lineList 4 $excludePars]]
                } else {
                    return -code error "Creating capacitor object from line '${origLine}' failed due to wrong or\
                            incompatible syntax"
                }
            }
            return
        }
        method CreateCoupling {line netlistObj} {
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
            set lineList [split $line]
            lassign $lineList elemName l1 l2 kval
            set elemName [string range $elemName 1 end]
            set nmspPath ${NamespacePath}::BasicDevices::K
            if {[my CheckBraced $kval]} {
                set kval [list [my Unbrace $kval] -eq]
            }
            $netlistObj add [$nmspPath new $elemName -l1 $l1 -l2 $l2 -k $kval]
            return
        }
        method CreateInd {line netlistObj} {
            # Creates inductor object from passed line and add it to netlist
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
            # Supports behavioural inductor only in form `l={equation}`, `l=equation` or `l='equation'` and only braced 
            # form `name={value}` of parameters.
            set origLine $line
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 lval fourth
            set elemName [string range $elemName 1 end]
            set excludePars {l model beh}
            set nmspPath ${NamespacePath}::BasicDevices::L
            set pattern {(l=([^\r\n=]+(?:\s*[\+\-\*\/]\s*[^\r\n=]+)*))\s*(?:\s+\S+\s*=\s*\S+)*?\s*$}
            set line [join [lrange $lineList 3 end]]
            if {[regexp $pattern $line match expr value]} {
                if {[my CheckBraced $value]} {
                    set value [my Unbrace $value]
                } elseif {[my CheckQuoted $value]} {
                    set value [my Unquote $value]
                }
                set line [string trim [string map [list $expr {}] $line]]
                $netlistObj add [$nmspPath new $elemName $pin1 $pin2 -l $value -beh\
                                         {*}[my ParseParams [split $line] 0 {}]]
            } elseif {[my CheckModelName $fourth]} {
                if {[my CheckBraced $lval]} {
                    set lval [list [my Unbrace $lval] -eq]
                    $netlistObj add [$nmspPath new $elemName $pin1 $pin2 -l $lval -model\
                                             $fourth {*}[my ParseParams $lineList 5 $excludePars]]
                } elseif {[my CheckNumber $lval]} {
                    $netlistObj add [$nmspPath new $elemName $pin1 $pin2 -l $lval -model\
                                             $fourth {*}[my ParseParams $lineList 5 $excludePars]]
                } else {
                    return -code error "Creating inductor object from line '${origLine}' failed due to wrong or\
                            incompatible syntax"
                }
            } else {
                if {[my CheckBraced $lval]} {
                    set lval [list [my Unbrace $lval] -eq]
                    $netlistObj add [$nmspPath new $elemName $pin1 $pin2 -l $lval\
                                             {*}[my ParseParams $lineList 4 $excludePars]]
                } elseif {[my CheckNumber $lval]} {
                    $netlistObj add [$nmspPath new $elemName $pin1 $pin2 -l $lval\
                                             {*}[my ParseParams $lineList 4 $excludePars]]
                } elseif {[my CheckModelName $lval]} {
                    $netlistObj add [$nmspPath new $elemName $pin1 $pin2 -model $lval\
                                             {*}[my ParseParams $lineList 4 $excludePars]]
                } else {
                    return -code error "Creating inductor object from line '${origLine}' failed due to wrong or\
                            incompatible syntax"
                }
            }
            return
        }
        method CreateBehSource {line netlistObj} {
            # Creates behavioural source object from passed line and add it to netlist
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
            # Supports behavioural sources in forms `v|i={equation}`, `v|i=equation` or `v|i='equation'` and only braced
            # form `name={value}` of parameters.
            set origLine $line
            set pattern {((i|v)=([^\r\n=]+(?:\s*[\+\-\*\/]\s*[^\r\n=]+)*))\s*(?:\s+\S+\s*=\s*\S+)*?\s*$}
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2
            set elemName [string range $elemName 1 end]
            set line [join [lrange $lineList 3 end]]
            if {[regexp $pattern $line match expr type value]} {
                if {[my CheckBraced $value]} {
                    set value [my Unbrace $value]
                } elseif {[my CheckQuoted $value]} {
                    set value [my Unquote $value]
                }
                set line [string trim [string map [list $expr {}] $line]]
                $netlistObj add [${NamespacePath}::Sources::B new $elemName $pin1 $pin2 -$type $value\
                                         {*}[my ParseParams [split $line] 0 {}]]
            } else {
                return -code error "Creating behavioural source object from line '${origLine}' failed due to wrong or\
                            incompatible syntax"
            }
            return
        }
        method CreateDio {line netlistObj} {
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 modelVal
            set elemName [string range $elemName 1 end]
            if {[set offIndex [lsearch -exact $lineList off]]!=-1} {
                lappend paramsList -off
                set lineList [lremove $lineList $offIndex]
            }
            if {[my CheckModelName $modelVal]} {
                lappend paramsList {*}[my ParseParams [lrange $lineList 1 end] 3 {}]
                $netlistObj add [${NamespacePath}::SemiconductorDevices::D new $elemName $pin1 $pin2 -model $modelVal\
                                         {*}$paramsList]
            }
        }
        method CreateVCVS {line netlistObj} {
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 pin3 pin4 val
            set elemName [string range $elemName 1 end]
            if {[my CheckBraced $val]} {
                set val [list [my Unbrace $val] -eq]
                $netlistObj add [${NamespacePath}::Sources::E new $elemName $pin1 $pin2 $pin3 $pin4 -gain $val]
            } elseif {[my CheckNumber $val]} {
                $netlistObj add [${NamespacePath}::Sources::E new $elemName $pin1 $pin2 $pin3 $pin4 -gain $val]
            } else {
                return -code error "Creating VCVS object from line '${line}' failed due to wrong or incompatible syntax"
            }
            return
        }
        method CreateCCCS {line netlistObj} {
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 vnam val
            set elemName [string range $elemName 1 end]
            if {[my CheckBraced $val]} {
                set val [list [my Unbrace $val] -eq]
                $netlistObj add [${NamespacePath}::Sources::F new $elemName $pin1 $pin2 -consrc $vnam -gain $val\
                                         {*}[my ParseParams $lineList 6]]
            } elseif {[my CheckNumber $val]} {
                $netlistObj add [${NamespacePath}::Sources::F new $elemName $pin1 $pin2 -consrc $vnam -gain $val\
                                         {*}[my ParseParams $lineList 6]]
            } else {
                return -code error "Creating CCCS object from line '${line}' failed due to wrong or incompatible syntax"
            }
            return
        }
        method CreateVCCS {line netlistObj} {
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 pin3 pin4 val
            set elemName [string range $elemName 1 end]
            if {[my CheckBraced $val]} {
                set val [list [my Unbrace $val] -eq]
                $netlistObj add [${NamespacePath}::Sources::G new $elemName $pin1 $pin2 $pin3 $pin4 -trcond $val\
                                         {*}[my ParseParams $lineList 6]]
            } elseif {[my CheckNumber $val]} {
                $netlistObj add [${NamespacePath}::Sources::G new $elemName $pin1 $pin2 $pin3 $pin4 -trcond $val\
                                         {*}[my ParseParams $lineList 6]]
            } else {
                return -code error "Creating VCCS object from line '${line}' failed due to wrong or incompatible syntax"
            }
            return
        }
        method CreateCCVS {line netlistObj} {
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 vnam val
            set elemName [string range $elemName 1 end]
            if {[my CheckBraced $val]} {
                set val [list [my Unbrace $val] -eq]
                $netlistObj add [${NamespacePath}::Sources::H new $elemName $pin1 $pin2 -consrc $vnam -transr $val]
            } elseif {[my CheckNumber $val]} {
                $netlistObj add [${NamespacePath}::Sources::H new $elemName $pin1 $pin2 -consrc $vnam -transr $val]
            } else {
                return -code error "Creating CCVS object from line '${line}' failed due to wrong or incompatible syntax"
            }
            return
        }
        method CreateJFET {line netlistObj} {
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
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
                $netlistObj add [${NamespacePath}::SemiconductorDevices::J new $elemName $pin1 $pin2 $pin3 -model\
                                         $modelVal {*}$paramsList]
            } else {
                return -code error "Creating JFET object from line '${line}' failed due to wrong or incompatible syntax"
            }
        }
       
        method CreateMOSFET {line netlistObj} {
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
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
                $netlistObj add [${NamespacePath}::SemiconductorDevices::M new $elemName $pin1 $pin2 $pin3\
                                         -model $modelVal {*}$paramsList]
            } else {
                return -code error "Creating MOSFET object from line '${line}' failed due to wrong or incompatible\
                        syntax"
            }
        }
        method CreateVeriloga {line netlistObj} {

        }
        method CreateBJT {line netlistObj} {
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
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
                $netlistObj add [${NamespacePath}::SemiconductorDevices::Q new $elemName $pin1 $pin2 $pin3\
                                         -model $modelVal {*}$paramsList]
            } else {
                return -code error "Creating BJT object from line '${line}' failed due to wrong or incompatible syntax"
            }
        }
        method CreateVSwitch {line netlistObj} {
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 pin3 pin4 model state
            set elemName [string range $elemName 1 end]
            set paramsList {}
            if {$state in {on off}} {
                lappend paramsList -$state
            }
            $netlistObj add [${NamespacePath}::BasicDevices::S new $elemName $pin1 $pin2 $pin3 $pin4 -model $model\
                                     {*}$paramsList]
            return
        }
        method CreateVIsource {line netlistObj} {
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
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
            set nmspPath ${NamespacePath}::Sources
            switch [@ $lineList 0] {
                pulse {
                    lappend paramsList {*}[my ParsePosParams [lrange $lineList 1 end] [dget $functsDict pulse]]
                    $netlistObj add [${nmspPath}::[string toupper ${type}]pulse new $elemName $pin1 $pin2 {*}$paramsList]
                }
                sin {
                    lappend paramsList {*}[my ParsePosParams [lrange $lineList 1 end] [dget $functsDict sin]]
                    $netlistObj add [${nmspPath}::[string toupper ${type}]sin new $elemName $pin1 $pin2 {*}$paramsList]
                }
                exp {
                    lappend paramsList {*}[my ParsePosParams [lrange $lineList 1 end] [dget $functsDict exp]]
                    $netlistObj add [${nmspPath}::[string toupper ${type}]exp new $elemName $pin1 $pin2 {*}$paramsList]
                }
                pwl {
                    foreach value [lrange $lineList 1 end] {
                        if {[my CheckBraced $value]} {
                            set value [list [my Unbrace $value] -eq]
                        } 
                        lappend seqList $value
                    }
                    lappend paramsList -seq $seqList
                    $netlistObj add [${nmspPath}::[string toupper ${type}]pwl new $elemName $pin1 $pin2 {*}$paramsList]
                }
                sffm {
                    lappend paramsList {*}[my ParsePosParams [lrange $lineList 1 end] [dget $functsDict sffm]]
                    $netlistObj add [${nmspPath}::[string toupper ${type}]sffm new $elemName $pin1 $pin2 {*}$paramsList]
                }
                am {
                    lappend paramsList {*}[my ParsePosParams [lrange $lineList 1 end] [dget $functsDict am]]
                    $netlistObj add [${nmspPath}::[string toupper ${type}]am new $elemName $pin1 $pin2 {*}$paramsList]
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
                    $netlistObj add [${nmspPath}::Vport new $elemName $pin1 $pin2 -portnum $portnumVal {*}$paramsList]
                }
                default {
                    if {$acType} {
                        $netlistObj add [${nmspPath}::[string toupper ${type}]ac new $elemName $pin1 $pin2\
                                                 {*}$paramsList]
                    } else {
                        $netlistObj add [${nmspPath}::[string toupper ${type}]dc new $elemName $pin1 $pin2\
                                                 {*}$paramsList]
                    }
                }
            }
            return
        }
        method CreateCSwitch {line netlistObj} {
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 vnam model state
            set elemName [string range $elemName 1 end]
            set paramsList {}
            if {$state in {on off}} {
                lappend paramsList -$state
            }
            $netlistObj add [${NamespacePath}::BasicDevices::W new $elemName $pin1 $pin2 -icntrl $vnam -model $model\
                                     {*}$paramsList]
            return
        }
        method CreateSubcktInst {line netlistObj} {
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
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
            $netlistObj add [${NamespacePath}::BasicDevices::X new $elemName $pins $subName\
                                     [my ParseParams $lineList $paramsStartIndex {} list]]
            return
        }
        method CreateMESFET {line netlistObj} {
            #   line - line to parse
            #   netlistObj - reference to the object of class `::SpiceGenTcl::Netlist` (and its children) to which the 
            #   element should be attached.
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
                $netlistObj add [${NamespacePath}::SemiconductorDevices::Z new $elemName $pin1 $pin2 $pin3\
                                         -model $modelVal {*}$paramsList]
            } else {
                return -code error "Creating MESFET object from line '${line}' failed due to wrong or incompatible\
                        syntax"
            }
        }
    }
}
