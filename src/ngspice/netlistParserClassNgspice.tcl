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
        property name
        variable name
        property filepath
        variable filepath
        property FileData
        variable FileData
        variable ClassifiedLines

        constructor {name filepath} {
            my configure -name $name -filepath $filepath
        }

        method readFile {} {
            # replace all sequences of white space characters with single space character
            foreachLine line [my configure -filepath] {
                set processedLine [regsub -all {[[:space:]]+} [string trim $line] { }]
                if {$processedLine ne ""} {
                    lappend lines $processedLine
                }
            }
            # find continuations and move them to line that is the start of continuation
            set fileData $lines
            set i 0
            set contFlag false
            # create a dictionary like '2 {3 4 5} 6 {7} 8 {} 9 {} 10 {} {11 12} 13 {}...' where keys are start lines,
            # indexes and values are the lists of lines indexes that are the continuation of the line with key index
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
            # to be '+' symbol)
            dict map {lineIndex contLinesIndexes} $continLinesIndex {
                if {$contLinesIndexes eq ""} {
                    lappend finalList [@ $fileData $lineIndex]
                } else {
                    set locList [@ $fileData $lineIndex]
                    foreach contLineIndex $contLinesIndexes {
                        lappend locList [string trim [string range [@ $fileData $contLineIndex] 1 end]]
                    }
                    lappend finalList [join $locList]
                }
            }

            my configure -FileData $finalList
            return
        }
        method classifyLines {} {
            # parse line by line and classify each line to next classes:
            # comments, dot commands, elements, subcircuits, ends of subcircuits
        }

    }

}
