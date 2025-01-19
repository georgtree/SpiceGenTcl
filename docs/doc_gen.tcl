
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
    global path chartsMap
    dict for {mark file} $chartsMap {
        set fileData [fileutil::cat [file join $path $file]]
        set fileContents [string map [list $mark $fileData] $fileContents]
    }
    return $fileContents
}

set chartsMap [dcreate !ticklechart_mark_diode_iv_ngspice! diode_iv.html !ticklechart_mark_diode_cv_ngspice!\
                       diode_cv.html !ticklechart_mark_switch_oscillator_ngspice! switch_oscillator.html\
                       !ticklechart_mark_four_bit_adder_ngspice! fourbitadder.html !ticklechart_mark_filter_ngspice!\
                       filter.html]
set path [file join $docDir .. examples ngspice html_charts]
fileutil::updateInPlace [file join $docDir index-Tutorials.html] processContentsTutorial
set chartsMap [dcreate !ticklechart_mark_resistor_divider_ngspice! resistor_divider.html]
fileutil::updateInPlace [file join $docDir index.html] processContentsTutorial
set chartsMap [dcreate !ticklechart_mark_monte_carlo_typ_mag_ngspice! monte_carlo_typ.html\
                       !ticklechart_mark_monte_carlo_dists_ngspice! monte_carlo.html\
                       !ticklechart_mark_monte_carlo_dists_comb_ngspice! monte_carlo_combined.html\
                       !ticklechart_mark_diode_extract_ngspice! diode_extract.html]
fileutil::updateInPlace [file join $docDir index-Advanced.html] processContentsTutorial
