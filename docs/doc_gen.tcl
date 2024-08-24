#RUNF: doc_gen.tcl

lappend auto_path "../"
lappend auto_path "/home/georgtree/tcl/"
package require ruff
package require fileutil
set dir [file dirname [file normalize [info script]]]
set sourceDir "${dir}/../src"
source startPage.ruff
source tutorials.ruff
source faq.ruff
source tips.ruff
source [file join $sourceDir generalClasses.tcl]
source [file join $sourceDir ngspice/specElementsClasses.tcl]
source [file join $sourceDir ngspice/specAnalysesClasses.tcl]
source [file join $sourceDir ngspice/specModelsClasses.tcl]
source [file join $sourceDir ngspice/specSimulatorClasses.tcl]

set packageVersion [package versions SpiceGenTcl]

set title "Tcl SpiceGenTcl package"

set common [list \
                -title $title \
                -sortnamespaces false \
                -preamble $startPage \
                -pagesplit namespace \
                -recurse false \
                -includesource true \
                -pagesplit namespace \
                -autopunctuate true \
                -compact false \
                -includeprivate true \
                -product SpiceGenTcl \
                -diagrammer "ditaa --border-width 1" \
                -version $packageVersion \
                -copyright "George Yashin" {*}$::argv
               ]
set namespaces [list ::FAQ ::Tutorials ::Tips ::SpiceGenTcl ::SpiceGenTcl::Ngspice::BasicDevices \
                ::SpiceGenTcl::Ngspice::Sources ::SpiceGenTcl::Ngspice::SemiconductorDevices \
                ::SpiceGenTcl::Ngspice::Analyses ::SpiceGenTcl::Ngspice::Simulators]

if {[llength $argv] == 0 || "html" in $argv} {
    ruff::document $namespaces \
        -format html \
        -outfile index.html \
        {*}$common
}


exec tclsh /home/georgtree/tcl/hl_tcl/tcl_html.tcl "./index.html" 
exec tclsh /home/georgtree/tcl/hl_tcl/tcl_html.tcl "./index-SpiceGenTcl.html" 
exec tclsh /home/georgtree/tcl/hl_tcl/tcl_html.tcl "./index-Tutorials.html" 
exec tclsh /home/georgtree/tcl/hl_tcl/tcl_html.tcl "./index-FAQ.html" 
exec tclsh /home/georgtree/tcl/hl_tcl/tcl_html.tcl "./index-Tips.html" 
exec tclsh /home/georgtree/tcl/hl_tcl/tcl_html.tcl "./index-SpiceGenTcl-Ngspice.html" 
exec tclsh /home/georgtree/tcl/hl_tcl/tcl_html.tcl "./index-SpiceGenTcl-Ngspice-Sources.html" 
exec tclsh /home/georgtree/tcl/hl_tcl/tcl_html.tcl "./index-SpiceGenTcl-Ngspice-Simulators.html" 
exec tclsh /home/georgtree/tcl/hl_tcl/tcl_html.tcl "./index-SpiceGenTcl-Ngspice-SemiconductorDevices.html" 
exec tclsh /home/georgtree/tcl/hl_tcl/tcl_html.tcl "./index-SpiceGenTcl-Ngspice-BasicDevices.html" 
exec tclsh /home/georgtree/tcl/hl_tcl/tcl_html.tcl "./index-SpiceGenTcl-Ngspice-Analyses.html" 
exec tclsh /home/georgtree/tcl/hl_tcl/tcl_html.tcl "./index-docindex.html" 

proc processContents {fileContents} {
    # Search: AA, replace: aa
    return [string map {max-width:60rem max-width:100rem} $fileContents]
}

fileutil::updateInPlace ./assets/ruff-min.css processContents

