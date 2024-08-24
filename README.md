This package provides Tcl interface to different SPICE and SPICE-like simulator, Ngspice, Xyce.
It was inspired by [PySpice](https://github.com/PySpice-org/PySpice) project, object-oriented interface to SPICE-like simulators written in Python.

## General concept
The general concept of package is building netlist by using Tcl scripts. 
It is based on TclOO object-oriented system, where all elements are represented by objects, 
including elements, models, analyses, waveforms, netlists, etc. After netlist definition you can run simulation, read result data and then process/display data using Tcl scripting language. 

This approach is different from [Tclspice](https://ngspice.sourceforge.io/tclspice.html) extension that comes
together with Ngspice and tightly binded to internal structures of simulator. SpiceGenTcl provides more flexible approach 
that could be extended for applying to different simulators that follow the concept of netlists with similar syntax.

## Install and dependencies
To install the package you should extract archive with source code and add path of the package folder to *auto_path*
variable. Package is written in pure Tcl with relying on Tcllib and Tklib. The only necessary external dependency is 
the simulator itself.

- [Ngspice](https://ngspice.sourceforge.io/download.html)
- [Tcllib](https://www.tcl.tk/software/tcllib/)
- [Tklib](https://www.tcl.tk/software/tklib/)