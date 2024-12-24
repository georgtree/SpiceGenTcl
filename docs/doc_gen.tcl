
set path_to_hl_tcl "/home/georgtree/tcl/hl_tcl"
package require ruff
package require fileutil
set dir [file dirname [file normalize [info script]]]
set sourceDir "${dir}/../src"
source [file join $dir startPage.ruff]
source [file join $dir generalInformation.ruff]
source [file join $dir listOfDevices.ruff]
source [file join $dir tutorials.ruff]
source [file join $dir faq.ruff]
source [file join $dir tips.ruff]
source [file join $dir advanced.ruff]
source [file join $sourceDir generalClasses.tcl]
source [file join $sourceDir specElementsClassesCommon.tcl]
source [file join $sourceDir ngspice specElementsClassesNgspice.tcl]
source [file join $sourceDir ngspice specAnalysesClassesNgspice.tcl]
source [file join $sourceDir ngspice specModelsClassesNgspice.tcl]
source [file join $sourceDir ngspice specSimulatorClassesNgspice.tcl]
source [file join $sourceDir xyce specAnalysesClassesXyce.tcl]
source [file join $sourceDir xyce specElementsClassesXyce.tcl]
source [file join $sourceDir xyce specSimulatorClassesXyce.tcl]

set packageVersion [package versions SpiceGenTcl]
puts $packageVersion
set title "Tcl SpiceGenTcl package"

set common [list -title $title -sortnamespaces false -preamble $startPage -pagesplit namespace -recurse false\
                    -includesource true -pagesplit namespace -autopunctuate true -compact false -includeprivate false\
                    -product SpiceGenTcl -diagrammer "ditaa --border-width 1" -version $packageVersion\
                    -copyright "George Yashin" {*}$::argv]
set commonNroff [list -title $title -sortnamespaces false -preamble $startPage -pagesplit namespace -recurse false\
                         -pagesplit namespace -autopunctuate true -compact false -includeprivate false\
                         -product SpiceGenTcl -diagrammer "ditaa --border-width 1" -version $packageVersion \
                         -copyright "George Yashin" {*}$::argv]
set namespaces [list "::List of devices" ::FAQ ::Tutorials ::Tips ::Advanced ::SpiceGenTcl \
                ::SpiceGenTcl::Common::BasicDevices \
                ::SpiceGenTcl::Common::Sources ::SpiceGenTcl::Ngspice::BasicDevices \
                ::SpiceGenTcl::Ngspice::Sources ::SpiceGenTcl::Ngspice::SemiconductorDevices \
                ::SpiceGenTcl::Ngspice::Analyses ::SpiceGenTcl::Ngspice::Simulators \
                ::SpiceGenTcl::Xyce::BasicDevices ::SpiceGenTcl::Xyce::Sources \
                ::SpiceGenTcl::Xyce::SemiconductorDevices ::SpiceGenTcl::Xyce::Analyses \
                ::SpiceGenTcl::Xyce::Simulators]
set namespacesNroff [list "::List of devices" ::SpiceGenTcl ::SpiceGenTcl::Common::BasicDevices \
                ::SpiceGenTcl::Common::Sources ::SpiceGenTcl::Ngspice::BasicDevices \
                ::SpiceGenTcl::Ngspice::Sources ::SpiceGenTcl::Ngspice::SemiconductorDevices \
                ::SpiceGenTcl::Ngspice::Analyses ::SpiceGenTcl::Ngspice::Simulators \
                ::SpiceGenTcl::Xyce::BasicDevices ::SpiceGenTcl::Xyce::Sources \
                ::SpiceGenTcl::Xyce::SemiconductorDevices ::SpiceGenTcl::Xyce::Analyses \
                ::SpiceGenTcl::Xyce::Simulators]                

if {[llength $argv] == 0 || "html" in $argv} {
    ruff::document $namespaces -outdir $dir -format html -outfile index.html {*}$common
    ruff::document $namespacesNroff -outdir $dir -format nroff -outfile SpiceGenTcl.n {*}$commonNroff
}

foreach file [glob *.html] {
    exec tclsh "${path_to_hl_tcl}/tcl_html.tcl" "./$file"
}

proc processContents {fileContents} {
    return [string map {max-width:60rem max-width:100rem} $fileContents]
}

fileutil::updateInPlace [file join $dir assets ruff-min.css] processContents

