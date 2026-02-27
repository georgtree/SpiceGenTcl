
set path_to_hl_tcl "/home/georgtree/tcl/hl_tcl"
#set path_to_hl_tcl "C:/msys64/mingw64/lib/hl_tcl"
source /home/georgtree/tcl/ruff/src/ruff.tcl
package require fileutil
source [file join $path_to_hl_tcl hl_tcl_html.tcl]
set docDir [file dirname [file normalize [info script]]]
set sourceDir "${docDir}/../src"
source [file join $docDir startPage.ruff]
source [file join $docDir generalInformation.ruff]
source [file join $docDir listOfDevices.ruff]
source [file join $docDir tutorials.ruff]
source [file join $docDir faq.ruff]
source [file join $docDir tips.ruff]
source [file join $docDir advanced.ruff]
source [file join $docDir parser.ruff]
source [file join $docDir .. SpiceGenTcl.tcl]

set packageVersion [package versions SpiceGenTcl]
puts $packageVersion
set title "Tcl SpiceGenTcl package"

set commonSphinx [list -title $title -sortnamespaces false -preamble $startPage -pagesplit namespace -recurse false\
                    -includesource false -pagesplit namespace -autopunctuate true -compact false -includeprivate false\
                    -product SpiceGenTcl -diagrammer "ditaa --border-width 1" -version $packageVersion\
                    -copyright "George Yashin" {*}$::argv]
set commonNroff [list -title $title -sortnamespaces false -preamble $startPage -pagesplit namespace -recurse false\
                         -pagesplit namespace -autopunctuate true -compact false -includeprivate false\
                         -product SpiceGenTcl -diagrammer "ditaa --border-width 1" -version $packageVersion\
                         -copyright "George Yashin" {*}$::argv]
set namespaces [list "::List of devices" ::FAQ ::Tutorials ::Tips ::Advanced ::Parser ::SpiceGenTcl\
                ::SpiceGenTcl::Common::BasicDevices ::SpiceGenTcl::Common::Analyses\
                ::SpiceGenTcl::Common::Sources ::SpiceGenTcl::Ngspice ::SpiceGenTcl::Ngspice::BasicDevices\
                ::SpiceGenTcl::Ngspice::Sources ::SpiceGenTcl::Ngspice::SemiconductorDevices\
                ::SpiceGenTcl::Ngspice::Analyses ::SpiceGenTcl::Ngspice::Simulators ::SpiceGenTcl::Ngspice::Misc\
                ::SpiceGenTcl::Xyce::BasicDevices ::SpiceGenTcl::Xyce::Sources\
                ::SpiceGenTcl::Xyce::SemiconductorDevices ::SpiceGenTcl::Xyce::Analyses\
                ::SpiceGenTcl::Xyce::Simulators ::SpiceGenTcl::Ltspice::BasicDevices ::SpiceGenTcl::Ltspice::Sources\
                ::SpiceGenTcl::Ltspice::SemiconductorDevices ::SpiceGenTcl::Ltspice::Analyses\
                ::SpiceGenTcl::Ltspice::Simulators]
set namespacesNroff [list "::List of devices" ::SpiceGenTcl ::SpiceGenTcl::Common::BasicDevices\
                ::SpiceGenTcl::Common::Analyses ::SpiceGenTcl::Common::Sources ::SpiceGenTcl::Ngspice::BasicDevices\
                ::SpiceGenTcl::Ngspice::Sources ::SpiceGenTcl::Ngspice ::SpiceGenTcl::Ngspice::SemiconductorDevices\
                ::SpiceGenTcl::Ngspice::Analyses ::SpiceGenTcl::Ngspice::Simulators ::SpiceGenTcl::Ngspice::Misc\
                ::SpiceGenTcl::Xyce::BasicDevices ::SpiceGenTcl::Xyce::Sources\
                ::SpiceGenTcl::Xyce::SemiconductorDevices ::SpiceGenTcl::Xyce::Analyses\
                ::SpiceGenTcl::Xyce::Simulators ::SpiceGenTcl::Ltspice::BasicDevices ::SpiceGenTcl::Ltspice::Sources\
                ::SpiceGenTcl::Ltspice::SemiconductorDevices ::SpiceGenTcl::Ltspice::Analyses\
                ::SpiceGenTcl::Ltspice::Simulators]

if {[llength $argv] == 0 || "html" in $argv} {
    ruff::document $namespaces -outdir $docDir -format sphinx -outfile SpiceGenTcl.rst -outdir [file join $docDir sphinx] {*}$commonSphinx
    #ruff::document $namespacesNroff -outdir $docDir -format nroff -outfile SpiceGenTcl.n {*}$commonNroff
}

::fileutil::appendToFile [file join $docDir sphinx conf.py] {html_theme = "classic"
extensions = [
    "sphinx.ext.githubpages",
]
suppress_warnings = [
    "image.not_readable",
]
from pygments.lexers.tcl import TclLexer
from pygments.token import Operator

class MyTclLexer(TclLexer):
    def get_tokens_unprocessed(self, text):
        for i, t, v in super().get_tokens_unprocessed(text):
            if v == "=":
                yield i, Operator, v   # or Name.Builtin
            else:
                yield i, t, v

def setup(app):
    from sphinx.highlighting import lexers
    lexers["tcl"] = MyTclLexer()
}
catch {exec sphinx-build -b html [file join $docDir sphinx] [file join $docDir]} errorStr
puts $errorStr

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
fileutil::updateInPlace [file join $docDir SpiceGenTcl-Tutorials.html] processContentsTutorial
set chartsMap [dcreate !ticklechart_mark_resistor_divider_ngspice! resistor_divider.html]
fileutil::updateInPlace [file join $docDir SpiceGenTcl.html] processContentsTutorial
set chartsMap [dcreate !ticklechart_mark_monte_carlo_typ_mag_ngspice! monte_carlo_typ.html\
                       !ticklechart_mark_monte_carlo_dists_ngspice! monte_carlo.html\
                       !ticklechart_mark_monte_carlo_dists_comb_ngspice! monte_carlo_combined.html\
                       !ticklechart_mark_diode_extract_ngspice! diode_extract.html\
                       !ticklechart_mark_inverter_optimization_plot_ngspice! inverter_optimization_plot.html\
                       !ticklechart_mark_inverter_optimization_waveforms_ngspice! inverter_optimization_waveforms_plot.html]
fileutil::updateInPlace [file join $docDir SpiceGenTcl-Advanced.html] processContentsTutorial
set chartsMap [dcreate !ticklechart_mark_c432_test_with_parsing_ngspice! c432_test_with_parsing.html]
fileutil::updateInPlace [file join $docDir SpiceGenTcl-Parser.html] processContentsTutorial
