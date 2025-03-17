package require SpiceGenTcl

const configurableOOSyntax {set ::syntax(oo::configurable) {s x*}
set {::syntax(oo::configurable create)} {do=_stdclass_oo cn?}
set {::syntax(oo::configurable create::configurable)} x
set {::syntax(oo::configurable create::constructor)} dk
set {::syntax(oo::configurable create::deletemethod)} {x x*}
set {::syntax(oo::configurable create::destructor)} dd
set {::syntax(oo::configurable create::export)} {x x*}
set {::syntax(oo::configurable create::filter)} {o? x*}
set {::syntax(oo::configurable create::forward)} {x x x*}
set {::syntax(oo::configurable create::method)} dm
set {::syntax(oo::configurable create::mixin)} {o? di}
set {::syntax(oo::configurable create::renamemethod)} {x x}
set {::syntax(oo::configurable create::self)} x*
set {::syntax(oo::configurable create::superclass)} {o? di}
set {::syntax(oo::configurable create::unexport)} {x x*}
set {::syntax(oo::configurable create::variable)} {o? div*}
}

const additionalCommand {set ::knownCommands {
next
property}}

set currentDir [file dirname [file normalize [info script]]]
global env
if {[string match -nocase *linux* $tcl_platform(os)]} {
    set nagelfarPath "/home/$env(USER)/tcl/nagelfar/"
} elseif {[string match -nocase "*windows nt*" $tcl_platform(os)]} {
    set nagelfarPath "C:\\msys64\\home\\georgtree1\\nagelfar\\"
}

source [file join $nagelfarPath syntaxbuild.tcl]

set file [open [file join $currentDir syntaxdb.tcl] w+]

buildDb $file
puts $file $configurableOOSyntax
close $file
