# source main file
lappend auto_path "../../"
package require SpiceGenTcl
package require ticklecharts
set ::ticklecharts::theme dark
# import class names to current namespace
namespace import ::SpiceGenTcl::*
importNgspice
        
        
oo::class create Core {
    superclass Device
    constructor {args} {
        set arguments [argparse -inline -pfirst -helplevel 1 -help {} {
            {-model= -required -help {Model of the core}}
            {-len= -default 0.1 -help {Length of the core}}
            {-area= -default 1 -help {Cross-section area of the core}}
            {name -help {Name of the device without first-letter designator}}
            {pNode -help {Name of node connected to positive pin}}
            {nNode -help {Name of node connected to negative pin}}
        }]
        lappend params [list model [dget $arguments model] -posnocheck]
        dict for {paramName value} $arguments {
            if {$paramName ni {model name pNode nNode}} {
                lappend params [list $paramName $value]
            }
        }
        next n[dget $arguments name] [list [list p [dget $arguments pNode]] [list n [dget $arguments nNode]]] $params
    }
}

oo::class create CoreModel {
    superclass Model
    constructor {args} {
        next {*}[my argsPreprocess {ms a k alpha c} {name type} type {*}[linsert $args 1 coreja]]
    }
}

oo::class create Gap {
    superclass Device
    constructor {args} {
        set arguments [argparse -inline -pfirst -helplevel 1 -help {} {
            {-model= -required -help {Model of the gap}}
            {-len= -required -help {Length of the gap}}
            {-area= -required -help {Cross-section area of the gap}}
            {name -help {Name of the device without first-letter designator}}
            {pNode -help {Name of node connected to positive pin}}
            {nNode -help {Name of node connected to negative pin}}
        }]
        lappend params [list model [dget $arguments model] -posnocheck]
        dict for {paramName value} $arguments {
            if {$paramName ni {model name pNode nNode}} {
                lappend params [list $paramName $value]
            }
        }
        next n[dget $arguments name] [list [list p [dget $arguments pNode]] [list n [dget $arguments nNode]]] $params
    }
}

oo::class create GapModel {
    superclass Model
    constructor {args} {
        argparse -helplevel 1 -help {} {
            {name -help {Name of the model}}
        }
        next $name gap
    }
}

oo::class create Winding {
    superclass Device
    constructor {args} {
        set arguments [argparse -inline -pfirst -help {} {
            {-model= -required -help {Model of the gap}}
            {-turns= -required -help {Number of turns}}
            {name -help {Name of the device without first-letter designator}}
            {e1Node -help {Name of node connected to first electrical pin}}
            {e2Node -help {Name of node connected to second electrical pin}}
            {m1Node -help {Name of node connected to first magnetic pin}}
            {m2Node -help {Name of node connected to second magnetic pin}}
        }]
        lappend params [list model [dget $arguments model] -posnocheck]
        dict for {paramName value} $arguments {
            if {$paramName ni {model name e1Node e2Node m1Node m2Node}} {
                lappend params [list $paramName $value]
            }
        }
        next n[dget $arguments name] [list [list e1 [dget $arguments e1Node]] [list e2 [dget $arguments e2Node]]\
                                              [list m1 [dget $arguments m1Node]] [list m2 [dget $arguments m2Node]]]\
                $params
    }
}

oo::class create WindingModel {
    superclass Model
    constructor {args} {
        argparse -helplevel 1 -help {} {
            {name -help {Name of the model}}
        }
        next {*}[my argsPreprocess r {name type} type {*}[linsert $args 1 winding]]
    }
}
set dir [file dirname [file normalize [info script]]]
set control ".control
pre_osdi [file join $dir verilog_a core.osdi]
pre_osdi [file join $dir verilog_a gap.osdi]
pre_osdi [file join $dir verilog_a winding.osdi]
.endc"
set osdiInclude [RawString new $control]
set core1 [Core new c1 mi m1 -model coremodel -len 60m -area 4u]
set phCore [Vdc new phmeas m mi -dc 0]
set core2 [Core new c2 m m2a -model coremodel -len 20m -area 8u]
set core3 [Core new c3 m m3a -model coremodel -len 60m -area 4u]
set coreModel [CoreModel new coremodel -ms 1.7meg -a 1100 -k 2000 -alpha 1.6m -c 0.2]
set gap1 [Gap new g1 m2a m2b -model gapmodel -len 0.4m -area 8u]
set gap2 [Gap new g2 m 0 -model gapmodel -len 20m -area 80u]
set gapModel [GapModel new gapmodel]
set wind1 [Winding new w1 e1 0 m1 0 -model windmodel -turns 200]
set wind2 [Winding new w2 e2 0 m2b 0 -model windmodel -turns 200]
set wind3a [Winding new w3a e3 0 m3a m3b -model windmodel -turns 100]
set wind3b [Winding new w3b e4 0 m3b 0 -model windmodel -turns 10]
set windModel [WindingModel new windmodel]
set vsin [Vsin new si 0 vs -freq 1k -va 1 -v0 0.0]
set vpwl [Vpwl new i vr 0 -seq {0 0 0.3m 15 7m 2}]
set vin [B new in vi 0 -v {v(vs)*v(vr)}]
set r1 [R new 1 vi e1 -r 2]
set r2 [R new 2 e2 0 -r 2]
set r3a [R new 3a e3 0 -r 2]
set r3b [R new 3b e4 0 -r 2]
set circuit [Circuit new transformer]
set tran [Tran new -name sineResp -tstop 6.75m -tstep 0.01m]
$circuit add $core1 $phCore $core2 $core3 $gap1 $gap2 $wind1 $wind2 $wind3a $wind3b $vsin $vpwl $vin $r1 $r2 $r3a $r3b
$circuit add $coreModel $gapModel $windModel
$circuit add $tran
$circuit add $osdiInclude
$circuit configure -simulator [Batch new {batch1}]
$circuit runAndRead
set data [$circuit getDataDict]
foreach time [dget $data time] m [dget $data v(m)] m1 [dget $data v(m1)] ph1 [dget $data i(vphmeas)] {
    lappend timeMmf [list $time [= {($m-$m1)}]]
    lappend timePh1 [list $time [= {$ph1}]]
    lappend hb [list [= {($m-$m1)/60e-3}] [= {$ph1/4e-6}]]
}

# plot results with ticklecharts
set chart [ticklecharts::chart new]
$chart Xaxis -name "H, A (A t)" -minorTick {show "True"}  -type "value" -splitLine {show "True"}
$chart Yaxis -name "B, T" -minorTick {show "True"}  -type "value" -splitLine {show "True"} -min "-2"\
        -max "2"
$chart SetOptions -title {} -tooltip {} -animation "False" -legend {} -toolbox {feature {dataZoom {yAxisIndex "none"}}}\
        -grid {left "10%" right "15%"} -backgroundColor "#212121"
$chart Add "lineSeries" -data $hb -showAllSymbol "nothing" -name "fitted" -symbolSize "4"
set fbasename [file rootname [file tail [info script]]]
$chart Render -outfile [file normalize [file join .. html_charts $fbasename.html]]
