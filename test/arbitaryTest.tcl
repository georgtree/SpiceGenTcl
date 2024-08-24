lappend auto_path "../"
package require SpiceGenTcl
namespace import ::SpiceGenTcl::*
set ngspiceNameSpc [namespace children ::SpiceGenTcl::Ngspice]
foreach nameSpc $ngspiceNameSpc {
    namespace import ${nameSpc}::*
}



#set circuit [Circuit new {voltage divider netlist}]
#
#$circuit add [Vdc new 1 in 0 1]
#$circuit add [R new 1 in out 1e3]
#$circuit add [R new 2 out 0 2e3]
#$circuit add [Dc new vdc1 0 5 1]
#
#puts [$circuit genSPICEString]
#
##set simulator [NgspiceBatch new {batch1} {/usr/local/bin/} $scriptPath]
#set simulator [NgspiceBatch new {batch1} {/usr/local/bin/}]
#$circuit attachSimulator $simulator
#$circuit runAndRead
#set dataObj [$circuit getData]
#set axis [[$dataObj getAxis] getDataPoints]
#set trace [[$dataObj getTrace v(out)]  getDataPoints]
#gnuplotutil::plotXYN $axis -xlabel "x label" -ylabel "y label" -delete -grid -names v(outs) -columns $trace

set elem [VSwitch new 1 net1 0 netc 0 sw1 -on]

puts [$elem genSPICEString]
