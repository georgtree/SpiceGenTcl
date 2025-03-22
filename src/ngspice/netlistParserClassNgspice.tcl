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

    namespace export NgspiceParser

    oo::configurable create NgspiceParser {
        superclass ::SpiceGenTcl::Parser
        variable parsername
        variable filepath
        variable FileData
        variable SubcktsTree
        variable ElemsMethods
        variable DotsMethods
        variable SupModelsTypes
        variable topnetlist
        variable ModelTemplate
        variable SubcircuitTemplate
        variable NamespacePath

        constructor {name filepath} {
            # Creates object of class `Parser` that do parsing of valid Ngspice netlist.
            #   name - name of the object
            #   filepath - path to file that should be parsed
            set ElemsMethods [dcreate b CreateBehSource c CreateCap d CreateDio e CreateVCVS f CreateCCCS\
                                      g CreateVCCS h CreateCCVS i CreateVIsource j CreateJFET k CreateCoupling\
                                      l CreateInd m CreateMOSFET n CreateVerilogA q CreateBJT r CreateRes\
                                      s CreateVSwitch v CreateVIsource w CreateCSwitch x CreateSubcktInst\
                                      z CreateMESFET]
            set DotsMethods [dcreate ac CreateAc dc CreateDc func CreateFunc global CreateGlobal ic CreateIc\
                                     include CreateInclude model CreateModel nodeset CreateNodeset op CreateOp\
                                     options CreateOptions option CreateOptions opt CreateOptions param CreateParam\
                                     temp CreateTemp tran CreateTran params CreateParam lib CreateLib\
                                     sens CreateSens sp CreateSp save CreateSave]
            set SupModelsTypes {r c l sw csw d npn pnp njf pjf nmf pmf}
            set NamespacePath ::SpiceGenTcl::Ngspice
            next $name $filepath
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
                    lappend lines $processedLine
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
                        ##nagelfar variable startIndex
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
            # convert each line to lower case except lines that contains paths in .lib or .include statements
            foreach line $finalList {
                set tempLine [string tolower $line]
                if {[regexp {^\.(include|lib).*} $tempLine]} {
                    lappend tempList $line
                } else {
                    lappend tempList $tempLine
                }
            }
            set finalList $tempList
            unset tempList
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
        method CheckVectorName {string} {
            # Checks if string is a valid vector name string, acceptable by SPICE syntax
            #   string - input string
            # Returns: boolean value
            if {[regexp {^([a-zA-Z0-9]+|[vi]\([a-zA-Z0-9]+\)|[a-zA-Z0-9]+#[a-zA-Z0-9]+|@[a-zA-Z0-9]+\[[a-zA-Z0-9]+\])$} $string]} {
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
        method CreateModel {line} {
            # Creates [::SpiceGenTcl::Model] object from passed line and add it to `netlistObj`
            #   line - line to parse
            # Returns: code string for model object creation
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
                return [list [string map [list @type@ $modelClassName @paramsList@ $paramString] $ModelTemplate]\
                                [list $modelClassName new $name {*}$paramsList]]
            } else {
                switch $type {
                    r {
                        return [list ${NamespacePath}::BasicDevices::RModel new $name {*}$paramsList]
                    }
                    c {
                        return [list ${NamespacePath}::BasicDevices::CModel new $name {*}$paramsList]
                    }
                    l {
                        return [list ${NamespacePath}::BasicDevices::LModel new $name {*}$paramsList]
                    }
                    sw {
                        return [list ${NamespacePath}::BasicDevices::VSwitchModel new $name {*}$paramsList]
                    }
                    csw {
                        return [list ${NamespacePath}::BasicDevices::CSwitchModel new $name {*}$paramsList]
                    }
                    d {
                        return [list ${NamespacePath}::SemiconductorDevices::DiodeModel new $name {*}$paramsList]
                    }
                    npn -
                    pnp {
                        if {{-level} in [dkeys $paramsList]} {
                            set level [dget $paramsList -level]
                            if {$level==1} {
                                set paramsList [dict remove $paramsList -level]
                                return [list ${NamespacePath}::SemiconductorDevices::BjtGPModel new $name\
                                                         $type {*}$paramsList]
                            } elseif {$level in {4 8}} {
                                puts "Level '${level}' of type '${type}' model '${name}' is not in the list of\
                                        SpiceGenTcl supported levels, custom level model was created"
                                set paramString [string map {- {}} [join [dkeys $paramsList]]]
                                set modelClassName [string totitle $type]Model
                                return [list [string map [list @type@ $modelClassName @paramsList@ $paramString] $ModelTemplate]\
                                                [list $modelClassName new $name {*}$paramsList]]
                            } else {
                                puts "Level '${level}' of BJT model in line '${line}' is not supported, skip that line"
                            }
                        } else {
                            return [list ${NamespacePath}::SemiconductorDevices::BjtGPModel new $name $type\
                                            {*}$paramsList]
                        }
                    }
                    njf -
                    pjf {
                        if {{-level} in [dkeys $paramsList]} {
                            set level [dget $paramsList -level]
                            if {$level==1} {
                                set paramsList [dict remove $paramsList -level]
                                return [list ${NamespacePath}::SemiconductorDevices::Jfet1Model new $name $type\
                                                {*}$paramsList]
                            } elseif {$level==2} {
                                set paramsList [dict remove $paramsList -level]
                                return [list ${NamespacePath}::SemiconductorDevices::Jfet2Model new $name $type\
                                                {*}$paramsList]
                            } else {
                                puts "Level '${level}' of JFET model in line '${line}' is not supported, skip that line"
                            }
                        } else {
                            return [list ${NamespacePath}::SemiconductorDevices::Jfet1Model new $name $type\
                                            {*}$paramsList]
                        }
                    }
                    nmf -
                    pmf {
                        if {{-level} in [dkeys $paramsList]} {
                            set level [dget $paramsList -level]
                            if {$level==1} {
                                set paramsList [dict remove $paramsList -level]
                                return [list ${NamespacePath}::SemiconductorDevices::Mesfet1Model new $name $type\
                                                {*}$paramsList]
                            } else {
                                puts "Level '${level}' of MESFET in line '${line}' is not supported, skip that line"
                            }
                        } else {
                            return [list ${NamespacePath}::SemiconductorDevices::Mesfet1Model new $name $type\
                                            {*}$paramsList]
                        }
                    }
                }
            }
            return
        }
        method CreateOp {line} {
            # Creates [::SpiceGenTcl::Ngspice::Analyses::Op] object from passed line and add it to `netlistObj`
            #   line - line to parse
            # Returns: code string for object creation
            return [list ${NamespacePath}::Analyses::Op new]
        }
        method CreateAc {line} {
            # Creates [::SpiceGenTcl::Ngspice::Analyses::Ac] object from passed line and add it to `netlistObj`
            #   line - line to parse
            # Returns: code string for object creation
            set lineList [lrange [split $line] 1 end]
            return [list ${NamespacePath}::Analyses::Ac new\
                            {*}[my ParsePosParams $lineList {variation n fstart fstop}]]
        }
        method CreateDc {line} {
            # Creates [::SpiceGenTcl::Ngspice::Analyses::Dc] object from passed line and add it to `netlistObj`
            #   line - line to parse
            # Returns: code string for object creation
            set lineList [lrange [split $line] 1 end]
            set paramsNames {src start stop incr}
            if {[llength $lineList]>[llength $paramsNames]} {
                puts "DC analysis with multiple sources is not supported in SpiceGenTcl, skip the other sources in line\
                        '${line}'"
            }
            return [list ${NamespacePath}::Analyses::Dc new {*}[my ParsePosParams $lineList $paramsNames]]
        }
        method CreateTran {line} {
            # Creates [::SpiceGenTcl::Ngspice::Analyses::Tran] object from passed line and add it to `netlistObj`
            #   line - line to parse
            # Returns: code string for object creation
            set lineList [lrange [split $line] 1 end]
            set paramsNames {tstep tstop tstart tmax}
            if {[set index [lsearch -exact $lineList uic]]!=-1} {
                set lineList [lremove $lineList $index]
                set configParams [linsert [my ParsePosParams $lineList $paramsNames] end -uic]
                return [list ${NamespacePath}::Analyses::Tran new {*}$configParams]
            } else {
                return [list ${NamespacePath}::Analyses::Tran new {*}[my ParsePosParams $lineList $paramsNames]]
            }
        }
        method CreateSens {line} {
            # Creates [::SpiceGenTcl::Ngspice::Analyses::Sens] object from passed line and add it to `netlistObj`
            #   line - line to parse
            # Returns: code string for object creation
            if {[regexp {(v|i)\(([^{}()=]+)\)} $line]} {
                ##nagelfar ignore Wrong number of arguments
                set line [regsub -command {(v|i)\(([^{}()=]+)\)} $line {apply {{- a b} {
                    format %s(%s) $a [string map {" " ""} $b]
                }}}]
                set lineList [lrange [split $line] 1 end]
                if {[@ $lineList 1] eq {}} {
                    return [list ${NamespacePath}::Analyses::SensDc new -outvar [@ $lineList 0]]
                } elseif {[@ $lineList 1] eq {ac}} {
                    set lineList [lremove $lineList 1]
                    set paramsNames {outvar variation n fstart fstop}
                    return [list ${NamespacePath}::Analyses::SensAc new\
                                    {*}[my ParsePosParams $lineList $paramsNames]]
                } else {
                    error "Sense analysis has usupported type '[@ $lineList 1]'"
                }
            } else {
                error "Sense analysis in line '${line}' doesn't have output variable with proper syntax"
            }
        }
        method CreateSp {line} {
            # Creates [::SpiceGenTcl::Ngspice::Analyses::Sp] object from passed line and add it to `netlistObj`
            #   line - line to parse
            # Returns: code string for object creation
            set lineList [lrange [split $line] 1 end]
            set paramsNames {variation n fstart fstop}
            if {[@ $lineList 4]==1} {
                set lineList [lremove $lineList 4]
                set configParams [linsert [my ParsePosParams $lineList $paramsNames] end -donoise]
                return [list ${NamespacePath}::Analyses::Sp new {*}$configParams]
            } else {
                return [list ${NamespacePath}::Analyses::Sp new {*}[my ParsePosParams $lineList $paramsNames]]
            }
        }
        method CreateFunc {line} {

        }
        method CreateGlobal {line} {
            # Creates [::SpiceGenTcl::Global] object from passed line and add it to `netlistObj`
            #   line - line to parse
            # Returns: code string for object creation
            set lineList [lrange [split $line] 1 end]
            return [list ::SpiceGenTcl::Global new $lineList]
        }
        method CreateSave {line} {
            # Creates [::SpiceGenTcl::Save] object from passed line and add it to `netlistObj`
            #   line - line to parse
            # Returns: code string for object creation
            set lineList [lrange [split $line] 1 end]
            return [list ::SpiceGenTcl::Save new $lineList]
        }
        method CreateIc {line} {
            # Creates [::SpiceGenTcl::Ic] object from passed line and add it to `netlistObj`
            #   line - line to parse
            # Returns: code string for object creation
            set lineList [lrange [split $line] 1 end]
            return [list ::SpiceGenTcl::Ic new [my ParseParams $lineList 0 {} list]]
        }
        method CreateInclude {line} {
            # Creates [::SpiceGenTcl::Include] object from passed line and add it to `netlistObj`
            #   line - line to parse
            # Returns: code string for object creation
            set value [join [lrange [split $line] 1 end]]
            return [list ::SpiceGenTcl::Include new $value]
        }
        method CreateLib {line} {
            # Creates [::SpiceGenTcl::Library] object from passed line and add it to `netlistObj`
            #   line - line to parse
            # Returns: code string for object creation
            set lineList [split $line]
            set value [lrange $lineList 1 end-1]
            set libValue [@ $lineList end]
            return [list ::SpiceGenTcl::Library new $value $libValue]
        }
        method CreateNodeset {line} {
            # Creates [::SpiceGenTcl::Nodeset] object from passed line and add it to `netlistObj`
            #   line - line to parse
            # Returns: code string for object creation
            set lineList [lrange [split $line] 1 end]
            return [list ::SpiceGenTcl::Nodeset new [my ParseParams $lineList 0 {} list]]
        }
        method CreateOptions {line} {
            # Creates [::SpiceGenTcl::Options] object from passed line and add it to `netlistObj`
            #   line - line to parse
            # Returns: code string for object creation
            set lineList [lrange [split $line] 1 end]
            return [list ::SpiceGenTcl::Ngspice::Misc::OptionsNgspice new\
                            {*}[my ParseMixedParams $lineList 0 {} arg]]
        }
        method CreateParam {line} {
            # Creates [::SpiceGenTcl::ParamStatement] object from passed line and add it to `netlistObj`
            #   line - line to parse
            # Returns: code string for object creation
            set lineList [lrange [split $line] 1 end]
            return [list ::SpiceGenTcl::ParamStatement new [my ParseParams $lineList 0 {} list]]
        }
        method CreateTemp {line} {
            # Creates [::SpiceGenTcl::Temp] object from passed line and add it to `netlistObj`
            #   line - line to parse
            # Returns: code string for object creation
            set lineList [lrange [split $line] 1 end]
            lassign $lineList value
            if {[my CheckBraced $value]} {
                set value [list [my Unbrace $value] -eq]
            }
            return [list ::SpiceGenTcl::Temp new {*}$value]
        }
        method CreateSubcktInst {line} {
            # Creates [::SpiceGenTcl::Ngspice::BasicDevices::X] object from passed line and add it to `netlistObj`
            #   line - line to parse
            # Returns: code string for object creation
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
            return [list ${NamespacePath}::BasicDevices::X new $elemName $pins $subName\
                            [my ParseParams $lineList $paramsStartIndex {} list]]
        }
        method CreateRes {line} {
            # Creates [::SpiceGenTcl::Ngspice::BasicDevices::R] object from passed line and add it to netlist
            #   line - line to parse
            # Returns: code string for object creation
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
                return [list $nmspPath new $elemName $pin1 $pin2 -r $value -beh\
                                {*}[my ParseParams [split $line] 0 {}]]
            } elseif {[my CheckModelName $fourth]} {
                # check if fourth element in line is a valid model name. It process the case when resistor with model
                # also specified with resistance value
                if {[my CheckBraced $rval]} {
                    # check if rval has form '{param}'
                    set rval [list [my Unbrace $rval] -eq]
                    return [list $nmspPath new $elemName $pin1 $pin2 -r $rval -model $fourth\
                                    {*}[my ParseParams $lineList 5 $excludePars]]
                } elseif {[my CheckNumber $rval]} {
                    # check if rval is a valid float value
                    return [list $nmspPath new $elemName $pin1 $pin2 -r $rval -model $fourth\
                                    {*}[my ParseParams $lineList 5 $excludePars]]
                } else {
                    return -code error "Creating resistor object from line '${origLine}' failed due to wrong or\
                            incompatible syntax"
                }
            } else {
                if {[my CheckBraced $rval]} {
                    # check if rval has form `{param}`
                    set rval [list [my Unbrace $rval] -eq]
                    return [list $nmspPath new $elemName $pin1 $pin2 -r $rval\
                                    {*}[my ParseParams $lineList 4 $excludePars]]
                } elseif {[my CheckNumber $rval]} {
                    # check if rval is a valid float value
                    return [list $nmspPath new $elemName $pin1 $pin2 -r $rval\
                                    {*}[my ParseParams $lineList 4 $excludePars]]
                } elseif {[my CheckModelName $rval]} {
                    # check if rval contains valid model value
                    return [list $nmspPath new $elemName $pin1 $pin2 -model $rval\
                                    {*}[my ParseParams $lineList 4 $excludePars]]
                } else {
                    return -code error "Creating resistor object from line '${origLine}' failed due to wrong or\
                            incompatible syntax"
                }
            }
            return
        }
        method CreateCap {line} {
            # Creates [::SpiceGenTcl::Ngspice::BasicDevices::C] object from passed line and add it to netlist
            #   line - line to parse
            # Returns: code string for object creation
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
                return [list $nmspPath new $elemName $pin1 $pin2 -$type $value -beh\
                                {*}[my ParseParams [split $line] 0 {}]]
            } elseif {[my CheckModelName $fourth]} {
                if {[my CheckBraced $cval]} {
                    set cval [list [my Unbrace $cval] -eq]
                    return [list $nmspPath new $elemName $pin1 $pin2 -c $cval -model\
                                    $fourth {*}[my ParseParams $lineList 5 $excludePars]]
                } elseif {[my CheckNumber $cval]} {
                    return [list $nmspPath new $elemName $pin1 $pin2 -c $cval -model\
                                    $fourth {*}[my ParseParams $lineList 5 $excludePars]]
                } else {
                    return -code error "Creating capacitor object from line '${origLine}' failed due to wrong or\
                            incompatible syntax"
                }
            } else {
                if {[my CheckBraced $cval]} {
                    set cval [list [my Unbrace $cval] -eq]
                    return [list $nmspPath new $elemName $pin1 $pin2 -c $cval\
                                    {*}[my ParseParams $lineList 4 $excludePars]]
                } elseif {[my CheckNumber $cval]} {
                    return [list $nmspPath new $elemName $pin1 $pin2 -c $cval\
                                    {*}[my ParseParams $lineList 4 $excludePars]]
                } elseif {[my CheckModelName $cval]} {
                    return [list $nmspPath new $elemName $pin1 $pin2 -model $cval\
                                    {*}[my ParseParams $lineList 4 $excludePars]]
                } else {
                    return -code error "Creating capacitor object from line '${origLine}' failed due to wrong or\
                            incompatible syntax"
                }
            }
        }
        method CreateCoupling {line} {
            # Creates [::SpiceGenTcl::Ngspice::BasicDevices::K] object from passed line and add it to netlist
            #   line - line to parse
            # Returns: code string for object creation
            set lineList [split $line]
            lassign $lineList elemName l1 l2 kval
            set elemName [string range $elemName 1 end]
            set nmspPath ${NamespacePath}::BasicDevices::K
            if {[my CheckBraced $kval]} {
                set kval [list [my Unbrace $kval] -eq]
            }
            return [list $nmspPath new $elemName -l1 $l1 -l2 $l2 -k $kval]
        }
        method CreateInd {line} {
            # Creates [::SpiceGenTcl::Ngspice::BasicDevices::L] object from passed line and add it to netlist
            #   line - line to parse
            # Returns: code string for object creation
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
                return [list $nmspPath new $elemName $pin1 $pin2 -l $value -beh\
                                {*}[my ParseParams [split $line] 0 {}]]
            } elseif {[my CheckModelName $fourth]} {
                if {[my CheckBraced $lval]} {
                    set lval [list [my Unbrace $lval] -eq]
                    return [list $nmspPath new $elemName $pin1 $pin2 -l $lval -model\
                                    $fourth {*}[my ParseParams $lineList 5 $excludePars]]
                } elseif {[my CheckNumber $lval]} {
                    return [list $nmspPath new $elemName $pin1 $pin2 -l $lval -model\
                                    $fourth {*}[my ParseParams $lineList 5 $excludePars]]
                } else {
                    return -code error "Creating inductor object from line '${origLine}' failed due to wrong or\
                            incompatible syntax"
                }
            } else {
                if {[my CheckBraced $lval]} {
                    set lval [list [my Unbrace $lval] -eq]
                    return [list $nmspPath new $elemName $pin1 $pin2 -l $lval\
                                    {*}[my ParseParams $lineList 4 $excludePars]]
                } elseif {[my CheckNumber $lval]} {
                    return [list $nmspPath new $elemName $pin1 $pin2 -l $lval\
                                    {*}[my ParseParams $lineList 4 $excludePars]]
                } elseif {[my CheckModelName $lval]} {
                    return [list $nmspPath new $elemName $pin1 $pin2 -model $lval\
                                    {*}[my ParseParams $lineList 4 $excludePars]]
                } else {
                    return -code error "Creating inductor object from line '${origLine}' failed due to wrong or\
                            incompatible syntax"
                }
            }
        }
        method CreateVSwitch {line} {
            # Creates [::SpiceGenTcl::Ngspice::BasicDevices::S] object from passed line and add it to netlist
            #   line - line to parse
            # Returns: code string for object creation
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 pin3 pin4 model state
            set elemName [string range $elemName 1 end]
            set paramsList {}
            if {$state in {on off}} {
                lappend paramsList -$state
            }
            return [list ${NamespacePath}::BasicDevices::S new $elemName $pin1 $pin2 $pin3 $pin4 -model $model\
                            {*}$paramsList]
        }
        method CreateCSwitch {line} {
            # Creates [::SpiceGenTcl::Ngspice::BasicDevices::W] object from passed line and add it to netlist
            #   line - line to parse
            # Returns: code string for object creation
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 vnam model state
            set elemName [string range $elemName 1 end]
            set paramsList {}
            if {$state in {on off}} {
                lappend paramsList -$state
            }
            return [list ${NamespacePath}::BasicDevices::W new $elemName $pin1 $pin2 -icntrl $vnam -model $model\
                            {*}$paramsList]
        }
        method CreateBehSource {line} {
            # Creates [::SpiceGenTcl::Ngspice::Sources::B] object from passed line and add it to netlist
            #   line - line to parse
            # Returns: code string for object creation
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
                return [list ${NamespacePath}::Sources::B new $elemName $pin1 $pin2 -$type $value\
                                {*}[my ParseParams [split $line] 0 {}]]
            } else {
                return -code error "Creating behavioural source object from line '${origLine}' failed due to wrong or\
                            incompatible syntax"
            }
        }
        method CreateVCVS {line} {
            # Creates [::SpiceGenTcl::Ngspice::Sources::E] object from passed line and add it to netlist
            #   line - line to parse
            # Returns: code string for object creation
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 pin3 pin4 val
            set elemName [string range $elemName 1 end]
            if {[my CheckBraced $val]} {
                set val [list [my Unbrace $val] -eq]
                return [list ${NamespacePath}::Sources::E new $elemName $pin1 $pin2 $pin3 $pin4 -gain $val]
            } elseif {[my CheckNumber $val]} {
                return [list ${NamespacePath}::Sources::E new $elemName $pin1 $pin2 $pin3 $pin4 -gain $val]
            } else {
                return -code error "Creating VCVS object from line '${line}' failed due to wrong or incompatible syntax"
            }
        }
        method CreateCCCS {line} {
            # Creates [::SpiceGenTcl::Ngspice::Sources::F] object from passed line and add it to netlist
            #   line - line to parse
            # Returns: code string for object creation
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 vnam val
            set elemName [string range $elemName 1 end]
            if {[my CheckBraced $val]} {
                set val [list [my Unbrace $val] -eq]
                return [list ${NamespacePath}::Sources::F new $elemName $pin1 $pin2 -consrc $vnam -gain $val\
                                {*}[my ParseParams $lineList 6]]
            } elseif {[my CheckNumber $val]} {
                return [list ${NamespacePath}::Sources::F new $elemName $pin1 $pin2 -consrc $vnam -gain $val\
                                {*}[my ParseParams $lineList 6]]
            } else {
                return -code error "Creating CCCS object from line '${line}' failed due to wrong or incompatible syntax"
            }
        }
        method CreateVCCS {line} {
            # Creates [::SpiceGenTcl::Ngspice::Sources::G] object from passed line and add it to netlist
            #   line - line to parse
            # Returns: code string for object creation
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 pin3 pin4 val
            set elemName [string range $elemName 1 end]
            if {[my CheckBraced $val]} {
                set val [list [my Unbrace $val] -eq]
                return [list ${NamespacePath}::Sources::G new $elemName $pin1 $pin2 $pin3 $pin4 -trcond $val\
                                {*}[my ParseParams $lineList 6]]
            } elseif {[my CheckNumber $val]} {
                return [list ${NamespacePath}::Sources::G new $elemName $pin1 $pin2 $pin3 $pin4 -trcond $val\
                                {*}[my ParseParams $lineList 6]]
            } else {
                return -code error "Creating VCCS object from line '${line}' failed due to wrong or incompatible syntax"
            }
        }
        method CreateCCVS {line} {
            # Creates [::SpiceGenTcl::Ngspice::Sources::H] object from passed line and add it to netlist
            #   line - line to parse
            # Returns: code string for object creation
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 vnam val
            set elemName [string range $elemName 1 end]
            if {[my CheckBraced $val]} {
                set val [list [my Unbrace $val] -eq]
                return [list ${NamespacePath}::Sources::H new $elemName $pin1 $pin2 -consrc $vnam -transr $val]
            } elseif {[my CheckNumber $val]} {
                return [list ${NamespacePath}::Sources::H new $elemName $pin1 $pin2 -consrc $vnam -transr $val]
            } else {
                return -code error "Creating CCVS object from line '${line}' failed due to wrong or incompatible syntax"
            }
        }
        method CreateDio {line} {
            # Creates [::SpiceGenTcl::Ngspice::SemiconductorDevices::D] object from passed line and add it to netlist
            #   line - line to parse
            # Returns: code string for object creation
            set lineList [split $line]
            lassign $lineList elemName pin1 pin2 modelVal
            set elemName [string range $elemName 1 end]
            if {[set offIndex [lsearch -exact $lineList off]]!=-1} {
                lappend paramsList -off
                set lineList [lremove $lineList $offIndex]
            }
            if {[my CheckModelName $modelVal]} {
                lappend paramsList {*}[my ParseParams [lrange $lineList 1 end] 3 {}]
                return [list ${NamespacePath}::SemiconductorDevices::D new $elemName $pin1 $pin2 -model $modelVal\
                                {*}$paramsList]
            } else {
                return -code error "Creating diode object from line '${line}' failed due to wrong or incompatible syntax"
            }
        }
        method CreateJFET {line} {
            # Creates [::SpiceGenTcl::Ngspice::SemiconductorDevices::J] object from passed line and add it to netlist
            #   line - line to parse
            # Returns: code string for object creation
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
                return [list ${NamespacePath}::SemiconductorDevices::J new $elemName $pin1 $pin2 $pin3 -model\
                                $modelVal {*}$paramsList]
            } else {
                return -code error "Creating JFET object from line '${line}' failed due to wrong or incompatible syntax"
            }
        }

        method CreateMOSFET {line} {
            # Creates [::SpiceGenTcl::Ngspice::SemiconductorDevices::M] object from passed line and add it to netlist
            #   line - line to parse
            # Returns: code string for object creation
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
                return [list ${NamespacePath}::SemiconductorDevices::M new $elemName $pin1 $pin2 $pin3\
                                -model $modelVal {*}$paramsList]
            } else {
                return -code error "Creating MOSFET object from line '${line}' failed due to wrong or incompatible\
                        syntax"
            }
        }
        method CreateVerilogA {line} {
            # Creates [::SpiceGenTcl::Ngspice::BasicDevices::N] object from passed line and add it to `netlistObj`
            #   line - line to parse
            # Returns: code string for object creation
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
            return [list ${NamespacePath}::BasicDevices::N new $elemName $pins $subName\
                            [my ParseParams $lineList $paramsStartIndex {} list]]
        }
        method CreateBJT {line} {
            # Creates [::SpiceGenTcl::Ngspice::SemiconductorDevices::Q] object from passed line and add it to netlist
            #   line - line to parse
            # Returns: code string for object creation
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
                return [list ${NamespacePath}::SemiconductorDevices::Q new $elemName $pin1 $pin2 $pin3\
                                -model $modelVal {*}$paramsList]
            } else {
                return -code error "Creating BJT object from line '${line}' failed due to wrong or incompatible syntax"
            }
        }
        method CreateVIsource {line} {
            # Creates children object of [::SpiceGenTcl::Ngspice::Sources] class from passed line and add it to netlist
            #   line - line to parse
            # Returns: code string for object creation

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
                    return [list ${nmspPath}::[string toupper ${type}]pulse new $elemName $pin1 $pin2 {*}$paramsList]
                }
                sin {
                    lappend paramsList {*}[my ParsePosParams [lrange $lineList 1 end] [dget $functsDict sin]]
                    return [list ${nmspPath}::[string toupper ${type}]sin new $elemName $pin1 $pin2 {*}$paramsList]
                }
                exp {
                    lappend paramsList {*}[my ParsePosParams [lrange $lineList 1 end] [dget $functsDict exp]]
                    return [list ${nmspPath}::[string toupper ${type}]exp new $elemName $pin1 $pin2 {*}$paramsList]
                }
                pwl {
                    foreach value [lrange $lineList 1 end] {
                        if {[my CheckBraced $value]} {
                            set value [list [my Unbrace $value] -eq]
                        }
                        lappend seqList $value
                    }
                    lappend paramsList -seq $seqList
                    return [list ${nmspPath}::[string toupper ${type}]pwl new $elemName $pin1 $pin2 {*}$paramsList]
                }
                sffm {
                    lappend paramsList {*}[my ParsePosParams [lrange $lineList 1 end] [dget $functsDict sffm]]
                    return [list ${nmspPath}::[string toupper ${type}]sffm new $elemName $pin1 $pin2 {*}$paramsList]
                }
                am {
                    lappend paramsList {*}[my ParsePosParams [lrange $lineList 1 end] [dget $functsDict am]]
                    return [list ${nmspPath}::[string toupper ${type}]am new $elemName $pin1 $pin2 {*}$paramsList]
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
                    return [list ${nmspPath}::Vport new $elemName $pin1 $pin2 -portnum $portnumVal {*}$paramsList]
                }
                default {
                    if {$acType} {
                        return [list ${nmspPath}::[string toupper ${type}]ac new $elemName $pin1 $pin2\
                                        {*}$paramsList]
                    } else {
                        return [list ${nmspPath}::[string toupper ${type}]dc new $elemName $pin1 $pin2\
                                        {*}$paramsList]
                    }
                }
            }
            return
        }
        method CreateMESFET {line} {
            # Creates [::SpiceGenTcl::Ngspice::SemiconductorDevices::Z] object from passed line and add it to netlist
            #   line - line to parse
            # Returns: code string for object creation
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
                return [list ${NamespacePath}::SemiconductorDevices::Z new $elemName $pin1 $pin2 $pin3\
                                -model $modelVal {*}$paramsList]
            } else {
                return -code error "Creating MESFET object from line '${line}' failed due to wrong or incompatible\
                        syntax"
            }
        }
    }
}
