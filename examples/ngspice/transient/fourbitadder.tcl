# example is from Ngspice example folder (/tests/transient/fourbitadder.cir)

package require SpiceGenTcl
package require ticklecharts
namespace import ::tcl::mathop::*
namespace import ::SpiceGenTcl::*
importNgspice


# create class that represents NAND subcircuit
oo::class create NAND {
    superclass Subcircuit
    constructor {} {
        # define external pins of subcircuit
        set pins {1 2 3 4}
        # define input parameters of subcircuit
        set params {}
        # add elements to subcircuit definition
        my add [Q new 1 9 5 1 -model qmod] [D new 1clamp 0 1 -model dmod] [Q new 2 9 5 2 -model qmod]\
                [D new 2clamp 0 2 -model dmod] [R new b 4 5 -r 4e3] [R new 1 4 6 -r 1.6e3] [Q new 3 6 9 8 -model qmod]\
                [R new 2 8 0 -r 1e3] [R new c 4 7 -r 130] [Q new 4 7 6 10 -model qmod] [D new vbedrop 10 3 -model dmod]\
                [Q new 5 3 8 0 -model qmod]
        # pass name, list of pins and list of parameters to Subcircuit constructor
        next nand $pins $params
    }
}
# create NAND subcircuit definition instance
set nand [NAND new]

# create class that represents ONEBIT subcircuit
oo::class create ONEBIT {
    superclass Subcircuit
    constructor {} {
        # define external pins of subcircuit
        set pins {1 2 3 4 5 6}
        # define input parameters of subcircuit
        set params {}
        # add elements to subcircuit definition
        global variable nand
        my add [XAuto new $nand x1 "1 2 7 6"] [XAuto new $nand x2 "1 7 8 6"] [XAuto new $nand x3 "2 7 9 6"]\
                [XAuto new $nand x4 "8 9 10 6"] [XAuto new $nand x5 "3 10 11 6"] [XAuto new $nand x6 "3 11 12 6"]\
                [XAuto new $nand x7 "10 11 13 6"] [XAuto new $nand x8 "12 13 4 6"] [XAuto new $nand x9 "11 7 5 6"]
        # pass name, list of pins and list of parameters to Subcircuit constructor
        next onebit $pins $params
    }
}
# create ONEBIT subcircuit definition instance
set onebit [ONEBIT new]

# create class that represents TWOBIT subcircuit
oo::class create TWOBIT {
    superclass Subcircuit
    constructor {} {
        # define external pins of subcircuit
        set pins {1 2 3 4 5 6 7 8 9}
        # define input parameters of subcircuit
        set params {}
        # add elements to subcircuit definition
        global variable onebit
        my add [XAuto new $onebit x1 "1 2 7 5 10 9"] [XAuto new $onebit x2 "3 4 10 6 8 9"]
        # pass name, list of pins and list of parameters to Subcircuit constructor
        next twobit $pins $params
    }
}
# create TWOBIT subcircuit definition instance
set twobit [TWOBIT new]

# create class that represents FOURBIT subcircuit
oo::class create FOURBIT {
    superclass Subcircuit
    constructor {} {
        # define external pins of subcircuit
        set pins {1 2 3 4 5 6 7 8 9 10 11 12 13 14 15}
        # define input parameters of subcircuit
        set params {}
        # add elements to subcircuit definition
        global variable twobit
        my add [XAuto new $twobit x1 "1 2 3 4 9 10 13 16 15"] [XAuto new $twobit x2 "5 6 7 8 11 12 16 14 15"] 
        # pass name, list of pins and list of parameters to Subcircuit constructor
        next fourbit $pins $params
    }
}
# create FOURBIT subcircuit definition instance
set fourbit [FOURBIT new]

# create top-level circuit
set circuit [Circuit new {Four-bit adder}]
# add elements to circuit
$circuit add [Tran new -tstep 1e-9 -tstop 10e-6]
$circuit add [Options new {{noacct -sw}}]
$circuit add $nand $onebit $twobit $fourbit
$circuit add [XAuto new $fourbit x18 {1 2 3 4 5 6 7 8 9 10 11 12 0 13 99}]

set trtf 10e-9
set tonStep 10e-9
set perStep 50e-9
$circuit add [Vdc new cc 99 0 -dc 5]
set i 1
foreach name [list in1a in1b in2a in2b in3a in3b in4a in4b] {
    $circuit add [Vpulse new $name $i 0 -low 0 -high 3 -td 0 -tf $trtf -tr $trtf -pw [= {$tonStep*pow(2,$i-1)}]\
                          -per [= {$perStep*pow(2,$i-1)}]]
    incr i
}

$circuit add [R new bit0 9 0 -r 1e3] [R new bit1 10 0 -r 1e3] [R new bit2 11 0 -r 1e3] [R new bit3 12 0 -r 1e3]\
        [R new cout 13 0 -r 1e3]
$circuit add [DiodeModel new dmod] [BjtGPModel new qmod npn -bf 75 -rb 100 -cje 1e-12 -cjc 3e-12]

#set simulator with default temporary directory
set simulator [BatchLiveLog new {batch1}]
# attach simulator object to circuit
$circuit configure -simulator $simulator
# run circuit, read log and data
$circuit runAndRead
# get data dict
set data [$circuit getDataDict]
set timeList [dget $data time]
set v9List [dget $data v(9)]
set v10List [dget $data v(10)]
set v11List [dget $data v(11)]
set v12List [dget $data v(12)]

foreach time $timeList v9 $v9List v10 $v10List v11 $v11List v12 $v12List {
    lappend timeV9 [list $time $v9]
    lappend timeV10 [list $time $v10]
    lappend timeV11 [list $time $v11]
    lappend timeV12 [list $time $v12]
}

# plot data with ticklecharts
set nodes [list 9 10 11 12]
set layout [ticklecharts::Gridlayout new]
set i 0
foreach node $nodes {
    ticklecharts::chart create chartV$node
    chartV$node SetOptions -title {} -tooltip {trigger "axis"} -animation "False"\
            -toolbox {feature {dataZoom {yAxisIndex "none"}}}
    chartV$node Xaxis -name "time, s" -minorTick {show "True"} -type "value" -splitLine {show "True"}
    chartV$node Yaxis -name "v(${node}), V" -minorTick {show "True"} -type "value" -splitLine {show "True"}
    chartV$node Add "lineSeries" -data [subst $[subst timeV$node]] -showAllSymbol "nothing" -name "V(${node})"\
            -symbolSize "0"
    $layout Add chartV$node -bottom "[= {4+24*$i}]%" -height "18%" -width "80%"
    incr i
}

set fbasename [file rootname [file tail [info script]]]
$layout Render -outfile [file normalize [file join .. html_charts $fbasename.html]] -width 800px -height 500px
