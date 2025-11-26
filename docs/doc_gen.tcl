
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

set common [list -title $title -sortnamespaces false -preamble $startPage -pagesplit namespace -recurse false\
                    -includesource true -pagesplit namespace -autopunctuate true -compact false -includeprivate false\
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
    ruff::document $namespaces -outdir $docDir -format html -outfile index.html {*}$common
    ruff::document $namespacesNroff -outdir $docDir -format nroff -outfile SpiceGenTcl.n {*}$commonNroff
}

# add new command keywords to hl_tcl
lappend ::hl_tcl::my::data(CMD_TCL) {*}{Pin ParameterSwitch Parameter ParameterNoCheck ParameterPositional\
                                                ParameterPositionalNoCheck ParameterDefault ParameterEquation\
                                                ParameterPositionalEquation Device Model RawString Comment Include\
                                                Options ParamStatement Temp Netlist Circuit Library Subcircuit Analysis\
                                                Simulator Dataset Axis Trace EmptyTrace RawFile Ic Nodeset\
                                                ParameterNode ParameterNodeEquation Global Parser ParameterVector Save\
                                                Function importNgspice importXyce importCommon importLtspice\
                                                forgetNgspice forgetXyce forgetCommon forgetLtspice Dc Ac Tran Op\
                                                Resistor R Capacitor C Inductor L SubcircuitInstance X\
                                                SubcircuitInstanceAuto XAuto VSwitch VSw CSwitch W Vdc Idc Vac Iac\
                                                Vpulse Ipulse Vsin Isin Vexp Iexp Vpwl Ipwl Vsffm Isffm Vccs G Vcvs E\
                                                Cccs F Ccvs H dget @ = dexist dcreate dset dappend dkeys dvalues\
                                                BehaviouralSource Diode D Bjt Q Jfet J Mesfet Z Mosfet M VSwitchModel\
                                                CSwitchModel DiodeModel DiodeIdealModel BjtGPModel JfetModel MesfetModel\
                                                Batch BatchLiveLog NgspiceParser SensAc SensDc Sp VerilogA N Vport\
                                                OptionsNgspice RModel CModel LModel Sens GenSwitch GenS Vsffm Isffm\
                                                BjtSub QSub BjtSubTj QSubTj measure}
set ::hl_tcl::my::data(CMD_TCL) [lsort $::hl_tcl::my::data(CMD_TCL)]

foreach file [glob ${docDir}/*.html] {
    ::hl_tcl_html::highlight $file no \
        {<pre class='ruff'>} </pre> \
        <div id='*' class='ruff_dyn_src'><pre> </pre> \
        <code> </code>  
}

# change default width
proc processContentsCss {fileContents} {
    return [string map [list max-width:60rem max-width:100rem "overflow-wrap:break-word" "overflow-wrap:normal"]\
                    $fileContents]
}
# change default theme 
proc processContentsJs {fileContents} {
    return [string map {init()\{currentTheme=localStorage.ruff_theme init()\{currentTheme=currentTheme="v1"}\
                    $fileContents]
}

fileutil::updateInPlace [file join $docDir assets ruff-min.css] processContentsCss
fileutil::updateInPlace [file join $docDir assets ruff-min.js] processContentsJs

set tableWrapping {
    .ruff-bd table.ruff_deflist th:first-child,
    .ruff-bd table.ruff_deflist td:first-child {
        white-space: nowrap;      /* never wrap */
        overflow-wrap: normal;
        word-break: normal;
    }
}
::fileutil::appendToFile [file join $docDir assets ruff-min.css] $tableWrapping

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
                       !ticklechart_mark_diode_extract_ngspice! diode_extract.html\
                       !ticklechart_mark_inverter_optimization_plot_ngspice! inverter_optimization_plot.html\
                       !ticklechart_mark_inverter_optimization_waveforms_ngspice! inverter_optimization_waveforms_plot.html]
fileutil::updateInPlace [file join $docDir index-Advanced.html] processContentsTutorial
set chartsMap [dcreate !ticklechart_mark_c432_test_with_parsing_ngspice! c432_test_with_parsing.html]
fileutil::updateInPlace [file join $docDir index-Parser.html] processContentsTutorial
