#!/bin/bash -norc
dnl	This file is an input file used by the GNU "autoconf" program to
dnl	generate the file "configure", which is run during Tcl installation
dnl	to configure the system for the local environment.

AC_INIT([SpiceGenTcl],[0.71])
TEA_INIT()
AC_CONFIG_AUX_DIR(tclconfig)
TEA_PATH_TCLCONFIG
TEA_LOAD_TCLCONFIG
TEA_PREFIX
TEA_ADD_SOURCES([])
TEA_ADD_HEADERS([])
TEA_ADD_INCLUDES([])
TEA_ADD_LIBS([])
TEA_ADD_CFLAGS([])
TEA_ADD_STUB_SOURCES([])
TEA_ADD_TCL_SOURCES([SpiceGenTcl.tcl src/generalClasses.tcl src/specElementsClassesCommon.tcl
                     src/specAnalysesClassesCommon.tcl src/ngspice/specAnalysesClassesNgspice.tcl
                     src/ngspice/specElementsClassesNgspice.tcl src/ngspice/specModelsClassesNgspice.tcl
                     src/ngspice/specSimulatorClassesNgspice.tcl src/ngspice/netlistParserClassNgspice.tcl
                     src/ngspice/specMiscClassesNgspice.tcl src/xyce/specAnalysesClassesXyce.tcl
                     src/xyce/specElementsClassesXyce.tcl src/xyce/specModelsClassesXyce.tcl
                     src/xyce/specSimulatorClassesXyce.tcl src/ltspice/specAnalysesClassesLtspice.tcl
                     src/ltspice/specElementsClassesLtspice.tcl src/ltspice/specModelsClassesLtspice.tcl
                     src/ltspice/specSimulatorClassesLtspice.tcl])

# The package uses Tcl 9 APIs despite containing only Tcl scripts.
if test "$TCL_MAJOR_VERSION" -lt 9; then
    AC_MSG_ERROR([SpiceGenTcl requires Tcl 9])
fi
# Discover documentation at make time, including files generated after configure.
AC_ARG_VAR([TCLLIBPATH], [Tcl list of directories containing build/test/doc dependencies])
TEA_PROG_TCLSH
#TEA_PROG_WISH
AC_SUBST(TCLLIBPATH)
AC_CONFIG_FILES([Makefile pkgIndex.tcl])
AC_OUTPUT
