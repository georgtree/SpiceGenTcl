
set path_to_hl_tcl "/home/georgtree/tcl/hl_tcl"
package require ruff
package require fileutil
set docDir [file dirname [file normalize [info script]]]
set sourceDir "${docDir}/../src"
source [file join $docDir startPage.ruff]
source [file join $docDir generalInformation.ruff]
source [file join $docDir listOfDevices.ruff]
source [file join $docDir tutorials.ruff]
source [file join $docDir faq.ruff]
source [file join $docDir tips.ruff]
source [file join $docDir advanced.ruff]
source [file join $docDir .. SpiceGenTcl.tcl]

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
    ruff::document $namespaces -outdir $docDir -format html -outfile index.html {*}$common
    ruff::document $namespacesNroff -outdir $docDir -format nroff -outfile SpiceGenTcl.n {*}$commonNroff
}

foreach file [glob ${docDir}/*.html] {
    exec tclsh "${path_to_hl_tcl}/tcl_html.tcl" [file join ${docDir} $file]
}

# change default width
proc processContentsCss {fileContents} {
    return [string map {max-width:60rem max-width:100rem} $fileContents]
}
# change default theme 
proc processContentsJs {fileContents} {
    return [string map {init()\{currentTheme=localStorage.ruff_theme init()\{currentTheme=currentTheme="dark"}\
                    $fileContents]
}

fileutil::updateInPlace [file join $docDir assets ruff-min.css] processContentsCss
fileutil::updateInPlace [file join $docDir assets ruff-min.js] processContentsJs

# ticklechart graphs substitutions
proc processContentsTutorial {fileContents} {
    variable docDir
    set fp [open [file join $docDir .. examples ngspice html_charts diode_iv.html] r]
    set fileData [read $fp]
    close $fp
    set fileContents [string map [list !ticklechart_mark_diode_iv_ngspice! $fileData] $fileContents]
    set fp [open [file join $docDir .. examples ngspice html_charts diode_cv.html] r]
    set fileData [read $fp]
    close $fp
    set fileContents [string map [list !ticklechart_mark_diode_cv_ngspice! $fileData] $fileContents]
    set fp [open [file join $docDir .. examples ngspice html_charts switch_oscillator.html] r]
    set fileData [read $fp]
    close $fp
    set fileContents [string map [list !ticklechart_mark_switch_oscillator_ngspice! $fileData] $fileContents]
    set fp [open [file join $docDir .. examples ngspice html_charts fourbitadder.html] r]
    set fileData [read $fp]
    close $fp
    set fileContents [string map [list !ticklechart_mark_four_bit_adder_ngspice! $fileData] $fileContents]
    set fp [open [file join $docDir .. examples ngspice html_charts filter.html] r]
    set fileData [read $fp]
    close $fp
    set fileContents [string map [list !ticklechart_mark_filter_ngspice! $fileData] $fileContents]
    return $fileContents
}
fileutil::updateInPlace [file join $docDir index-Tutorials.html] processContentsTutorial

