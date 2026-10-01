namespace eval ::docgen {}

proc ::docgen::readSnippet {root path args} {
    # Supported forms:
    #   path
    #   path -lines {first last}
    #   path -region name
    if {[llength $args] ni {0 2}} {
        return -code error "expected file ?-lines {first last}|-region name?"
    }
    set mode {}
    if {[llength $args] == 2} {
        lassign $args mode selection
        if {$mode ni {-lines -region}} {
            return -code error "unknown option \"$mode\": expected -lines or -region"
        }
    }
    set filename [file normalize [file join $root $path]]
    set channel [open $filename r]
    try {
        fconfigure $channel -encoding utf-8 -translation auto
        set contents [read $channel]
    } finally {
        close $channel
    }
    # Remove the final line terminator without removing blank source lines.
    if {$contents eq {}} {
        set lines {}
    } else {
        if {[string index $contents end] eq "\n"} {
            set contents [string range $contents 0 end-1]
        }
        set lines [split $contents "\n"]
    }
    switch -- $mode {
        -lines {
            if {[llength $selection] != 2} {
                return -code error "-lines requires {first last}"
            }
            lassign $selection first last
            set count [llength $lines]
            foreach number [list $first $last] {
                if {![string is integer -strict $number]} {
                    return -code error "line numbers must be integers"
                }
            }
            if {$first < 1 || $last < $first || $last > $count} {
                return -code error "invalid range {$first $last} for '$path' ($count lines)"
            }
            set lines [lrange $lines [expr {$first - 1}] [expr {$last - 1}]]
        }
        -region {
            if {[string trim $selection] eq {}} {
                return -code error "region name must not be empty"
            }
            # Match whole marker lines, allowing surrounding whitespace.
            set trimmed {}
            foreach line $lines {
                lappend trimmed [string trim $line]
            }
            set begins [lsearch -all -exact $trimmed "# docs-begin $selection"]
            set ends [lsearch -all -exact $trimmed "# docs-end $selection"]

            if {[llength $begins] != 1 || [llength $ends] != 1} {
                return -code error "region '$selection' in '$path' must have exactly one begin and one end marker"
            }
            set first [lindex $begins 0]
            set last [lindex $ends 0]
            if {$last <= $first} {
                return -code error "end marker precedes begin marker for region '$selection' in '$path'"
            }
            set lines [lrange $lines [expr {$first + 1}] [expr {$last - 1}]]
        }
    }
    # Remove nested region markers from region-based snippets.
    if {$mode eq {-region}} {
        set filtered {}
        foreach line $lines {
            if {[regexp {^[ \t]*#[ \t]*docs-(begin|end)[ \t]+.*$} $line]} {
                continue
            }
            lappend filtered $line
        }
        set lines $filtered
    }
    return $lines
}

proc ::docgen::expandIncludes {text root} {
    set result {}
    set lineNumber 0
    foreach line [split $text "\n"] {
        incr lineNumber
        # Only standalone directives are expanded.
        if {![regexp {^([ \t]*)@include-code(?:[ \t]+|$)(.*)$} $line -> indent specification]} {
            lappend result $line
            continue
        }
        # Parse arguments as a Tcl list without evaluating them.
        if {[catch {
            if {[llength $specification] == 0} {
                return -code error "missing source filename"
            }
            set path [lindex $specification 0]
            set options [lrange $specification 1 end]
            if {[llength $options] % 2 != 0} {
                return -code error "each option requires a value"
            }
            set lang tcl
            set seen {}
            set snippetOptions {}
            foreach {option value} $options {
                if {$option in $seen} {
                    return -code error "duplicate option '$option'"
                }
                lappend seen $option
                switch -- $option {
                    -lang {
                        # Empty language produces an unlabelled code block.
                        if {$value ne {} && ![regexp {^[[:alnum:]_+.-]+$} $value]} {
                            return -code error "invalid language name '$value'"
                        }
                        set lang $value
                    }
                    -lines -
                    -region {
                        lappend snippetOptions $option $value
                    }

                    default {
                        return -code error "unknown option '$option': expected -lang, -lines or -region"
                    }
                }
            }

            if {"-lines" in $seen && "-region" in $seen} {
                return -code error "-lines and -region cannot be used together"
            }
            set snippet [::docgen::readSnippet $root $path {*}$snippetOptions]
        } message]} {
            return -code error "documentation line $lineNumber: $message"
        }
        # Preserve the directive's indentation and source indentation.
        lappend result "${indent}```${lang}"
        foreach sourceLine $snippet {
            lappend result "${indent}${sourceLine}"
        }
        lappend result "${indent}```"
    }
    return [join $result "\n"]
}
