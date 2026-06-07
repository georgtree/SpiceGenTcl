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

DOC_HTML_FILES="index.html objects.inv search.html searchindex.js genindex.html"
DOC_SRCDIR="${srcdir}/docs"
if test -d "$DOC_SRCDIR"; then
    # Add all top-level *.html files from docs/, not subdirectories.
    for f in "$DOC_SRCDIR"/*.html; do
        test -f "$f" || continue

        b=`basename "$f"`

        case " $DOC_HTML_FILES " in
            *" $b "*) ;;
            *) DOC_HTML_FILES="$DOC_HTML_FILES $b" ;;
        esac
    done
    # Add everything from docs/_static and docs/assets recursively.
    for d in _static assets; do
        if test -d "$DOC_SRCDIR/$d"; then
            for f in `find "$DOC_SRCDIR/$d" -type f -print`; do
                rel=`echo "$f" | sed "s|^$DOC_SRCDIR/||"`

                case " $DOC_HTML_FILES " in
                    *" $rel "*) ;;
                    *) DOC_HTML_FILES="$DOC_HTML_FILES $rel" ;;
                esac
            done
        fi
    done

else
    AC_MSG_WARN([documentation directory not found: $DOC_SRCDIR])
fi
#AC_MSG_NOTICE([DOC_HTML_FILES = $DOC_HTML_FILES])
AC_SUBST([DOC_HTML_FILES])

# Test files to include in the distribution.
# Paths are relative to $srcdir.
DIST_TEST_FILES="test/specElemsClassesCommon.test test/generalClasses.test test/testUtilities.tcl test/all.tcl"
# Add everything from test/xyce, test/ngspice, and test/ltspice recursively.
for d in test/xyce test/ngspice test/ltspice; do
    if test -d "$srcdir/$d"; then
        for f in `cd "$srcdir" && find "$d" -type f -print`; do
            case " $DIST_TEST_FILES " in
                *" $f "*) ;;
                *) DIST_TEST_FILES="$DIST_TEST_FILES $f" ;;
            esac
        done
    fi
done
#AC_MSG_NOTICE([DIST_TEST_FILES = $DIST_TEST_FILES])
AC_SUBST([DIST_TEST_FILES])

TEA_PROG_TCLSH
#TEA_PROG_WISH
AC_SUBST(TCLLIBPATH)
AC_CONFIG_FILES([Makefile pkgIndex.tcl])
AC_OUTPUT
