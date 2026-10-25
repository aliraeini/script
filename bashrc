#!/bin/bash

myUprDIR=$(cd "$(dirname ${BASH_SOURCE[0]})/.." && pwd)
if [  -n "$MS_INST" ] && [  "$PATH" == *"$MS_INST/bin"* ]; then
	echo "Info: msSrc(=$msSrc) is NOT reset from $myUprDIR"
	if [ "$msSrc" != "$myUprDIR" ]; then
		echo "Hint, try reseting your (terminal) session and its settings";
	fi
else

	export msSrc="$myUprDIR"
	# msRoot (.env, inst/, build/, test_runs/) is msSrc, or the folder above it if msSrc is called src, as in Makefile.in
	if [ "$(basename "$msSrc")" == "src" ]; then export msRoot=$( cd "$msSrc/../" && pwd ); else export msRoot="$msSrc"; fi
	if [ -f "$msRoot/.env" ]; then set -a; source "$msRoot/.env"; set +a; fi
	export MS_INST=${MS_INST:-$msRoot/inst}
	[ "$MS_INST" != "$HOME" ] || ! echo "Bad MS_INST: $MS_INST, put apps inside another subfolder and try again" || return
	export msBinDir=$MS_INST/bin
	export msLibDir=$MS_INST/lib
	export msIncDir=$MS_INST/include
	export msBilDir=${msBilDir:-$msRoot/build}
	export MS_TEST_DIR=${MS_TEST_DIR:-$msRoot/test_runs}

	# prepend, so that these binaries take precedence over any other installation
	export PATH=$msBinDir:$msBinDir/foamxm:$msSrc/script:$msSrc/porefoam1f/script:$msSrc/porefoam2f/script:$PATH
	export LD_LIBRARY_PATH=$msLibDir:$LD_LIBRARY_PATH

	# Openfoam vars
	export FOAM_ABORT=1

	export PYTHONPATH=$msSrc/script:$msSrc/pylib:$PYTHONPATH

	if ! [ -d $msBinDir ]; then
		mkdir -p $msBinDir;
		mkdir -p $msLibDir;
		mkdir -p $msIncDir;
	fi
fi
